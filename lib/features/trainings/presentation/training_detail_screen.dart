import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/launcher.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/cancel_reason_dialog.dart';
import '../../../core/widgets/visuals.dart';
import '../../attendance/presentation/attendance_widgets.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../clubs/domain/club.dart';
import '../../clubs/presentation/clubs_providers.dart';
import '../../groups/domain/group.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../media/presentation/media_providers.dart';
import '../domain/training.dart';
import 'trainings_providers.dart';

class TrainingDetailScreen extends ConsumerWidget {
  const TrainingDetailScreen({super.key, required this.trainingId, this.embedded = false});

  final String trainingId;

  /// Detail pane of the tablet calendar (no app bar / back button).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final training = ref.watch(trainingProvider(trainingId));
    final body = AsyncView<Training?>(
      value: training,
      onRetry: () => ref.invalidate(trainingProvider(trainingId)),
      data: (t) {
        if (t == null) return EmptyState(icon: Icons.search_off_rounded, title: l.errorNotFound);
        final group = ref.watch(groupsByIdProvider)[t.groupId];
        return _Body(training: t, group: group);
      },
    );
    if (embedded) {
      return Material(
        key: const Key('training-detail-pane'),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(left: false, child: body),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.trainingTitle)),
      body: ConstrainedContent(maxWidth: Breakpoints.readable, child: body),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.training, required this.group});

  final Training training;
  final Group? group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider);
    final venue = ref.watch(venuesByIdProvider)[training.venueId];
    final canManage = user != null && group != null && AccessPolicy.canManageTrainings(user, group!);
    final sport = group?.sportId ?? 'generic';
    final coachId = group?.coachIds.firstOrNull;
    final coach = coachId == null ? null : ref.watch(publicProfileProvider(coachId)).value;
    final status = StatusVisual.training(context, training.status);
    final cancelled = training.status == TrainingStatus.cancelled;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      children: [
        AppCard(
          gradient: cancelled ? AppColors.nightGradient : SportVisuals.gradient(sport),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group?.name ?? '',
                      style: t.titleMedium?.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      status.label,
                      style: t.labelSmall?.copyWith(color: status.color, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(f.weekdayDayMonth(training.startAt), style: t.titleMedium?.copyWith(color: Colors.white70)),
              Text(
                '${f.time(training.startAt)} – ${f.time(training.endAt)}',
                style: t.displaySmall?.copyWith(color: Colors.white),
              ),
              Row(
                children: [
                  Text(l.durationMinutes(training.durationMin), style: t.bodyMedium?.copyWith(color: Colors.white70)),
                  if (training.isRecurring && !training.detached) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.event_repeat_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text(l.seriesRecurringBadge, style: t.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ],
              ),
              if (training.previousStartAt != null && training.status == TrainingStatus.moved)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.movedFrom(f.dateTime(training.previousStartAt!)),
                    style: t.bodySmall?.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        if (cancelled) ...[
          const SizedBox(height: AppSpacing.sm),
          _Banner(
            key: const Key('training-cancel-reason'),
            icon: Icons.event_busy_rounded,
            color: AppColors.danger,
            text: training.cancelReason == null ? l.cancelledBanner : l.cancelledWithReason(training.cancelReason!),
          ),
        ],
        if (canManage) _CoachActions(training: training, group: group!),
        if (canManage) CoachAttendanceSummary(training: training, group: group!),
        if (user != null && user.isParent && group != null) RsvpSection(training: training, group: group!),
        SectionHeader(l.venueLabel),
        if (venue != null) _VenueCard(venue: venue, sport: sport) else const Text('—'),
        SectionHeader(l.coachLabel),
        AppCard(
          child: Row(
            children: [
              InitialsAvatar(name: coach?.fullName ?? '?', size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(coach?.fullName ?? '—', style: t.titleSmall)),
              if (coach?.phone != null)
                IconButton.filledTonal(
                  tooltip: l.call,
                  onPressed: () => callPhone(coach!.phone!),
                  icon: const Icon(Icons.call_rounded),
                ),
            ],
          ),
        ),
        SectionHeader(l.trainingFocus),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fo in training.focus)
              Chip(avatar: Icon(focusIcon(fo), size: 18), label: Text(focusLabel(context, fo))),
          ],
        ),
        if (training.description.isNotEmpty) ...[
          SectionHeader(l.trainingDescription),
          AppCard(child: Text(training.description, style: t.bodyLarge)),
        ],
        SectionHeader(l.trainingPhotos),
        if (training.photoUrls.isEmpty)
          AppCard(
            child: EmptyState(compact: true, icon: Icons.photo_library_outlined, title: l.noPhotos),
          )
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [for (final p in training.photoUrls) MediaPhoto(refPath: p, sportKey: sport)],
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue, required this.sport});

  final Venue venue;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final point = LatLng(venue.location.latitude, venue.location.longitude);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radius)),
            child: SizedBox(
              height: 140,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ge.sportparent.sport_parent_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on_rounded, color: SportVisuals.color(sport), size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(venueTypeIcon(venue.type)),
            title: Text(venue.name, style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text(venue.address),
            trailing: FilledButton.tonalIcon(
              onPressed: () => openDirections(context, venue.location, venue.name),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: Text(l.directions),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachActions extends ConsumerWidget {
  const _CoachActions({required this.training, required this.group});

  final Training training;
  final Group group;

  /// Recurring occurrences ask whether to edit only this one (detaches it)
  /// or this and all following ones (splits the series).
  Future<void> _edit(BuildContext context) async {
    final l = context.l10n;
    if (!training.isRecurring || training.detached || training.occurrenceDate == null) {
      context.push(Routes.editTraining(training.id));
      return;
    }
    final scope = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        key: const Key('edit-scope-dialog'),
        title: Text(l.editScopeTitle),
        children: [
          SimpleDialogOption(
            key: const Key('edit-scope-this'),
            onPressed: () => Navigator.pop(context, 'this'),
            child: ListTile(leading: const Icon(Icons.event_rounded), title: Text(l.editScopeThis)),
          ),
          SimpleDialogOption(
            key: const Key('edit-scope-future'),
            onPressed: () => Navigator.pop(context, 'future'),
            child: ListTile(leading: const Icon(Icons.event_repeat_rounded), title: Text(l.editScopeFuture)),
          ),
        ],
      ),
    );
    if (!context.mounted || scope == null) return;
    if (scope == 'this') {
      context.push(Routes.editTraining(training.id));
    } else {
      context.push(Routes.editSeries(training.seriesId!, training.occurrenceDate!));
    }
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final now = ref.read(clockProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: training.startAt.isAfter(now) ? training.startAt : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(training.startAt));
    if (time == null || !context.mounted) return;
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await runGuarded(
      context,
      () => ref.read(trainingsRepositoryProvider).reschedule(training.id, start),
      success: l.trainingRescheduled,
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final reason = await showCancelReasonDialog(context, title: l.cancelTraining);
    if (reason != null && context.mounted) {
      await runGuarded(
        context,
        () => ref.read(trainingsRepositoryProvider).cancel(training.id, reason),
        success: l.trainingCancelledSnack,
      );
    }
  }

  Future<void> _addPhotos(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final photos = await MediaPicker.pickPhotos();
    if (photos.isEmpty || !context.mounted) return;
    final ok = await confirmDialog(
      context,
      title: l.photoConsentTitle,
      message: l.photoConsentConfirm,
      confirmLabel: l.confirm,
    );
    if (!ok || !context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(trainingsRepositoryProvider).addPhotos(training.id, photos, consentConfirmed: true),
      success: l.photosAdded,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final active = training.status.isActive;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (active)
            ActionChip(
              key: const Key('edit-training'),
              avatar: const Icon(Icons.edit_rounded, size: 18),
              label: Text(l.edit),
              onPressed: () => _edit(context),
            ),
          if (active)
            ActionChip(
              key: const Key('reschedule-training'),
              avatar: const Icon(Icons.update_rounded, size: 18),
              label: Text(l.rescheduleTraining),
              onPressed: () => _reschedule(context, ref),
            ),
          if (active)
            ActionChip(
              key: const Key('cancel-training'),
              avatar: const Icon(Icons.event_busy_rounded, size: 18, color: AppColors.danger),
              label: Text(l.cancelTraining),
              onPressed: () => _cancel(context, ref),
            ),
          if (active && training.startAt.isBefore(ref.read(clockProvider)()))
            ActionChip(
              avatar: const Icon(Icons.task_alt_rounded, size: 18, color: AppColors.success),
              label: Text(l.markDone),
              onPressed: () => runGuarded(
                context,
                () => ref.read(trainingsRepositoryProvider).markDone(training.id),
                success: l.trainingMarkedDone,
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: Text(l.addPhotos),
            onPressed: () => _addPhotos(context, ref),
          ),
        ],
      ),
    );
  }
}
