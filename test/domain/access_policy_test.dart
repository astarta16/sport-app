import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/features/authentication/domain/access_policy.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:sport_parent_app/features/children/domain/child.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';

AppUser user(String id, UserRole role, {CoachStatus? status, NotificationPreferences? prefs}) => AppUser(
  id: id,
  role: role,
  firstName: 'F',
  lastName: 'L',
  phone: '+99555500000$id'.substring(0, 13),
  createdAt: DateTime(2026),
  coachStatus: status,
  notificationPrefs: prefs ?? const NotificationPreferences(),
);

void main() {
  final parentA = user('pa', UserRole.parent);
  final parentB = user('pb', UserRole.parent);
  final coach = user('co', UserRole.coach, status: CoachStatus.approved);
  final pendingCoach = user('cp', UserRole.coach, status: CoachStatus.pending);
  final otherCoach = user('cx', UserRole.coach, status: CoachStatus.approved);
  final childUser = user('ch', UserRole.child);

  final childA = Child(id: 'kA', firstName: 'a', lastName: 'b', birthDate: DateTime(2016), parentIds: const ['pa']);
  const grp = Group(
    id: 'g',
    clubId: 'c',
    sportId: 'football',
    coachIds: ['co', 'cp'],
    name: 'U10',
    ageMin: 8,
    ageMax: 10,
    memberChildIds: ['kA'],
    parentIds: ['pa'],
  );

  group('children', () {
    test('only the parent edits; parent B cannot view', () {
      expect(AccessPolicy.canEditChild(parentA, childA), isTrue);
      expect(AccessPolicy.canEditChild(parentB, childA), isFalse);
      expect(AccessPolicy.canViewChild(parentB, childA, [grp]), isFalse);
    });

    test('approved coach of a current group views; pending/other coach cannot', () {
      expect(AccessPolicy.canViewChild(coach, childA, [grp]), isTrue);
      expect(AccessPolicy.canViewChild(pendingCoach, childA, [grp]), isFalse);
      expect(AccessPolicy.canViewChild(otherCoach, childA, [grp]), isFalse);
    });

    test('leaving the group revokes coach access to certificates', () {
      expect(AccessPolicy.canViewCertificate(coach, childA, [grp]), isTrue);
      final left = grp.copyWith(memberChildIds: const []);
      expect(AccessPolicy.canViewCertificate(coach, childA, [left]), isFalse);
      expect(AccessPolicy.canViewCertificate(parentA, childA, [left]), isTrue);
    });

    test('only parents upload/delete certificates', () {
      expect(AccessPolicy.canUploadCertificate(parentA, childA), isTrue);
      expect(AccessPolicy.canUploadCertificate(coach, childA), isFalse);
      expect(AccessPolicy.canDeleteCertificate(parentB, childA), isFalse);
    });
  });

  group('trainings', () {
    test('only approved coaches of the group manage trainings', () {
      expect(AccessPolicy.canManageTrainings(coach, grp), isTrue);
      expect(AccessPolicy.canManageTrainings(pendingCoach, grp), isFalse);
      expect(AccessPolicy.canManageTrainings(otherCoach, grp), isFalse);
      expect(AccessPolicy.canManageTrainings(parentA, grp), isFalse);
    });

    test('parents view trainings of their children\'s groups only', () {
      expect(AccessPolicy.canViewTrainings(parentA, grp), isTrue);
      expect(AccessPolicy.canViewTrainings(parentB, grp), isFalse);
    });
  });

  group('chat', () {
    test('children never have chat', () {
      final g = grp.copyWith(parentIds: const ['pa', 'ch']);
      expect(AccessPolicy.canAccessChat(childUser, g), isFalse);
      expect(childUser.canUseChat, isFalse);
    });

    test('group parents and assigned approved coaches only', () {
      expect(AccessPolicy.canAccessChat(parentA, grp), isTrue);
      expect(AccessPolicy.canAccessChat(coach, grp), isTrue);
      expect(AccessPolicy.canAccessChat(parentB, grp), isFalse);
      expect(AccessPolicy.canAccessChat(otherCoach, grp), isFalse);
      expect(AccessPolicy.canAccessChat(pendingCoach, grp), isFalse);
    });
  });

  group('phone visibility', () {
    final g2 = grp.copyWith(parentIds: const ['pa', 'pb']);
    test('coach sees parents of own group; parents never see each other', () {
      expect(AccessPolicy.canSeePhone(coach, parentA, [g2]), isTrue);
      expect(AccessPolicy.canSeePhone(otherCoach, parentA, [g2]), isFalse);
      expect(AccessPolicy.canSeePhone(parentA, parentB, [g2]), isFalse);
      expect(AccessPolicy.canSeePhone(parentA, coach, [g2]), isTrue);
    });
  });

  group('payments', () {
    final p = Payment(
      id: 'x',
      childId: 'kA',
      parentId: 'pa',
      groupId: 'g',
      sportId: 'football',
      amount: 80,
      dueDate: DateTime(2026),
    );
    test('parent sees own payment; other parent does not; coach manages group payments', () {
      expect(AccessPolicy.canViewPayment(parentA, p, grp), isTrue);
      expect(AccessPolicy.canViewPayment(parentB, p, grp), isFalse);
      expect(AccessPolicy.canManagePayments(coach, grp), isTrue);
      expect(AccessPolicy.canManagePayments(parentA, grp), isFalse);
    });
  });

  group('registration', () {
    test('children cannot self-register while the policy flag is off', () {
      expect(PolicyFlags.childAccountsEnabled, isFalse);
      expect(AccessPolicy.canSelfRegisterAs(UserRole.child), isFalse);
      expect(AccessPolicy.canSelfRegisterAs(UserRole.admin), isFalse);
      expect(AccessPolicy.canSelfRegisterAs(UserRole.parent), isTrue);
      expect(AccessPolicy.canSelfRegisterAs(UserRole.coach), isTrue);
    });
  });

  group('notification recipients', () {
    test('training events go to group parents only, respecting prefs', () {
      final optedOut = user(
        'pz',
        UserRole.parent,
        prefs: const NotificationPreferences().toggle(NotificationType.newTraining, false),
      );
      final g = grp.copyWith(parentIds: const ['pa', 'pz', 'ch']);
      final r = AccessPolicy.notificationRecipients(
        type: NotificationType.newTraining,
        group: g,
        users: [parentA, parentB, optedOut, coach, childUser],
      );
      expect(r.map((u) => u.id), ['pa']);
    });

    test('chat goes to parents and coaches except sender, never children', () {
      final g = grp.copyWith(parentIds: const ['pa', 'ch']);
      final r = AccessPolicy.notificationRecipients(
        type: NotificationType.chatMessage,
        group: g,
        users: [parentA, coach, childUser, otherCoach],
        excludeUserId: 'co',
      );
      expect(r.map((u) => u.id), ['pa']);
    });

    test('payment reminders only to the targeted parent', () {
      final g = grp.copyWith(parentIds: const ['pa', 'pb']);
      final r = AccessPolicy.notificationRecipients(
        type: NotificationType.paymentReminder,
        group: g,
        users: [parentA, parentB],
        onlyParentIds: {'pb'},
      );
      expect(r.map((u) => u.id), ['pb']);
    });
  });
}
