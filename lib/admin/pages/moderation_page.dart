import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/visuals.dart';
import '../../features/groups/presentation/groups_providers.dart';
import '../../features/moderation/domain/report.dart';
import '../widgets.dart';
import 'admin_providers.dart';

/// Moderation queue (v1.2): reported chat messages, photos and videos.
class ModerationPage extends ConsumerWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reports = ref.watch(adminReportsProvider);
    final f = Fmt.of(context);
    String status(ContentReport r) => switch (r.status) {
      ReportStatus.open => l.adminReportOpen,
      ReportStatus.resolved => l.adminReportResolved,
      ReportStatus.dismissed => l.adminReportDismissed,
    };
    return AdminSection(
      title: l.adminNavModeration,
      subtitle: l.adminModerationNote,
      child: AsyncView<List<ContentReport>>(
        value: reports,
        data: (list) => AdminTable<ContentReport>(
          rows: list,
          searchText: (r) => '${r.preview} ${r.note ?? ''}',
          filters: [(l.adminReportOpen, (r) => r.isOpen), (l.adminFilterAll, (_) => true)],
          columns: [
            AdminColumn(l.adminColWhen, (r) => Text(f.dateTime(r.createdAt)), flex: 2, sortKey: (r) => r.createdAt),
            AdminColumn(
              l.adminColContent,
              (r) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(switch (r.targetType) {
                        ReportTarget.chatMessage => Icons.chat_bubble_outline_rounded,
                        ReportTarget.mediaPost => Icons.video_library_outlined,
                        ReportTarget.trainingPhoto => Icons.photo_outlined,
                      }, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          r.preview.isEmpty ? r.targetPath : r.preview,
                          key: Key('report-${r.id}'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Consumer(
                    builder: (context, ref, _) => Text(
                      ref.watch(groupsByIdProvider)[r.groupId]?.name ?? r.groupId,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              flex: 4,
            ),
            AdminColumn(
              l.adminColReason,
              (r) => Text('${reportReasonLabel(context, r.reason)}${r.note == null ? '' : ' — ${r.note}'}'),
              flex: 3,
            ),
            AdminColumn(
              l.adminColStatus,
              (r) => Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  label: status(r),
                  color: r.isOpen ? AppColors.warning : AppColors.neutral,
                  dense: true,
                ),
              ),
              flex: 2,
            ),
            AdminColumn(
              l.adminColActions,
              (r) => r.isOpen
                  ? Wrap(
                      spacing: 4,
                      children: [
                        FilledButton(
                          key: Key('hide-${r.id}'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                          onPressed: () => runGuarded(
                            context,
                            () => ref.read(adminRepositoryProvider).moderate(r.id, ModerationDecision.hidden),
                            success: l.adminSaved,
                          ),
                          child: Text(l.adminHide),
                        ),
                        OutlinedButton(
                          key: Key('keep-${r.id}'),
                          onPressed: () => runGuarded(
                            context,
                            () => ref.read(adminRepositoryProvider).moderate(r.id, ModerationDecision.kept),
                            success: l.adminSaved,
                          ),
                          child: Text(l.adminKeep),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              flex: 3,
            ),
          ],
        ),
      ),
    );
  }
}
