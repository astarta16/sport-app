import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/admin/data/demo_admin_repository.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v17.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v18.dart';
import 'package:sport_parent_app/features/groups/data/demo_groups_repository.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';

import '../responsive/responsive_screens_test.dart' show pumpFrames, expectNoLayoutErrors;
import '../v17/v17_ui_test.dart' show tapKey, bootAdmin, adminSignIn;

final denied = throwsA(isA<PermissionDeniedException>());
Matcher invalid(String code) => throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));

void main() {
  setUpAll(() => initializeDateFormatting());
  final now = DateTime(2026, 11, 16, 12);
  late DemoBackend db;
  late DemoGroupsRepository groups;
  late DemoAdminRepository admin;
  setUp(() {
    db = DemoSeed.create(clock: () => now);
    groups = DemoGroupsRepository(db);
    admin = DemoAdminRepository(db);
  });
  void as(String uid) => db.session = (uid: uid, phone: db.users[uid]!.phone);
  const tianeti = DemoSeedV17.tianeti;
  GroupDraft draft({String club = tianeti, List<String> coaches = const [DemoSeedV17.volleyCoach], int? capacity}) =>
      GroupDraft(
        clubId: club,
        sportId: 'volleyball',
        name: 'Volleyball U-10',
        ageMin: 8,
        ageMax: 10,
        coachIds: coaches,
        capacity: capacity,
      );

  group('organization admin manages groups of their own organization', () {
    test('creates a group with a coach of the organization', () async {
      as(DemoSeedV17.tianetiAdmin);
      final g = await groups.createGroup(draft(capacity: 12));
      expect(g.clubId, tianeti);
      expect(g.coachIds, [DemoSeedV17.volleyCoach]);
      expect(g.capacity, 12);
      expect(g.createdBy, DemoSeedV17.tianetiAdmin);
      expect(db.audit.any((a) => a.action == 'group.create' && a.targetId == g.id), isTrue);
    });

    test('is denied in another organization', () async {
      as(DemoSeedV17.tianetiAdmin);
      expect(groups.createGroup(draft(club: DemoSeedV18.saburtalo, coaches: [DemoSeedV18.saburtaloCoach])), denied);
    });

    test('cannot assign a coach who is not in the organization', () async {
      as(DemoSeedV17.tianetiAdmin);
      expect(groups.createGroup(draft(coaches: [DemoSeedV18.saburtaloCoach])), invalid('groupCoachNotInOrg'));
      expect(groups.createGroup(draft(coaches: const [])), invalid('groupCoachNotInOrg'));
    });

    test('the organization group limit applies', () async {
      as(DemoSeedV17.tianetiAdmin);
      final c = db.orgConfig(tianeti);
      final used = db.groups.values.where((g) => g.clubId == tianeti && g.isActive).length;
      db.orgConfigs[tianeti] = c.copyWith(limits: c.limits.copyWith(maxGroups: used));
      expect(groups.createGroup(draft()), invalid('limitGroups'));
    });

    test('a parent, a coach of another organization and an unauthenticated user cannot', () async {
      as(DemoIds.parent);
      expect(groups.createGroup(draft()), denied);
      as(DemoSeedV18.saburtaloCoach);
      expect(groups.createGroup(draft()), denied);
    });

    test('coaches keep creating groups for themselves', () async {
      as(DemoSeedV17.volleyCoach);
      final g = await groups.createGroup(draft(coaches: const []));
      expect(g.coachIds, [DemoSeedV17.volleyCoach]);
    });

    test('edits details and coaches; capacity cannot go below current members', () async {
      as(DemoSeedV17.tianetiAdmin);
      final g = db.groups[DemoSeedV17.volleyGroup]!;
      await admin.updateGroupDetails(g.id, name: 'Volleyball U-12 A', coachIds: [DemoSeedV17.badmintonCoach]);
      expect(db.groups[g.id]!.name, 'Volleyball U-12 A');
      expect(db.groups[g.id]!.coachIds, [DemoSeedV17.badmintonCoach]);
      expect(admin.updateGroupDetails(g.id, capacity: 1), invalid('capacityBelowMembers'));
      expect(admin.updateGroupDetails(g.id, coachIds: [DemoSeedV18.saburtaloCoach]), invalid('groupCoachNotInOrg'));
    });

    test('roster is minimal and only for the own organization', () async {
      as(DemoSeedV17.tianetiAdmin);
      final rows = await admin.groupRoster(DemoSeedV17.volleyGroup);
      expect(rows, isNotEmpty);
      expect(rows.every((r) => r.lastInitial.length <= 1), isTrue);
      as(DemoSeedV18.saburtaloAdmin);
      expect(admin.groupRoster(DemoSeedV17.volleyGroup), denied);
      expect(admin.removeGroupMember(DemoSeedV17.volleyGroup, 'child-t1'), denied);
    });

    test('removes a member; history (attendance) is kept', () async {
      as(DemoSeedV17.tianetiAdmin);
      final before = db.attendance.length;
      await admin.removeGroupMember(DemoSeedV17.volleyGroup, 'child-t1');
      expect(db.groups[DemoSeedV17.volleyGroup]!.memberChildIds, isNot(contains('child-t1')));
      expect(db.attendance.length, before);
    });

    test('enrolls through the guardian; a full group refuses new children', () async {
      as(DemoSeedV17.tianetiAdmin);
      final g = await groups.createGroup(draft(capacity: 1));
      final inv = await groups.invitePendingChild(
        groupId: g.id,
        child: PendingChildDraft(
          firstName: 'Ana',
          lastName: 'Test',
          birthDate: DateTime(2017, 3, 1),
          parentPhone: db.users[DemoIds.parent]!.phone,
        ),
      );
      expect(inv.status, InviteStatus.sent);
      expect(db.groups[g.id]!.memberChildIds, isEmpty, reason: 'nobody joins before the guardian accepts');
      // The guardian accepts → the child joins.
      as(DemoIds.parent);
      await groups.respondInvite(inv.id, accept: true);
      expect(db.groups[g.id]!.memberChildIds, hasLength(1));
      // Second child → group full.
      as(DemoSeedV17.tianetiAdmin);
      final inv2 = await groups.invitePendingChild(
        groupId: g.id,
        child: PendingChildDraft(
          firstName: 'Nika',
          lastName: 'Test',
          birthDate: DateTime(2017, 5, 1),
          parentPhone: db.users['parent-2']!.phone,
        ),
      );
      as('parent-2');
      expect(groups.respondInvite(inv2.id, accept: true), invalid('groupFull'));
    });
  });

  group('admin web', () {
    testWidgets('organization admin creates a group with the wizard (validation per step)', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
      await tapKey(tester, 'admin-nav-/groups');
      await tapKey(tester, 'group-new');
      expect(find.byKey(const Key('group-wizard')), findsOneWidget);
      // Next without a sport → error, stays on step 1.
      await tapKey(tester, 'gw-next');
      expect(find.byKey(const Key('gw-error')), findsOneWidget);
      await tapKey(tester, 'sports-picker');
      await tapKey(tester, 'app-picker-option-volleyball');
      await tapKey(tester, 'gw-next');
      await tester.enterText(find.byKey(const Key('gw-name')), 'Volleyball Beginners');
      await tapKey(tester, 'gw-next');
      await tapKey(tester, 'gw-coaches');
      await tapKey(tester, 'app-picker-option-${DemoSeedV17.volleyCoach}');
      await tapKey(tester, 'app-picker-done');
      await tapKey(tester, 'gw-next');
      await tester.enterText(find.byKey(const Key('gw-capacity')), '14');
      await tapKey(tester, 'gw-next');
      expect(find.byKey(const Key('gw-review')), findsOneWidget);
      await tapKey(tester, 'gw-create');
      final g = db.groups.values.singleWhere((x) => x.name == 'Volleyball Beginners');
      expect(g.clubId, DemoSeedV17.tianeti);
      expect(g.coachIds, [DemoSeedV17.volleyCoach]);
      expect(g.capacity, 14);
      expect(find.byKey(const Key('group-wizard')), findsNothing);
      expectNoLayoutErrors();
    });

    testWidgets('members dialog: minimal roster, remove with confirmation, invite guardian', (tester) async {
      final db = await bootAdmin(tester);
      await adminSignIn(tester, DemoSeedV17.tianetiAdmin);
      await tapKey(tester, 'admin-nav-/groups');
      await tapKey(tester, 'group-members-${DemoSeedV17.volleyGroup}');
      expect(find.byKey(const Key('gm-row-child-t1')), findsOneWidget);
      await tapKey(tester, 'gm-remove-child-t1');
      expect(find.byType(AlertDialog), findsNWidgets(2));
      await tester.tap(find.byType(FilledButton).last);
      await pumpFrames(tester);
      expect(db.groups[DemoSeedV17.volleyGroup]!.memberChildIds, isNot(contains('child-t1')));
      expectNoLayoutErrors();
    });
  });
}
