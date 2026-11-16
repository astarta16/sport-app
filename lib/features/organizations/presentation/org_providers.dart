import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../brain_academy/domain/brain_models.dart';
import '../../brain_academy/domain/scoring.dart';
import '../domain/coach_contact.dart';
import '../domain/organization.dart';
import '../domain/scheduling.dart';

/// Tenant configuration (branding + enabled modules) of one organization.
final orgConfigProvider = StreamProvider.autoDispose.family<OrgConfig, String>((ref, orgId) {
  ref.watch(currentUidProvider);
  return ref.watch(organizationsRepositoryProvider).watchConfig(orgId);
});

/// All organizations visible to the signed-in user.
final orgConfigsProvider = StreamProvider.autoDispose<List<OrgConfig>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(organizationsRepositoryProvider).watchConfigs();
});

final myMembershipsProvider = StreamProvider.autoDispose<List<OrgMembership>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(organizationsRepositoryProvider).watchMyMemberships();
});

/// The organization context the user is working in. A user may belong to
/// several organizations; the choice is remembered on the device and falls
/// back to the first membership. It only scopes what is SHOWN — every
/// request is still authorized server-side against the user's memberships.
class ActiveOrgNotifier extends Notifier<String?> {
  static const _key = 'org.active';

  @override
  String? build() {
    final memberships = ref.watch(myMembershipsProvider).value ?? const <OrgMembership>[];
    String? saved;
    try {
      saved = ref.read(sharedPreferencesProvider).getString(_key);
    } catch (_) {
      saved = null;
    }
    if (saved != null && memberships.any((m) => m.orgId == saved)) return saved;
    return memberships.firstOrNull?.orgId;
  }

  void select(String orgId) {
    state = orgId;
    try {
      final SharedPreferences p = ref.read(sharedPreferencesProvider);
      p.setString(_key, orgId);
    } catch (_) {
      // No local persistence (admin web demo): selection lasts the session.
    }
  }
}

final activeOrgProvider = NotifierProvider<ActiveOrgNotifier, String?>(ActiveOrgNotifier.new);

final programsProvider = StreamProvider.autoDispose.family<List<SportsProgram>, String>((ref, orgId) {
  ref.watch(currentUidProvider);
  return ref.watch(organizationsRepositoryProvider).watchPrograms(orgId);
});

final roomsProvider = StreamProvider.autoDispose.family<List<Room>, String>((ref, orgId) {
  ref.watch(currentUidProvider);
  return ref.watch(schedulingRepositoryProvider).watchRooms(orgId);
});

/// Bookings of one organization in [from, to).
final bookingsProvider = StreamProvider.autoDispose.family<List<Booking>, (String, DateTime, DateTime)>((ref, k) {
  ref.watch(currentUidProvider);
  return ref.watch(schedulingRepositoryProvider).watchBookings(k.$1, from: k.$2, to: k.$3);
});

final leaderboardConsentProvider = StreamProvider.autoDispose.family<LeaderboardConsent?, (String, String)>((ref, k) {
  ref.watch(currentUidProvider);
  return ref.watch(leaderboardRepositoryProvider).watchConsent(k.$1, k.$2);
});

final leaderboardProvider = StreamProvider.autoDispose
    .family<LeaderboardBoard, (String, String, LeaderboardPeriod, BrainGame?)>((ref, k) {
      ref.watch(currentUidProvider);
      return ref.watch(leaderboardRepositoryProvider).watchBoard(k.$1, k.$2, period: k.$3, game: k.$4);
    });

final myContactRequestsProvider = StreamProvider.autoDispose<List<CoachContactRequest>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(coachContactRepositoryProvider).watchMine();
});

final parentContactRequestsProvider = StreamProvider.autoDispose<List<CoachContactRequest>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(coachContactRepositoryProvider).watchForParent();
});
