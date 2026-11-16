import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/organization.dart';
import '../domain/platform.dart';
import '../domain/repositories.dart';

/// Production Platform Super Admin. Reads are rule-protected (platform
/// claim); every write is a callable in functions/src/triggers/v18.ts that
/// re-checks the claim, validates, versions and audits the change.
class FirebasePlatformRepository implements PlatformRepository {
  FirebasePlatformRepository(this.db, this.functions);

  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  /// Maps the server's version conflict (`aborted`, details.currentVersion).
  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final r = await functions.httpsCallable(name).call<Object?>(data);
      final d = r.data;
      return d is Map ? d.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      if (e.code == 'aborted' && details is Map && details['currentVersion'] is num) {
        throw ConfigConflictException((details['currentVersion'] as num).toInt());
      }
      return guardFirebase(() => Future.error(e));
    }
  }

  Future<OrgConfig> _config(String orgId) async {
    final d = await db.collection('orgConfigs').doc(orgId).get();
    return d.exists ? OrgConfig.fromMap(d.id, d.data()!) : OrgConfig.legacy(orgId);
  }

  @override
  Stream<PlatformStats> watchStats() async* {
    final r = await _call('platformStats', {});
    int n(String k) => (r[k] as num?)?.toInt() ?? 0;
    yield PlatformStats(
      organizations: n('organizations'),
      active: n('active'),
      suspended: n('suspended'),
      trial: n('trial'),
      users: n('users'),
      coaches: n('coaches'),
      students: n('students'),
      parents: n('parents'),
      adoption: {for (final m in OrgModule.values) m: ((r['adoption'] as Map?)?[m.name] as num?)?.toInt() ?? 0},
      bySubscription: {
        for (final st in SubscriptionStatus.values) st: ((r['bySubscription'] as Map?)?[st.name] as num?)?.toInt() ?? 0,
      },
      alerts: [
        for (final a in (r['alerts'] as List?) ?? const [])
          PlatformAlert(
            AlertKind.values.firstWhere((k) => k.name == (a as Map)['kind'], orElse: () => AlertKind.overLimit),
            '${(a as Map)['orgId']}',
            detail: '${a['detail'] ?? ''}',
          ),
      ],
    );
  }

  @override
  Stream<List<SubscriptionPackage>> watchPackages() => db
      .collection('subscriptionPackages')
      .snapshots()
      .map((s) => [for (final d in s.docs) SubscriptionPackage.fromMap(d.id, d.data())])
      .mapFirebaseErrors();

  @override
  Future<SubscriptionPackage> upsertPackage(SubscriptionPackage p) async {
    final r = await _call('upsertPackage', {'id': p.id, ...p.toMap()});
    return p.copyWith(id: r['id'] as String);
  }

  @override
  Stream<List<OrgTemplate>> watchTemplates() => db
      .collection('orgTemplates')
      .snapshots()
      .map((s) => [for (final d in s.docs) OrgTemplate.fromMap(d.id, d.data())])
      .mapFirebaseErrors();

  @override
  Future<OrgTemplate> upsertTemplate(OrgTemplate t) async {
    final r = await _call('upsertTemplate', {'id': t.id, ...t.toMap()});
    return t.copyWith(id: r['id'] as String);
  }

  @override
  Future<OrgTemplate> duplicateTemplate(String templateId) async {
    final r = await _call('duplicateTemplate', {'templateId': templateId});
    final d = await db.collection('orgTemplates').doc(r['id'] as String).get();
    return OrgTemplate.fromMap(d.id, d.data() ?? const {});
  }

  @override
  Future<void> archiveTemplate(String templateId, {required bool archived}) =>
      _call('archiveTemplate', {'templateId': templateId, 'archived': archived});

  @override
  Future<ProvisionResult> provisionOrganization(ProvisionRequest r) async {
    final res = await _call('provisionOrganization', {
      'names': r.names,
      'legalName': r.legalName,
      'type': r.type.name,
      'funding': r.funding.name,
      'registrationId': r.registrationId,
      'address': r.address,
      'city': r.city,
      'lat': r.lat,
      'lng': r.lng,
      'contactEmail': r.contactEmail,
      'contactPhone': r.contactPhone,
      'description': r.description,
      'logoUrl': r.logoUrl,
      'primaryColor': r.primaryColor,
      'secondaryColor': r.secondaryColor,
      'sportIds': r.sportIds,
      'timezone': r.timezone,
      'defaultLanguage': r.defaultLanguage,
      'packageId': r.packageId,
      'templateId': r.templateId,
      if (r.modules != null) 'modules': [for (final m in r.modules!) m.name],
      'subscription': {...r.subscription.toMap(), 'startAt': null, 'endAt': r.subscription.endAt?.toIso8601String()},
      'adminPhone': r.adminPhone,
      'adminEmail': r.adminEmail,
    });
    final inv = await db.collection('orgInvitations').doc(res['invitationId'] as String).get();
    return ProvisionResult(
      orgId: res['orgId'] as String,
      invitation: OrgInvitation.fromMap(inv.id, inv.data() ?? (throw const NotFoundException())),
      token: res['token'] as String,
    );
  }

  @override
  Future<List<TemplateChange>> previewTemplate(String orgId, String templateId) async {
    final t = await db.collection('orgTemplates').doc(templateId).get();
    return TemplateDiff.compute(await _config(orgId), OrgTemplate.fromMap(t.id, t.data() ?? const {}));
  }

  @override
  Future<OrgConfig> applyTemplate(
    String orgId,
    String templateId, {
    required int expectedVersion,
    required String reason,
  }) async {
    await _call('applyTemplate', {
      'orgId': orgId,
      'templateId': templateId,
      'expectedVersion': expectedVersion,
      'reason': reason,
    });
    return _config(orgId);
  }

  @override
  Future<OrgConfig> updateEntitlements(
    String orgId, {
    required int expectedVersion,
    required Set<OrgModule> allowed,
    Map<OrgModule, FeatureRollout> rollout = const {},
    required String reason,
  }) async {
    await _call('updateEntitlements', {
      'orgId': orgId,
      'expectedVersion': expectedVersion,
      'allowed': [for (final m in allowed) m.name],
      'rollout': {
        for (final e in rollout.entries)
          e.key.name: {
            'state': e.value.state.name,
            'until': e.value.until?.toUtc().toIso8601String(),
            'at': e.value.at?.toUtc().toIso8601String(),
          },
      },
      'reason': reason,
    });
    return _config(orgId);
  }

  @override
  Future<OrgConfig> updateSubscription(
    String orgId, {
    required int expectedVersion,
    String? packageId,
    SubscriptionInfo? subscription,
    OrgLimits? limits,
    required String reason,
  }) async {
    await _call('updateSubscription', {
      'orgId': orgId,
      'expectedVersion': expectedVersion,
      'packageId': ?packageId,
      if (subscription != null)
        'subscription': {
          'status': subscription.status.name,
          'endAt': subscription.endAt?.toUtc().toIso8601String(),
          'graceDays': subscription.graceDays,
          'note': subscription.note,
        },
      if (limits != null) 'limits': limits.toMap(),
      'reason': reason,
    });
    return _config(orgId);
  }

  @override
  Stream<List<ConfigHistoryEntry>> watchHistory(String orgId) => db
      .collection('orgConfigs')
      .doc(orgId)
      .collection('history')
      .orderBy('version', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            ConfigHistoryEntry(
              orgId: orgId,
              version: (d.data()['version'] as num?)?.toInt() ?? 0,
              at: (d.data()['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
              by: d.data()['by'] as String? ?? '',
              reason: d.data()['reason'] as String? ?? '',
              changes: ((d.data()['changes'] as List?) ?? const []).cast<String>(),
            ),
        ],
      )
      .mapFirebaseErrors();

  @override
  Future<OrgUsage> usage(String orgId) async {
    final r = await _call('orgUsage', {'orgId': orgId});
    int n(String k) => (r[k] as num?)?.toInt() ?? 0;
    return OrgUsage(
      coaches: n('coaches'),
      students: n('students'),
      groups: n('groups'),
      rooms: n('rooms'),
      storageMb: n('storageMb'),
      notificationsThisMonth: n('notificationsThisMonth'),
      smsThisMonth: n('smsThisMonth'),
    );
  }

  @override
  Stream<List<OrgInvitation>> watchInvitations({String? orgId}) {
    Query<Map<String, dynamic>> q = db.collection('orgInvitations');
    if (orgId != null) q = q.where('orgId', isEqualTo: orgId);
    return q
        .snapshots()
        .map((s) => [for (final d in s.docs) OrgInvitation.fromMap(d.id, d.data())])
        .mapFirebaseErrors();
  }

  Future<InvitationIssued> _issued(Map<String, dynamic> r) async {
    final d = await db.collection('orgInvitations').doc(r['invitationId'] as String).get();
    return InvitationIssued(
      OrgInvitation.fromMap(d.id, d.data() ?? (throw const NotFoundException())),
      r['token'] as String,
    );
  }

  @override
  Future<InvitationIssued> inviteAdmin(String orgId, {String? phone, String? email, String? transferFrom}) async =>
      _issued(
        await _call('inviteOrgAdmin', {
          'orgId': orgId,
          'phone': ?phone,
          'email': ?email,
          'transferFrom': ?transferFrom,
        }),
      );

  @override
  Future<InvitationIssued> resendInvitation(String invitationId) async =>
      _issued(await _call('resendInvitation', {'invitationId': invitationId}));

  @override
  Future<void> revokeInvitation(String invitationId) => _call('revokeInvitation', {'invitationId': invitationId});

  @override
  Future<String> acceptInvitation(String token) async =>
      (await _call('acceptInvitation', {'token': token}))['orgId'] as String;

  @override
  Future<void> rejectInvitation(String token) => _call('rejectInvitation', {'token': token});

  /// Runs hourly on the server schedule (`refreshEntitlements`); the
  /// platform admin can also run it now (`refreshEntitlementsNow`).
  @override
  Future<List<String>> refreshEntitlements() async =>
      ((await _call('refreshEntitlementsNow', {}))['changed'] as List? ?? const []).cast<String>();
}
