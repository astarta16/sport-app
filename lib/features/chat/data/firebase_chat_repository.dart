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
}
