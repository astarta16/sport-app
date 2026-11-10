import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/media_post.dart';

/// `mediaPosts/{id}` + private Storage `media/{coachId}/{postId}/{file}`.
/// The post doc is written first (consentConfirmed: true) so the Storage rule
/// can verify ownership; `onMediaUpload` re-validates type/size and creates
/// the thumbnail. Videos are played through `getMediaUrl` signed URLs.
class FirebaseMediaPostsRepository implements MediaPostsRepository {
  FirebaseMediaPostsRepository(this.auth, this.db, this.storage);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseStorage storage;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('mediaPosts');

  List<MediaPost> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => MediaPost.fromMap(d.id, d.data())).where((p) => !p.hidden).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<MediaPost>> watchForGroups(List<String> groupIds) {
    if (groupIds.isEmpty) return Stream.value(const []);
    return _col
        .where('groupIds', arrayContainsAny: groupIds.take(30).toList())
        .snapshots()
        .map(_map)
        .mapFirebaseErrors();
  }

  @override
  Stream<List<MediaPost>> watchByCoach(String coachId) =>
      _col.where('coachId', isEqualTo: coachId).snapshots().map(_map).mapFirebaseErrors();

  @override
  Future<MediaPost> publish({
    required MediaUpload upload,
    required List<String> groupIds,
    required bool consentConfirmed,
    String? caption,
  }) => guardFirebase(() async {
    final error = MediaPost.validateUpload(
      type: upload.type,
      mimeType: upload.file.mimeType,
      bytes: upload.file.bytes.length,
      durationSec: upload.durationSec,
      groupIds: groupIds,
      consentConfirmed: consentConfirmed,
      caption: caption,
    );
    if (error != null) throw ValidationException(error);
    final uid = requireUid(auth);
    final me = (await db.collection('users').doc(uid).get()).data() ?? const {};
    final group = (await db.collection('groups').doc(groupIds.first).get()).data() ?? const {};
    final ref = _col.doc();
    final path = 'media/$uid/${ref.id}/${upload.file.fileName}';
    final post = MediaPost(
      id: ref.id,
      coachId: uid,
      coachName: '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim(),
      groupIds: groupIds,
      clubId: group['clubId'] as String? ?? '',
      type: upload.type,
      storagePath: path,
      caption: (caption ?? '').trim().isEmpty ? null : caption!.trim(),
      durationSec: upload.durationSec,
      createdAt: DateTime.now(),
    );
    await ref.set(post.toMap()..removeWhere((_, v) => v == null));
    try {
      // Resumable upload task (survives brief network loss).
      await storage
          .ref(path)
          .putData(Uint8ListX.from(upload.file.bytes), SettableMetadata(contentType: upload.file.mimeType));
    } catch (e) {
      await ref.delete();
      rethrow;
    }
    return post;
  });

  @override
  Future<void> delete(String postId) => guardFirebase(() async {
    final snap = await _col.doc(postId).get();
    final p = MediaPost.fromMap(postId, snap.data() ?? (throw const NotFoundException()));
    await storage.ref(p.storagePath).delete().catchError((_) {});
    await _col.doc(postId).delete();
  });
}
