import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../domain/report.dart';

/// Lets a group member report a chat message, media post or photo to the
/// club's moderators. The backend validates membership and rate-limits.
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required ReportTarget targetType,
  required String targetPath,
  required String groupId,
}) async {
  final l = context.l10n;
  var reason = ReportReason.inappropriate;
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: const Key('report-dialog'),
        title: Text(l.reportTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final r in ReportReason.values)
                    ChoiceChip(
                      key: Key('report-reason-${r.name}'),
                      label: Text(reportReasonLabel(context, r)),
                      selected: reason == r,
                      onSelected: (_) => setState(() => reason = r),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                maxLength: 300,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(labelText: l.reportNote),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
            key: const Key('report-submit'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.send),
          ),
        ],
      ),
    ),
  );
  final text = note.text;
  note.dispose();
  if (ok != true || !context.mounted) return;
  await runGuarded(
    context,
    () => ref
        .read(moderationRepositoryProvider)
        .report(targetType: targetType, targetPath: targetPath, groupId: groupId, reason: reason, note: text),
    success: l.reportSent,
  );
}
