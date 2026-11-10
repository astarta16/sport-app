import '../../demo/data/demo_backend.dart';
import '../domain/notification_models.dart';
import '../domain/notifications_repository.dart';

class DemoNotificationsRepository implements NotificationsRepository {
  DemoNotificationsRepository(this.db);

  final DemoBackend db;

  /// Owner-only, like the rules on `notifications/{id}`.
  @override
  Stream<List<AppNotification>> watchInbox({int limit = 30, NotificationCategory? category}) => db.watch(() {
    final me = db.currentUser;
    if (me == null) return const <AppNotification>[];
    final list =
        db.notifications.where((n) => n.userId == me.id && (category == null || n.category == category)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(limit).toList();
  });

  @override
  Stream<int> watchUnreadCount() => db.watch(() {
    final me = db.currentUser;
    if (me == null) return 0;
    return db.notifications.where((n) => n.userId == me.id && !n.read).length;
  });

  @override
  Future<void> markRead(String id) async {
    final i = db.notifications.indexWhere((n) => n.id == id && n.userId == db.me.id);
    if (i < 0 || db.notifications[i].read) return;
    db.notifications[i] = db.notifications[i].copyWith(read: true);
    db.commit();
  }

  @override
  Future<void> markAllRead() async {
    final me = db.me;
    for (var i = 0; i < db.notifications.length; i++) {
      if (db.notifications[i].userId == me.id) db.notifications[i] = db.notifications[i].copyWith(read: true);
    }
    db.commit();
  }

  /// Demo mode never registers for real push notifications.
  @override
  Future<void> registerDevice() async {}
}
