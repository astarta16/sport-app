import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/admin/domain/admin_models.dart';
import '../widgets.dart';
import 'admin_providers.dart';

/// Append-only audit trail (server-written; nobody can edit it).
class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final audit = ref.watch(adminAuditProvider);
    final f = Fmt.of(context);
    return AdminSection(
      title: l.adminNavAudit,
      child: AsyncView<List<AuditEntry>>(
        value: audit,
        data: (list) {
          final prefixes = {for (final e in list) e.action.split('.').first}.toList()..sort();
          return AdminTable<AuditEntry>(
            rows: list,
            pageSize: 20,
            searchText: (e) => '${e.action} ${e.actorName} ${e.targetId} ${e.details.values.join(' ')}',
            filters: [
              (l.adminFilterAll, (_) => true),
              for (final p in prefixes) (p, (e) => e.action.startsWith('$p.')),
            ],
            columns: [
              AdminColumn(l.adminColWhen, (e) => Text(f.dateTime(e.at)), flex: 2, sortKey: (e) => e.at),
              AdminColumn(l.adminColActor, (e) => Text(e.actorName), flex: 2),
              AdminColumn(
                l.adminColAction,
                (e) => Text(
                  e.action,
                  key: Key('audit-${e.id}'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                flex: 2,
                sortKey: (e) => e.action,
              ),
              AdminColumn(
                l.adminColTarget,
                (e) => Text('${e.targetType}: ${e.targetId}', maxLines: 2, overflow: TextOverflow.ellipsis),
                flex: 3,
              ),
              AdminColumn(
                l.adminColDetails,
                (e) => Text(e.details.entries.map((x) => '${x.key}=${x.value}').join(', ')),
                flex: 3,
              ),
            ],
          );
        },
      ),
    );
  }
}
