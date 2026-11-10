import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/form_fields.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../moderation/domain/report.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../../trainings/domain/training.dart';
import '../domain/media_post.dart';
import 'media_providers.dart';

/// Coach publishes a photo or video to selected groups (v1.1 §5).
class MediaPublishScreen extends ConsumerStatefulWidget {
  const MediaPublishScreen({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<MediaPublishScreen> createState() => _MediaPublishScreenState();
}

class _MediaPublishScreenState extends ConsumerState<MediaPublishScreen> {
  MediaUpload? _upload;
  final _groups = <String>{};
  final _caption = TextEditingController();
  bool _consent = false;
  bool _saving = false;
  List<String> _errors = const [];

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) _groups.add(widget.groupId!);
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(Future<PhotoUpload?> Function() pick, MediaType type) async {
    final f = await pick();
    if (f == null || !mounted) return;
    setState(() => _upload = MediaUpload(type: type, file: f));
  }

  Future<void> _publish() async {
    final l = context.l10n;
    final u = _upload;
    final error = u == null
        ? 'fileEmpty'
        : MediaPost.validateUpload(
            type: u.type,
            mimeType: u.file.mimeType,
            bytes: u.file.bytes.length,
            durationSec: u.durationSec,
            groupIds: _groups.toList(),
            consentConfirmed: _consent,
            caption: _caption.text,
          );
    setState(() => _errors = [?error]);
    if (error != null) return;
    setState(() => _saving = true);
    final ok = await runGuarded(
      context,
      () => ref
          .read(mediaPostsRepositoryProvider)
          .publish(upload: u!, groupIds: _groups.toList(), consentConfirmed: _consent, caption: _caption.text),
      success: l.mediaPublished,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.popOrHome();
  }

  /// Demo helper: a generated image so the flow works without a camera.
  void _demoPhoto() => setState(
    () => _upload = MediaUpload(
      type: MediaType.photo,
      file: PhotoUpload(bytes: Uint8List.fromList(List.filled(2048, 7)), fileName: 'demo.jpg', mimeType: 'image/jpeg'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final groups = (ref.watch(myGroupsProvider).value ?? const <Group>[])
        .where((g) => g.hasCoach(me?.id ?? ''))
        .toList();
    final members = [for (final gid in _groups) ...?ref.watch(groupMembersProvider(gid)).value];
    final noConsent = {
      for (final c in members)
        if (!c.photoConsent) c.id: c,
    }.values.toList();
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    return Scaffold(
      appBar: AppBar(title: Text(l.addMedia)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _pick(MediaPicker.takePhoto, MediaType.photo),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text(l.mediaTakePhoto),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _pick(() => MediaPicker.pickVideo(camera: true), MediaType.video),
                  icon: const Icon(Icons.videocam_rounded),
                  label: Text(l.mediaRecordVideo),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _pick(MediaPicker.pickOnePhoto, MediaType.photo),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(l.mediaFromGallery),
                ),
                if (demo)
                  OutlinedButton.icon(
                    key: const Key('media-demo-photo'),
                    onPressed: _demoPhoto,
                    icon: const Icon(Icons.science_rounded),
                    label: Text(l.demoBadge),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l.mediaLimits, style: Theme.of(context).textTheme.bodySmall),
            if (_upload != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Row(
                  children: [
                    Icon(_upload!.type == MediaType.video ? Icons.movie_rounded : Icons.image_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(_upload!.file.fileName)),
                    Text('${(_upload!.file.bytes.length / 1024).ceil()} KB'),
                  ],
                ),
              ),
            ],
            SectionHeader(l.mediaGroups),
            for (final g in groups)
              CheckboxListTile(
                key: Key('media-group-${g.id}'),
                value: _groups.contains(g.id),
                onChanged: (v) => setState(() => v == true ? _groups.add(g.id) : _groups.remove(g.id)),
                title: Text(g.name),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            if (noConsent.isNotEmpty)
              DemoBanner(
                text: l.mediaConsentMissing(noConsent.length, noConsent.map((Child c) => c.firstName).join(', ')),
              ),
            SectionHeader(l.mediaCaption),
            TextField(
              key: const Key('media-caption'),
              controller: _caption,
              maxLength: MediaPost.maxCaption,
              maxLines: 3,
              minLines: 1,
            ),
            CheckboxListTile(
              key: const Key('media-consent'),
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: Text(l.mediaConsentConfirm),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            FormErrors(errors: _errors),
            const SizedBox(height: AppSpacing.md),
            LoadingButton(
              key: const Key('media-publish'),
              label: l.mediaPublish,
              loading: _saving,
              onPressed: _publish,
              icon: Icons.publish_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid tile for a media post (photo / video placeholder).
class MediaPostTile extends StatelessWidget {
  const MediaPostTile({super.key, required this.post, this.sportKey = 'football', this.size});

  final MediaPost post;
  final String sportKey;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('media-${post.id}'),
      onTap: () => context.push(Routes.media(post.id)),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Stack(
        children: [
          MediaPhoto(refPath: post.thumbPath ?? post.storagePath, sportKey: sportKey, size: size),
          if (post.type == MediaType.video)
            const Positioned.fill(
              child: Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40)),
            ),
        ],
      ),
    );
  }
}

/// Horizontal strip of recent media for dashboards.
class MediaStrip extends ConsumerWidget {
  const MediaStrip({super.key, required this.groupIds, this.sportKey = 'football'});

  final Set<String> groupIds;
  final String sportKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final posts = (ref.watch(mediaFeedProvider).value ?? const <MediaPost>[])
        .where((p) => p.groupIds.any(groupIds.contains))
        .take(10)
        .toList();
    if (posts.isEmpty) {
      return AppCard(
        child: EmptyState(compact: true, icon: Icons.photo_library_outlined, title: l.mediaEmpty),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        key: const Key('media-strip'),
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) => MediaPostTile(post: posts[i], sportKey: sportKey, size: 110),
      ),
    );
  }
}

class MediaViewerScreen extends ConsumerWidget {
  const MediaViewerScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final feed = ref.watch(mediaFeedProvider);
    final mine = me == null ? null : ref.watch(coachMediaProvider(me.id)).value;
    final post = [...?feed.value, ...?mine].where((p) => p.id == postId).firstOrNull;
    final groups = ref.watch(groupsByIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.mediaTitle),
        actions: [
          if (post != null && post.coachId != me?.id)
            IconButton(
              key: const Key('media-report'),
              tooltip: l.report,
              onPressed: () => showReportDialog(
                context,
                ref,
                targetType: ReportTarget.mediaPost,
                targetPath: 'mediaPosts/${post.id}',
                groupId: post.groupIds.firstWhere(groups.containsKey, orElse: () => post.groupIds.first),
              ),
              icon: const Icon(Icons.flag_outlined),
            ),
          if (post != null && post.coachId == me?.id)
            IconButton(
              tooltip: l.mediaDelete,
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: l.mediaDelete,
                  message: l.mediaDelete,
                  confirmLabel: l.delete,
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                final done = await runGuarded(context, () => ref.read(mediaPostsRepositoryProvider).delete(post.id));
                if (done && context.mounted) context.popOrHome();
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: post == null
          ? (feed.isLoading
                ? const SkeletonList()
                : EmptyState(icon: Icons.lock_outline_rounded, title: l.errorPermission))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MediaPhoto(
                        refPath: post.storagePath,
                        sportKey: groups[post.groupIds.first]?.sportId ?? 'football',
                      ),
                      if (post.type == MediaType.video)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64),
                              Text(l.mediaVideo(post.durationSec ?? 0), style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (post.caption != null) Text(post.caption!, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${post.coachName} · ${Fmt.of(context).dateTime(post.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  post.groupIds.map((g) => groups[g]?.name).whereType<String>().join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                DemoBanner(text: l.mediaNoDownload),
              ],
            ),
    );
  }
}
