import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
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
  Stream<List<ChatMessage>> watchMessages(String groupId) =>
      _col(groupId)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(includeMetadataChanges: true)
          .map((s) => s.docs.reversed.map((d) => ChatMessage.fromMap(groupId, d.id, d.data())).toList())
          .mapFirebaseErrors();

  @override
  Future<void> send(String groupId, String text, {List<PhotoUpload> attachments = const []}) => guardFirebase(() async {
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
    });
  });
}
