import '../../../core/utils/dates.dart';

/// Inbox categories (v1.2 notification center).
enum NotificationCategory { trainings, matches, invitations, attendance, payments, chat, certificates, announcements }

/// Push/in-app notification types (spec §9, payments §14.5, v1.1, v1.2).
enum NotificationType {
  newTraining,
  trainingChanged,
  trainingReminder,
  chatMessage,
  certificateExpiry,
  newPhotos,
  paymentReminder,
  paymentSms,
  newMatch,
  matchChanged,
  matchReminder,
  groupInvite,
  inviteAnswered,
  attendanceRecorded,
  feedbackAdded,
  announcement,
  newMedia,
  scheduleChanged,
  paymentProofSubmitted,
  paymentProofApproved,
  paymentProofRejected,
  trainingPlanPublished,

  /// v1.4: a coach message asks the parent to confirm they read it.
  ackRequested,

  /// v1.5: final match score published.
  matchResult,

  /// v1.5: a message in a child-context parent↔coach conversation.
  childMessage;

  static NotificationType fromName(String name) =>
      NotificationType.values.firstWhere((t) => t.name == name, orElse: () => NotificationType.newTraining);

  NotificationCategory get category => switch (this) {
    newTraining ||
    trainingChanged ||
    trainingReminder ||
    scheduleChanged ||
    trainingPlanPublished => NotificationCategory.trainings,
    newMatch || matchChanged || matchReminder || matchResult => NotificationCategory.matches,
    groupInvite || inviteAnswered => NotificationCategory.invitations,
    attendanceRecorded || feedbackAdded => NotificationCategory.attendance,
    paymentReminder ||
    paymentSms ||
    paymentProofSubmitted ||
    paymentProofApproved ||
    paymentProofRejected => NotificationCategory.payments,
    chatMessage || childMessage => NotificationCategory.chat,
    certificateExpiry => NotificationCategory.certificates,
    announcement || newPhotos || newMedia || ackRequested => NotificationCategory.announcements,
  };
}

/// Per-user opt-outs. Unknown keys default to enabled.
class NotificationPreferences {
  const NotificationPreferences([this._values = const {}]);

  final Map<NotificationType, bool> _values;

  bool isEnabled(NotificationType type) => _values[type] ?? true;

  NotificationPreferences toggle(NotificationType type, bool enabled) =>
      NotificationPreferences({..._values, type: enabled});

  bool isCategoryEnabled(NotificationCategory c) =>
      NotificationType.values.where((t) => t.category == c).any(isEnabled);

  NotificationPreferences toggleCategory(NotificationCategory c, bool enabled) => NotificationPreferences({
    ..._values,
    for (final t in NotificationType.values)
      if (t.category == c) t: enabled,
  });

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
    this.childId,
    this.groupId,
    this.dedupeKey,
  });

  final String id;
  final String userId;
  final NotificationType type;

  /// Context the deep link opens with (child / sport / group switch).
  final String? childId;
  final String? groupId;

  /// Server-side idempotency key; the doc id is derived from it.
  final String? dedupeKey;

  NotificationCategory get category => type.category;

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
    childId: childId,
    groupId: groupId,
    dedupeKey: dedupeKey,
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
    'category': category.name,
    'childId': childId,
    'groupId': groupId,
    'dedupeKey': dedupeKey,
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
    childId: m['childId'] as String?,
    groupId: m['groupId'] as String?,
    dedupeKey: m['dedupeKey'] as String?,
  );
}
