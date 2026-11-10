import 'notification_models.dart';

abstract interface class NotificationsRepository {
  Stream<List<AppNotification>> watchInbox();
  Future<void> markRead(String id);
  Future<void> markAllRead();

  /// Registers the device for push (FCM token) — no-op in demo.
  Future<void> registerDevice();
}
