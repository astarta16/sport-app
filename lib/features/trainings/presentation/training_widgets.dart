import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../domain/training.dart';

/// Compact row used in calendars and lists.
class TrainingTile extends ConsumerWidget {
  const TrainingTile({
    super.key,
    required this.training,
    this.group,
    this.showDate = true,
    this.selected = false,
    this.onTap,
  });

  final Training training;
  final Group? group;
  final bool showDate;
  final bool selected;

  /// Overrides navigation (tablet master-detail shows the detail in a pane).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final venue = ref.watch(venuesByIdProvider)[training.venueId];
    final status = StatusVisual.training(context, training.status);
    final cancelled = training.status == TrainingStatus.cancelled;
    final sport = group?.sportId ?? 'generic';
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      color: selected ? scheme.primaryContainer : null,
      onTap: onTap ?? () => context.push(Routes.training(training.id)),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cancelled ? scheme.surfaceContainerHigh : SportVisuals.color(sport).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                if (showDate) Text(f.weekdayShort(training.startAt), style: t.labelSmall),
                Text(
                  showDate ? '${training.startAt.day}' : f.time(training.startAt),
                  style: (showDate ? t.titleLarge : t.titleSmall)?.copyWith(
                    color: cancelled ? scheme.onSurfaceVariant : SportVisuals.color(sport),
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group names can be long (Georgian / Russian): two lines
                // before anything is cut.
                Text(
                  '${f.time(training.startAt)} – ${f.time(training.endAt)} · ${group?.name ?? ''}',
                  key: Key('training-tile-title-${training.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(decoration: cancelled ? TextDecoration.lineThrough : null),
                ),
                const SizedBox(height: 2),
                Text(venue?.name ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (training.status != TrainingStatus.scheduled) StatusPill.of(status, dense: true),
                    for (final fo in training.focus.take(2))
                      StatusPill(label: focusLabel(context, fo), color: scheme.primary, dense: true),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Hero card for the next training on dashboards.
class NextTrainingCard extends ConsumerWidget {
  const NextTrainingCard({
    super.key,
    required this.training,
    required this.group,
    required this.now,
    this.coachName,
    this.onDirections,
  });

  final Training training;
  final Group group;
  final DateTime now;
  final String? coachName;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final venue = ref.watch(venuesByIdProvider)[training.venueId];
    final days = DateUtils.dateOnly(training.startAt).difference(DateUtils.dateOnly(now)).inDays;
    final hours = training.startAt.difference(now).inHours;
    final countdown = days == 0 && hours >= 0 && hours < 6 ? l.startsInHours(hours) : l.inDays(days);
    final cancelled = training.status == TrainingStatus.cancelled;
    final moved = training.status == TrainingStatus.moved;
    return AppCard(
      key: const Key('next-training-card'),
      padding: EdgeInsets.zero,
      gradient: cancelled ? AppColors.nightGradient : SportVisuals.gradient(group.sportId),
      onTap: () => context.push(Routes.training(training.id)),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Icon(SportVisuals.icon(group.sportId), size: 150, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // v1.9.1: a Wrap, not a Row — on narrow phones the countdown
                // moves to its own line instead of cutting the label short
                // ("შემდეგი ვარჯ…"). The label itself may wrap, never clip.
                Wrap(
                  key: const Key('next-training-header'),
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l.nextTraining.toUpperCase(),
                        key: const Key('next-training-label'),
                        softWrap: true,
                        style: t.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cancelled ? AppColors.coral : (moved ? AppColors.warning : AppColors.volt),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cancelled ? l.statusCancelled : (moved ? l.statusMoved : countdown),
                        key: const Key('next-training-countdown'),
                        softWrap: true,
                        style: t.labelSmall?.copyWith(
                          color: cancelled || moved ? Colors.white : AppColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  f.weekdayDayMonth(training.startAt),
                  style: t.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                Text(
                  '${f.time(training.startAt)} – ${f.time(training.endAt)}',
                  style: t.displaySmall?.copyWith(
                    color: Colors.white,
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white,
                  ),
                ),
                if (moved && training.previousStartAt != null)
                  Text(
                    l.movedFrom(f.dateTime(training.previousStartAt!)),
                    style: t.bodySmall?.copyWith(color: Colors.white70),
                  ),
                const SizedBox(height: AppSpacing.md),
                _InfoLine(icon: Icons.place_rounded, text: venue == null ? '—' : '${venue.name} · ${venue.address}'),
                const SizedBox(height: 6),
                _InfoLine(icon: Icons.sports_rounded, text: '${l.coachLabel}: ${coachName ?? '—'}'),
                const SizedBox(height: 6),
                _InfoLine(
                  icon: Icons.track_changes_rounded,
                  text: training.focus.map((x) => focusLabel(context, x)).join(' · '),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('directions-button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.navy,
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: venue == null ? null : onDirections,
                        icon: const Icon(Icons.directions_rounded, size: 20),
                        label: Text(l.directions),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: () => context.push(Routes.training(training.id)),
                        child: Text(l.details),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
