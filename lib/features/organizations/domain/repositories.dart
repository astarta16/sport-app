import '../../admin/domain/admin_models.dart';
import '../../brain_academy/domain/brain_models.dart';
import '../../brain_academy/domain/scoring.dart';
import '../../clubs/domain/club.dart';
import 'coach_contact.dart';
import 'organization.dart';
import 'scheduling.dart';

/// Tenant administration. Platform-only operations are re-checked on the
/// server (Cloud Functions / demo backend), never just hidden in the UI.
abstract interface class OrganizationsRepository {
  /// Platform admin: every organization. Organization admin: their own.
  /// Anyone else: the organizations they are a member of.
  Stream<List<OrgConfig>> watchConfigs();

  /// Branding and enabled modules of one organization (members only).
  Stream<OrgConfig> watchConfig(String orgId);

  /// Platform admin creates a tenant (a club document + its config).
  Future<Club> createOrganization({
    required ClubDraft club,
    required OrgPlan plan,
    required OrgBranding branding,
    String timezone = OrgTimeZones.tbilisi,
    String defaultLanguage = 'ka',
  });

  /// Platform-only fields: status, plan, allowed modules, limits.
  Future<void> updatePlatformSettings(
    String orgId, {
    OrgStatus? status,
    OrgPlan? plan,
    Set<OrgModule>? allowedModules,
    OrgLimits? limits,
  });

  /// Organization-admin fields. Enabled modules must be a subset of the
  /// allowed modules (no self-enabling of premium or restricted modules).
  Future<void> updateOrgSettings(
    String orgId, {
    Set<OrgModule>? enabledModules,
    OrgBranding? branding,
    String? defaultLanguage,
    String? timezone,
    LeaderboardSettings? leaderboard,
    int? bookingBufferMin,
    List<String>? sportIds,
  });

  /// Platform admin assigns / removes an organization administrator.
  Future<void> setOrgAdmin(String orgId, String userId, {required bool admin});

  /// Organization admin adds an approved coach to the organization.
  Future<void> setOrgCoach(String orgId, String coachId, {required bool member});

  /// Memberships of the signed-in user (several organizations possible).
  Stream<List<OrgMembership>> watchMyMemberships();
  Stream<List<OrgMembership>> watchMembers(String orgId);

  Stream<List<SportsProgram>> watchPrograms(String orgId);
  Future<SportsProgram> upsertProgram(SportsProgram p);

  Future<TenantHealth> health(String orgId);
}

abstract interface class SchedulingRepository {
  Stream<List<Room>> watchRooms(String orgId);
  Future<Room> upsertRoom(Room r);
  Future<void> setRoomStatus(String orgId, String roomId, RoomStatus status);

  /// Active and cancelled bookings in [from, to).
  Stream<List<Booking>> watchBookings(String orgId, {required DateTime from, required DateTime to});

  /// Instant (non-authoritative) check for the editor UI.
  Future<List<BookingConflict>> preview(Booking draft, {Set<String> ignoreIds = const {}});

  /// Atomic, server-validated create. Throws [BookingRejected].
  Future<Booking> createBooking(Booking draft, {bool allowGroupOverlap = false});

  /// All occurrences within the generation window are checked before
  /// anything is written; one conflict rejects the whole series.
  Future<List<Booking>> createRecurring(Booking template, WeeklyRule rule, {bool allowGroupOverlap = false});

  /// Move / edit one booking (or one occurrence, which detaches it).
  Future<Booking> updateBooking(Booking updated, {bool allowGroupOverlap = false});

  /// Changes the time of this and all later occurrences of a series.
  Future<List<Booking>> updateSeriesFrom(
    String bookingId, {
    required int startMinute,
    required int durationMin,
    String? roomId,
  });

  Future<void> cancelBooking(String bookingId, {SeriesEditScope scope = SeriesEditScope.thisOccurrence});
}

abstract interface class LeaderboardRepository {
  Stream<LeaderboardConsent?> watchConsent(String orgId, String childId);

  /// Guardian grants or revokes consent (revocation removes the child from
  /// the board immediately).
  Future<void> setConsent(String orgId, String childId, {required bool granted, DisplayNameMode mode});

  /// The board the signed-in student (or their parent) may see.
  Stream<LeaderboardBoard> watchBoard(
    String orgId,
    String childId, {
    required LeaderboardPeriod period,
    BrainGame? game,
  });
}

abstract interface class CoachContactRepository {
  /// Student asks a parent to contact the coach (no direct child→adult chat).
  Future<CoachContactRequest> request({required String coachId, required String groupId, required String topic});

  /// Open requests of the parent's children.
  Stream<List<CoachContactRequest>> watchForParent();

  /// The student's own requests.
  Stream<List<CoachContactRequest>> watchMine();
  Future<void> markHandled(String id);
}
