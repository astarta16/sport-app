import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/notification_models.dart';
import '../domain/notifications_repository.dart';

/// FCM integration. Push fan-out and recipient selection happen server-side
/// (Cloud Functions). Messages received while the app runs are kept in a
/// session inbox; a persisted inbox collection is a documented follow-up.
class FirebaseNotificationsRepository implements NotificationsRepository {
  FirebaseNotificationsRepository(this.auth, this.db, this.messaging) {
    _sub = FirebaseMessaging.onMessage.listen(_add);
    FirebaseMessaging.onMessageOpenedApp.listen(_add);
  }

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseMessaging messaging;
  final _items = <AppNotification>[];
  final _controller = StreamController<List<AppNotification>>.broadcast();
  StreamSubscription<RemoteMessage>? _sub;

  void _add(RemoteMessage m) {
    final type = NotificationType.fromName(m.data['type'] as String? ?? '');
    _items.insert(
      0,
      AppNotification(
        id: m.messageId ?? '${DateTime.now().microsecondsSinceEpoch}',
        userId: auth.currentUser?.uid ?? '',
        type: type,
        title: m.notification?.title ?? '',
        body: m.notification?.body ?? '',
        createdAt: m.sentTime ?? DateTime.now(),
        route: m.data['route'] as String?,
      ),
    );
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<AppNotification>> watchInbox() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0) _items[i] = _items[i].copyWith(read: true);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    _controller.add(List.unmodifiable(_items));
  }

  /// Requests permission and stores the FCM token on `users/{uid}.fcmTokens`.
  @override
  Future<void> registerDevice() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    // The Cloud Functions send to FCM registration tokens (admin SDK
    // multicast), so the token API is used deliberately over the newer
    // FID-based register()/onRegistered direct-send flow.
    // ignore: deprecated_member_use
    final token = await messaging.getToken();
    if (token == null) return;
    await db.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
