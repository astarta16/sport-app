import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/groups/presentation/groups_providers.dart';
import '../widgets.dart';

final adminMediaDownloadsProvider = StreamProvider.autoDispose<List<MediaDownloadRow>>(
  (ref) => ref.watch(adminRepositoryProvider).watchMediaDownloads(),
);

/// v1.4 media download audit: who downloaded which coach post, when.
/// Scoped to the admin's clubs. Shows no phone numbers and no chat data.
class MediaDownloadsPage extends ConsumerWidget {
  const MediaDownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final groups = ref.watch(groupsByIdProvider);
    return AdminSection(
      title: l.adminNavMediaDownloads,
      subtitle: l.adminMediaDownloadsNote,
      child: AsyncView<List<MediaDownloadRow>>(
        value: ref.watch(adminMediaDownloadsProvider),
        data: (rows) => AdminTable<MediaDownloadRow>(
          rows: rows,
          searchText: (r) => '${r.userName} ${r.postId} ${groups[r.groupId]?.name ?? ''}',
          columns: [
            AdminColumn(
              l.adminColWhen,
              (r) => Text(f.dateTime(r.at), key: Key('dl-row-${r.postId}-${r.userId}')),
              flex: 2,
              sortKey: (r) => r.at,
            ),
            AdminColumn(l.adminColUser, (r) => Text(r.userName), flex: 2, sortKey: (r) => r.userName),
            AdminColumn(l.adminColPost, (r) => Text('${r.postId} · ${r.mediaType}'), flex: 2),
            AdminColumn(l.adminColGroups, (r) => Text(groups[r.groupId]?.name ?? r.groupId ?? '—'), flex: 2),
          ],
        ),
      ),
    );
  }
}
