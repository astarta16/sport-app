import '../../../core/utils/dates.dart';
import '../../notifications/domain/notification_models.dart';

enum UserRole {
  parent,
  child,
  coach,
  admin;

  static UserRole fromName(String? name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => UserRole.parent);
}

enum CoachStatus {
  pending,
  approved,
  rejected;

  static CoachStatus? fromName(String? name) =>
      name == null ? null : CoachStatus.values.firstWhere((s) => s.name == name, orElse: () => CoachStatus.pending);
}

/// Last selected child / sport / group (spec §5 `lastContext`).
class UserContext {
  const UserContext({this.childId, this.sportId, this.groupId});

  final String? childId;
  final String? sportId;
  final String? groupId;

  bool get isEmpty => childId == null && sportId == null && groupId == null;

  UserContext copyWith({String? childId, String? sportId, String? groupId}) => UserContext(
        childId: childId ?? this.childId,
        sportId: sportId ?? this.sportId,
        groupId: groupId ?? this.groupId,
      );

  Map<String, dynamic> toMap() => {'childId': childId, 'sportId': sportId, 'groupId': groupId};

  factory UserContext.fromMap(Object? map) {
    if (map is! Map) return const UserContext();
    return UserContext(
      childId: map['childId'] as String?,
      sportId: map['sportId'] as String?,
      groupId: map['groupId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserContext && other.childId == childId && other.sportId == sportId && other.groupId == groupId;

  @override
  int get hashCode => Object.hash(childId, sportId, groupId);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.createdAt,
    this.lastContext = const UserContext(),
    this.fcmTokens = const [],
    this.coachStatus,
    this.clubIds = const [],
    this.sportIds = const [],
    this.dataConsentAt,
    this.smsConsentAt,
    this.notificationPrefs = const NotificationPreferences(),
  });

  final String id;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String phone;
  final DateTime createdAt;
  final UserContext lastContext;
  final List<String> fcmTokens;

  /// Coaches only. A coach sees no child data until `approved` (spec §8).
  final CoachStatus? coachStatus;
  final List<String> clubIds;
  final List<String> sportIds;
  final DateTime? dataConsentAt;
  final DateTime? smsConsentAt;
  final NotificationPreferences notificationPrefs;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isEmpty ? '' : firstName.characters0}${lastName.isEmpty ? '' : lastName.characters0}';

  bool get isParent => role == UserRole.parent;
  bool get isCoach => role == UserRole.coach;
  bool get isApprovedCoach => role == UserRole.coach && coachStatus == CoachStatus.approved;
  bool get isAdmin => role == UserRole.admin;

  /// Children never have chat (spec §3, §8).
  bool get canUseChat => isParent || isApprovedCoach;

  AppUser copyWith({
    String? firstName,
    String? lastName,
    UserContext? lastContext,
    List<String>? fcmTokens,
    CoachStatus? coachStatus,
    List<String>? clubIds,
    List<String>? sportIds,
    DateTime? smsConsentAt,
    NotificationPreferences? notificationPrefs,
  }) =>
      AppUser(
        id: id,
        role: role,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone,
        createdAt: createdAt,
        lastContext: lastContext ?? this.lastContext,
        fcmTokens: fcmTokens ?? this.fcmTokens,
        coachStatus: coachStatus ?? this.coachStatus,
        clubIds: clubIds ?? this.clubIds,
        sportIds: sportIds ?? this.sportIds,
        dataConsentAt: dataConsentAt,
        smsConsentAt: smsConsentAt ?? this.smsConsentAt,
        notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      );

  Map<String, dynamic> toMap() => {
        'role': role.name,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'createdAt': createdAt,
        'lastContext': lastContext.toMap(),
        'fcmTokens': fcmTokens,
        if (coachStatus != null) 'coachStatus': coachStatus!.name,
        'clubIds': clubIds,
        'sportIds': sportIds,
        'dataConsentAt': dataConsentAt,
        'smsConsentAt': smsConsentAt,
        'notificationPrefs': notificationPrefs.toMap(),
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> m) => AppUser(
        id: id,
        role: UserRole.fromName(m['role'] as String?),
        firstName: m['firstName'] as String? ?? '',
        lastName: m['lastName'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        createdAt: readDateOrNull(m['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        lastContext: UserContext.fromMap(m['lastContext']),
        fcmTokens: readStringList(m['fcmTokens']),
        coachStatus: CoachStatus.fromName(m['coachStatus'] as String?),
        clubIds: readStringList(m['clubIds']),
        sportIds: readStringList(m['sportIds']),
        dataConsentAt: readDateOrNull(m['dataConsentAt']),
        smsConsentAt: readDateOrNull(m['smsConsentAt']),
        notificationPrefs: NotificationPreferences.fromMap(m['notificationPrefs']),
      );
}

/// Public-facing identity. Phone is only filled when the viewer is allowed to
/// see it (coach ↔ parents of the same group; never parent ↔ parent).
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
  });

  final String id;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phone;

  String get fullName => '$firstName $lastName';
}

extension on String {
  String get characters0 => runes.isEmpty ? '' : String.fromCharCode(runes.first);
}

/// Session = verified phone identity, optionally with a completed profile.
class AuthSession {
  const AuthSession({required this.uid, required this.phone, this.user});

  final String uid;
  final String phone;
  final AppUser? user;

  bool get needsRegistration => user == null;
}

/// Data collected by the registration form (spec §4).
class RegistrationData {
  const RegistrationData({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.sportIds,
    required this.dataConsent,
    this.clubIds = const [],
    this.smsConsent = false,
  });

  final UserRole role;
  final String firstName;
  final String lastName;
  final List<String> sportIds;
  final List<String> clubIds;
  final bool dataConsent;
  final bool smsConsent;
}
