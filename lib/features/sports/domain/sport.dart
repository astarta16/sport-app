class Sport {
  const Sport({required this.id, required this.name, required this.icon});

  final String id;
  final String name;

  /// Icon key resolved by the presentation layer (see `SportVisuals`).
  final String icon;

  Map<String, dynamic> toMap() => {'name': name, 'icon': icon};

  factory Sport.fromMap(String id, Map<String, dynamic> m) =>
      Sport(id: id, name: m['name'] as String? ?? id, icon: m['icon'] as String? ?? 'generic');
}
