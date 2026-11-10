enum SportCategory {
  team,
  combat,
  other;

  static SportCategory fromName(String? n) =>
      SportCategory.values.firstWhere((c) => c.name == n, orElse: () => SportCategory.other);
}

/// Sports catalog entry. The catalog lives in the database and is managed by
/// platform admins (v1.1 §6) — never hardcoded in widgets.
class Sport {
  const Sport({
    required this.id,
    required this.name,
    required this.icon,
    this.category = SportCategory.other,
    this.ageMin,
    bool? requiresMedicalCert,
    this.active = true,
    this.order = 100,
  }) : requiresMedicalCert = requiresMedicalCert ?? category == SportCategory.combat;

  final String id;
  final String name;

  /// Icon key resolved by the presentation layer (see `SportVisuals`).
  final String icon;
  final SportCategory category;

  /// Recommended or legally required minimum age.
  final int? ageMin;

  /// Combat sports default to true.
  final bool requiresMedicalCert;
  final bool active;
  final int order;

  Sport copyWith({
    String? name,
    String? icon,
    SportCategory? category,
    int? ageMin,
    bool clearAgeMin = false,
    bool? requiresMedicalCert,
    bool? active,
    int? order,
  }) => Sport(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    category: category ?? this.category,
    ageMin: clearAgeMin ? null : (ageMin ?? this.ageMin),
    requiresMedicalCert: requiresMedicalCert ?? this.requiresMedicalCert,
    active: active ?? this.active,
    order: order ?? this.order,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'icon': icon,
    'category': category.name,
    'ageMin': ageMin,
    'requiresMedicalCert': requiresMedicalCert,
    'active': active,
    'order': order,
  };

  factory Sport.fromMap(String id, Map<String, dynamic> m) {
    final category = SportCategory.fromName(m['category'] as String?);
    return Sport(
      id: id,
      name: m['name'] as String? ?? id,
      icon: m['icon'] as String? ?? 'generic',
      category: category,
      ageMin: (m['ageMin'] as num?)?.toInt(),
      requiresMedicalCert: m['requiresMedicalCert'] as bool? ?? category == SportCategory.combat,
      active: m['active'] as bool? ?? true,
      order: (m['order'] as num?)?.toInt() ?? 100,
    );
  }
}
