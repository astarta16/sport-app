import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/account/data/demo_account_repository.dart';
import '../features/admin/data/demo_admin_repository.dart';
import '../features/attendance/data/demo_attendance_repository.dart';
import '../features/authentication/data/demo_auth_repository.dart';
import '../features/chat/data/demo_chat_repository.dart';
import '../features/children/data/demo_children_repository.dart';
import '../features/clubs/data/demo_clubs_repository.dart';
import '../features/brain_academy/data/demo_brain_repositories.dart';
import '../features/child_threads/data/demo_child_threads_repository.dart';
import '../features/contacts/data/demo_contacts_repository.dart';
import '../features/demo/data/demo_backend.dart';
import '../features/groups/data/demo_groups_repository.dart';
import '../features/maps/data/demo_location_repository.dart';
import '../features/matches/data/demo_matches_repository.dart';
import '../features/media/data/demo_media_access_repository.dart';
import '../features/media/data/demo_media_repository.dart';
import '../features/medical_certificates/data/demo_certificates_repository.dart';
import '../features/moderation/data/demo_moderation_repository.dart';
import '../features/notifications/data/demo_notifications_repository.dart';
import '../features/organizations/data/demo_org_repositories.dart';
import '../features/payments/data/demo_payment_proofs_repository.dart';
import '../features/payments/data/demo_payments_repository.dart';
import '../features/sports/data/demo_sports_repository.dart';
import '../features/training_plans/data/demo_training_plans_repository.dart';
import '../features/trainings/data/demo_trainings_repository.dart';
import 'config.dart';
import 'di.dart';

/// Binds every repository to the in-memory demo backend.
List<Override> demoOverrides(DemoBackend db) => [
  appModeProvider.overrideWithValue(AppMode.demo),
  demoBackendProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(db.clock),
  authRepositoryProvider.overrideWithValue(DemoAuthRepository(db)),
  userDirectoryRepositoryProvider.overrideWithValue(DemoUserDirectoryRepository(db)),
  childrenRepositoryProvider.overrideWithValue(DemoChildrenRepository(db)),
  sportsRepositoryProvider.overrideWithValue(DemoSportsRepository(db)),
  clubsRepositoryProvider.overrideWithValue(DemoClubsRepository(db)),
  groupsRepositoryProvider.overrideWithValue(DemoGroupsRepository(db)),
  trainingsRepositoryProvider.overrideWithValue(DemoTrainingsRepository(db)),
  chatRepositoryProvider.overrideWithValue(DemoChatRepository(db)),
  certificatesRepositoryProvider.overrideWithValue(DemoCertificatesRepository(db)),
  notificationsRepositoryProvider.overrideWithValue(DemoNotificationsRepository(db)),
  paymentsRepositoryProvider.overrideWithValue(DemoPaymentsRepository(db)),
  locationRepositoryProvider.overrideWithValue(DemoLocationRepository(db)),
  mediaRepositoryProvider.overrideWithValue(DemoMediaRepository(db)),
  matchesRepositoryProvider.overrideWithValue(DemoMatchesRepository(db)),
  attendanceRepositoryProvider.overrideWithValue(DemoAttendanceRepository(db)),
  mediaPostsRepositoryProvider.overrideWithValue(DemoMediaPostsRepository(db)),
  moderationRepositoryProvider.overrideWithValue(DemoModerationRepository(db)),
  adminRepositoryProvider.overrideWithValue(DemoAdminRepository(db)),
  accountRepositoryProvider.overrideWithValue(DemoAccountRepository(db)),
  paymentProofsRepositoryProvider.overrideWithValue(DemoPaymentProofsRepository(db)),
  trainingPlansRepositoryProvider.overrideWithValue(DemoTrainingPlansRepository(db)),
  contactsRepositoryProvider.overrideWithValue(DemoContactsRepository(db)),
  mediaAccessRepositoryProvider.overrideWithValue(DemoMediaAccessRepository(db)),
  mediaDownloaderProvider.overrideWithValue(DemoMediaDownloader(db)),
  childThreadsRepositoryProvider.overrideWithValue(DemoChildThreadsRepository(db)),
  // Demo progress survives restarts (SharedPreferences); never Firebase.
  brainAcademyRepositoryProvider.overrideWith((ref) {
    SharedPreferences? prefs;
    try {
      prefs = ref.watch(sharedPreferencesProvider);
    } catch (_) {
      prefs = null; // admin web demo: no local persistence needed
    }
    return DemoBrainAcademyRepository(db, prefs);
  }),
  studentRepositoryProvider.overrideWithValue(DemoStudentRepository(db)),
  organizationsRepositoryProvider.overrideWithValue(DemoOrganizationsRepository(db)),
  schedulingRepositoryProvider.overrideWithValue(DemoSchedulingRepository(db)),
  leaderboardRepositoryProvider.overrideWithValue(DemoLeaderboardRepository(db)),
  coachContactRepositoryProvider.overrideWithValue(DemoCoachContactRepository(db)),
];
