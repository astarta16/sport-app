import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../attendance/domain/attendance.dart';
import '../../attendance/presentation/attendance_providers.dart';
import '../../groups/domain/group.dart';
import '../../trainings/domain/training.dart';
import '../../trainings/presentation/trainings_providers.dart';
import '../data/export_service.dart';
import '../domain/roster.dart';
import 'student_roster_screen.dart';

enum ExportKind { roster, trainingSheet, monthly }

/// Builds localized export tables from the coach's own data.
class RosterExports {
  RosterExports._();

  static ExportTable roster(
    AppLocalizations l,
    Fmt f,
    Group g,
    List<RosterEntry> rows,
    DateTime now, {
    required bool compliance,
  }) => ExportTable(
    title: l.exportRoster,
    subtitle: g.name,
    headers: [l.exportColStudent, l.exportColAge, l.exportColGroup, l.exportColRate, if (compliance) l.exportColCert],
    rows: [
      for (final r in rows)
        [
          r.child.fullName,
          '${r.age}',
          r.groupName,
          r.attendanceRate == null ? '—' : '${(r.attendanceRate! * 100).round()}%',
          if (compliance) _cert(l, r),
        ],
    ],
    footer: l.exportGenerated(f.dateTime(now)),
    confidential: l.exportConfidential,
    pageLabel: (n) => l.exportPage(n),
  );

  static ExportTable trainingSheet(
    AppLocalizations l,
    Fmt f,
    Group g,
    Training t,
    List<RosterEntry> rows,
    List<AttendanceRecord> records,
    DateTime now, {
    required String Function(AttendanceStatus?) label,
    required bool compliance,
  }) => ExportTable(
    title: l.exportTrainingSheet,
    subtitle: '${g.name} · ${f.weekdayDayMonth(t.startAt)} ${f.time(t.startAt)}',
    headers: [
      l.exportColStudent,
      l.exportColGroup,
      l.exportColDate,
      l.exportColStatus,
      if (compliance) l.exportColCert,
    ],
    rows: [
      for (final r in rows)
        [
          r.child.fullName,
          r.groupName,
          f.numericDate(t.startAt),
          label(records.where((a) => a.childId == r.child.id).firstOrNull?.status),
          if (compliance) _cert(l, r),
        ],
    ],
    footer: l.exportGenerated(f.dateTime(now)),
    confidential: l.exportConfidential,
    pageLabel: (n) => l.exportPage(n),
  );

  static ExportTable monthly(
    AppLocalizations l,
    Fmt f,
    Group g,
    DateTime month,
    List<RosterEntry> rows,
    List<AttendanceRecord> records,
    Map<String, DateTime> starts,
    DateTime now, {
    required String Function(AttendanceStatus?) label,
  }) {
    final inMonth = records.where((a) {
      final s = starts[a.trainingId];
      return s != null && s.year == month.year && s.month == month.month;
    }).toList();
    int count(String childId, AttendanceStatus s) => inMonth.where((a) => a.childId == childId && a.status == s).length;
    return ExportTable(
      title: l.exportMonthly,
      subtitle: '${g.name} · ${f.monthYear(month)}',
      headers: [
        l.exportColStudent,
        l.exportColGroup,
        label(AttendanceStatus.present),
        label(AttendanceStatus.absent),
        label(AttendanceStatus.excused),
        l.exportColRate,
      ],
      rows: [
        for (final r in rows)
          () {
            final p = count(r.child.id, AttendanceStatus.present);
            final a = count(r.child.id, AttendanceStatus.absent);
            final e = count(r.child.id, AttendanceStatus.excused);
            final total = p + a + e;
            return [
              r.child.fullName,
              r.groupName,
              '$p',
              '$a',
              '$e',
              total == 0 ? '—' : '${(p * 100 / total).round()}%',
            ];
          }(),
      ],
      footer: l.exportGenerated(f.dateTime(now)),
      confidential: l.exportConfidential,
      pageLabel: (n) => l.exportPage(n),
    );
  }

  static String _cert(AppLocalizations l, RosterEntry r) => switch (r.certStatus.name) {
    'valid' => l.adminColValid,
    'expiring' => l.adminColExpiring,
    'expired' => l.adminColExpired,
    _ => l.adminColMissing,
  };
}

/// Export flow: choose kind/format/options → personal-data warning →
/// generate → system share/save sheet (works on mobile and web).
Future<void> showExportSheet(BuildContext context, WidgetRef ref, {required Group group}) async {
  await showAdaptiveSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExportForm(group: group),
  );
}

class _ExportForm extends ConsumerStatefulWidget {
  const _ExportForm({required this.group});

  final Group group;

  @override
  ConsumerState<_ExportForm> createState() => _ExportFormState();
}

class _ExportFormState extends ConsumerState<_ExportForm> {
  ExportKind _kind = ExportKind.roster;
  ExportFormat _format = ExportFormat.pdf;
  bool _compliance = false;
  String? _trainingId;
  late DateTime _month;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _month = DateTime(now.year, now.month);
  }

  Future<void> _export() async {
    final l = context.l10n;
    final f = Fmt.of(context);
    final ok = await confirmDialog(
      context,
      title: l.exportTitle,
      message: l.exportWarning,
      confirmLabel: l.exportConfirm,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final g = widget.group;
      final now = ref.read(clockProvider)();
      final rows = const RosterQuery().apply(ref.read(rosterProvider(g)).value ?? const []);
      final records = ref.read(attendanceForGroupProvider(g.id)).value ?? const <AttendanceRecord>[];
      final starts = ref.read(trainingStartsProvider);
      String label(AttendanceStatus? s) => attendanceLabel(context, s);
      final trainings = ref.read(myTrainingsProvider).value ?? const <Training>[];
      final ExportTable table;
      final String kindName;
      switch (_kind) {
        case ExportKind.roster:
          table = RosterExports.roster(l, f, g, rows, now, compliance: _compliance);
          kindName = 'roster';
        case ExportKind.trainingSheet:
          final t = trainings.where((x) => x.id == _trainingId).firstOrNull ?? (throw StateError('training'));
          table = RosterExports.trainingSheet(
            l,
            f,
            g,
            t,
            rows,
            records.where((a) => a.trainingId == t.id).toList(),
            now,
            label: label,
            compliance: _compliance,
          );
          kindName = 'attendance';
        case ExportKind.monthly:
          table = RosterExports.monthly(l, f, g, _month, rows, records, starts, now, label: label);
          kindName = 'monthly';
      }
      final bytes = _format == ExportFormat.pdf ? await ExportService.pdf(table) : ExportService.csv(table);
      final name = ExportService.fileName(kindName, g.id, now, _format);
      final mime = _format == ExportFormat.pdf ? 'application/pdf' : 'text/csv';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: name, mimeType: mime)],
          fileNameOverrides: [name],
          title: table.title,
        ),
      );
      if (mounted) showAppSnack(context, l.exportReady(name));
      ref.read(lastExportProvider.notifier).state = (name: name, bytes: bytes.length);
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider)();
    final trainings =
        (ref.watch(myTrainingsProvider).value ?? const <Training>[])
            .where(
              (t) =>
                  t.groupId == widget.group.id &&
                  t.status != TrainingStatus.cancelled &&
                  t.startAt.isBefore(now.add(const Duration(days: 7))),
            )
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));
    _trainingId ??= trainings.firstOrNull?.id;
    final months = [for (var i = 0; i < 6; i++) DateTime(now.year, now.month - i)];
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          key: const Key('export-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l.exportTitle} · ${widget.group.name}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            RadioGroup<ExportKind>(
              groupValue: _kind,
              onChanged: (v) => setState(() => _kind = v ?? _kind),
              child: Column(
                children: [
                  RadioListTile(key: const Key('export-roster'), value: ExportKind.roster, title: Text(l.exportRoster)),
                  RadioListTile(
                    key: const Key('export-sheet-kind'),
                    value: ExportKind.trainingSheet,
                    title: Text(l.exportTrainingSheet),
                  ),
                  RadioListTile(
                    key: const Key('export-monthly'),
                    value: ExportKind.monthly,
                    title: Text(l.exportMonthly),
                  ),
                ],
              ),
            ),
            if (_kind == ExportKind.trainingSheet)
              DropdownButtonFormField<String>(
                key: const Key('export-training'),
                initialValue: _trainingId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.exportChooseTraining),
                items: [
                  for (final t in trainings.take(30))
                    DropdownMenuItem(value: t.id, child: Text('${f.weekdayDayMonth(t.startAt)} ${f.time(t.startAt)}')),
                ],
                onChanged: (v) => setState(() => _trainingId = v),
              ),
            if (_kind == ExportKind.monthly)
              DropdownButtonFormField<DateTime>(
                key: const Key('export-month'),
                initialValue: _month,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.exportChooseMonth),
                items: [for (final m in months) DropdownMenuItem(value: m, child: Text(f.monthYear(m)))],
                onChanged: (v) => setState(() => _month = v ?? _month),
              ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(value: ExportFormat.pdf, label: Text('PDF'), icon: Icon(Icons.picture_as_pdf_rounded)),
                ButtonSegment(value: ExportFormat.csv, label: Text('CSV'), icon: Icon(Icons.table_chart_rounded)),
              ],
              selected: {_format},
              onSelectionChanged: (s) => setState(() => _format = s.first),
            ),
            if (_kind != ExportKind.monthly)
              CheckboxListTile(
                key: const Key('export-compliance'),
                contentPadding: EdgeInsets.zero,
                value: _compliance,
                onChanged: (v) => setState(() => _compliance = v ?? false),
                title: Text(l.exportIncludeCompliance),
              ),
            DemoBanner(text: l.exportWarning),
            const SizedBox(height: AppSpacing.sm),
            LoadingButton(
              key: const Key('export-go'),
              label: l.exportTitle,
              icon: Icons.ios_share_rounded,
              loading: _busy,
              onPressed: _kind == ExportKind.trainingSheet && _trainingId == null ? null : _export,
            ),
          ],
        ),
      ),
    );
  }
}

/// Last export (name + size), used by tests and the snackbar.
final lastExportProvider = StateProvider<({String name, int bytes})?>((_) => null);
