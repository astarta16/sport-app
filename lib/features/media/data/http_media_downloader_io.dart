import 'dart:async';
import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../domain/media_access.dart';

/// Streams the short-lived URL into the app's temporary directory (no broad
/// storage permission needed); the user then saves/shares it with the system
/// share sheet. Partial files are deleted on cancel or failure.
class HttpMediaDownloader implements MediaDownloader {
  @override
  Future<DownloadedFile> fetch(
    DownloadTicket ticket, {
    required void Function(int received, int total) onProgress,
    required DownloadCancelToken cancel,
  }) async {
    final url = ticket.url;
    if (url == null) throw const NotFoundException('download');
    final dir = await Directory.systemTemp.createTemp('sp_dl_');
    final file = File('${dir.path}/${ticket.fileName}');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    cancel.onCancel(() => client.close(force: true));
    IOSink? sink;
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode == 403 || res.statusCode == 401) throw const PermissionDeniedException('download');
      if (res.statusCode != 200) throw BackendUnavailableException('http ${res.statusCode}');
      final total = res.contentLength > 0 ? res.contentLength : ticket.sizeBytes;
      sink = file.openWrite();
      var received = 0;
      await for (final chunk in res) {
        cancel.throwIfCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await sink.close();
      sink = null;
      cancel.throwIfCancelled();
      return DownloadedFile(fileName: ticket.fileName, mimeType: ticket.mimeType, sizeBytes: received, path: file.path);
    } catch (e) {
      await sink?.close().catchError((_) {});
      await dir.delete(recursive: true).catchError((_) => dir);
      if (cancel.isCancelled) throw const DownloadCancelledException();
      if (e is AppException || e is DownloadCancelledException) rethrow;
      throw const BackendUnavailableException('download');
    } finally {
      client.close(force: true);
    }
  }
}
