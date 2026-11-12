import 'package:flutter/services.dart';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/media_access.dart';
import '../domain/media_post.dart';

/// Demo playback and downloads use bundled sample media (no real children):
/// `assets/demo/sample_video.mp4` and `assets/demo/sample_photo.png`.
class DemoMediaAccessRepository implements MediaAccessRepository {
  DemoMediaAccessRepository(this.db);

  final DemoBackend db;

  static const sampleVideo = 'assets/demo/sample_video.mp4';
  static const samplePhoto = 'assets/demo/sample_photo.png';

  MediaPost _live(MediaPost post) => db.mediaPosts[post.id] ?? (throw const NotFoundException('media'));

  @override
  Future<PlaybackSource> playbackSource(MediaPost post) async {
    final p = _live(post);
    final me = db.me;
    final groups = [for (final g in p.groupIds) ?db.groups[g]];
    final visible =
        me.id == p.coachId ||
        (!p.hidden && groups.any((g) => g.isActive && (g.hasParent(me.id) || AccessPolicy.isCoachOf(me, g))));
    if (!visible) throw const PermissionDeniedException('media');
    return const PlaybackSource(assetPath: sampleVideo);
  }

  @override
  Future<DownloadTicket> authorizeDownload(MediaPost post) async {
    db.requireOnline();
    final p = _live(post);
    final me = db.me;
    final groups = [for (final g in p.groupIds) ?db.groups[g]];
    if (!AccessPolicy.canDownloadMedia(me, p, groups)) throw const PermissionDeniedException('mediaDownload');
    final video = p.type == MediaType.video;
    final asset = video ? sampleVideo : samplePhoto;
    final size = (await rootBundle.load(asset)).lengthInBytes;
    final group = groups.where((g) => g.hasParent(me.id)).firstOrNull ?? groups.firstOrNull;
    db.mediaDownloads.add(
      MediaDownloadEvent(
        postId: p.id,
        userId: me.id,
        role: me.role.name,
        groupId: group?.id,
        clubId: p.clubId.isNotEmpty ? p.clubId : (group?.clubId ?? ''),
        mediaType: p.type.name,
        at: db.clock(),
      ),
    );
    db.commit();
    return DownloadTicket(
      fileName: 'sportparent_${video ? 'video' : 'photo'}_${p.id}.${video ? 'mp4' : 'png'}',
      mimeType: video ? 'video/mp4' : 'image/png',
      sizeBytes: size,
      assetPath: asset,
    );
  }
}

/// Demo transfer: reads the bundled asset in chunks so progress, cancel and
/// failures behave like a network download ([DemoBackend.downloadChunkDelay],
/// [DemoBackend.failNextDownload]).
class DemoMediaDownloader implements MediaDownloader {
  DemoMediaDownloader(this.db);

  final DemoBackend db;

  @override
  Future<DownloadedFile> fetch(
    DownloadTicket ticket, {
    required void Function(int received, int total) onProgress,
    required DownloadCancelToken cancel,
  }) async {
    final data = (await rootBundle.load(ticket.assetPath!)).buffer.asUint8List();
    final total = data.length;
    const steps = 10;
    for (var i = 1; i <= steps; i++) {
      cancel.throwIfCancelled();
      if (db.failNextDownload && i == steps ~/ 2) {
        db.failNextDownload = false;
        throw const BackendUnavailableException('download');
      }
      await Future<void>.delayed(db.downloadChunkDelay);
      cancel.throwIfCancelled();
      onProgress(total * i ~/ steps, total);
    }
    return DownloadedFile(fileName: ticket.fileName, mimeType: ticket.mimeType, sizeBytes: total, bytes: data);
  }
}
