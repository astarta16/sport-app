import '../../../core/utils/dates.dart';

/// Push/in-app notification categories (spec §9 + payments §14.5).
enum NotificationType {
  newTraining,
  trainingChanged,
  trainingReminder,
  chatMessage,
  certificateExpiry,
  newPhotos,
  paymentReminder,
  paymentSms;

  static NotificationType fromName(String name) =>
      NotificationType.values.firstWhere((t) => t.name == name, orElse: () => NotificationType.newTraining);
}

/// Per-user opt-outs. Unknown keys default to enabled.
class NotificationPreferences {
  const NotificationPreferences([this._values = const {}]);

  final Map<NotificationType, bool> _values;

  bool isEnabled(NotificationType type) => _values[type] ?? true;

  NotificationPreferences toggle(NotificationType type, bool enabled) =>
      NotificationPreferences({..._values, type: enabled});

  Map<String, bool> toMap() => {for (final t in NotificationType.values) t.name: isEnabled(t)};

  factory NotificationPreferences.fromMap(Object? map) {
    if (map is! Map) return const NotificationPreferences();
    return NotificationPreferences({
      for (final e in map.entries)
        if (e.value is bool) NotificationType.fromName(e.key.toString()): e.value as bool,
    });
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences && NotificationType.values.every((t) => other.isEnabled(t) == isEnabled(t));

  @override
  int get hashCode => Object.hashAll(NotificationType.values.map(isEnabled));
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.route,
    this.args = const {},
  });

  final String id;
  final String userId;
  final NotificationType type;

  /// Server-rendered fallback text (FCM payload). The app prefers to render
  /// localized text from [type] + [args].
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  /// In-app deep link, e.g. `/training/abc`.
  final String? route;
  final Map<String, String> args;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    userId: userId,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    route: route,
    args: args,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt,
    'read': read,
    'route': route,
    'args': args,
  };

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) => AppNotification(
    id: id,
    userId: m['userId'] as String,
    type: NotificationType.fromName(m['type'] as String),
    title: m['title'] as String? ?? '',
    body: m['body'] as String? ?? '',
    createdAt: readDate(m['createdAt']),
    read: m['read'] as bool? ?? false,
    route: m['route'] as String?,
    args: (m['args'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const {},
  );
}
