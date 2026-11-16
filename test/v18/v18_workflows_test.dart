import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:sport_parent_app/features/chat/data/demo_chat_repository.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v18.dart';
import 'package:sport_parent_app/features/groups/data/demo_groups_repository.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/organizations/data/demo_org_repositories.dart';
import 'package:sport_parent_app/features/organizations/data/demo_platform_repository.dart';
import 'package:sport_parent_app/features/organizations/domain/organization.dart';
import 'package:sport_parent_app/features/organizations/domain/platform.dart';
import 'package:sport_parent_app/features/organizations/domain/repositories.dart';
import 'package:sport_parent_app/features/payments/data/demo_payments_repository.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/payments/domain/payment_reminders.dart';

final denied = throwsA(isA<PermissionDeniedException>());
Matcher invalid(String code) => throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));
final conflict = throwsA(isA<ConfigConflictException>());

void main() {
  final now = DateTime(2026, 11, 16, 12);
  late DemoBackend db;
  late DemoPlatformRepository platform;
  late DemoOrganizationsRepository orgs;
  setUp(() {
    db = DemoSeed.create(clock: () => now);
    platform = DemoPlatformRepository(db);
    orgs = DemoOrganizationsRepository(db);
  });
  void as(String uid) => db.session = (uid: uid, phone: db.users[uid]!.phone);
  const tianeti = DemoSeedV17.tianeti;
  const saburtalo = DemoSeedV18.saburtalo;

  ProvisionRequest request({
    String? templateId,
    Set<OrgModule>? modules,
    String packageId = SubscriptionPackage.professionalId,
    String? adminPhone = '+995555400701',
    SubscriptionInfo subscription = const SubscriptionInfo(),
  }) => ProvisionRequest(
    names: const {'ka': 'რუსთავის სპორტსკოლა', 'en': 'Rustavi Sports School'},
    legalName: 'Rustavi Sports School (synthetic)',
    funding: FundingType.government,
    type: OrgType.sportsSchool,
    address: 'მშვიდობის ქ. 1',
    city: 'რუსთავი',
    contactEmail: 'info@rustavi.example',
    contactPhone: '+995555400700',
    sportIds: const ['volleyball'],
    packageId: packageId,
    templateId: templateId,
    modules: modules,
    subscription: subscription,
    adminPhone: adminPhone,
  );

  group('seeded demo tenants', () {
    test('Tianeti is a government school without payments; rooms, students, Brain Academy on', () {
      final c = db.orgConfig(tianeti);
      expect(c.profile.funding, FundingType.government);
      for (final m in DemoSeedV18.paymentModules) {
        expect(c.isEnabled(m, now: now), isFalse, reason: m.name);
      }
      for (final m in [
        OrgModule.facilities,
        OrgModule.roomScheduling,
        OrgModule.studentAccounts,
        OrgModule.brainAcademy,
      ]) {
        expect(c.isEnabled(m, now: now), isTrue, reason: m.name);
      }
    });

    test('Saburtalo is a private club with the payments workflow on', () {
      final c = db.orgConfig(saburtalo);
      expect(c.profile.funding, FundingType.private);
      for (final m in DemoSeedV18.paymentModules) {
        expect(c.isEnabled(m, now: now), isTrue, reason: m.name);
      }
    });
  });

  group('provisioning', () {
    test('platform admin provisions an organization; id is stable and unique; admin invited', () async {
      as(DemoIds.platformAdmin);
      final a = await platform.provisionOrganization(request());
      final b = await platform.provisionOrganization(request());
      expect(a.orgId, startsWith('org-rustavi-sports-school-'));
      expect(a.orgId, isNot(b.orgId));
      final c = db.orgConfig(a.orgId);
      expect(c.provisioning, ProvisioningState.ready);
      expect(c.version, greaterThanOrEqualTo(1));
      expect(c.profile.funding, FundingType.government);
      expect(db.clubs[a.orgId]!.name, 'რუსთავის სპორტსკოლა');
      expect(a.invitation.status, InvitationStatus.pending);
      expect(a.invitation.tokenHash, InvitationTokens.hash(a.token));
      expect(a.invitation.tokenHash, isNot(a.token), reason: 'only the hash is stored');
      expect(db.audit.any((e) => e.action == 'org.provision' && e.targetId == a.orgId), isTrue);
    });

    test('only the platform admin may provision', () async {
      as(DemoSeedV17.tianetiAdmin);
      expect(platform.provisionOrganization(request()), denied);
      as(DemoIds.parent);
      expect(platform.provisionOrganization(request()), denied);
    });

    test('invalid requests change nothing', () async {
      as(DemoIds.platformAdmin);
      final clubs = db.clubs.length;
      expect(platform.provisionOrganization(request(adminPhone: null)), invalid('orgAdminMissing'));
      expect(
        platform.provisionOrganization(request(modules: {OrgModule.paymentReceipts})),
        invalid('featureDependencies'),
      );
      expect(
        platform.provisionOrganization(
          request(packageId: SubscriptionPackage.starterId, modules: {OrgModule.trainings, OrgModule.payments}),
        ),
        throwsA(isA<ValidationException>().having((e) => e.code, 'code', startsWith('notInPackage:'))),
      );
      await Future<void>.delayed(Duration.zero);
      expect(db.clubs.length, clubs);
    });

    test('a template sets type, funding and features; archived templates cannot be used', () async {
      as(DemoIds.platformAdmin);
      final r = await platform.provisionOrganization(request(templateId: OrgTemplate.privateClub));
      final c = db.orgConfig(r.orgId);
      expect(c.templateId, OrgTemplate.privateClub);
      expect(c.isEnabled(OrgModule.payments, now: now), isTrue);
      await platform.archiveTemplate(OrgTemplate.privateClub, archived: true);
      expect(platform.provisionOrganization(request(templateId: OrgTemplate.privateClub)), invalid('templateArchived'));
    });
  });

  group('templates', () {
    test('four built-ins exist; duplicate, edit, archive and restore', () async {
      as(DemoIds.platformAdmin);
      expect(db.templates.keys, containsAll(OrgTemplate.builtIns.map((t) => t.id)));
      final copy = await platform.duplicateTemplate(OrgTemplate.government);
      expect(copy.id, isNot(OrgTemplate.government));
      expect(copy.modules, db.templates[OrgTemplate.government]!.modules);
      final edited = await platform.upsertTemplate(copy.copyWith(modules: {...copy.modules, OrgModule.media}));
      expect(db.templates[edited.id]!.modules, contains(OrgModule.media));
      await platform.archiveTemplate(edited.id, archived: true);
      expect(db.templates[edited.id]!.archived, isTrue);
      await platform.archiveTemplate(edited.id, archived: false);
      expect(db.templates[edited.id]!.archived, isFalse);
    });

    test('applying to an existing organization: preview first, then a versioned change', () async {
      as(DemoIds.platformAdmin);
      final before = db.orgConfig(saburtalo);
      final changes = await platform.previewTemplate(saburtalo, OrgTemplate.government);
      expect(changes.map((c) => c.key), contains('module:payments'));
      final after = await platform.applyTemplate(
        saburtalo,
        OrgTemplate.government,
        expectedVersion: before.version,
        reason: 'switch to municipal funding',
      );
      expect(after.version, before.version + 1);
      expect(after.isEnabled(OrgModule.payments, now: now), isFalse);
      // Historical data is kept.
      expect(db.payments['pay-saburtalo-1'], isNotNull);
    });
  });

  group('feature management', () {
    test('disabling payments blocks writes; history keeps version, reason and author', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      await platform.updateEntitlements(
        saburtalo,
        expectedVersion: c.version,
        allowed: c.allowedModules.difference(DemoSeedV18.paymentModules),
        reason: 'municipal funding from January',
      );
      final h = db.configHistory.where((e) => e.orgId == saburtalo).last;
      expect(h.version, c.version + 1);
      expect(h.reason, 'municipal funding from January');
      expect(h.by, DemoIds.platformAdmin);
      as(DemoSeedV18.saburtaloAdmin);
      expect(
        DemoPaymentsRepository(db).setStatus('pay-saburtalo-1', PaymentStatus.paid),
        invalid('moduleDisabled:payments'),
      );
      expect(db.payments['pay-saburtalo-1'], isNotNull, reason: 'data is kept');
    });

    test('stale version is rejected, never silently overwritten', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      await platform.updateEntitlements(
        saburtalo,
        expectedVersion: c.version,
        allowed: c.allowedModules,
        reason: 'first editor',
      );
      expect(
        platform.updateEntitlements(
          saburtalo,
          expectedVersion: c.version,
          allowed: c.allowedModules.difference({OrgModule.media}),
          reason: 'second editor with stale data',
        ),
        conflict,
      );
      await Future<void>.delayed(Duration.zero);
      expect(db.orgConfig(saburtalo).allowedModules, contains(OrgModule.media));
    });

    test('an entitlement set with a missing dependency is rejected', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      expect(
        platform.updateEntitlements(
          saburtalo,
          expectedVersion: c.version,
          allowed: c.allowedModules.difference({OrgModule.payments}),
          reason: 'remove only payments',
        ),
        invalid('featureDependencies'),
      );
    });

    test('a reason is required', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      expect(
        platform.updateEntitlements(saburtalo, expectedVersion: c.version, allowed: c.allowedModules, reason: ' '),
        invalid('changeReason'),
      );
    });

    test('scheduled and trial rollout', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      await platform.updateEntitlements(
        saburtalo,
        expectedVersion: c.version,
        allowed: c.allowedModules,
        rollout: {
          OrgModule.media: FeatureRollout(RolloutState.scheduled, at: now.add(const Duration(days: 2))),
          OrgModule.trainingPlans: FeatureRollout(RolloutState.trial, until: now.add(const Duration(days: 1))),
        },
        reason: 'pilot',
      );
      final s = db.orgConfig(saburtalo);
      expect(s.isEnabled(OrgModule.media, now: now), isFalse);
      expect(s.isEnabled(OrgModule.media, now: now.add(const Duration(days: 3))), isTrue);
      expect(s.isEnabled(OrgModule.trainingPlans, now: now), isTrue);
      expect(s.isEnabled(OrgModule.trainingPlans, now: now.add(const Duration(days: 2))), isFalse);
    });

    test('an organization admin cannot enable a module the platform did not allow', () async {
      as(DemoSeedV17.tianetiAdmin);
      final c = db.orgConfig(tianeti);
      expect(
        orgs.updateOrgSettings(tianeti, enabledModules: {...c.enabledModules, OrgModule.payments}),
        throwsA(isA<AppException>()),
      );
      expect(platform.updateEntitlements(tianeti, expectedVersion: c.version, allowed: {}, reason: 'x'), denied);
    });
  });

  group('jobs and notifications respect features', () {
    test('payment reminders run only for organizations with reminders on (mock SMS only)', () async {
      final tianetiGroup = db.groups[DemoSeedV17.volleyGroup]!;
      Payment overdue(String id, Group g, String child, String parent) => Payment(
        id: id,
        childId: child,
        parentId: parent,
        groupId: g.id,
        sportId: g.sportId,
        amount: 50,
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 30)),
      );
      db.payments['pay-tianeti-x'] = overdue('pay-tianeti-x', tianetiGroup, 'child-t1', DemoSeedV17.tianetiParent);
      db.payments['pay-saburtalo-1'] = overdue(
        'pay-saburtalo-1',
        db.groups[DemoSeedV18.saburtaloGroup]!,
        DemoSeedV18.saburtaloChild,
        DemoSeedV18.saburtaloParent,
      );
      final sms = MockSmsProvider();
      await DemoPaymentsRepository(db, smsProvider: sms).runReminderJob(now);
      final phones = sms.sent.map((s) => s.phone).toSet();
      expect(phones, isNot(contains(db.users[DemoSeedV17.tianetiParent]!.phone)));
      expect(phones, contains(db.users[DemoSeedV18.saburtaloParent]!.phone), reason: 'payments org still reminded');
      expect(db.payments['pay-tianeti-x']!.reminders.d1SentAt, isNull);
    });

    test('notifications of a disabled feature are not created', () {
      final before = db.notifications.length;
      db.notifyUser(DemoSeedV17.tianetiParent, NotificationType.paymentReminder, groupId: DemoSeedV17.volleyGroup);
      expect(db.notifications.length, before);
      db.notifyUser(DemoSeedV18.saburtaloParent, NotificationType.paymentReminder, groupId: DemoSeedV18.saburtaloGroup);
      expect(db.notifications.length, before + 1);
    });

    test('chat writes are rejected when communication is off', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      await platform.updateEntitlements(
        saburtalo,
        expectedVersion: c.version,
        allowed: c.allowedModules.difference({OrgModule.communication, OrgModule.messageAcks}),
        reason: 'no chat',
      );
      as(DemoSeedV18.saburtaloCoach);
      expect(DemoChatRepository(db).send(DemoSeedV18.saburtaloGroup, 'hello'), invalid('moduleDisabled:communication'));
    });
  });

  group('package limits', () {
    test('groups beyond the package limit are rejected', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      await platform.updateSubscription(
        saburtalo,
        expectedVersion: c.version,
        // Negotiated limits apply to the Custom package (built-ins use theirs).
        packageId: SubscriptionPackage.customId,
        limits: c.limits.copyWith(maxGroups: 1),
        reason: 'tight limit for the test',
      );
      as(DemoSeedV18.saburtaloCoach);
      expect(
        DemoGroupsRepository(
          db,
        ).createGroup(const GroupDraft(clubId: saburtalo, sportId: 'swimming', name: 'ცურვა 2', ageMin: 8, ageMax: 12)),
        invalid('limitGroups'),
      );
    });
  });

  group('subscriptions', () {
    test('suspended / expired subscription is read-only; data is never deleted', () async {
      as(DemoIds.platformAdmin);
      final c = db.orgConfig(saburtalo);
      await platform.updateSubscription(
        saburtalo,
        expectedVersion: c.version,
        subscription: c.subscription.copyWith(status: SubscriptionStatus.suspended),
        reason: 'contract paused',
      );
      final s = db.orgConfig(saburtalo);
      expect(s.accessAt(now), AccessMode.readOnly);
      expect(s.isEnabled(OrgModule.trainings, now: now), isFalse);
      expect(db.groups[DemoSeedV18.saburtaloGroup], isNotNull);
      expect(db.payments['pay-saburtalo-1'], isNotNull);
    });

    test('grace period keeps full access after the end date; then refresh makes it read-only', () async {
      final sub = SubscriptionInfo(status: SubscriptionStatus.active, endAt: now.subtract(const Duration(days: 5)));
      expect(sub.accessAt(now), AccessMode.full);
      expect(sub.inGrace(now), isTrue);
      expect(sub.accessAt(now.add(const Duration(days: 10))), AccessMode.readOnly);
    });

    test('scheduled refresh expires an ended trial', () async {
      final trial = db.orgConfig(DemoSeedV18.vake);
      expect(trial.subscription.status, SubscriptionStatus.trial);
      db.orgConfigs[DemoSeedV18.vake] = trial.copyWith(
        subscription: trial.subscription.copyWith(endAt: now.subtract(const Duration(days: 1)), graceDays: 0),
      );
      as(DemoIds.platformAdmin);
      final changed = await platform.refreshEntitlements();
      expect(changed, contains(DemoSeedV18.vake));
      expect(db.orgConfig(DemoSeedV18.vake).subscription.status, SubscriptionStatus.expired);
      expect(db.clubs[DemoSeedV18.vake], isNotNull);
    });
  });

  group('invitations', () {
    test('accept: bound to the invited phone; grants admin of that organization only', () async {
      as('parent-2');
      expect(platform.acceptInvitation(DemoSeedV18.demoInviteToken), denied);
      as(DemoIds.parent);
      final org = await platform.acceptInvitation(DemoSeedV18.demoInviteToken);
      expect(org, saburtalo);
      final nino = db.users[DemoIds.parent]!;
      expect(nino.administersClub(saburtalo), isTrue);
      expect(nino.isPlatformAdmin, isFalse);
      expect(nino.administersClub(tianeti), isFalse);
      expect(db.invitations[DemoSeedV18.invitationId]!.status, InvitationStatus.accepted);
      // Single use.
      expect(platform.acceptInvitation(DemoSeedV18.demoInviteToken), invalid('invitationClosed'));
    });

    test('reject, revoke, resend and expiry', () async {
      as(DemoIds.parent);
      await platform.rejectInvitation(DemoSeedV18.demoInviteToken);
      expect(db.invitations[DemoSeedV18.invitationId]!.status, InvitationStatus.rejected);

      as(DemoIds.platformAdmin);
      final issued = await platform.inviteAdmin(saburtalo, phone: db.users[DemoIds.parent]!.phone);
      await platform.revokeInvitation(issued.invitation.id);
      as(DemoIds.parent);
      expect(platform.acceptInvitation(issued.token), invalid('invitationClosed'));

      as(DemoIds.platformAdmin);
      final again = await platform.inviteAdmin(saburtalo, phone: db.users[DemoIds.parent]!.phone);
      final resent = await platform.resendInvitation(again.invitation.id);
      expect(resent.token, isNot(again.token));
      as(DemoIds.parent);
      expect(platform.acceptInvitation(again.token), throwsA(isA<AppException>()), reason: 'old token is replaced');

      db.invitations[resent.invitation.id] = db.invitations[resent.invitation.id]!.copyWith(
        expiresAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(platform.acceptInvitation(resent.token), invalid('invitationExpired'));
    });

    test('transfer: accepting removes the previous administrator', () async {
      as(DemoIds.platformAdmin);
      final issued = await platform.inviteAdmin(
        saburtalo,
        phone: db.users[DemoIds.parent]!.phone,
        transferFrom: DemoSeedV18.saburtaloAdmin,
      );
      as(DemoIds.parent);
      await platform.acceptInvitation(issued.token);
      expect(db.users[DemoIds.parent]!.administersClub(saburtalo), isTrue);
      expect(db.users[DemoSeedV18.saburtaloAdmin]!.administersClub(saburtalo), isFalse);
      expect(db.clubs[saburtalo]!.adminIds, isNot(contains(DemoSeedV18.saburtaloAdmin)));
    });

    test('an organization admin cannot invite to another organization', () async {
      as(DemoSeedV17.tianetiAdmin);
      expect(platform.inviteAdmin(saburtalo, phone: '+995555999999'), denied);
    });
  });

  group('tenant isolation', () {
    test('an organization admin cannot change another organization', () async {
      as(DemoSeedV17.tianetiAdmin);
      expect(orgs.updateOrgSettings(saburtalo, enabledModules: const {}), denied);
      as(DemoSeedV18.saburtaloCoach);
      expect(
        DemoGroupsRepository(db)
            .createGroup(const GroupDraft(clubId: tianeti, sportId: 'volleyball', name: 'x', ageMin: 8, ageMax: 10)),
        denied,
      );
    });

    test('platform-only operations are denied to organization admins and parents', () async {
      for (final uid in [DemoSeedV17.tianetiAdmin, DemoIds.parent]) {
        as(uid);
        expect(platform.upsertPackage(SubscriptionPackage.builtIns.first), denied);
        expect(platform.duplicateTemplate(OrgTemplate.government), denied);
        expect(platform.refreshEntitlements(), denied);
      }
    });
  });

  group('legacy compatibility', () {
    test('a v1.7 document expands coarse modules into the v1.8 features', () {
      final legacy = OrgConfig.fromMap('legacy', {
        'status': 'active',
        'plan': 'standard',
        'allowedModules': ['trainings', 'payments', 'communication', 'brainAcademy'],
        'enabledModules': ['trainings', 'payments', 'communication', 'brainAcademy'],
      });
      for (final m in [
        OrgModule.paymentReceipts,
        OrgModule.paymentVerification,
        OrgModule.paymentReminders,
        OrgModule.messageAcks,
        OrgModule.coachChallenges,
      ]) {
        expect(legacy.isEnabled(m, now: now), isTrue, reason: m.name);
      }
      expect(OrgConfig.legacy('x').isEnabled(OrgModule.payments, now: now), isTrue);
    });

    test('derived fields are written for the security rules', () {
      final m = db.orgConfig(tianeti).toMap(now: now);
      expect(m['featureSchema'], 2);
      expect(m['accessMode'], 'full');
      expect(m['effectiveModules'], isNot(contains('payments')));
      expect(m['effectiveModules'], contains('roomScheduling'));
    });
  });

  group('three-level authorization', () {
    test('platform entitlement × organization switch × role', () {
      final c = db.orgConfig(saburtalo);
      expect(EntitlementResolver.can(c, {OrgRole.admin}, OrgPermission.managePayments, now), isTrue);
      expect(EntitlementResolver.can(c, {OrgRole.parent}, OrgPermission.managePayments, now), isFalse);
      expect(EntitlementResolver.can(c, {OrgRole.parent}, OrgPermission.uploadReceipts, now), isTrue);
      final off = c.copyWith(enabledModules: c.enabledModules.difference(DemoSeedV18.paymentModules));
      expect(EntitlementResolver.can(off, {OrgRole.admin}, OrgPermission.managePayments, now), isFalse);
      final t = db.orgConfig(tianeti);
      expect(EntitlementResolver.blockOf(t, OrgModule.payments, now), EntitlementBlock.notEntitled);
      expect(EntitlementResolver.can(t, {OrgRole.coach}, OrgPermission.bookRooms, now), t.settings.coachesCanBookRooms);
    });
  });

  test('impliedRoles uses the account when no membership exists', () {
    final u = db.users[DemoSeedV18.saburtaloAdmin]!;
    expect(impliedRoles(u, saburtalo), containsAll({OrgRole.admin, OrgRole.coach}));
    expect(u.role, UserRole.coach);
  });
}
