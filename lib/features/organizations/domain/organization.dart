import '../../../core/utils/dates.dart';
import '../../brain_academy/domain/brain_models.dart';
import 'platform.dart';

/// v1.7 multi-academy SaaS. An organization (sports school, academy,
/// company) is the tenant. It is stored as the existing `clubs/{clubId}`
/// document, so `clubId` IS the tenant id (`organizationId`) on every
/// tenant-owned record — no parallel organization system. This file holds
/// the tenant configuration that lives next to it (`orgConfigs/{clubId}`).

/// Switchable product modules. Every module is checked in the UI, in the
/// repositories (demo backend / Cloud Functions) and in Firestore rules.
enum OrgModule {
  trainings,
  matches,
  attendance,
  communication,
  studentAccounts,
  brainAcademy,
  trainingPlans,
  payments,
  medicalCertificates,
  media,
  leaderboards,
  roomScheduling,
  notifications,
  // v1.8 finer-grained features (stable ids; see FeatureCatalog).
  parentRsvp,
  messageAcks,
  coachChallenges,
  paymentReceipts,
  paymentVerification,
  paymentReminders,
  facilities,
  reports,
  dataExports;

  static OrgModule? fromName(String? n) => values.where((v) => v.name == n).firstOrNull;

  static Set<OrgModule> readSet(Object? raw) => {
    if (raw is List)
      for (final e in raw) ?fromName(e?.toString()),
  };
}

enum OrgStatus {
  active,

  /// Temporarily blocked (e.g. unpaid): data is kept and readable, every
  /// module is off, nothing new can be written.
  suspended,

  /// Switched off by the platform. Same effect as suspended, plus hidden
  /// from search.
  deactivated;

  static OrgStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => active);
}

/// Subscription plan. The plan only proposes defaults; the platform admin's
/// [OrgConfig.allowedModules] list is what actually applies.
enum OrgPlan {
  free,
  standard,
  premium;

  static OrgPlan fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => standard);

  Set<OrgModule> get defaultModules => switch (this) {
    free => {
      OrgModule.trainings,
      OrgModule.matches,
      OrgModule.attendance,
      OrgModule.parentRsvp,
      OrgModule.communication,
      OrgModule.messageAcks,
      OrgModule.notifications,
      OrgModule.reports,
    },
    standard => {
      ...free.defaultModules,
      OrgModule.studentAccounts,
      OrgModule.brainAcademy,
      OrgModule.coachChallenges,
      OrgModule.trainingPlans,
      OrgModule.payments,
      OrgModule.paymentReceipts,
      OrgModule.paymentVerification,
      OrgModule.paymentReminders,
      OrgModule.medicalCertificates,
      OrgModule.media,
      OrgModule.dataExports,
    },
    premium => {...OrgModule.values},
  };

  OrgLimits get defaultLimits => switch (this) {
    free => const OrgLimits(maxStudents: 50, maxCoaches: 5, maxRooms: 1, maxGroups: 5),
    standard => const OrgLimits(maxStudents: 300, maxCoaches: 30, maxRooms: 5, maxGroups: 40),
    premium => const OrgLimits(maxStudents: 2000, maxCoaches: 200, maxRooms: 30, maxGroups: 300),
  };
}

/// Modules only the platform may switch on (they need review or cost money).
final restrictedModules = FeatureCatalog.restricted;

class OrgLimits {
  const OrgLimits({
    required this.maxStudents,
    required this.maxCoaches,
    required this.maxRooms,
    required this.maxGroups,
  });

  final int maxStudents;
  final int maxCoaches;
  final int maxRooms;
  final int maxGroups;

  Map<String, dynamic> toMap() => {
    'maxStudents': maxStudents,
    'maxCoaches': maxCoaches,
    'maxRooms': maxRooms,
    'maxGroups': maxGroups,
  };

  factory OrgLimits.fromMap(Object? m, OrgLimits fallback) {
    if (m is! Map) return fallback;
    int v(String k, int d) => (m[k] as num?)?.toInt() ?? d;
    return OrgLimits(
      maxStudents: v('maxStudents', fallback.maxStudents),
      maxCoaches: v('maxCoaches', fallback.maxCoaches),
      maxRooms: v('maxRooms', fallback.maxRooms),
      maxGroups: v('maxGroups', fallback.maxGroups),
    );
  }

  OrgLimits copyWith({int? maxStudents, int? maxCoaches, int? maxRooms, int? maxGroups}) => OrgLimits(
    maxStudents: maxStudents ?? this.maxStudents,
    maxCoaches: maxCoaches ?? this.maxCoaches,
    maxRooms: maxRooms ?? this.maxRooms,
    maxGroups: maxGroups ?? this.maxGroups,
  );
}

/// Academy branding shown in the apps without a rebuild.
class OrgBranding {
  const OrgBranding({
    this.names = const {},
    this.logoUrl,
    this.primaryColor = 0xFF1D4ED8,
    this.secondaryColor = 0xFF0F172A,
    this.description = '',
    this.contactPhone,
    this.contactEmail,
    this.address = '',
  });

  /// locale → display name (`ka`, `en`, `ru`).
  final Map<String, String> names;
  final String? logoUrl;

  /// ARGB colour value.
  final int primaryColor;

  /// v1.8 secondary brand colour (accents, headers).
  final int secondaryColor;
  final String description;
  final String? contactPhone;
  final String? contactEmail;
  final String address;

  String nameFor(String locale, {String fallback = ''}) =>
      names[locale] ?? names['ka'] ?? names['en'] ?? (names.values.isEmpty ? fallback : names.values.first);

  static bool validColor(int c) => c >= 0xFF000000 && c <= 0xFFFFFFFF;

  Map<String, dynamic> toMap() => {
    'names': names,
    'logoUrl': logoUrl,
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'description': description,
    'contactPhone': contactPhone,
    'contactEmail': contactEmail,
    'address': address,
  };

  factory OrgBranding.fromMap(Object? m) {
    if (m is! Map) return const OrgBranding();
    return OrgBranding(
      names: {for (final e in ((m['names'] as Map?) ?? const {}).entries) e.key.toString(): e.value.toString()},
      logoUrl: m['logoUrl'] as String?,
      primaryColor: (m['primaryColor'] as num?)?.toInt() ?? 0xFF1D4ED8,
      secondaryColor: (m['secondaryColor'] as num?)?.toInt() ?? 0xFF0F172A,
      description: m['description'] as String? ?? '',
      contactPhone: m['contactPhone'] as String?,
      contactEmail: m['contactEmail'] as String?,
      address: m['address'] as String? ?? '',
    );
  }

  OrgBranding copyWith({
    Map<String, String>? names,
    String? logoUrl,
    int? primaryColor,
    int? secondaryColor,
    String? description,
    String? contactPhone,
    String? contactEmail,
    String? address,
  }) => OrgBranding(
    names: names ?? this.names,
    logoUrl: logoUrl ?? this.logoUrl,
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    description: description ?? this.description,
    contactPhone: contactPhone ?? this.contactPhone,
    contactEmail: contactEmail ?? this.contactEmail,
    address: address ?? this.address,
  );
}

enum LeaderboardPeriod {
  week,
  month,
  allTime;

  static LeaderboardPeriod fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => week);
}

/// Organization leaderboard configuration (child-safe defaults: off).
class LeaderboardSettings {
  const LeaderboardSettings({
    this.enabled = false,
    this.games = const {},
    this.periods = const {LeaderboardPeriod.week, LeaderboardPeriod.month},
    this.byAgeBand = true,
    this.minParticipants = 3,
  });

  final bool enabled;

  /// Games that count; empty = all six.
  final Set<BrainGame> games;
  final Set<LeaderboardPeriod> periods;

  /// Rank only within the student's age band (see [ageBandOf]).
  final bool byAgeBand;

  /// A board with fewer opted-in students is not shown (prevents
  /// identifying a single child).
  final int minParticipants;

  Set<BrainGame> get effectiveGames => games.isEmpty ? BrainGame.values.toSet() : games;

  /// 6–8, 9–11, 12–14, 15–17.
  static String ageBandOf(int age) => switch (age) {
    <= 8 => '6-8',
    <= 11 => '9-11',
    <= 14 => '12-14',
    _ => '15-17',
  };

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'games': [for (final g in games) g.name],
    'periods': [for (final p in periods) p.name],
    'byAgeBand': byAgeBand,
    'minParticipants': minParticipants,
  };

  factory LeaderboardSettings.fromMap(Object? m) {
    if (m is! Map) return const LeaderboardSettings();
    return LeaderboardSettings(
      enabled: m['enabled'] as bool? ?? false,
      games: {for (final g in (m['games'] as List?) ?? const []) ?BrainGame.fromName(g?.toString())},
      periods: {
        for (final p in (m['periods'] as List?) ?? const ['week', 'month']) LeaderboardPeriod.fromName('$p'),
      },
      byAgeBand: m['byAgeBand'] as bool? ?? true,
      minParticipants: ((m['minParticipants'] as num?)?.toInt() ?? 3).clamp(2, 50),
    );
  }

  LeaderboardSettings copyWith({
    bool? enabled,
    Set<BrainGame>? games,
    Set<LeaderboardPeriod>? periods,
    bool? byAgeBand,
    int? minParticipants,
  }) => LeaderboardSettings(
    enabled: enabled ?? this.enabled,
    games: games ?? this.games,
    periods: periods ?? this.periods,
    byAgeBand: byAgeBand ?? this.byAgeBand,
    minParticipants: minParticipants ?? this.minParticipants,
  );
}

/// Tenant configuration (`orgConfigs/{clubId}`). Platform-only fields:
/// status, plan, allowedModules, limits. Organization-admin fields:
/// enabledModules (within allowed), branding, defaultLanguage, leaderboard.
class OrgConfig {
  const OrgConfig({
    required this.orgId,
    this.status = OrgStatus.active,
    this.plan = OrgPlan.standard,
    this.allowedModules = const {},
    this.enabledModules = const {},
    this.branding = const OrgBranding(),
    this.timezone = OrgTimeZones.tbilisi,
    this.defaultLanguage = 'ka',
    OrgLimits? limits,
    this.leaderboard = const LeaderboardSettings(),
    this.bookingBufferMin = 0,
    this.updatedAt,
    String? packageId,
    this.subscription = const SubscriptionInfo(),
    this.rollout = const {},
    this.profile = const OrgProfile(),
    this.settings = const OrgSettings(),
    this.provisioning = ProvisioningState.ready,
    this.version = 1,
    this.updatedBy,
    this.changeReason,
    this.templateId,
  }) : limits = limits ?? const OrgLimits(maxStudents: 300, maxCoaches: 30, maxRooms: 5, maxGroups: 40),
       packageId =
           packageId ?? (plan == OrgPlan.free ? 'starter' : (plan == OrgPlan.premium ? 'enterprise' : 'professional'));

  /// Legacy clubs created before v1.7 (no config document yet): everything
  /// that existed before stays on, the new restricted modules stay off.
  factory OrgConfig.legacy(String orgId) => OrgConfig(
    orgId: orgId,
    allowedModules: OrgPlan.standard.defaultModules,
    enabledModules: OrgPlan.standard.defaultModules,
  );

  final String orgId;
  final OrgStatus status;

  /// v1.7 plan (kept for old documents); v1.8 uses [packageId].
  final OrgPlan plan;

  /// Level 1 — what the platform entitles the organization to.
  final Set<OrgModule> allowedModules;

  /// Level 2 — what the organization switched on (subset of allowed).
  final Set<OrgModule> enabledModules;
  final OrgBranding branding;
  final String timezone;
  final String defaultLanguage;
  final OrgLimits limits;
  final LeaderboardSettings leaderboard;

  /// Minutes that must stay free between two bookings of the same room.
  final int bookingBufferMin;
  final DateTime? updatedAt;

  // v1.8
  final String packageId;
  final SubscriptionInfo subscription;

  /// Platform rollout per feature (trial / scheduled); absent = enabled.
  final Map<OrgModule, FeatureRollout> rollout;
  final OrgProfile profile;
  final OrgSettings settings;
  final ProvisioningState provisioning;

  /// Optimistic-concurrency version; every change increments it.
  final int version;
  final String? updatedBy;
  final String? changeReason;
  final String? templateId;

  bool get isActive => status == OrgStatus.active;

  AccessMode accessAt(DateTime now) => subscription.accessAt(now);

  /// The single feature-flag check used everywhere: organization active and
  /// provisioned, subscription not read-only, feature entitled by the
  /// platform (incl. trial / scheduled rollout), switched on by the
  /// organization, and every dependency effectively on as well.
  bool isEnabled(OrgModule m, {DateTime? now}) {
    final t = now ?? DateTime.now();
    if (!isActive || provisioning != ProvisioningState.ready || accessAt(t) != AccessMode.full) return false;
    if (!allowedModules.contains(m) || !enabledModules.contains(m)) return false;
    if (!(rollout[m]?.allows(t) ?? true)) return false;
    for (final group in FeatureCatalog.of(m).requires) {
      if (!group.any((d) => isEnabled(d, now: t))) return false;
    }
    return true;
  }

  bool get leaderboardOn => isEnabled(OrgModule.leaderboards) && leaderboard.enabled;

  /// Modules the organization admin may switch themselves.
  bool canOrgAdminToggle(OrgModule m) => allowedModules.contains(m);

  Map<String, dynamic> toMap({DateTime? now}) => {
    'status': status.name,
    'plan': plan.name,
    'allowedModules': [for (final m in allowedModules) m.name],
    'enabledModules': [for (final m in enabledModules) m.name],
    // Derived: what the rules check (refreshed by the server on every write
    // and by the scheduled `refreshEntitlements` job).
    'effectiveModules': [
      for (final m in OrgModule.values)
        if (isEnabled(m, now: now)) m.name,
    ],
    'accessMode': accessAt(now ?? DateTime.now()).name,
    'featureSchema': 2,
    'branding': branding.toMap(),
    'timezone': timezone,
    'defaultLanguage': defaultLanguage,
    'limits': limits.toMap(),
    'leaderboard': leaderboard.toMap(),
    'bookingBufferMin': bookingBufferMin,
    'updatedAt': updatedAt,
    'packageId': packageId,
    'subscription': subscription.toMap(),
    'rollout': {for (final e in rollout.entries) e.key.name: e.value.toMap()},
    'profile': profile.toMap(),
    'settings': settings.toMap(),
    'provisioning': provisioning.name,
    'version': version,
    'updatedBy': updatedBy,
    'changeReason': changeReason,
    'templateId': templateId,
  };

  factory OrgConfig.fromMap(String id, Map<String, dynamic> m) {
    final plan = OrgPlan.fromName(m['plan'] as String?);
    // v1.7 documents (featureSchema < 2) used coarse modules: expand them.
    final legacy = ((m['featureSchema'] as num?)?.toInt() ?? 1) < 2;
    Set<OrgModule> read(Object? raw) =>
        legacy ? FeatureCatalog.expandLegacy(OrgModule.readSet(raw)) : OrgModule.readSet(raw);
    return OrgConfig(
      orgId: id,
      status: OrgStatus.fromName(m['status'] as String?),
      plan: plan,
      allowedModules: m.containsKey('allowedModules') ? read(m['allowedModules']) : plan.defaultModules,
      enabledModules: m.containsKey('enabledModules')
          ? read(m['enabledModules'])
          : plan.defaultModules.difference(restrictedModules),
      branding: OrgBranding.fromMap(m['branding']),
      timezone: OrgTimeZones.normalize(m['timezone'] as String?),
      defaultLanguage: const {'ka', 'en', 'ru'}.contains(m['defaultLanguage']) ? m['defaultLanguage'] as String : 'ka',
      limits: OrgLimits.fromMap(m['limits'], plan.defaultLimits),
      leaderboard: LeaderboardSettings.fromMap(m['leaderboard']),
      bookingBufferMin: ((m['bookingBufferMin'] as num?)?.toInt() ?? 0).clamp(0, 120),
      updatedAt: readDateOrNull(m['updatedAt']),
      packageId: m['packageId'] as String?,
      subscription: SubscriptionInfo.fromMap(m['subscription']),
      rollout: {
        for (final e in ((m['rollout'] as Map?) ?? const {}).entries)
          if (OrgModule.fromName('${e.key}') case final mod?) mod: FeatureRollout.fromMap(e.value),
      },
      profile: OrgProfile.fromMap(m['profile']),
      settings: OrgSettings.fromMap(m['settings']),
      provisioning: ProvisioningState.fromName(m['provisioning'] as String?),
      version: (m['version'] as num?)?.toInt() ?? 1,
      updatedBy: m['updatedBy'] as String?,
      changeReason: m['changeReason'] as String?,
      templateId: m['templateId'] as String?,
    );
  }

  OrgConfig copyWith({
    OrgStatus? status,
    OrgPlan? plan,
    Set<OrgModule>? allowedModules,
    Set<OrgModule>? enabledModules,
    OrgBranding? branding,
    String? timezone,
    String? defaultLanguage,
    OrgLimits? limits,
    LeaderboardSettings? leaderboard,
    int? bookingBufferMin,
    DateTime? updatedAt,
    String? packageId,
    SubscriptionInfo? subscription,
    Map<OrgModule, FeatureRollout>? rollout,
    OrgProfile? profile,
    OrgSettings? settings,
    ProvisioningState? provisioning,
    int? version,
    String? updatedBy,
    String? changeReason,
    String? templateId,
  }) => OrgConfig(
    orgId: orgId,
    status: status ?? this.status,
    plan: plan ?? this.plan,
    allowedModules: allowedModules ?? this.allowedModules,
    enabledModules: enabledModules ?? this.enabledModules,
    branding: branding ?? this.branding,
    timezone: timezone ?? this.timezone,
    defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    limits: limits ?? this.limits,
    leaderboard: leaderboard ?? this.leaderboard,
    bookingBufferMin: bookingBufferMin ?? this.bookingBufferMin,
    updatedAt: updatedAt ?? this.updatedAt,
    packageId: packageId ?? this.packageId,
    subscription: subscription ?? this.subscription,
    rollout: rollout ?? this.rollout,
    profile: profile ?? this.profile,
    settings: settings ?? this.settings,
    provisioning: provisioning ?? this.provisioning,
    version: version ?? this.version,
    updatedBy: updatedBy ?? this.updatedBy,
    changeReason: changeReason ?? this.changeReason,
    templateId: templateId ?? this.templateId,
  );
}

/// Supported organization time zones. Only zones with a fixed UTC offset
/// and no daylight saving are offered in the beta, so local↔UTC conversion
/// is exact without shipping the tz database (documented limitation).
class OrgTimeZones {
  OrgTimeZones._();

  static const tbilisi = 'Asia/Tbilisi';

  static const offsets = <String, Duration>{
    'Asia/Tbilisi': Duration(hours: 4),
    'Asia/Yerevan': Duration(hours: 4),
    'Asia/Baku': Duration(hours: 4),
    'Europe/Istanbul': Duration(hours: 3),
    'Europe/Minsk': Duration(hours: 3),
    'UTC': Duration.zero,
  };

  static String normalize(String? tz) => offsets.containsKey(tz) ? tz! : tbilisi;

  static Duration offsetOf(String tz) => offsets[normalize(tz)]!;

  /// Wall-clock fields of [instant] in [tz], as a UTC DateTime.
  static DateTime wall(DateTime instant, String tz) => instant.toUtc().add(offsetOf(tz));

  /// The UTC instant of a wall-clock date/time in [tz].
  static DateTime instant(String tz, int y, int m, int d, [int hour = 0, int minute = 0]) =>
      DateTime.utc(y, m, d, hour, minute).subtract(offsetOf(tz));
}

enum OrgRole {
  admin,
  coach,
  parent,
  student;

  static Set<OrgRole> readSet(Object? raw) => {
    if (raw is List)
      for (final e in raw)
        for (final r in values)
          if (r.name == e) r,
  };
}

/// `clubs/{clubId}/orgMembers/{uid}` — a user may belong to several
/// organizations; nothing assumes one permanent organization per user.
class OrgMembership {
  const OrgMembership({required this.orgId, required this.userId, required this.roles, this.active = true});

  final String orgId;
  final String userId;
  final Set<OrgRole> roles;
  final bool active;

  Map<String, dynamic> toMap() => {
    'orgId': orgId,
    'userId': userId,
    'roles': [for (final r in roles) r.name],
    'active': active,
  };

  factory OrgMembership.fromMap(Map<String, dynamic> m) => OrgMembership(
    orgId: m['orgId'] as String? ?? '',
    userId: m['userId'] as String? ?? '',
    roles: OrgRole.readSet(m['roles']),
    active: m['active'] as bool? ?? true,
  );
}

enum ProgramStatus {
  active,
  paused,
  archived;

  static ProgramStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => active);
}

/// A sports program / circle (`clubs/{clubId}/programs/{id}`).
class SportsProgram {
  const SportsProgram({
    required this.id,
    required this.orgId,
    required this.sportId,
    required this.name,
    this.description = '',
    this.ageMin = 6,
    this.ageMax = 17,
    this.coachIds = const [],
    this.groupIds = const [],
    this.roomId,
    this.venueId,
    this.scheduleNote = '',
    this.capacity = 20,
    this.status = ProgramStatus.active,
  });

  final String id;
  final String orgId;
  final String sportId;
  final String name;
  final String description;
  final int ageMin;
  final int ageMax;
  final List<String> coachIds;
  final List<String> groupIds;
  final String? roomId;
  final String? venueId;
  final String scheduleNote;
  final int capacity;
  final ProgramStatus status;

  static List<String> validate(SportsProgram p) => [
    if (p.name.trim().length < 2 || p.name.length > 80) 'programName',
    if (p.sportId.isEmpty) 'programSport',
    if (p.ageMin < 3 || p.ageMax > 99 || p.ageMin > p.ageMax) 'programAge',
    if (p.capacity < 1 || p.capacity > 500) 'programCapacity',
  ];

  Map<String, dynamic> toMap() => {
    'orgId': orgId,
    'clubId': orgId,
    'sportId': sportId,
    'name': name,
    'description': description,
    'ageMin': ageMin,
    'ageMax': ageMax,
    'coachIds': coachIds,
    'groupIds': groupIds,
    'roomId': roomId,
    'venueId': venueId,
    'scheduleNote': scheduleNote,
    'capacity': capacity,
    'status': status.name,
  };

  factory SportsProgram.fromMap(String id, Map<String, dynamic> m) => SportsProgram(
    id: id,
    orgId: m['orgId'] as String? ?? m['clubId'] as String? ?? '',
    sportId: m['sportId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    description: m['description'] as String? ?? '',
    ageMin: (m['ageMin'] as num?)?.toInt() ?? 6,
    ageMax: (m['ageMax'] as num?)?.toInt() ?? 17,
    coachIds: readStringList(m['coachIds']),
    groupIds: readStringList(m['groupIds']),
    roomId: m['roomId'] as String?,
    venueId: m['venueId'] as String?,
    scheduleNote: m['scheduleNote'] as String? ?? '',
    capacity: (m['capacity'] as num?)?.toInt() ?? 20,
    status: ProgramStatus.fromName(m['status'] as String?),
  );

  SportsProgram copyWith({
    String? sportId,
    String? name,
    String? description,
    int? ageMin,
    int? ageMax,
    List<String>? coachIds,
    List<String>? groupIds,
    String? roomId,
    String? venueId,
    String? scheduleNote,
    int? capacity,
    ProgramStatus? status,
  }) => SportsProgram(
    id: id,
    orgId: orgId,
    sportId: sportId ?? this.sportId,
    name: name ?? this.name,
    description: description ?? this.description,
    ageMin: ageMin ?? this.ageMin,
    ageMax: ageMax ?? this.ageMax,
    coachIds: coachIds ?? this.coachIds,
    groupIds: groupIds ?? this.groupIds,
    roomId: roomId ?? this.roomId,
    venueId: venueId ?? this.venueId,
    scheduleNote: scheduleNote ?? this.scheduleNote,
    capacity: capacity ?? this.capacity,
    status: status ?? this.status,
  );
}

/// Operational statistics of one tenant for the platform health view.
class TenantHealth {
  const TenantHealth({
    required this.orgId,
    required this.students,
    required this.coaches,
    required this.groups,
    required this.rooms,
    required this.upcomingEvents,
    required this.bookingsThisWeek,
    required this.brainPlays7d,
  });

  final String orgId;
  final int students;
  final int coaches;
  final int groups;
  final int rooms;
  final int upcomingEvents;
  final int bookingsThisWeek;
  final int brainPlays7d;

  /// Limits that are exceeded (shown as warnings).
  List<String> overLimits(OrgLimits l) => [
    if (students > l.maxStudents) 'students',
    if (coaches > l.maxCoaches) 'coaches',
    if (groups > l.maxGroups) 'groups',
    if (rooms > l.maxRooms) 'rooms',
  ];
}
