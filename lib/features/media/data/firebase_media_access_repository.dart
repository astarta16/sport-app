import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/media_access.dart';
import '../domain/media_post.dart';

/// Playback (`getMediaUrl`, 15-minute URL) and downloads (`getMediaDownload`,
/// 5-minute attachment URL, logged). URLs are kept in memory only and are
/// never logged or stored.
class FirebaseMediaAccessRepository implements MediaAccessRepository {
  FirebaseMediaAccessRepository(this.functions);

  final FirebaseFunctions functions;

  @override
  Future<PlaybackSource> playbackSource(MediaPost post) => guardFirebase(() async {
    final r = await functions.httpsCallable('getMediaUrl').call<Map<String, dynamic>>({'postId': post.id});
    return PlaybackSource(
      url: r.data['url'] as String?,
      expiresAt: DateTime.tryParse(r.data['expiresAt'] as String? ?? ''),
    );
  });

  @override
  Future<DownloadTicket> authorizeDownload(MediaPost post) => guardFirebase(() async {
    final r = await functions.httpsCallable('getMediaDownload').call<Map<String, dynamic>>({'postId': post.id});
    return DownloadTicket(
      url: r.data['url'] as String?,
      fileName: r.data['fileName'] as String? ?? 'sportparent_${post.id}',
      mimeType: r.data['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: (r.data['sizeBytes'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(r.data['expiresAt'] as String? ?? ''),
    );
  });
}
