import 'dart:typed_data';

import 'media_post.dart';

/// Where the player reads a video from. Firebase: a short-lived signed URL
/// (re-requested when expired); demo: a bundled sample asset.
class PlaybackSource {
  const PlaybackSource({this.url, this.assetPath, this.expiresAt});

  final String? url;
  final String? assetPath;
  final DateTime? expiresAt;

  /// Expired (or about to) → ask the backend again before (re)trying.
  bool isExpired(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!.subtract(const Duration(seconds: 20)));
}

/// Result of an authorized download request (`getMediaDownload`).
class DownloadTicket {
  const DownloadTicket({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.url,
    this.assetPath,
    this.expiresAt,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? url;
  final String? assetPath;
  final DateTime? expiresAt;
}

/// A finished download: a local file (mobile) or bytes (demo / web).
class DownloadedFile {
  const DownloadedFile({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.path,
    this.bytes,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? path;
  final Uint8List? bytes;
}

class DownloadCancelledException implements Exception {
  const DownloadCancelledException();
}

/// Cooperative cancellation for [MediaDownloader.fetch].
class DownloadCancelToken {
  bool _cancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  void onCancel(void Function() f) => _listeners.add(f);

  void throwIfCancelled() {
    if (_cancelled) throw const DownloadCancelledException();
  }
}

abstract interface class MediaAccessRepository {
  /// Server-checked playback source for a video post.
  Future<PlaybackSource> playbackSource(MediaPost post);

  /// Live authorization + audit of a download. Throws
  /// PermissionDeniedException when not (or no longer) allowed.
  Future<DownloadTicket> authorizeDownload(MediaPost post);
}

/// Transfers the authorized file with progress and cancellation.
abstract interface class MediaDownloader {
  Future<DownloadedFile> fetch(
    DownloadTicket ticket, {
    required void Function(int received, int total) onProgress,
    required DownloadCancelToken cancel,
  });
}
