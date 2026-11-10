import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/report.dart';

class DemoModerationRepository implements ModerationRepository {
  DemoModerationRepository(this.db);

  final DemoBackend db;

  @override
  Future<void> report({
    required ReportTarget targetType,
    required String targetPath,
    required String groupId,
    required ReportReason reason,
    String? note,
  }) async {
    db.requireOnline();
    final me = db.me;
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canReport(me, g)) throw const PermissionDeniedException('report');
    db.rateLimit('report', 20);
    final dup = db.reports.values.any((r) => r.reporterId == me.id && r.targetPath == targetPath && r.isOpen);
    if (dup) throw const ValidationException('alreadyReported');
    if ((note ?? '').length > 300) throw const ValidationException('validationTooLong');
    final id = db.newId('rep');
    db.reports[id] = ContentReport(
      id: id,
      targetType: targetType,
      targetPath: targetPath,
      groupId: groupId,
      clubId: g.clubId,
      reason: reason,
      note: (note ?? '').trim().isEmpty ? null : note!.trim(),
      reporterId: me.id,
      createdAt: db.clock(),
      preview: DemoModeration.preview(db, targetType, targetPath),
    );
    db.commit();
  }
}

/// Server-side moderation helpers shared by the demo admin repository.
class DemoModeration {
  DemoModeration._();

  static String preview(DemoBackend db, ReportTarget type, String path) {
    switch (type) {
      case ReportTarget.chatMessage:
        final parts = path.split('/'); // chats/{g}/messages/{m}
        if (parts.length < 4) return '';
        final m = db.messages[parts[1]]?.where((m) => m.id == parts[3]).firstOrNull;
        final t = m?.text ?? '';
        return t.length > 200 ? '${t.substring(0, 200)}…' : t;
      case ReportTarget.mediaPost:
        return db.mediaPosts[path.split('/').last]?.caption ?? '';
      case ReportTarget.trainingPhoto:
        return '';
    }
  }

  /// Applies the decision to the reported content.
  static void apply(DemoBackend db, ContentReport r, ModerationDecision d) {
    final hide = d == ModerationDecision.hidden;
    switch (r.targetType) {
      case ReportTarget.chatMessage:
        final parts = r.targetPath.split('/');
        final list = db.messages[parts[1]];
        final i = list?.indexWhere((m) => m.id == parts[3]) ?? -1;
        if (i >= 0) list![i] = list[i].copyWith(hidden: hide);
      case ReportTarget.mediaPost:
        final id = r.targetPath.split('/').last;
        final p = db.mediaPosts[id];
        if (p != null) db.mediaPosts[id] = p.copyWith(hidden: hide);
      case ReportTarget.trainingPhoto:
        // trainings/{id}#{photoRef}
        final hash = r.targetPath.indexOf('#');
        if (hash < 0) return;
        final tid = r.targetPath.substring('trainings/'.length, hash);
        final ref = r.targetPath.substring(hash + 1);
        final t = db.trainings[tid];
        if (t != null && hide) db.trainings[tid] = t.copyWith(photoUrls: t.photoUrls.where((p) => p != ref).toList());
    }
  }
}
