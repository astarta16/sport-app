import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/account_screens.dart';
import '../features/payments/presentation/payment_proof_screens.dart';
import '../features/roster/presentation/student_roster_screen.dart';
import '../features/training_plans/presentation/plan_editor_screen.dart';
import '../features/training_plans/presentation/plans_screens.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/attendance/presentation/progress_screen.dart';
import '../features/coach/presentation/group_management.dart';
import '../features/groups/presentation/invites_screen.dart';
import '../features/matches/presentation/match_screens.dart';
import '../features/media/presentation/media_screens.dart';
import '../features/trainings/presentation/series_form_screen.dart';
import '../features/authentication/domain/app_user.dart';
import '../features/authentication/presentation/coach_pending_screen.dart';
import '../features/authentication/presentation/otp_screen.dart';
import '../features/authentication/presentation/phone_screen.dart';
import '../features/authentication/presentation/registration_screen.dart';
import '../features/authentication/presentation/session_providers.dart';
import '../features/authentication/presentation/splash_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/chat/presentation/chat_list_screen.dart';
import '../features/chat/presentation/chat_room_screen.dart';
import '../features/children/presentation/child_form_screen.dart';
import '../features/children/presentation/child_profile_screen.dart';
import '../features/clubs/presentation/club_screen.dart';
import '../features/coach/presentation/coach_home_screen.dart';
import '../features/coach/presentation/group_roster_screen.dart';
import '../features/maps/presentation/map_screen.dart';
import '../features/medical_certificates/presentation/certificates_screen.dart';
import '../features/medical_certificates/presentation/upload_certificate_screen.dart';
import '../features/notifications/presentation/inbox_screen.dart';
import '../features/notifications/presentation/notification_settings_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/parent/presentation/parent_home_screen.dart';
import '../features/payments/presentation/coach_payments_screen.dart';
import '../features/payments/presentation/parent_payments_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/trainings/presentation/training_detail_screen.dart';
import '../features/trainings/presentation/training_form_screen.dart';
import 'routes.dart';
import 'settings.dart';
import 'shell.dart';
import '../features/contacts/presentation/contacts_screens.dart';
import '../features/chat/presentation/receipt_details_screen.dart';
import '../features/children/presentation/student_profile_screen.dart';
import '../features/child_threads/presentation/child_thread_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pure redirect decision, unit-tested in `test/app/redirect_test.dart`.
String? resolveRedirect({
  required String location,
  required AsyncValue<AuthSession?> session,
  required bool onboardingSeen,
}) {
  const publicPrefixes = [Routes.phone, Routes.otp, Routes.onboarding, Routes.explore, '/club/'];
  final isPublic = publicPrefixes.any(location.startsWith);

  if (session is AsyncLoading && !session.hasValue) return location == Routes.splash ? null : Routes.splash;

  final s = session.value;
  if (s == null) {
    if (!onboardingSeen) return location == Routes.onboarding ? null : Routes.onboarding;
    return isPublic && location != Routes.onboarding ? null : Routes.phone;
  }
  final user = s.user;
  if (user == null) return location == Routes.register ? null : Routes.register;
  if (user.role == UserRole.child) return location == Routes.childUnsupported ? null : Routes.childUnsupported;
  if (user.isCoach && !user.isApprovedCoach) return location == Routes.coachPending ? null : Routes.coachPending;

  // Admins use the separate web dashboard (lib/main_admin.dart).
  if (user.role == UserRole.admin) return location == Routes.adminOnly ? null : Routes.adminOnly;
  final home = user.isCoach ? Routes.coachHome : Routes.parentHome;
  if (location == Routes.calendar) return user.isCoach ? Routes.coachCalendar : Routes.parentCalendar;
  if (location == Routes.splash || location.startsWith('/auth') || location == Routes.onboarding) return home;
  if (location == Routes.explore) return user.isCoach ? Routes.coachMap : Routes.parentMap;
  if (user.isParent && location.startsWith('/coach')) return home;
  if (user.isCoach &&
      (location.startsWith('/parent') ||
          location == Routes.payments ||
          location == Routes.invites ||
          (location.startsWith('/children') && !location.endsWith('/progress')))) {
    return home;
  }
  if (user.isParent &&
      ((location.startsWith('/group/') && !location.split('?').first.endsWith('/contacts')) ||
          location.contains('/receipts/') ||
          location.startsWith('/series/') ||
          location == Routes.newMedia ||
          location.startsWith('/media/new') ||
          location.endsWith('/attendance') ||
          location.startsWith('/match/new') ||
          location.startsWith('/students') ||
          location.startsWith('/plans/new') ||
          location == Routes.paymentReview ||
          location.endsWith('/edit'))) {
    return home;
  }
  if (user.isCoach && location.startsWith('/payments/') && location.endsWith('/proof')) return home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (_, _) => refresh.value++);
  ref.listen(appSettingsProvider.select((s) => s.onboardingSeen), (_, _) => refresh.value++);

  StatefulShellBranch branch(String path, Widget child) => StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (_, _) => NoTransitionPage(child: child),
      ),
    ],
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      session: ref.read(authSessionProvider),
      onboardingSeen: ref.read(appSettingsProvider).onboardingSeen,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: Routes.otp,
        builder: (_, s) =>
            OtpScreen(verificationId: s.uri.queryParameters['vid'] ?? '', phone: s.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(path: Routes.register, builder: (_, _) => const RegistrationScreen()),
      GoRoute(path: Routes.coachPending, builder: (_, _) => const CoachPendingScreen()),
      GoRoute(path: Routes.childUnsupported, builder: (_, _) => const ChildUnsupportedScreen()),
      GoRoute(path: Routes.explore, builder: (_, _) => const MapScreen(guest: true)),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          branch(Routes.parentHome, const ParentHomeScreen()),
          branch(Routes.parentCalendar, const CalendarScreen()),
          branch(Routes.parentMap, const MapScreen()),
          branch(Routes.parentProfile, const ProfileScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          branch(Routes.coachHome, const CoachHomeScreen()),
          branch(Routes.coachCalendar, const CalendarScreen()),
          branch(Routes.coachMap, const MapScreen()),
          branch(Routes.coachProfile, const ProfileScreen()),
        ],
      ),
      GoRoute(path: Routes.adminOnly, builder: (_, _) => const AdminUseWebScreen()),
      GoRoute(path: Routes.calendar, redirect: (_, _) => null, builder: (_, _) => const SizedBox.shrink()),
      GoRoute(path: Routes.invites, builder: (_, _) => const InvitesScreen()),
      GoRoute(
        path: '/students',
        builder: (_, s) => StudentRosterScreen(groupId: s.uri.queryParameters['groupId']),
      ),
      GoRoute(
        path: Routes.plans,
        builder: (_, s) => PlansListScreen(childId: s.uri.queryParameters['childId']),
      ),
      GoRoute(
        path: '/plans/new',
        builder: (_, s) => PlanEditorScreen(groupId: s.uri.queryParameters['groupId']),
      ),
      GoRoute(
        path: '/plans/:id',
        builder: (_, s) => PlanDetailScreen(planId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plans/:id/edit',
        builder: (_, s) => PlanEditorScreen(planId: s.pathParameters['id']),
      ),
      GoRoute(path: Routes.paymentReview, builder: (_, _) => const PaymentReviewScreen()),
      GoRoute(
        path: '/payments/proofs/:id',
        builder: (_, s) => ProofDetailScreen(proofId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payments/:id/proof',
        builder: (_, s) => PaymentProofScreen(paymentId: s.pathParameters['id']!),
      ),
      GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen()),
      GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(
        path: '/match/new',
        builder: (_, s) => MatchFormScreen(groupId: s.uri.queryParameters['groupId']),
      ),
      GoRoute(
        path: '/match/:id',
        builder: (_, s) => MatchDetailScreen(matchId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/match/:id/edit',
        builder: (_, s) => MatchFormScreen(matchId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/series/new',
        builder: (_, s) => SeriesFormScreen(groupId: s.uri.queryParameters['groupId']),
      ),
      GoRoute(
        path: '/series/:id/edit',
        builder: (_, s) => SeriesFormScreen(seriesId: s.pathParameters['id'], fromDate: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/media/new',
        builder: (_, s) => MediaPublishScreen(groupId: s.uri.queryParameters['groupId']),
      ),
      GoRoute(
        path: '/media/:id',
        builder: (_, s) => MediaViewerScreen(postId: s.pathParameters['id']!),
      ),
      GoRoute(path: Routes.newGroup, builder: (_, _) => const CreateGroupScreen()),
      GoRoute(
        path: '/training/:id/attendance',
        builder: (_, s) => AttendanceScreen(trainingId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/children/:id/progress',
        builder: (_, s) => ProgressScreen(childId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:groupId/invite',
        builder: (_, s) => InviteChildScreen(groupId: s.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/training/new',
        builder: (_, s) => TrainingFormScreen(groupId: s.uri.queryParameters['groupId']),
      ),
      GoRoute(
        path: '/training/:id',
        builder: (_, s) => TrainingDetailScreen(trainingId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/training/:id/edit',
        builder: (_, s) => TrainingFormScreen(trainingId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/chat/:groupId',
        builder: (_, s) => ChatRoomScreen(groupId: s.pathParameters['groupId']!),
      ),
      GoRoute(path: Routes.newChild, builder: (_, _) => const ChildFormScreen()),
      GoRoute(
        path: '/children/:id',
        builder: (_, s) => ChildProfileScreen(childId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/certificates/:childId',
        builder: (_, s) => CertificatesScreen(childId: s.pathParameters['childId']!),
      ),
      GoRoute(
        path: '/certificates/:childId/upload',
        builder: (_, s) => UploadCertificateScreen(
          childId: s.pathParameters['childId']!,
          replaceCertId: s.uri.queryParameters['replace'],
        ),
      ),
      GoRoute(
        path: '/group/:groupId',
        builder: (_, s) => GroupRosterScreen(groupId: s.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/student/:childId',
        builder: (_, s) => StudentProfileScreen(childId: s.pathParameters['childId']!),
      ),
      GoRoute(
        path: '/student/:childId/coach/:coachId',
        builder: (_, s) =>
            ChildThreadScreen(childId: s.pathParameters['childId']!, coachId: s.pathParameters['coachId']!),
      ),
      GoRoute(
        path: '/group/:groupId/contacts',
        builder: (_, s) =>
            GroupContactsScreen(groupId: s.pathParameters['groupId']!, childId: s.uri.queryParameters['childId']),
      ),
      GoRoute(
        path: '/chat/:groupId/receipts/:messageId',
        builder: (_, s) =>
            ReceiptDetailsScreen(groupId: s.pathParameters['groupId']!, messageId: s.pathParameters['messageId']!),
      ),
      GoRoute(
        path: '/group/:groupId/payments',
        builder: (_, s) => CoachPaymentsScreen(groupId: s.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/club/:id',
        builder: (_, s) => ClubScreen(clubId: s.pathParameters['id']!),
      ),
      GoRoute(path: Routes.chats, builder: (_, _) => const ChatListScreen()),
      GoRoute(path: Routes.parentChat, redirect: (_, _) => Routes.chats),
      GoRoute(path: Routes.coachChat, redirect: (_, _) => Routes.chats),
      GoRoute(path: Routes.notifications, builder: (_, _) => const InboxScreen()),
      GoRoute(path: Routes.notificationSettings, builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.payments, builder: (_, _) => const ParentPaymentsScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
