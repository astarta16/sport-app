import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/training_plan.dart';
import 'plans_providers.dart';

String planTypeLabel(BuildContext context, PlanType t) {
  final l = context.l10n;
  return switch (t) {
    PlanType.seasonal => l.planTypeSeasonal,
    PlanType.monthly => l.planTypeMonthly,
    PlanType.weekly => l.planTypeWeekly,
    PlanType.exercise => l.planTypeExercise,
    PlanType.homework => l.planTypeHomework,
  };
}

String planStatusLabel(BuildContext context, PlanStatus s) {
  final l = context.l10n;
  return switch (s) {
    PlanStatus.draft => l.planStatusDraft,
    PlanStatus.published => l.planStatusPublished,
    PlanStatus.archived => l.planStatusArchived,
  };
}

Color planStatusColor(PlanStatus s) => switch (s) {
  PlanStatus.draft => AppColors.warning,
  PlanStatus.published => AppColors.success,
  PlanStatus.archived => AppColors.neutral,
};

String progressLabel(BuildContext context, ProgressStatus s) {
  final l = context.l10n;
  return switch (s) {
    ProgressStatus.notStarted => l.progressNotStarted,
    ProgressStatus.inProgress => l.progressInProgress,
    ProgressStatus.completed => l.progressCompleted,
  };
}

IconData mediaIcon(MediaKind k) => switch (k) {
  MediaKind.photo => Icons.image_rounded,
  MediaKind.video => Icons.play_circle_rounded,
  MediaKind.pdf => Icons.picture_as_pdf_rounded,
  MediaKind.link => Icons.link_rounded,
};

String periodLabel(BuildContext context, TrainingPlan p) {
  final f = Fmt.of(context);
  final start = f.dayMonthShort(p.startDate.toDateTime());
  return p.endDate == null
      ? context.l10n.planOpenEnded(start)
      : context.l10n.planPeriod(start, f.dayMonthShort(p.endDate!.toDateTime()));
}

/// Opens an external link only after it passed [PlanDraft.isSafeLink],
/// in the system browser (no app session/cookies are shared).
Future<void> openExternalLink(BuildContext context, String url) async {
  final l = context.l10n;
  if (!PlanDraft.isSafeLink(url)) {
    showAppSnack(context, l.exerciseLinkInvalid, error: true);
    return;
  }
  final ok = await confirmDialog(
    context,
    title: l.exerciseOpenLink,
    message: '$url\n\n${l.exerciseExternalWarning}',
    confirmLabel: l.exerciseOpenLink,
  );
  if (!ok) return;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Tile for one media item of an exercise (private bytes or placeholder).
class ExerciseMediaTile extends ConsumerWidget {
  const ExerciseMediaTile({super.key, required this.planId, required this.media, this.onRemove, this.localBytes});

  final String planId;
  final ExerciseMedia media;
  final VoidCallback? onRemove;

  /// Editor preview of a not-yet-uploaded file.
  final List<int>? localBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isPhoto = media.kind == MediaKind.photo;
    final bytes =
        localBytes ??
        (isPhoto && planId.isNotEmpty && media.path != null
            ? ref.watch(planMediaBytesProvider((planId: planId, media: media))).value
            : null);
    final tile = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: bytes != null && bytes.length > 100
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Image.memory(
                Uint8List.fromList(bytes),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(mediaIcon(media.kind)),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  mediaIcon(media.kind),
                  size: 32,
                  color: media.kind == MediaKind.pdf ? AppColors.danger : scheme.primary,
                ),
                if (media.name != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      media.name!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
    );
    return Stack(
      children: [
        InkWell(
          key: Key('media-${media.id}'),
          onTap: media.kind == MediaKind.link && media.url != null ? () => openExternalLink(context, media.url!) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: tile,
        ),
        if (onRemove != null)
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              key: Key('remove-media-${media.id}'),
              tooltip: context.l10n.m191RemoveAttachment,
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}
