import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_parent_app/app/di.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:sport_parent_app/features/authentication/presentation/session_providers.dart';
import 'package:sport_parent_app/features/children/domain/child.dart';
import 'package:sport_parent_app/features/children/presentation/children_providers.dart';
import 'package:sport_parent_app/features/coach/presentation/coach_context.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/groups/presentation/groups_providers.dart';
import 'package:sport_parent_app/features/parent/presentation/parent_context.dart';
import 'package:sport_parent_app/features/trainings/presentation/trainings_providers.dart';

import '../helpers.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('resolveParentSelection (pure)', () {
    final kids = [
      Child(
        id: 'a',
        firstName: 'ა',
        lastName: 'ბ',
        birthDate: DateTime(2016),
        parentIds: const ['p'],
        sportIds: const ['football', 'swimming'],
      ),
      Child(
        id: 'b',
        firstName: 'გ',
        lastName: 'დ',
        birthDate: DateTime(2014),
        parentIds: const ['p'],
        sportIds: const ['basketball'],
      ),
    ];
    const groups = [
      Group(
        id: 'gf',
        clubId: 'c',
        sportId: 'football',
        coachIds: [],
        name: 'F',
        ageMin: 0,
        ageMax: 99,
        memberChildIds: ['a'],
      ),
      Group(
        id: 'gs',
        clubId: 'c',
        sportId: 'swimming',
        coachIds: [],
        name: 'S',
        ageMin: 0,
        ageMax: 99,
        memberChildIds: ['a'],
      ),
    ];

    test('restores stored child + sport and resolves the matching group', () {
      final s = resolveParentSelection(const UserContext(childId: 'a', sportId: 'swimming'), kids, groups);
      expect(s.child!.id, 'a');
      expect(s.sportId, 'swimming');
      expect(s.group!.id, 'gs');
    });

    test('falls back when stored ids are stale', () {
      final s = resolveParentSelection(const UserContext(childId: 'gone', sportId: 'chess'), kids, groups);
      expect(s.child!.id, 'a');
      expect(s.sportId, 'football');
      expect(s.group!.id, 'gf');
    });

    test('without stored context, prefers a child who is in a group', () {
      final s = resolveParentSelection(const UserContext(), [kids[1], kids[0]], groups);
      expect(s.child!.id, 'a');
    });

    test('child without a group in that sport → no group', () {
      final s = resolveParentSelection(const UserContext(childId: 'b'), kids, groups);
      expect(s.sportId, 'basketball');
      expect(s.group, isNull);
    });
  });

  group('providers with demo backend', () {
    test('switching child/sport persists lastContext locally and remotely and updates trainings', () async {
      final (db, overrides) = await demoSetup();
      final c = container(overrides);
      addTearDown(c.dispose);
      await c.read(authRepositoryProvider).signInAsDemo(DemoIds.parent);
      c.listen(authSessionProvider, (_, _) {});
      c.listen(myChildrenProvider, (_, _) {});
      c.listen(myGroupsProvider, (_, _) {});
      c.listen(myTrainingsProvider, (_, _) {});
      await settle();

      final initial = c.read(parentSelectionProvider).value!;
      expect(initial.children.length, 3);

      await c.read(selectionContextProvider.notifier).selectChild('child-1');
      await c.read(selectionContextProvider.notifier).selectSport('swimming');
      await settle();
      final sel = c.read(parentSelectionProvider).value!;
      expect(sel.child!.id, 'child-1');
      expect(sel.group!.id, 'g-swim-juniors');

      expect(db.users[DemoIds.parent]!.lastContext.sportId, 'swimming');
      final prefs = await SharedPreferences.getInstance();
      final stored = UserContext.fromMap(jsonDecode(prefs.getString('lastContext.${DemoIds.parent}')!));
      expect(stored.childId, 'child-1');

      final trainings = c.read(myTrainingsProvider).value!;
      expect(trainings.any((t) => t.groupId == 'g-swim-juniors'), isTrue);
    });

    test('reopening the app restores the stored dashboard context', () async {
      final (_, overrides) = await demoSetup(
        prefs: {
          'lastContext.${DemoIds.parent}': jsonEncode(
            const UserContext(childId: 'child-2', sportId: 'basketball').toMap(),
          ),
        },
      );
      final c = container(overrides);
      addTearDown(c.dispose);
      await c.read(authRepositoryProvider).signInAsDemo(DemoIds.parent);
      c.listen(authSessionProvider, (_, _) {});
      c.listen(myChildrenProvider, (_, _) {});
      c.listen(myGroupsProvider, (_, _) {});
      await settle();
      final sel = c.read(parentSelectionProvider).value!;
      expect(sel.child!.id, 'child-2');
      expect(sel.group!.id, 'g-basket-u13');
    });

    test('adding a child updates the child list provider', () async {
      final (_, overrides) = await demoSetup();
      final c = container(overrides);
      addTearDown(c.dispose);
      await c.read(authRepositoryProvider).signInAsDemo(DemoIds.parent);
      c.listen(authSessionProvider, (_, _) {});
      c.listen(myChildrenProvider, (_, _) {});
      await settle();
      final before = c.read(myChildrenProvider).value!.length;
      await c
          .read(childrenRepositoryProvider)
          .addChild(
            ChildDraft(
              firstName: 'ელენე',
              lastName: 'ბერიძე',
              birthDate: DateTime(2019, 2, 2),
              sportIds: const ['gymnastics'],
            ),
          );
      await settle();
      expect(c.read(myChildrenProvider).value!.length, before + 1);
    });

    test('coach selection defaults to the first group and follows lastContext.groupId', () async {
      final (_, overrides) = await demoSetup();
      final c = container(overrides);
      addTearDown(c.dispose);
      await c.read(authRepositoryProvider).signInAsDemo(DemoIds.coach);
      c.listen(authSessionProvider, (_, _) {});
      c.listen(myGroupsProvider, (_, _) {});
      await settle();
      expect(c.read(myGroupsProvider).value!.map((g) => g.id), containsAll(['g-football-u10', 'g-football-u12']));
      await c.read(selectionContextProvider.notifier).selectGroup('g-football-u12');
      await settle();
      expect(c.read(coachSelectedGroupProvider).value!.id, 'g-football-u12');
    });
  });
}
