import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/app/router.dart';
import 'package:sport_parent_app/app/routes.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';

AuthSession session(UserRole? role, {CoachStatus? status}) => AuthSession(
  uid: 'u',
  phone: '+995555000000',
  user: role == null
      ? null
      : AppUser(
          id: 'u',
          role: role,
          firstName: 'a',
          lastName: 'b',
          phone: '',
          createdAt: DateTime(2026),
          coachStatus: status,
        ),
);

String? go(String loc, AsyncValue<AuthSession?> s, {bool onboarded = true}) =>
    resolveRedirect(location: loc, session: s, onboardingSeen: onboarded);

void main() {
  test('loading session shows splash', () {
    expect(go(Routes.parentHome, const AsyncLoading()), Routes.splash);
  });

  test('first launch goes to onboarding, then phone sign-in', () {
    expect(go(Routes.splash, const AsyncData(null), onboarded: false), Routes.onboarding);
    expect(go(Routes.splash, const AsyncData(null)), Routes.phone);
    expect(go(Routes.parentHome, const AsyncData(null)), Routes.phone);
  });

  test('guests may browse the map and club pages', () {
    expect(go(Routes.explore, const AsyncData(null)), isNull);
    expect(go(Routes.club('club-1'), const AsyncData(null)), isNull);
  });

  test('verified phone without profile → registration', () {
    expect(go(Routes.parentHome, AsyncData(session(null))), Routes.register);
  });

  test('role-based homes and route guards', () {
    final parent = AsyncData(session(UserRole.parent));
    final coach = AsyncData(session(UserRole.coach, status: CoachStatus.approved));
    expect(go(Routes.splash, parent), Routes.parentHome);
    expect(go(Routes.coachHome, parent), Routes.parentHome);
    expect(go(Routes.parentCalendar, parent), isNull);
    expect(go(Routes.splash, coach), Routes.coachHome);
    expect(go(Routes.parentHome, coach), Routes.coachHome);
    expect(go(Routes.payments, coach), Routes.coachHome);
    expect(go(Routes.training('t1'), coach), isNull);
  });

  test('pending coach is held on the approval screen; child accounts blocked', () {
    final pending = AsyncData(session(UserRole.coach, status: CoachStatus.pending));
    expect(go(Routes.coachHome, pending), Routes.coachPending);
    expect(go(Routes.chat('g'), pending), Routes.coachPending);
    expect(go(Routes.parentChat, AsyncData(session(UserRole.child))), Routes.childUnsupported);
  });
}
