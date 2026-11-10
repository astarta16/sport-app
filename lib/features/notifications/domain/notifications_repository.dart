import 'notification_models.dart';

abstract interface class NotificationsRepository {
  /// Newest first; [limit] grows as the user scrolls (pagination).
  Stream<List<AppNotification>> watchInbox({int limit = 30, NotificationCategory? category});
  Stream<int> watchUnreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();

  /// Registers the device for push (FCM token) — no-op in demo.
  Future<void> registerDevice();
}
