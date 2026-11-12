import '../domain/media_access.dart';

class HttpMediaDownloader implements MediaDownloader {
  @override
  Future<DownloadedFile> fetch(
    DownloadTicket ticket, {
    required void Function(int received, int total) onProgress,
    required DownloadCancelToken cancel,
  }) => throw UnsupportedError('Downloads are available in the mobile app');
}
