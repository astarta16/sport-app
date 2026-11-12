import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/media_access.dart';
import '../domain/media_post.dart';

/// Last finished download (file name, bytes). Tests read it.
final lastMediaDownloadProvider = StateProvider<({String name, int bytes})?>((_) => null);

Future<void> showMediaDownloadSheet(BuildContext context, MediaPost post) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  builder: (_) => MediaDownloadSheet(post: post),
);

enum _Phase { confirm, running, failed, denied, cancelled }

/// Confirm (with the "a local copy cannot be revoked" notice) → authorize on
/// the server → transfer with progress and cancel → system share/save sheet.
class MediaDownloadSheet extends ConsumerStatefulWidget {
  const MediaDownloadSheet({super.key, required this.post});

  final MediaPost post;

  @override
  ConsumerState<MediaDownloadSheet> createState() => _MediaDownloadSheetState();
}

class _MediaDownloadSheetState extends ConsumerState<MediaDownloadSheet> {
  _Phase _phase = _Phase.confirm;
  int _received = 0;
  int _total = 0;
  DownloadCancelToken? _cancel;

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final l = context.l10n;
    final cancel = _cancel = DownloadCancelToken();
    setState(() {
      _phase = _Phase.running;
      _received = 0;
      _total = 0;
    });
    try {
      // Authorization is checked again on every attempt (membership may have ended).
      final ticket = await ref.read(mediaAccessRepositoryProvider).authorizeDownload(widget.post);
      cancel.throwIfCancelled();
      final file = await ref
          .read(mediaDownloaderProvider)
          .fetch(
            ticket,
            cancel: cancel,
            onProgress: (r, t) {
              if (mounted && !cancel.isCancelled) {
                setState(() {
                  _received = r;
                  _total = t;
                });
              }
            },
          );
      if (!mounted || cancel.isCancelled) return;
      ref.read(lastMediaDownloadProvider.notifier).state = (name: file.fileName, bytes: file.sizeBytes);
      final messenger = ScaffoldMessenger.of(context);
      final x = file.path != null
          ? XFile(file.path!, mimeType: file.mimeType, name: file.fileName)
          : XFile.fromData(file.bytes!, mimeType: file.mimeType, name: file.fileName);
      Navigator.of(context).pop();
      try {
        await SharePlus.instance.share(ShareParams(files: [x], fileNameOverrides: [file.fileName]));
        messenger.showSnackBar(SnackBar(content: Text(l.downloadDone(file.fileName))));
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(l.downloadStorageError)));
      }
    } on DownloadCancelledException {
      if (mounted) setState(() => _phase = _Phase.cancelled);
    } on PermissionDeniedException {
      if (mounted) setState(() => _phase = _Phase.denied);
    } catch (_) {
      if (mounted && !cancel.isCancelled) setState(() => _phase = _Phase.failed);
    }
  }

  void _stop() {
    _cancel?.cancel();
    setState(() => _phase = _Phase.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final pct = _total > 0 ? (_received * 100 ~/ _total).clamp(0, 100) : 0;
    final isVideo = widget.post.type == MediaType.video;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          key: const Key('download-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(isVideo ? Icons.movie_rounded : Icons.image_rounded),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(l.downloadTitle, style: t.titleMedium)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l.downloadNotice, key: const Key('download-notice'), style: t.bodySmall),
            const SizedBox(height: AppSpacing.md),
            ...switch (_phase) {
              _Phase.running => [
                LinearProgressIndicator(
                  key: const Key('download-progress'),
                  value: _total > 0 ? _received / _total : null,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l.downloadProgress(pct), key: const Key('download-percent')),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(key: const Key('download-cancel'), onPressed: _stop, child: Text(l.cancel)),
              ],
              _Phase.failed => [
                Text(
                  l.downloadFailed,
                  key: const Key('download-error'),
                  style: t.bodyMedium?.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  key: const Key('download-retry'),
                  onPressed: _start,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.retry),
                ),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
              ],
              _Phase.denied => [
                Text(
                  l.downloadDenied,
                  key: const Key('download-denied'),
                  style: t.bodyMedium?.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.close)),
              ],
              _Phase.cancelled || _Phase.confirm => [
                if (_phase == _Phase.cancelled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(l.downloadCancelled, key: const Key('download-cancelled')),
                  ),
                FilledButton.icon(
                  key: const Key('download-start'),
                  onPressed: _start,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(l.downloadAction),
                ),
                TextButton(
                  key: const Key('download-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}
