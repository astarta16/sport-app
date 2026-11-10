import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../demo/data/demo_backend.dart';
import '../../payments/domain/payment.dart';
import '../domain/account_request.dart';

/// Server-side account deletion (mirrors `processAccountRequests`):
/// * children with another guardian are only unlinked;
/// * solely-owned children are deleted with certificates (+files), RSVPs,
///   attendance, feedback, avatars and pending invites;
/// * payments are anonymised (`parentId: deleted`) and kept for the club.
class DemoAccountDeletion {
  DemoAccountDeletion._();

  static DeletionImpact impact(DemoBackend db, String uid) {
    final owned = db.children.values.where((c) => c.parentIds.contains(uid)).toList();
    return DeletionImpact(
      deletedChildren: [
        for (final c in owned)
          if (c.parentIds.length == 1) c.fullName,
      ],
      unlinkedChildren: [
        for (final c in owned)
          if (c.parentIds.length > 1) c.fullName,
      ],
    );
  }

  static void run(DemoBackend db, String uid) {
    final owned = db.children.values.where((c) => c.parentIds.contains(uid)).toList();
    for (final c in owned) {
      final others = c.parentIds.where((p) => p != uid).toList();
      if (others.isNotEmpty) {
        db.children[c.id] = c.copyWith(parentIds: others);
        continue;
      }
      for (final cert in db.certificates.values.where((x) => x.childId == c.id).toList()) {
        db.certificateFiles.remove(cert.storagePath);
        db.certificates.remove(cert.id);
      }
      db.rsvps.removeWhere((_, r) => r.childId == c.id);
      db.attendance.removeWhere((_, a) => a.childId == c.id);
      db.feedback.removeWhere((_, f) => f.childId == c.id);
      if (c.photoPath != null) db.photos.remove(c.photoPath);
      db.children.remove(c.id);
      for (final g in db.groups.values.toList()) {
        db.groups[g.id] = g.copyWith(memberChildIds: g.memberChildIds.where((id) => id != c.id).toList());
      }
    }
    for (final p in db.payments.values.where((p) => p.parentId == uid).toList()) {
      db.payments[p.id] = Payment(
        id: p.id,
        childId: p.childId,
        parentId: 'deleted',
        groupId: p.groupId,
        sportId: p.sportId,
        amount: p.amount,
        currency: p.currency,
        dueDate: p.dueDate,
        status: p.status == PaymentStatus.pending ? PaymentStatus.cancelled : p.status,
        paidAt: p.paidAt,
        createdAt: p.createdAt,
        planId: p.planId,
        cancelledReason: p.status == PaymentStatus.pending ? 'account deleted' : p.cancelledReason,
        title: p.title,
      );
    }
    db.rsvps.removeWhere((_, r) => r.parentId == uid);
    db.notifications.removeWhere((n) => n.userId == uid);
    final u = db.users[uid];
    if (u?.photoPath != null) db.photos.remove(u!.photoPath);
    db.users.remove(uid);
    db.recomputeMemberships();
  }
}

class DemoAccountRepository implements AccountRepository {
  DemoAccountRepository(this.db);

  final DemoBackend db;

  /// Export files (`exports/{uid}/{id}.json`) — demo keeps them in memory.
  final _exports = <String, String>{};

  @override
  Stream<List<AccountRequest>> watchMyRequests() => db.watch(() {
    final me = db.currentUser;
    if (me == null) return const <AccountRequest>[];
    return db.accountRequests.values.where((r) => r.uid == me.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<DeletionImpact> deletionImpact() async => DemoAccountDeletion.impact(db, db.me.id);

  @override
  Future<AccountRequest> requestDeletion() async {
    db.requireOnline();
    final me = db.me;
    final r = AccountRequest(id: db.newId('acc'), uid: me.id, type: AccountRequestType.delete, createdAt: db.clock());
    db.accountRequests[r.id] = r;
    db.auditLog('account.deleteRequest', 'user', me.id);
    // Demo runs the server job immediately.
    DemoAccountDeletion.run(db, me.id);
    db.accountRequests[r.id] = AccountRequest.fromMap(r.id, {
      'uid': me.id,
      'type': 'delete',
      'status': 'done',
      'createdAt': r.createdAt,
      'completedAt': db.clock(),
    });
    db.session = null;
    db.commit();
    return db.accountRequests[r.id]!;
  }

  @override
  Future<AccountRequest> requestExport() async {
    db.requireOnline();
    final me = db.me;
    final pending = db.accountRequests.values.any(
      (r) => r.uid == me.id && r.type == AccountRequestType.export && r.status == AccountRequestStatus.pending,
    );
    if (pending) throw const ValidationException('requestExists');
    db.rateLimit('export', 3);
    final id = db.newId('acc');
    final path = 'exports/${me.id}/$id.json';
    _exports[path] = _buildExport(me.id);
    db.accountRequests[id] = AccountRequest.fromMap(id, {
      'uid': me.id,
      'type': 'export',
      'status': 'done',
      'createdAt': db.clock(),
      'completedAt': db.clock(),
      'result': path,
    });
    db.auditLog('account.exportRequest', 'user', me.id);
    db.commit();
    return db.accountRequests[id]!;
  }

  /// Demo-only: the JSON a signed URL would serve. Owner only.
  String? exportContent(AccountRequest r) => r.uid == db.currentUser?.id ? _exports[r.resultPath] : null;

  /// Personal data of the user and their children. Medical files are listed
  /// by metadata only (never their contents).
  String _buildExport(String uid) {
    final u = db.users[uid]!;
    final kids = db.children.values.where((c) => c.parentIds.contains(uid)).toList();
    final ids = kids.map((c) => c.id).toSet();
    String iso(DateTime d) => d.toIso8601String();
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': iso(db.clock()),
      'profile': {
        'firstName': u.firstName,
        'lastName': u.lastName,
        'phone': u.phone,
        'role': u.role.name,
        'dataConsentAt': u.dataConsentAt == null ? null : iso(u.dataConsentAt!),
        'smsConsentAt': u.smsConsentAt == null ? null : iso(u.smsConsentAt!),
        'privacy': u.privacy.toMap(),
        'notificationPrefs': u.notificationPrefs.toMap(),
      },
      'children': [
        for (final c in kids)
          {
            'firstName': c.firstName,
            'lastName': c.lastName,
            'birthDate': iso(c.birthDate),
            'sports': c.sportIds,
            'groups': c.groupIds.map((g) => db.groups[g]?.name).toList(),
            'mediaConsent': c.mediaConsent,
          },
      ],
      'medicalCertificates': [
        for (final m in db.certificates.values.where((m) => ids.contains(m.childId)))
          {'childId': m.childId, 'issuedAt': iso(m.issuedAt), 'validUntil': iso(m.validUntil), 'fileName': m.fileName},
      ],
      'attendance': [
        for (final a in db.attendance.values.where((a) => ids.contains(a.childId)))
          {'trainingId': a.trainingId, 'status': a.status.name, 'markedAt': iso(a.markedAt)},
      ],
      'rsvps': [
        for (final r in db.rsvps.values.where((r) => r.parentId == uid))
          {'trainingId': r.trainingId, 'response': r.response.name, 'reason': r.reason},
      ],
      'payments': [
        for (final p in db.payments.values.where((p) => p.parentId == uid))
          {'amount': p.amount, 'currency': p.currency, 'dueDate': iso(p.dueDate), 'status': p.status.name},
      ],
    });
  }
}
