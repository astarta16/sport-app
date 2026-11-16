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
  rejected,

  /// Temporarily blocked by an admin; no access to child data.
  suspended,

  /// Permanently revoked by an admin.
  revoked;

  static CoachStatus? fromName(String? name) =>
      name == null ? null : CoachStatus.values.firstWhere((s) => s.name == name, orElse: () => CoachStatus.pending);
}

/// Administrative scope (v1.2). Rights come from server-side custom claims;
/// these fields mirror them for the UI only.
enum AdminRole {
  platform,
  club;

  static AdminRole? fromName(String? n) => switch (n) {
    'platform' => platform,
    'club' => club,
    _ => null,
  };
}

/// Per-user privacy choices (v1.2 account management).
class PrivacySettings {
  const PrivacySettings({this.profilePhotoVisible = true, this.analyticsConsent = false});

  /// Coaches/parents of shared groups may see the profile photo (v1.1 §3).
  final bool profilePhotoVisible;

  /// Anonymous crash/performance diagnostics (opt-in).
  final bool analyticsConsent;

  PrivacySettings copyWith({bool? profilePhotoVisible, bool? analyticsConsent}) => PrivacySettings(
    profilePhotoVisible: profilePhotoVisible ?? this.profilePhotoVisible,
    analyticsConsent: analyticsConsent ?? this.analyticsConsent,
  );

  Map<String, dynamic> toMap() => {'profilePhotoVisible': profilePhotoVisible, 'analyticsConsent': analyticsConsent};

  factory PrivacySettings.fromMap(Object? m) {
    if (m is! Map) return const PrivacySettings();
    return PrivacySettings(
      profilePhotoVisible: m['profilePhotoVisible'] as bool? ?? true,
      analyticsConsent: m['analyticsConsent'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PrivacySettings &&
      other.profilePhotoVisible == profilePhotoVisible &&
      other.analyticsConsent == analyticsConsent;

  @override
  int get hashCode => Object.hash(profilePhotoVisible, analyticsConsent);
}

/// Last selected child / sport / group (spec §5 `lastContext`).
class UserContext {
  const UserContext({this.childId, this.sportId, this.groupId});

  final String? childId;
  final String? sportId;
  final String? groupId;

  bool get isEmpty => childId == null && sportId == null && groupId == null;

  UserContext copyWith({String? childId, String? sportId, String? groupId}) =>
      UserContext(childId: childId ?? this.childId, sportId: sportId ?? this.sportId, groupId: groupId ?? this.groupId);

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
    this.photoPath,
    this.adminRole,
    this.adminClubIds = const [],
    this.coachStatusReason,
    this.privacy = const PrivacySettings(),
    this.locale = 'ka',
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

  /// Storage path of the profile photo (`profiles/{uid}/avatar.jpg`, v1.1 §3).
  final String? photoPath;

  /// Server-managed mirror of the admin custom claims.
  final AdminRole? adminRole;
  final List<String> adminClubIds;

  /// Reason given by an admin when rejecting / suspending a coach.
  final String? coachStatusReason;
  final PrivacySettings privacy;

  /// ka | en | ru — language for server-generated text.
  final String locale;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isEmpty ? '' : firstName.characters0}${lastName.isEmpty ? '' : lastName.characters0}';

  bool get isParent => role == UserRole.parent;
  bool get isCoach => role == UserRole.coach;

  /// v1.6 student account (role `child`), linked to one child via lastContext.
  bool get isStudent => role == UserRole.child;
  bool get isApprovedCoach => role == UserRole.coach && coachStatus == CoachStatus.approved;

  /// Admin rights come from the server-set claims (mirrored in [adminRole]);
  /// a coach can also be the admin of their club.
  bool get isAdmin => adminRole != null;
  bool get isPlatformAdmin => isAdmin && adminRole == AdminRole.platform;

  /// Club admin of [clubId] (platform admins manage every club).
  bool administersClub(String clubId) => isPlatformAdmin || (isAdmin && adminClubIds.contains(clubId));

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
    String? photoPath,
    bool clearPhoto = false,
    String? coachStatusReason,
    PrivacySettings? privacy,
    AdminRole? adminRole,
    List<String>? adminClubIds,
    String? locale,
  }) => AppUser(
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
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    adminRole: adminRole ?? this.adminRole,
    adminClubIds: adminClubIds ?? this.adminClubIds,
    coachStatusReason: coachStatusReason ?? this.coachStatusReason,
    privacy: privacy ?? this.privacy,
    locale: locale ?? this.locale,
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
    'photoPath': photoPath,
    'privacy': privacy.toMap(),
    'locale': locale,
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
    photoPath: m['photoPath'] as String?,
    adminRole: AdminRole.fromName(m['adminRole'] as String?),
    adminClubIds: readStringList(m['adminClubIds']),
    coachStatusReason: m['coachStatusReason'] as String?,
    privacy: PrivacySettings.fromMap(m['privacy']),
    locale: const ['ka', 'en', 'ru'].contains(m['locale']) ? m['locale'] as String : 'ka',
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
    this.photoPath,
  });

  final String id;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phone;
  final String? photoPath;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isEmpty ? '' : firstName.characters0}${lastName.isEmpty ? '' : lastName.characters0}';
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
