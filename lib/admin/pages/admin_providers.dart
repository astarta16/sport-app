import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/authentication/domain/app_user.dart';
import '../../features/authentication/presentation/session_providers.dart';
import '../../features/moderation/domain/report.dart';
import '../../features/sports/domain/sport.dart';

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  ref.watch(currentUidProvider);
  // Recompute when anything the admin can change is updated.
  ref.watch(adminCoachesProvider);
  ref.watch(adminReportsProvider);
  ref.watch(adminGroupsProvider);
  return ref.watch(adminRepositoryProvider).stats();
});

final adminCoachesProvider = StreamProvider.autoDispose<List<CoachSummary>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchCoaches();
});

final adminClubsProvider = StreamProvider.autoDispose<List<ClubOverview>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchClubs();
});

final adminSportsProvider = StreamProvider.autoDispose<List<Sport>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchSports();
});

final adminGroupsProvider = StreamProvider.autoDispose<List<GroupOverview>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchGroups();
});

final adminReportsProvider = StreamProvider.autoDispose<List<ContentReport>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchReports();
});

final adminAuditProvider = StreamProvider.autoDispose<List<AuditEntry>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchAudit();
});

final adminAdminsProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(adminRepositoryProvider).watchAdmins();
});
