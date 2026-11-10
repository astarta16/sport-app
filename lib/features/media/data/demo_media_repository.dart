import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../groups/domain/group.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/media_post.dart';
import '../domain/media_repository.dart';

/// Loads private media by reference and enforces *current* group
/// membership, like the Storage rules: a parent whose child left the group
/// can no longer open that group's photos, videos or chat attachments.
class DemoMediaRepository implements MediaRepository {
  DemoMediaRepository(this.db);

  final DemoBackend db;

  /// `demo://` placeholders return null so the UI draws a branded tile.
  @override
  Future<Uint8List?> load(String ref) async {
    final me = db.me;
    if (me.isAdmin) {
      // Moderators may review reported content in clubs they administer.
      final g = _groupsOf(ref);
      if (g.isEmpty || g.any((x) => me.administersClub(x.clubId))) return db.photos[ref];
      throw const PermissionDeniedException('media');
    }
    final post = db.mediaPosts.values.where((p) => p.storagePath == ref || p.thumbPath == ref).firstOrNull;
    if (post != null) {
      if (!AccessPolicy.canViewMedia(me, post, db.groups.values)) throw const PermissionDeniedException('media');
      return db.photos[ref];
    }
    final groups = _groupsOf(ref);
    if (groups.isNotEmpty && !groups.any((g) => AccessPolicy.canViewGroup(me, g))) {
      throw const PermissionDeniedException('media');
    }
    return db.photos[ref];
  }

  List<Group> _groupsOf(String ref) => [
    for (final t in db.trainings.values)
      if (t.photoUrls.contains(ref)) db.groups[t.groupId]!,
    for (final e in db.messages.entries)
      if (e.value.any((m) => m.attachments.contains(ref))) ?db.groups[e.key],
    for (final p in db.mediaPosts.values)
      if (p.storagePath == ref || p.thumbPath == ref) ...p.groupIds.map((id) => db.groups[id]).whereType<Group>(),
  ];
}

class DemoMediaPostsRepository implements MediaPostsRepository {
  DemoMediaPostsRepository(this.db);

  final DemoBackend db;

  @override
  Stream<List<MediaPost>> watchForGroups(List<String> groupIds) => db.watch(() {
    final me = db.me;
    final ids = groupIds.toSet();
    return db.mediaPosts.values
        .where((p) => p.groupIds.any(ids.contains) && AccessPolicy.canViewMedia(me, p, db.groups.values))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Stream<List<MediaPost>> watchByCoach(String coachId) => db.watch(() {
    final me = db.me;
    return db.mediaPosts.values
        .where(
          (p) => p.coachId == coachId && (p.coachId == me.id || AccessPolicy.canViewMedia(me, p, db.groups.values)),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<MediaPost> publish({
    required MediaUpload upload,
    required List<String> groupIds,
    required bool consentConfirmed,
    String? caption,
  }) async {
    db.requireOnline();
    final me = db.me;
    final targets = groupIds.map(db.requireGroup).toList();
    if (!AccessPolicy.canPublishMedia(me, targets)) throw const PermissionDeniedException('media');
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
    final key = 'demo-mem://${db.newId('media')}';
    db.photos[key] = Uint8List.fromList(upload.file.bytes);
    final p = MediaPost(
      id: db.newId('post'),
      coachId: me.id,
      coachName: me.fullName,
      groupIds: groupIds,
      clubId: targets.first.clubId,
      type: upload.type,
      storagePath: key,
      thumbPath: upload.type == MediaType.photo ? key : null,
      caption: (caption ?? '').trim().isEmpty ? null : caption!.trim(),
      durationSec: upload.durationSec,
      createdAt: db.clock(),
    );
    db.mediaPosts[p.id] = p;
    for (final g in targets) {
      db.dispatch(
        NotificationType.newMedia,
        g,
        route: '/media/${p.id}',
        args: {'coach': me.fullName},
        dedupeKey: 'media:${p.id}',
      );
    }
    db.commit();
    return p;
  }

  @override
  Future<void> delete(String postId) async {
    db.requireOnline();
    final p = db.mediaPosts[postId] ?? (throw const NotFoundException());
    if (p.coachId != db.me.id) throw const PermissionDeniedException('media');
    db.mediaPosts.remove(postId);
    db.photos.remove(p.storagePath);
    db.commit();
  }
}
