import 'dart:math' as math;

import '../../../core/utils/dates.dart';
import '../../authentication/domain/app_user.dart';
import 'organization.dart';

/// v1.8 platform layer on top of the v1.7 tenant model (`orgConfigs`):
/// feature catalog with a dependency graph and rollout states, SaaS
/// packages and subscriptions, organization templates, admin invitations,
/// the level-3 permission matrix and the single entitlement resolver.
/// Mirrored by functions/src/lib/platform.ts (same ids, same rules).

// ───────────────────────────────────────────────────── feature catalog

enum FeatureCategory { core, communication, learning, finance, facilities, administration }

/// One switchable feature. [requires] is a list of any-of groups: every
/// group needs at least one enabled member (e.g. RSVP needs trainings OR
/// matches).
class FeatureDef {
  const FeatureDef(this.module, this.category, {this.requires = const [], this.restricted = false});

  final OrgModule module;
  final FeatureCategory category;
  final List<Set<OrgModule>> requires;

  /// Only the platform may grant it (child safety, cost, review needed).
  final bool restricted;

  /// Stable machine-readable id (`payments`, `paymentReceipts`, …). The
  /// chat module keeps its v1.7 id `communication` for data compatibility.
  String get id => module.name;
}

class FeatureCatalog {
  FeatureCatalog._();

  static const defs = <FeatureDef>[
    FeatureDef(OrgModule.trainings, FeatureCategory.core),
    FeatureDef(OrgModule.matches, FeatureCategory.core),
    FeatureDef(
      OrgModule.attendance,
      FeatureCategory.core,
      requires: [
        {OrgModule.trainings, OrgModule.matches},
      ],
    ),
    FeatureDef(
      OrgModule.parentRsvp,
      FeatureCategory.core,
      requires: [
        {OrgModule.trainings, OrgModule.matches},
      ],
    ),
    FeatureDef(OrgModule.communication, FeatureCategory.communication),
    FeatureDef(
      OrgModule.messageAcks,
      FeatureCategory.communication,
      requires: [
        {OrgModule.communication},
      ],
    ),
    FeatureDef(OrgModule.notifications, FeatureCategory.communication),
    FeatureDef(OrgModule.medicalCertificates, FeatureCategory.core),
    FeatureDef(OrgModule.trainingPlans, FeatureCategory.learning),
    FeatureDef(OrgModule.studentAccounts, FeatureCategory.learning, restricted: true),
    FeatureDef(OrgModule.brainAcademy, FeatureCategory.learning),
    FeatureDef(
      OrgModule.coachChallenges,
      FeatureCategory.learning,
      requires: [
        {OrgModule.brainAcademy},
      ],
    ),
    FeatureDef(
      OrgModule.leaderboards,
      FeatureCategory.learning,
      restricted: true,
      requires: [
        {OrgModule.brainAcademy},
      ],
    ),
    FeatureDef(OrgModule.media, FeatureCategory.communication),
    FeatureDef(OrgModule.payments, FeatureCategory.finance),
    FeatureDef(
      OrgModule.paymentReceipts,
      FeatureCategory.finance,
      requires: [
        {OrgModule.payments},
      ],
    ),
    FeatureDef(
      OrgModule.paymentVerification,
      FeatureCategory.finance,
      requires: [
        {OrgModule.payments},
        {OrgModule.paymentReceipts},
      ],
    ),
    FeatureDef(
      OrgModule.paymentReminders,
      FeatureCategory.finance,
      requires: [
        {OrgModule.payments},
      ],
    ),
    FeatureDef(OrgModule.facilities, FeatureCategory.facilities, restricted: true),
    FeatureDef(
      OrgModule.roomScheduling,
      FeatureCategory.facilities,
      restricted: true,
      requires: [
        {OrgModule.facilities},
      ],
    ),
    FeatureDef(OrgModule.reports, FeatureCategory.administration),
    FeatureDef(OrgModule.dataExports, FeatureCategory.administration),
  ];

  static FeatureDef of(OrgModule m) => defs.firstWhere((d) => d.module == m);

  static Set<OrgModule> get restricted => {
    for (final d in defs)
      if (d.restricted) d.module,
  };

  /// Unsatisfied any-of groups per module within [enabled].
  static Map<OrgModule, List<Set<OrgModule>>> missing(Set<OrgModule> enabled) => {
    for (final m in enabled)
      if (of(m).requires.where((g) => g.intersection(enabled).isEmpty).toList() case final miss when miss.isNotEmpty)
        m: miss,
  };

  static bool isValid(Set<OrgModule> enabled) => missing(enabled).isEmpty;

  /// [enabled] plus every missing dependency (the first member of an
  /// any-of group). Used only after the admin confirms the additions.
  static Set<OrgModule> withDependencies(Set<OrgModule> enabled) {
    final out = {...enabled};
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in missing(out).entries) {
        for (final g in e.value) {
          if (out.add(g.first)) changed = true;
        }
      }
    }
    return out;
  }

  /// Largest valid subset: drops features whose dependencies are missing
  /// (transitively). Used when the platform withdraws a feature.
  static Set<OrgModule> prune(Set<OrgModule> s) {
    var out = {...s};
    while (true) {
      final miss = missing(out).keys.toSet();
      if (miss.isEmpty) return out;
      out = out.difference(miss);
    }
  }

  /// Features that stop working when [m] is switched off.
  static Set<OrgModule> dependents(OrgModule m, Set<OrgModule> enabled) {
    final without = {...enabled}..remove(m);
    final broken = <OrgModule>{};
    var current = without;
    while (true) {
      final miss = missing(current).keys.toSet();
      if (miss.isEmpty) break;
      broken.addAll(miss);
      current = current.difference(miss);
    }
    return broken;
  }

  /// v1.7 documents had coarse modules; the finer v1.8 features they
  /// implied are added so nothing a club used is switched off.
  static Set<OrgModule> expandLegacy(Set<OrgModule> s) => {
    ...s,
    if (s.contains(OrgModule.payments)) ...{
      OrgModule.paymentReceipts,
      OrgModule.paymentVerification,
      OrgModule.paymentReminders,
    },
    if (s.contains(OrgModule.brainAcademy)) OrgModule.coachChallenges,
    if (s.contains(OrgModule.communication)) OrgModule.messageAcks,
    if (s.contains(OrgModule.attendance)) OrgModule.parentRsvp,
    if (s.contains(OrgModule.roomScheduling)) OrgModule.facilities,
    if (s.contains(OrgModule.trainings) || s.contains(OrgModule.attendance)) ...{
      OrgModule.reports,
      OrgModule.dataExports,
    },
  };
}

/// Platform-side rollout of one feature for one organization.
enum RolloutState {
  enabled,
  disabled,

  /// Allowed until [FeatureRollout.until], then off again automatically.
  trial,

  /// Becomes allowed at [FeatureRollout.at].
  scheduled;

  static RolloutState fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => enabled);
}

class FeatureRollout {
  const FeatureRollout(this.state, {this.until, this.at});

  final RolloutState state;
  final DateTime? until;
  final DateTime? at;

  bool allows(DateTime now) => switch (state) {
    RolloutState.enabled => true,
    RolloutState.disabled => false,
    RolloutState.trial => until == null || now.isBefore(until!),
    RolloutState.scheduled => at != null && !now.isBefore(at!),
  };

  Map<String, dynamic> toMap() => {'state': state.name, 'until': until, 'at': at};

  factory FeatureRollout.fromMap(Object? m) {
    final map = m is Map ? m : const {};
    return FeatureRollout(
      RolloutState.fromName(map['state'] as String?),
      until: readDateOrNull(map['until']),
      at: readDateOrNull(map['at']),
    );
  }
}

// ──────────────────────────────────────────── packages & subscriptions

class PackageLimits {
  const PackageLimits({
    required this.maxCoaches,
    required this.maxStudents,
    required this.maxGroups,
    required this.maxRooms,
    this.storageMb = 1024,
    this.mediaUploadMb = 50,
    this.notificationsPerMonth = 5000,
    this.smsPerMonth = 0,
  });

  final int maxCoaches;
  final int maxStudents;
  final int maxGroups;
  final int maxRooms;
  final int storageMb;
  final int mediaUploadMb;
  final int notificationsPerMonth;

  /// Optional SMS quota; 0 = SMS not included.
  final int smsPerMonth;

  OrgLimits get orgLimits =>
      OrgLimits(maxStudents: maxStudents, maxCoaches: maxCoaches, maxRooms: maxRooms, maxGroups: maxGroups);

  Map<String, dynamic> toMap() => {
    'maxCoaches': maxCoaches,
    'maxStudents': maxStudents,
    'maxGroups': maxGroups,
    'maxRooms': maxRooms,
    'storageMb': storageMb,
    'mediaUploadMb': mediaUploadMb,
    'notificationsPerMonth': notificationsPerMonth,
    'smsPerMonth': smsPerMonth,
  };

  factory PackageLimits.fromMap(Object? m) {
    final map = m is Map ? m : const {};
    int v(String k, int d) => (map[k] as num?)?.toInt() ?? d;
    return PackageLimits(
      maxCoaches: v('maxCoaches', 30),
      maxStudents: v('maxStudents', 300),
      maxGroups: v('maxGroups', 40),
      maxRooms: v('maxRooms', 5),
      storageMb: v('storageMb', 1024),
      mediaUploadMb: v('mediaUploadMb', 50),
      notificationsPerMonth: v('notificationsPerMonth', 5000),
      smsPerMonth: v('smsPerMonth', 0),
    );
  }

  static List<String> validate(PackageLimits l) => [
    if (l.maxCoaches < 1 || l.maxStudents < 1 || l.maxGroups < 1 || l.maxRooms < 0) 'limitRange',
    if (l.storageMb < 0 || l.mediaUploadMb < 1 || l.notificationsPerMonth < 0 || l.smsPerMonth < 0) 'limitRange',
  ];
}

/// Price is configuration, never hardcoded in logic. Amount in minor units.
class PackagePrice {
  const PackagePrice({this.amountMinor = 0, this.currency = 'GEL', this.period = 'month'});

  final int amountMinor;
  final String currency;
  final String period;

  Map<String, dynamic> toMap() => {'amountMinor': amountMinor, 'currency': currency, 'period': period};

  factory PackagePrice.fromMap(Object? m) {
    final map = m is Map ? m : const {};
    return PackagePrice(
      amountMinor: (map['amountMinor'] as num?)?.toInt() ?? 0,
      currency: map['currency'] as String? ?? 'GEL',
      period: map['period'] as String? ?? 'month',
    );
  }
}

/// A SaaS package sold by the platform to organizations (NOT parent tuition).
class SubscriptionPackage {
  const SubscriptionPackage({
    required this.id,
    required this.names,
    required this.modules,
    required this.limits,
    this.price = const PackagePrice(),
    this.durationDays = 365,
    this.custom = false,
    this.archived = false,
  });

  final String id;
  final Map<String, String> names;
  final Set<OrgModule> modules;
  final PackageLimits limits;
  final PackagePrice price;
  final int durationDays;

  /// Negotiated plan: modules are whatever the platform admin grants.
  final bool custom;
  final bool archived;

  bool includes(OrgModule m) => custom || modules.contains(m);
  String nameFor(String locale) => names[locale] ?? names['en'] ?? id;

  static const starterId = 'starter';
  static const professionalId = 'professional';
  static const enterpriseId = 'enterprise';
  static const customId = 'custom';

  static final builtIns = <SubscriptionPackage>[
    SubscriptionPackage(
      id: starterId,
      names: const {'ka': 'საწყისი', 'en': 'Starter', 'ru': 'Стартовый'},
      modules: OrgPlan.free.defaultModules,
      limits: const PackageLimits(maxCoaches: 5, maxStudents: 50, maxGroups: 5, maxRooms: 1, storageMb: 512),
    ),
    SubscriptionPackage(
      id: professionalId,
      names: const {'ka': 'პროფესიონალური', 'en': 'Professional', 'ru': 'Профессиональный'},
      modules: {...OrgPlan.standard.defaultModules, OrgModule.facilities, OrgModule.roomScheduling},
      limits: const PackageLimits(
        maxCoaches: 30,
        maxStudents: 300,
        maxGroups: 40,
        maxRooms: 5,
        storageMb: 10240,
        notificationsPerMonth: 20000,
      ),
    ),
    SubscriptionPackage(
      id: enterpriseId,
      names: const {'ka': 'კორპორაციული', 'en': 'Enterprise', 'ru': 'Корпоративный'},
      modules: OrgModule.values.toSet(),
      limits: const PackageLimits(
        maxCoaches: 200,
        maxStudents: 2000,
        maxGroups: 300,
        maxRooms: 30,
        storageMb: 102400,
        mediaUploadMb: 200,
        notificationsPerMonth: 200000,
        smsPerMonth: 2000,
      ),
    ),
    SubscriptionPackage(
      id: customId,
      names: const {'ka': 'ინდივიდუალური', 'en': 'Custom', 'ru': 'Индивидуальный'},
      modules: OrgModule.values.toSet(),
      limits: const PackageLimits(maxCoaches: 50, maxStudents: 500, maxGroups: 60, maxRooms: 10),
      custom: true,
    ),
  ];

  static String fromLegacyPlan(OrgPlan p) => switch (p) {
    OrgPlan.free => starterId,
    OrgPlan.standard => professionalId,
    OrgPlan.premium => enterpriseId,
  };

  Map<String, dynamic> toMap() => {
    'names': names,
    'modules': [for (final m in modules) m.name],
    'limits': limits.toMap(),
    'price': price.toMap(),
    'durationDays': durationDays,
    'custom': custom,
    'archived': archived,
  };

  factory SubscriptionPackage.fromMap(String id, Map<String, dynamic> m) => SubscriptionPackage(
    id: id,
    names: {for (final e in ((m['names'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
    modules: OrgModule.readSet(m['modules']),
    limits: PackageLimits.fromMap(m['limits']),
    price: PackagePrice.fromMap(m['price']),
    durationDays: (m['durationDays'] as num?)?.toInt() ?? 365,
    custom: m['custom'] as bool? ?? false,
    archived: m['archived'] as bool? ?? false,
  );

  SubscriptionPackage copyWith({
    String? id,
    Map<String, String>? names,
    Set<OrgModule>? modules,
    PackageLimits? limits,
    PackagePrice? price,
    int? durationDays,
    bool? custom,
    bool? archived,
  }) => SubscriptionPackage(
    id: id ?? this.id,
    names: names ?? this.names,
    modules: modules ?? this.modules,
    limits: limits ?? this.limits,
    price: price ?? this.price,
    durationDays: durationDays ?? this.durationDays,
    custom: custom ?? this.custom,
    archived: archived ?? this.archived,
  );
}

enum SubscriptionStatus {
  trial,
  active,
  pastDue,
  suspended,
  cancelled,
  expired;

  static SubscriptionStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => active);
}

/// Effective access derived from the subscription. Data is never deleted:
/// read-only keeps everything readable but switches every module off for
/// new writes.
enum AccessMode { full, readOnly }

class SubscriptionInfo {
  const SubscriptionInfo({
    this.status = SubscriptionStatus.active,
    this.startAt,
    this.endAt,
    this.graceDays = 14,
    this.note,
  });

  final SubscriptionStatus status;
  final DateTime? startAt;

  /// End of the paid / trial period (null = open-ended).
  final DateTime? endAt;

  /// Days after [endAt] (or after falling past due) with full access.
  final int graceDays;
  final String? note;

  bool _beforeGraceEnd(DateTime now) => endAt == null || now.isBefore(endAt!.add(Duration(days: graceDays)));

  /// Explicit policy per status:
  /// * trial / active — full until the end date, then the grace period;
  /// * pastDue — full during the grace period, then read-only;
  /// * suspended / cancelled / expired — read-only (data kept).
  AccessMode accessAt(DateTime now) => switch (status) {
    SubscriptionStatus.trial ||
    SubscriptionStatus.active ||
    SubscriptionStatus.pastDue => _beforeGraceEnd(now) ? AccessMode.full : AccessMode.readOnly,
    SubscriptionStatus.suspended || SubscriptionStatus.cancelled || SubscriptionStatus.expired => AccessMode.readOnly,
  };

  bool inGrace(DateTime now) => endAt != null && now.isAfter(endAt!) && _beforeGraceEnd(now);

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'startAt': startAt,
    'endAt': endAt,
    'graceDays': graceDays,
    'note': note,
  };

  factory SubscriptionInfo.fromMap(Object? m) {
    if (m is! Map) return const SubscriptionInfo();
    return SubscriptionInfo(
      status: SubscriptionStatus.fromName(m['status'] as String?),
      startAt: readDateOrNull(m['startAt']),
      endAt: readDateOrNull(m['endAt']),
      graceDays: ((m['graceDays'] as num?)?.toInt() ?? 14).clamp(0, 90),
      note: m['note'] as String?,
    );
  }

  SubscriptionInfo copyWith({
    SubscriptionStatus? status,
    DateTime? startAt,
    DateTime? endAt,
    int? graceDays,
    String? note,
  }) => SubscriptionInfo(
    status: status ?? this.status,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    graceDays: graceDays ?? this.graceDays,
    note: note ?? this.note,
  );
}

// ─────────────────────────────────────── organization profile & settings

enum OrgType {
  sportsSchool,
  club,
  academy,
  independentCoach,
  other;

  static OrgType fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => club);
}

/// Funding is descriptive; it never overrides the authorized features.
enum FundingType {
  government,
  private,
  nonprofit,
  mixed,
  other;

  static FundingType fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => private);
}

class OrgProfile {
  const OrgProfile({
    this.legalName = '',
    this.type = OrgType.club,
    this.funding = FundingType.private,
    this.registrationId,
    this.city = '',
  });

  final String legalName;
  final OrgType type;
  final FundingType funding;
  final String? registrationId;
  final String city;

  Map<String, dynamic> toMap() => {
    'legalName': legalName,
    'type': type.name,
    'funding': funding.name,
    'registrationId': registrationId,
    'city': city,
  };

  factory OrgProfile.fromMap(Object? m) {
    if (m is! Map) return const OrgProfile();
    return OrgProfile(
      legalName: m['legalName'] as String? ?? '',
      type: OrgType.fromName(m['type'] as String?),
      funding: FundingType.fromName(m['funding'] as String?),
      registrationId: m['registrationId'] as String?,
      city: m['city'] as String? ?? '',
    );
  }
}

/// Level-2 organization settings for permitted modules.
class OrgSettings {
  const OrgSettings({this.coachesCanBookRooms = false, this.coachesCanExport = true});

  /// Coaches may reserve rooms for their own groups (still conflict-checked).
  final bool coachesCanBookRooms;
  final bool coachesCanExport;

  Map<String, dynamic> toMap() => {'coachesCanBookRooms': coachesCanBookRooms, 'coachesCanExport': coachesCanExport};

  factory OrgSettings.fromMap(Object? m) {
    if (m is! Map) return const OrgSettings();
    return OrgSettings(
      coachesCanBookRooms: m['coachesCanBookRooms'] as bool? ?? false,
      coachesCanExport: m['coachesCanExport'] as bool? ?? true,
    );
  }

  OrgSettings copyWith({bool? coachesCanBookRooms, bool? coachesCanExport}) => OrgSettings(
    coachesCanBookRooms: coachesCanBookRooms ?? this.coachesCanBookRooms,
    coachesCanExport: coachesCanExport ?? this.coachesCanExport,
  );
}

/// Provisioning is two-phase: an organization is not usable until every
/// part of it (club, config, membership, invitation) exists.
enum ProvisioningState {
  ready,
  provisioning,
  failed;

  static ProvisioningState fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => ready);
}

/// Thrown when an edit was based on an older configuration version.
class ConfigConflictException implements Exception {
  const ConfigConflictException(this.currentVersion);

  final int currentVersion;

  @override
  String toString() => 'ConfigConflictException(current=$currentVersion)';
}

/// One audited configuration change (`orgConfigs/{id}/history/{version}`).
class ConfigHistoryEntry {
  const ConfigHistoryEntry({
    required this.orgId,
    required this.version,
    required this.at,
    required this.by,
    required this.reason,
    required this.changes,
  });

  final String orgId;
  final int version;
  final DateTime at;
  final String by;
  final String reason;

  /// Human-readable change keys, e.g. `+payments`, `-media`, `package:starter→professional`.
  final List<String> changes;
}

// ──────────────────────────────────────────────────────────── templates

class OrgTemplate {
  const OrgTemplate({
    required this.id,
    required this.names,
    required this.modules,
    this.description = const {},
    this.type = OrgType.club,
    this.funding = FundingType.private,
    this.packageId = SubscriptionPackage.professionalId,
    this.settings = const OrgSettings(),
    this.bookingBufferMin = 0,
    this.builtIn = false,
    this.archived = false,
  });

  final String id;
  final Map<String, String> names;
  final Map<String, String> description;
  final Set<OrgModule> modules;
  final OrgType type;
  final FundingType funding;
  final String packageId;
  final OrgSettings settings;
  final int bookingBufferMin;
  final bool builtIn;
  final bool archived;

  String nameFor(String locale) => names[locale] ?? names['en'] ?? id;

  static const government = 'tpl-government-school';
  static const privateClub = 'tpl-private-club';
  static const childrenAcademy = 'tpl-children-academy';
  static const independentCoach = 'tpl-independent-coach';

  static const builtIns = <OrgTemplate>[
    OrgTemplate(
      id: government,
      builtIn: true,
      names: {'ka': 'სახელმწიფო სპორტსკოლა', 'en': 'Government Sports School', 'ru': 'Государственная спортшкола'},
      type: OrgType.sportsSchool,
      funding: FundingType.government,
      packageId: SubscriptionPackage.enterpriseId,
      settings: OrgSettings(coachesCanBookRooms: false),
      bookingBufferMin: 10,
      modules: {
        OrgModule.trainings,
        OrgModule.matches,
        OrgModule.attendance,
        OrgModule.parentRsvp,
        OrgModule.communication,
        OrgModule.messageAcks,
        OrgModule.notifications,
        OrgModule.studentAccounts,
        OrgModule.brainAcademy,
        OrgModule.coachChallenges,
        OrgModule.facilities,
        OrgModule.roomScheduling,
        OrgModule.medicalCertificates,
        OrgModule.reports,
        OrgModule.dataExports,
      },
    ),
    OrgTemplate(
      id: privateClub,
      builtIn: true,
      names: {'ka': 'კერძო სპორტული კლუბი', 'en': 'Private Sports Club', 'ru': 'Частный спортклуб'},
      funding: FundingType.private,
      modules: {
        OrgModule.trainings,
        OrgModule.matches,
        OrgModule.attendance,
        OrgModule.parentRsvp,
        OrgModule.communication,
        OrgModule.messageAcks,
        OrgModule.notifications,
        OrgModule.payments,
        OrgModule.paymentReceipts,
        OrgModule.paymentVerification,
        OrgModule.paymentReminders,
        OrgModule.media,
        OrgModule.medicalCertificates,
        OrgModule.reports,
        OrgModule.dataExports,
      },
    ),
    OrgTemplate(
      id: childrenAcademy,
      builtIn: true,
      names: {
        'ka': 'საბავშვო სპორტული აკადემია',
        'en': "Children's Sports Academy",
        'ru': 'Детская спортивная академия',
      },
      type: OrgType.academy,
      modules: {
        OrgModule.trainings,
        OrgModule.attendance,
        OrgModule.parentRsvp,
        OrgModule.communication,
        OrgModule.messageAcks,
        OrgModule.notifications,
        OrgModule.brainAcademy,
        OrgModule.coachChallenges,
        OrgModule.trainingPlans,
        OrgModule.reports,
      },
    ),
    OrgTemplate(
      id: independentCoach,
      builtIn: true,
      names: {'ka': 'დამოუკიდებელი მწვრთნელი', 'en': 'Independent Coach', 'ru': 'Независимый тренер'},
      type: OrgType.independentCoach,
      packageId: SubscriptionPackage.starterId,
      modules: {
        OrgModule.trainings,
        OrgModule.attendance,
        OrgModule.parentRsvp,
        OrgModule.communication,
        OrgModule.notifications,
      },
    ),
  ];

  Map<String, dynamic> toMap() => {
    'names': names,
    'description': description,
    'modules': [for (final m in modules) m.name],
    'type': type.name,
    'funding': funding.name,
    'packageId': packageId,
    'settings': settings.toMap(),
    'bookingBufferMin': bookingBufferMin,
    'builtIn': builtIn,
    'archived': archived,
  };

  factory OrgTemplate.fromMap(String id, Map<String, dynamic> m) => OrgTemplate(
    id: id,
    names: {for (final e in ((m['names'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
    description: {for (final e in ((m['description'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
    modules: OrgModule.readSet(m['modules']),
    type: OrgType.fromName(m['type'] as String?),
    funding: FundingType.fromName(m['funding'] as String?),
    packageId: m['packageId'] as String? ?? SubscriptionPackage.professionalId,
    settings: OrgSettings.fromMap(m['settings']),
    bookingBufferMin: (m['bookingBufferMin'] as num?)?.toInt() ?? 0,
    builtIn: m['builtIn'] as bool? ?? false,
    archived: m['archived'] as bool? ?? false,
  );

  OrgTemplate copyWith({
    String? id,
    Map<String, String>? names,
    Set<OrgModule>? modules,
    OrgType? type,
    FundingType? funding,
    String? packageId,
    OrgSettings? settings,
    int? bookingBufferMin,
    bool? builtIn,
    bool? archived,
  }) => OrgTemplate(
    id: id ?? this.id,
    names: names ?? this.names,
    description: description,
    modules: modules ?? this.modules,
    type: type ?? this.type,
    funding: funding ?? this.funding,
    packageId: packageId ?? this.packageId,
    settings: settings ?? this.settings,
    bookingBufferMin: bookingBufferMin ?? this.bookingBufferMin,
    builtIn: builtIn ?? this.builtIn,
    archived: archived ?? this.archived,
  );

  static List<String> validate(OrgTemplate t) => [
    if (t.names.values.every((n) => n.trim().length < 2)) 'templateName',
    if (!FeatureCatalog.isValid(t.modules)) 'featureDependencies',
  ];
}

/// One proposed change when a template is applied to an EXISTING
/// organization (shown as a preview; nothing is overwritten silently).
class TemplateChange {
  const TemplateChange(this.key, {this.from, this.to});

  /// `module:<id>`, `package`, `bookingBufferMin`, `coachesCanBookRooms`, `funding`, `type`.
  final String key;
  final String? from;
  final String? to;

  @override
  String toString() => '$key: $from → $to';
}

class TemplateDiff {
  TemplateDiff._();

  static List<TemplateChange> compute(OrgConfig cfg, OrgTemplate t) {
    final out = <TemplateChange>[];
    for (final m in OrgModule.values) {
      final now = cfg.enabledModules.contains(m), next = t.modules.contains(m);
      if (now != next) out.add(TemplateChange('module:${m.name}', from: '$now', to: '$next'));
    }
    if (cfg.packageId != t.packageId) out.add(TemplateChange('package', from: cfg.packageId, to: t.packageId));
    if (cfg.bookingBufferMin != t.bookingBufferMin) {
      out.add(TemplateChange('bookingBufferMin', from: '${cfg.bookingBufferMin}', to: '${t.bookingBufferMin}'));
    }
    if (cfg.settings.coachesCanBookRooms != t.settings.coachesCanBookRooms) {
      out.add(
        TemplateChange(
          'coachesCanBookRooms',
          from: '${cfg.settings.coachesCanBookRooms}',
          to: '${t.settings.coachesCanBookRooms}',
        ),
      );
    }
    if (cfg.profile.funding != t.funding)
      out.add(TemplateChange('funding', from: cfg.profile.funding.name, to: t.funding.name));
    if (cfg.profile.type != t.type) out.add(TemplateChange('type', from: cfg.profile.type.name, to: t.type.name));
    return out;
  }
}

// ─────────────────────────────────────────────────────────── invitations

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  revoked,
  expired;

  static InvitationStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => pending);
}

/// `orgInvitations/{id}`. Only a hash of the token is stored; the link
/// carries the token once and never a password or permanent credential.
class OrgInvitation {
  const OrgInvitation({
    required this.id,
    required this.orgId,
    required this.tokenHash,
    required this.expiresAt,
    required this.invitedBy,
    required this.createdAt,
    this.phone,
    this.email,
    this.status = InvitationStatus.pending,
    this.acceptedBy,
    this.transferFrom,
    this.resendCount = 0,
  });

  static const validity = Duration(days: 7);

  final String id;
  final String orgId;
  final String tokenHash;
  final DateTime expiresAt;
  final String invitedBy;
  final DateTime createdAt;
  final String? phone;
  final String? email;
  final InvitationStatus status;
  final String? acceptedBy;

  /// Admin who hands over the role when this invitation is accepted.
  final String? transferFrom;
  final int resendCount;

  InvitationStatus statusAt(DateTime now) =>
      status == InvitationStatus.pending && !now.isBefore(expiresAt) ? InvitationStatus.expired : status;

  Map<String, dynamic> toMap() => {
    'orgId': orgId,
    'tokenHash': tokenHash,
    'expiresAt': expiresAt,
    'invitedBy': invitedBy,
    'createdAt': createdAt,
    'phone': phone,
    'email': email,
    'status': status.name,
    'acceptedBy': acceptedBy,
    'transferFrom': transferFrom,
    'resendCount': resendCount,
  };

  factory OrgInvitation.fromMap(String id, Map<String, dynamic> m) => OrgInvitation(
    id: id,
    orgId: m['orgId'] as String? ?? '',
    tokenHash: m['tokenHash'] as String? ?? '',
    expiresAt: readDate(m['expiresAt']),
    invitedBy: m['invitedBy'] as String? ?? '',
    createdAt: readDate(m['createdAt']),
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    status: InvitationStatus.fromName(m['status'] as String?),
    acceptedBy: m['acceptedBy'] as String?,
    transferFrom: m['transferFrom'] as String?,
    resendCount: (m['resendCount'] as num?)?.toInt() ?? 0,
  );

  OrgInvitation copyWith({
    String? tokenHash,
    DateTime? expiresAt,
    InvitationStatus? status,
    String? acceptedBy,
    int? resendCount,
  }) => OrgInvitation(
    id: id,
    orgId: orgId,
    tokenHash: tokenHash ?? this.tokenHash,
    expiresAt: expiresAt ?? this.expiresAt,
    invitedBy: invitedBy,
    createdAt: createdAt,
    phone: phone,
    email: email,
    status: status ?? this.status,
    acceptedBy: acceptedBy ?? this.acceptedBy,
    transferFrom: transferFrom,
    resendCount: resendCount ?? this.resendCount,
  );
}

/// Invitation tokens: 32 random bytes (hex); only the hash is stored.
class InvitationTokens {
  InvitationTokens._();

  static String generate([math.Random? rnd]) {
    final r = rnd ?? math.Random.secure();
    return List.generate(32, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// FNV-1a 64-bit in the demo backend; the Cloud Function stores SHA-256.
  static String hash(String token) {
    var h = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = (BigInt.one << 64) - BigInt.one;
    for (final c in token.codeUnits) {
      h = ((h ^ BigInt.from(c)) * prime) & mask;
    }
    return h.toRadixString(16).padLeft(16, '0');
  }
}

// ─────────────────────────────────────────────── level-3 permissions

/// Individual operations. Each is tied to a feature (level 1/2) and a role
/// policy (level 3); resource checks (own group, own child…) stay in
/// AccessPolicy / the backend.
enum OrgPermission {
  manageOrgSettings(null),
  manageBranding(null),
  manageMembers(null),
  manageGroups(null),
  managePrograms(null),
  manageRooms(OrgModule.facilities),
  bookRooms(OrgModule.roomScheduling),
  viewRoomSchedule(OrgModule.roomScheduling),
  manageSchedule(OrgModule.trainings),
  markAttendance(OrgModule.attendance),
  answerRsvp(OrgModule.parentRsvp),
  sendMessages(OrgModule.communication),
  requestAcknowledgment(OrgModule.messageAcks),
  publishMedia(OrgModule.media),
  managePlans(OrgModule.trainingPlans),
  assignChallenges(OrgModule.coachChallenges),
  managePayments(OrgModule.payments),
  uploadReceipts(OrgModule.paymentReceipts),
  verifyPayments(OrgModule.paymentVerification),
  runPaymentReminders(OrgModule.paymentReminders),
  uploadCertificates(OrgModule.medicalCertificates),
  viewReports(OrgModule.reports),
  exportData(OrgModule.dataExports),
  configureLeaderboard(OrgModule.leaderboards);

  const OrgPermission(this.module);

  final OrgModule? module;
}

class PermissionPolicy {
  PermissionPolicy._();

  static const _admin = {
    OrgPermission.manageOrgSettings,
    OrgPermission.manageBranding,
    OrgPermission.manageMembers,
    OrgPermission.manageGroups,
    OrgPermission.managePrograms,
    OrgPermission.manageRooms,
    OrgPermission.bookRooms,
    OrgPermission.viewRoomSchedule,
    OrgPermission.viewReports,
    OrgPermission.exportData,
    OrgPermission.managePayments,
    OrgPermission.verifyPayments,
    OrgPermission.runPaymentReminders,
    OrgPermission.configureLeaderboard,
  };

  static const _coach = {
    OrgPermission.manageSchedule,
    OrgPermission.markAttendance,
    OrgPermission.viewRoomSchedule,
    OrgPermission.sendMessages,
    OrgPermission.requestAcknowledgment,
    OrgPermission.publishMedia,
    OrgPermission.managePlans,
    OrgPermission.assignChallenges,
    OrgPermission.managePayments,
    OrgPermission.verifyPayments,
    OrgPermission.runPaymentReminders,
    OrgPermission.exportData,
    OrgPermission.manageGroups,
  };

  static const _parent = {
    OrgPermission.answerRsvp,
    OrgPermission.sendMessages,
    OrgPermission.uploadReceipts,
    OrgPermission.uploadCertificates,
  };

  /// Role policy, refined by organization settings (level 2).
  static Set<OrgPermission> forRoles(Set<OrgRole> roles, OrgSettings s) => {
    if (roles.contains(OrgRole.admin)) ..._admin,
    if (roles.contains(OrgRole.coach)) ...{
      ..._coach.where((p) => p != OrgPermission.exportData || s.coachesCanExport),
      if (s.coachesCanBookRooms) OrgPermission.bookRooms,
    },
    if (roles.contains(OrgRole.parent)) ..._parent,
  };
}

/// Why a feature or permission is unavailable (shown to admins).
enum EntitlementBlock {
  orgInactive,
  provisioning,
  readOnly,
  notInPackage,
  notEntitled,
  rolloutOff,
  disabledByOrg,
  dependencyMissing,
}

/// The single resolver used by UI, demo backend and (mirrored) Cloud
/// Functions: level 1 (platform entitlement, package, rollout,
/// subscription) × level 2 (organization switch) × level 3 (role).
class EntitlementResolver {
  EntitlementResolver._();

  static EntitlementBlock? blockOf(OrgConfig c, OrgModule m, DateTime now, {SubscriptionPackage? package}) {
    if (!c.isActive) return EntitlementBlock.orgInactive;
    if (c.provisioning != ProvisioningState.ready) return EntitlementBlock.provisioning;
    if (c.subscription.accessAt(now) == AccessMode.readOnly) return EntitlementBlock.readOnly;
    if (package != null && !package.includes(m) && c.allowedModules.contains(m)) return EntitlementBlock.notInPackage;
    if (!c.allowedModules.contains(m)) return EntitlementBlock.notEntitled;
    if (!(c.rollout[m]?.allows(now) ?? true)) return EntitlementBlock.rolloutOff;
    if (!c.enabledModules.contains(m)) return EntitlementBlock.disabledByOrg;
    for (final group in FeatureCatalog.of(m).requires) {
      if (!group.any((d) => c.isEnabled(d, now: now))) return EntitlementBlock.dependencyMissing;
    }
    return null;
  }

  static Set<OrgModule> effectiveModules(OrgConfig c, DateTime now, {SubscriptionPackage? package}) => {
    for (final m in OrgModule.values)
      if (blockOf(c, m, now, package: package) == null) m,
  };

  static bool can(OrgConfig c, Set<OrgRole> roles, OrgPermission p, DateTime now) =>
      PermissionPolicy.forRoles(roles, c.settings).contains(p) &&
      (p.module == null || c.isEnabled(p.module!, now: now)) &&
      c.isActive &&
      c.subscription.accessAt(now) == AccessMode.full;
}

/// Roles of a user in an organization from their account (used when no
/// explicit membership record exists, e.g. legacy data).
Set<OrgRole> impliedRoles(AppUser u, String orgId) => {
  if (u.administersClub(orgId)) OrgRole.admin,
  if (u.isCoach) OrgRole.coach,
  if (u.isParent) OrgRole.parent,
  if (u.isStudent) OrgRole.student,
};

// ────────────────────────────────────────────────────── branding helpers

class BrandContrast {
  BrandContrast._();

  static double _lum(int argb) {
    double ch(int v) {
      final c = v / 255;
      return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * ch((argb >> 16) & 0xff) + 0.7152 * ch((argb >> 8) & 0xff) + 0.0722 * ch(argb & 0xff);
  }

  /// WCAG contrast ratio (1–21).
  static double ratio(int a, int b) {
    final la = _lum(a), lb = _lum(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Text colour (white or near-black) that is readable on [background].
  static int onColor(int background) => ratio(background, 0xFFFFFFFF) >= 4.5 ? 0xFFFFFFFF : 0xFF0F172A;

  /// Brand colours must keep white text readable (WCAG AA, 4.5:1).
  static bool acceptable(int primary) => ratio(primary, 0xFFFFFFFF) >= 4.5;
}

// ────────────────────────────────────────────────────── platform overview

class PlatformStats {
  const PlatformStats({
    required this.organizations,
    required this.active,
    required this.suspended,
    required this.trial,
    required this.users,
    required this.coaches,
    required this.students,
    required this.parents,
    required this.adoption,
    required this.bySubscription,
    required this.alerts,
    this.synthetic = false,
  });

  final int organizations;
  final int active;
  final int suspended;
  final int trial;
  final int users;
  final int coaches;
  final int students;
  final int parents;

  /// Organizations with each feature effectively on.
  final Map<OrgModule, int> adoption;
  final Map<SubscriptionStatus, int> bySubscription;
  final List<PlatformAlert> alerts;

  /// Demo numbers are labelled as synthetic in the UI.
  final bool synthetic;
}

enum AlertKind { overLimit, trialEnding, pastDue, readOnly, provisioningStuck, invitationExpiring }

class PlatformAlert {
  const PlatformAlert(this.kind, this.orgId, {this.detail = ''});

  final AlertKind kind;
  final String orgId;
  final String detail;
}

class OrgUsage {
  const OrgUsage({
    required this.coaches,
    required this.students,
    required this.groups,
    required this.rooms,
    required this.storageMb,
    required this.notificationsThisMonth,
    required this.smsThisMonth,
  });

  final int coaches;
  final int students;
  final int groups;
  final int rooms;
  final int storageMb;
  final int notificationsThisMonth;
  final int smsThisMonth;

  List<String> exceeded(PackageLimits l) => [
    if (coaches > l.maxCoaches) 'coaches',
    if (students > l.maxStudents) 'students',
    if (groups > l.maxGroups) 'groups',
    if (rooms > l.maxRooms) 'rooms',
    if (storageMb > l.storageMb) 'storage',
    if (notificationsThisMonth > l.notificationsPerMonth) 'notifications',
    if (smsThisMonth > l.smsPerMonth && l.smsPerMonth > 0) 'sms',
  ];
}
