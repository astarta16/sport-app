import '../../../core/utils/geo.dart';
import '../../authentication/domain/app_user.dart';
import '../../children/domain/child.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../organizations/domain/organization.dart';
import '../../organizations/domain/platform.dart';
import '../../payments/domain/payment.dart';
import 'demo_backend.dart';
import 'demo_seed.dart';
import 'demo_seed_v17.dart';

/// v1.8 demo tenants (fictional, synthetic data only).
///
/// * **Tianeti** becomes a government-funded sports school: payments,
///   receipts, verification and reminders are OFF (not entitled), while
///   facilities, room scheduling, student accounts and Brain Academy are on.
/// * **Saburtalo Sports Club** — a private club on the Professional package
///   with the full payments workflow on.
/// * **Vake Youth Academy** — a trial organization (trial ends in
///   5 days) used for the trial / grace-period alerts.
/// * A pending administrator invitation to Saburtalo for the demo parent's
///   phone, with the fixed demo code [demoInviteToken], so the invitation
///   flow can be tried end to end in the admin web demo.
class DemoSeedV18 {
  DemoSeedV18._();

  static const saburtalo = 'org-saburtalo';
  static const vake = 'org-vake';
  static const saburtaloAdmin = 'admin-saburtalo';
  static const saburtaloCoach = 'coach-s1';
  static const saburtaloParent = 'parent-s1';
  static const saburtaloGroup = 'g-saburtalo-swim';
  static const saburtaloChild = 'child-s1';
  static const invitationId = 'inv-demo-saburtalo';

  /// Demo-only invitation code (synthetic; real codes are random 256-bit).
  static const demoInviteToken = 'demo-invite-saburtalo-2026';

  /// Payment modules switched off for the government school.
  static const paymentModules = {
    OrgModule.payments,
    OrgModule.paymentReceipts,
    OrgModule.paymentVerification,
    OrgModule.paymentReminders,
  };

  static void seed(DemoBackend db) {
    final now = db.clock();

    // ── Tianeti: government school without payments ────────────────────
    final t = db.orgConfigs[DemoSeedV17.tianeti]!;
    final tianetiModules = OrgPlan.premium.defaultModules.difference(paymentModules);
    db.orgConfigs[DemoSeedV17.tianeti] = t.copyWith(
      allowedModules: tianetiModules,
      enabledModules: tianetiModules,
      packageId: SubscriptionPackage.enterpriseId,
      profile: const OrgProfile(
        legalName: 'ა(ა)იპ თიანეთის მუნიციპალიტეტის სპორტული სკოლა',
        type: OrgType.sportsSchool,
        funding: FundingType.government,
        registrationId: 'DEMO-000000001',
        city: 'თიანეთი',
      ),
      subscription: SubscriptionInfo(
        status: SubscriptionStatus.active,
        startAt: now.subtract(const Duration(days: 60)),
      ),
      templateId: OrgTemplate.government,
      updatedBy: DemoIds.platformAdmin,
      changeReason: 'Demo seed v1.8',
    );
    db.orgConfigs[DemoSeedV17.mtskheta] = db.orgConfigs[DemoSeedV17.mtskheta]!.copyWith(
      profile: const OrgProfile(
        legalName: 'Mtskheta Youth Academy LLC (demo)',
        type: OrgType.academy,
        funding: FundingType.mixed,
        city: 'მცხეთა',
      ),
      subscription: SubscriptionInfo(
        status: SubscriptionStatus.pastDue,
        endAt: now.subtract(const Duration(days: 3)),
        graceDays: 14,
      ),
    );

    // ── Saburtalo Sports Club: private, payments on ────────────────────
    db.clubs[saburtalo] = const Club(
      id: saburtalo,
      name: 'საბურთალოს სპორტული კლუბი',
      address: 'ვაჟა-ფშაველას გამზ. 40, თბილისი',
      sportIds: ['swimming', 'basketball'],
      location: GeoCoord(41.7262, 44.7369),
      geohash: 'sz8w7z',
      phone: '+995555200700',
      description: 'კერძო სპორტული კლუბი (სადემონსტრაციო)',
      adminIds: [saburtaloAdmin],
    );
    final pro = SubscriptionPackage.builtIns.firstWhere((p) => p.id == SubscriptionPackage.professionalId);
    final saburtaloModules = pro.modules.difference(FeatureCatalog.restricted);
    db.orgConfigs[saburtalo] = OrgConfig(
      orgId: saburtalo,
      allowedModules: saburtaloModules,
      enabledModules: saburtaloModules,
      packageId: pro.id,
      limits: pro.limits.orgLimits,
      branding: const OrgBranding(
        names: {'ka': 'საბურთალოს სპორტული კლუბი', 'en': 'Saburtalo Sports Club', 'ru': 'Спортивный клуб Сабуртало'},
        primaryColor: 0xFF1D4ED8,
        secondaryColor: 0xFF0F172A,
        description: 'Swimming and basketball for ages 5–16.',
        contactPhone: '+995555200700',
        contactEmail: 'hello@saburtalo-club.example',
        address: 'ვაჟა-ფშაველას გამზ. 40, თბილისი',
      ),
      profile: const OrgProfile(
        legalName: 'Saburtalo Sports Club LLC (demo)',
        type: OrgType.club,
        funding: FundingType.private,
        registrationId: 'DEMO-000000002',
        city: 'თბილისი',
      ),
      subscription: SubscriptionInfo(
        status: SubscriptionStatus.active,
        startAt: now.subtract(const Duration(days: 30)),
        endAt: now.add(const Duration(days: 335)),
      ),
      templateId: OrgTemplate.privateClub,
      updatedAt: now,
      updatedBy: DemoIds.platformAdmin,
      changeReason: 'Demo seed v1.8',
    );

    AppUser user(String id, UserRole role, String first, String last, String phone, {List<String> clubs = const []}) =>
        AppUser(
          id: id,
          role: role,
          firstName: first,
          lastName: last,
          phone: phone,
          createdAt: now.subtract(const Duration(days: 30)),
          coachStatus: role == UserRole.coach ? CoachStatus.approved : null,
          clubIds: clubs,
          dataConsentAt: now.subtract(const Duration(days: 30)),
          smsConsentAt: role == UserRole.parent ? now.subtract(const Duration(days: 30)) : null,
        );
    db.users[saburtaloAdmin] = AppUser.fromMap(saburtaloAdmin, {
      ...user(saburtaloAdmin, UserRole.coach, 'თამარ', 'გელაშვილი', '+995555200701').toMap(),
      'role': UserRole.coach.name,
      'adminRole': AdminRole.club.name,
      'adminClubIds': [saburtalo],
    });
    db.users[saburtaloCoach] = user(
      saburtaloCoach,
      UserRole.coach,
      'ლევან',
      'ჩხეიძე',
      '+995555200702',
      clubs: [saburtalo],
    );
    db.users[saburtaloParent] = user(saburtaloParent, UserRole.parent, 'მარიამ', 'კაპანაძე', '+995555200703');

    db.children[saburtaloChild] = Child(
      id: saburtaloChild,
      firstName: 'ანა',
      lastName: 'კაპანაძე',
      birthDate: DateTime(now.year - 9, 3, 14),
      parentIds: const [saburtaloParent],
      sportIds: const ['swimming'],
      groupIds: const [saburtaloGroup],
    );
    db.groups[saburtaloGroup] = const Group(
      id: saburtaloGroup,
      clubId: saburtalo,
      sportId: 'swimming',
      coachIds: [saburtaloCoach],
      name: 'ცურვა · დამწყებები',
      ageMin: 6,
      ageMax: 10,
      memberChildIds: [saburtaloChild],
      scheduleNote: 'სამ, პარ 18:00',
    );
    db.recomputeMemberships();
    void member(String org, String uid, Set<OrgRole> roles) =>
        db.memberships['$org|$uid'] = OrgMembership(orgId: org, userId: uid, roles: roles);
    member(saburtalo, saburtaloAdmin, {OrgRole.admin});
    member(saburtalo, saburtaloCoach, {OrgRole.coach});
    member(saburtalo, saburtaloParent, {OrgRole.parent});

    final due = DateTime(now.year, now.month, 1).add(const Duration(days: 9));
    db.payments['pay-saburtalo-1'] = Payment(
      id: 'pay-saburtalo-1',
      childId: saburtaloChild,
      parentId: saburtaloParent,
      groupId: saburtaloGroup,
      sportId: 'swimming',
      amount: 120,
      dueDate: due,
      title: 'ცურვა · თვიური',
      createdAt: now.subtract(const Duration(days: 5)),
    );

    // ── Vake: trial organization ───────────────────────────────────────
    db.clubs[vake] = const Club(
      id: vake,
      name: 'ვაკის ახალგაზრდული აკადემია',
      address: 'ჭავჭავაძის გამზ. 20, თბილისი',
      sportIds: ['basketball'],
      location: GeoCoord(41.7097, 44.7612),
      geohash: 'sz8w5u',
    );
    final starter = SubscriptionPackage.builtIns.firstWhere((p) => p.id == SubscriptionPackage.starterId);
    db.orgConfigs[vake] = OrgConfig(
      orgId: vake,
      plan: OrgPlan.free,
      allowedModules: starter.modules,
      enabledModules: starter.modules.difference(FeatureCatalog.restricted),
      packageId: starter.id,
      limits: starter.limits.orgLimits,
      branding: const OrgBranding(
        names: {'ka': 'ვაკის ახალგაზრდული აკადემია', 'en': 'Vake Youth Academy', 'ru': 'Молодёжная академия Ваке'},
        primaryColor: 0xFF7C3AED,
      ),
      profile: const OrgProfile(
        legalName: 'Vake Youth Academy (demo)',
        type: OrgType.academy,
        funding: FundingType.nonprofit,
        city: 'თბილისი',
      ),
      subscription: SubscriptionInfo(
        status: SubscriptionStatus.trial,
        startAt: now.subtract(const Duration(days: 9)),
        endAt: now.add(const Duration(days: 5)),
        graceDays: 0,
      ),
      templateId: OrgTemplate.childrenAcademy,
      updatedAt: now,
    );

    // ── invitation for the demo parent (Nino) to administer Saburtalo ──
    final nino = db.users[DemoIds.parent];
    if (nino != null) {
      db.invitations[invitationId] = OrgInvitation(
        id: invitationId,
        orgId: saburtalo,
        tokenHash: InvitationTokens.hash(demoInviteToken),
        phone: nino.phone,
        expiresAt: now.add(const Duration(days: 6)),
        invitedBy: DemoIds.platformAdmin,
        createdAt: now.subtract(const Duration(days: 1)),
      );
    }
  }
}
