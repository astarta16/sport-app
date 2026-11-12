import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../../../core/utils/dates.dart';
import '../../trainings/domain/training.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/receipts.dart';

/// Real-time group chat at `chats/{groupId}/messages`. Rules restrict it to
/// the group's parents and approved coaches; child accounts are always denied.
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository(this.auth, this.db, this.storage);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseStorage storage;

  CollectionReference<Map<String, dynamic>> _col(String groupId) =>
      db.collection('chats').doc(groupId).collection('messages');

  @override
  Stream<List<ChatMessage>> watchMessages(String groupId, {int limit = 50}) =>
      _col(groupId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots(includeMetadataChanges: true)
          .map((s) => s.docs.reversed.map((d) => ChatMessage.fromMap(groupId, d.id, d.data())).toList())
          .mapFirebaseErrors();

  @override
  Future<void> send(
    String groupId,
    String text, {
    List<PhotoUpload> attachments = const [],
    bool announcement = false,
    bool requiresAck = false,
  }) => guardFirebase(() async {
    final uid = requireUid(auth);
    final me = (await db.collection('users').doc(uid).get()).data() ?? (throw const AuthException('not-signed-in'));
    final ref = _col(groupId).doc();
    final paths = <String>[];
    for (final a in attachments) {
      if (!a.mimeType.startsWith('image/')) throw const ValidationException('fileType');
      final path = 'chatAttachments/$groupId/${ref.id}/${a.fileName}';
      await storage.ref(path).putData(Uint8ListX.from(a.bytes), SettableMetadata(contentType: a.mimeType));
      paths.add(path);
    }
    final error = ChatValidator.validate(text, paths);
    if (error != null) throw ValidationException(error);
    await ref.set({
      'senderId': uid,
      'senderName': '${me['firstName']} ${me['lastName']}',
      'senderRole': me['role'],
      'text': text.trim(),
      if (paths.isNotEmpty) 'attachments': paths,
      'createdAt': FieldValue.serverTimestamp(),
      'type': announcement ? ChatMessageType.announcement.name : ChatMessageType.text.name,
      'pinned': announcement,
      if (requiresAck) 'requiresAck': true,
    });
    await markRead(groupId);
  });

  @override
  Future<void> setPinned(String groupId, String messageId, bool pinned) =>
      guardFirebase(() => _col(groupId).doc(messageId).update({'pinned': pinned}));

  @override
  Future<void> markRead(String groupId) => guardFirebase(() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await db.collection('chats').doc(groupId).collection('members').doc(uid).set({
      'lastReadAt': FieldValue.serverTimestamp(),
    });
  });

  /// Unread counts come from the server-maintained `userUnread/{uid}` doc
  /// (updateUnread function); last messages from one query per group.
  @override
  Stream<List<ChatSummary>> watchSummaries(List<String> groupIds) {
    final uid = auth.currentUser?.uid;
    if (uid == null || groupIds.isEmpty) return Stream.value(const []);
    final last = <String, ChatMessage?>{};
    var byGroup = <String, int>{};
    late StreamController<List<ChatSummary>> out;
    final subs = <StreamSubscription<Object?>>[];
    void emit() =>
        out.add([for (final g in groupIds) ChatSummary(groupId: g, unread: byGroup[g] ?? 0, lastMessage: last[g])]);
    out = StreamController<List<ChatSummary>>(
      onListen: () {
        subs.add(
          db.collection('userUnread').doc(uid).snapshots().listen((d) {
            final m = (d.data()?['byGroup'] as Map?) ?? const {};
            byGroup = {for (final e in m.entries) e.key.toString(): (e.value as num).toInt()};
            emit();
          }, onError: (Object e) => out.addError(mapFirebaseError(e))),
        );
        for (final g in groupIds) {
          subs.add(
            _col(g).orderBy('createdAt', descending: true).limit(1).snapshots().listen((s) {
              last[g] = s.docs.isEmpty ? null : ChatMessage.fromMap(g, s.docs.first.id, s.docs.first.data());
              emit();
            }, onError: (Object e) => out.addError(mapFirebaseError(e))),
          );
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }

  @override
  Stream<Map<String, DateTime>> watchReadReceipts(String groupId) => db
      .collection('chats')
      .doc(groupId)
      .collection('members')
      .snapshots()
      .map(
        (s) => {
          for (final d in s.docs)
            if (d.data()['lastReadAt'] != null) d.id: readDate(d.data()['lastReadAt']),
        },
      )
      .mapFirebaseErrors();

  // ── v1.4 read receipts / acknowledgments ──────────────────────────────

  CollectionReference<Map<String, dynamic>> _receipts(String groupId) =>
      db.collection('chats').doc(groupId).collection('receipts');

  @override
  Stream<Map<String, MessageReceipt>> watchSentReceipts(String groupId) {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const {});
    return _receipts(groupId)
        .where('senderId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => {for (final d in s.docs) d.id: MessageReceipt.fromMap(d.id, d.data())})
        .mapFirebaseErrors();
  }

  @override
  Stream<List<RecipientStatus>> watchRecipientStatuses(String groupId, String messageId) {
    final msg = _col(groupId).doc(messageId);
    MessageReceipt? receipt;
    var reads = <String, DateTime>{};
    var acks = <String, DateTime>{};
    final names = <String, String>{};
    final subs = <StreamSubscription<Object?>>[];
    late StreamController<List<RecipientStatus>> out;
    Future<void> emit() async {
      final r = receipt;
      if (r == null) return;
      final missing = r.recipientIds.where((u) => !names.containsKey(u)).toList();
      for (final u in missing) {
        final p = (await db.collection('publicProfiles').doc(u).get()).data();
        names[u] = p == null ? '—' : '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
      }
      if (out.isClosed) return;
      out.add([
        for (final u in r.recipientIds)
          RecipientStatus(uid: u, name: names[u] ?? '—', readAt: reads[u] ?? acks[u], ackAt: acks[u]),
      ]);
    }

    Map<String, DateTime> marks(QuerySnapshot<Map<String, dynamic>> s, String field) => {
      for (final d in s.docs)
        if (d.data()[field] != null) d.id: readDate(d.data()[field]),
    };
    void fail(Object e) => out.addError(mapFirebaseError(e));
    out = StreamController<List<RecipientStatus>>(
      onListen: () {
        subs
          ..add(
            _receipts(groupId).doc(messageId).snapshots().listen((d) {
              if (!d.exists) return out.addError(const NotFoundException('receipt'));
              receipt = MessageReceipt.fromMap(d.id, d.data()!);
              emit();
            }, onError: fail),
          )
          ..add(
            msg.collection('msgReads').snapshots().listen((s) {
              reads = marks(s, 'readAt');
              emit();
            }, onError: fail),
          )
          ..add(
            msg.collection('msgAcks').snapshots().listen((s) {
              acks = marks(s, 'ackAt');
              emit();
            }, onError: fail),
          );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }

  @override
  Stream<MyMarks> watchMyMarks(String groupId) {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const MyMarks());
    var read = <String>{};
    var acked = <String, DateTime>{};
    var requested = <String>{};
    final subs = <StreamSubscription<Object?>>[];
    late StreamController<MyMarks> out;
    void emit() => out.add(MyMarks(read: read, acked: acked, ackRequested: requested));
    void fail(Object e) => out.addError(mapFirebaseError(e));
    out = StreamController<MyMarks>(
      onListen: () {
        subs
          ..add(
            db
                .collectionGroup('msgReads')
                .where('uid', isEqualTo: uid)
                .where('groupId', isEqualTo: groupId)
                .snapshots()
                .listen((s) {
                  read = {for (final d in s.docs) d.data()['messageId'] as String? ?? ''};
                  emit();
                }, onError: fail),
          )
          ..add(
            db
                .collectionGroup('msgAcks')
                .where('uid', isEqualTo: uid)
                .where('groupId', isEqualTo: groupId)
                .snapshots()
                .listen((s) {
                  acked = {
                    for (final d in s.docs)
                      d.data()['messageId'] as String? ?? '': readDateOrNull(d.data()['ackAt']) ?? DateTime.now(),
                  };
                  emit();
                }, onError: fail),
          )
          ..add(
            // The server writes an inbox entry only for recipients of the
            // snapshot, so it doubles as "I was asked to acknowledge".
            db
                .collection('notifications')
                .where('userId', isEqualTo: uid)
                .where('type', isEqualTo: 'ackRequested')
                .snapshots()
                .listen((s) {
                  requested = {
                    for (final d in s.docs)
                      if ((d.data()['args'] as Map?)?['groupId'] == groupId)
                        (d.data()['args'] as Map)['messageId'].toString(),
                  };
                  emit();
                }, onError: fail),
          );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }

  Map<String, Object> _mark(String uid, String groupId, String messageId, String field) => {
    'uid': uid,
    'groupId': groupId,
    'messageId': messageId,
    field: FieldValue.serverTimestamp(),
  };

  /// One batch for the visible messages; if the batch is refused (e.g. one
  /// receipt not created yet, or already marked on another device), each
  /// mark is retried alone and refusals are ignored.
  @override
  Future<void> markSeen(String groupId, List<String> messageIds) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || messageIds.isEmpty) return;
    DocumentReference<Map<String, dynamic>> ref(String m) => _col(groupId).doc(m).collection('msgReads').doc(uid);
    try {
      final b = db.batch();
      for (final m in messageIds.toSet()) {
        b.set(ref(m), _mark(uid, groupId, m, 'readAt'));
      }
      await b.commit();
    } on FirebaseException {
      for (final m in messageIds.toSet()) {
        await ref(m).set(_mark(uid, groupId, m, 'readAt')).catchError((Object _) {});
      }
    }
  }

  @override
  Future<void> acknowledge(String groupId, String messageId) => guardFirebase(() async {
    final uid = requireUid(auth);
    await _col(groupId).doc(messageId).collection('msgAcks').doc(uid).set(_mark(uid, groupId, messageId, 'ackAt'));
  });

  @override
  Stream<List<PendingAck>> watchPendingAcks() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    var requested = <PendingAck>[];
    var acked = <String>{};
    final subs = <StreamSubscription<Object?>>[];
    late StreamController<List<PendingAck>> out;
    void emit() => out.add([
      for (final p in requested)
        if (!acked.contains(p.messageId)) p,
    ]);
    void fail(Object e) => out.addError(mapFirebaseError(e));
    out = StreamController<List<PendingAck>>(
      onListen: () {
        subs
          ..add(
            db
                .collection('notifications')
                .where('userId', isEqualTo: uid)
                .where('type', isEqualTo: 'ackRequested')
                .snapshots()
                .listen((s) {
                  requested = [
                    for (final d in s.docs)
                      if (d.data()['args'] case final Map a)
                        PendingAck(groupId: a['groupId'].toString(), messageId: a['messageId'].toString()),
                  ];
                  emit();
                }, onError: fail),
          )
          ..add(
            db.collectionGroup('msgAcks').where('uid', isEqualTo: uid).snapshots().listen((s) {
              acked = {for (final d in s.docs) d.data()['messageId'] as String? ?? ''};
              emit();
            }, onError: fail),
          );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }
}
