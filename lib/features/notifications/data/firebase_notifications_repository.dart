import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/notification_models.dart';
import '../domain/notifications_repository.dart';

/// Persisted inbox at `notifications/{id}` (written by Cloud Functions with
/// a dedupe-derived id; rules let the owner read and flip `read` only) plus
/// FCM device registration.
class FirebaseNotificationsRepository implements NotificationsRepository {
  FirebaseNotificationsRepository(this.auth, this.db, this.messaging);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseMessaging messaging;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('notifications');

  @override
  Stream<List<AppNotification>> watchInbox({int limit = 30, NotificationCategory? category}) {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    var q = _col.where('userId', isEqualTo: uid);
    if (category != null) q = q.where('category', isEqualTo: category.name);
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList())
        .mapFirebaseErrors();
  }

  @override
  Stream<int> watchUnreadCount() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return _col
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((s) => s.size)
        .mapFirebaseErrors();
  }

  @override
  Future<void> markRead(String id) => guardFirebase(() => _col.doc(id).update({'read': true}));

  @override
  Future<void> markAllRead() => guardFirebase(() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final unread = await _col.where('userId', isEqualTo: uid).where('read', isEqualTo: false).limit(400).get();
    final batch = db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  });

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
}
