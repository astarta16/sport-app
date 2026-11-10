import '../../../core/utils/dates.dart';

enum ReportTarget {
  chatMessage,
  mediaPost,
  trainingPhoto;

  static ReportTarget fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => chatMessage);
}

enum ReportReason {
  inappropriate,
  privacy,
  spam,
  other;

  static ReportReason fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => other);
}

enum ReportStatus {
  open,
  resolved,
  dismissed;

  static ReportStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => open);
}

enum ModerationDecision {
  hidden,
  kept;

  static ModerationDecision? fromName(String? n) => switch (n) {
    'hidden' => hidden,
    'kept' => kept,
    _ => null,
  };
}

/// Content report in the moderation queue (v1.2).
class ContentReport {
  const ContentReport({
    required this.id,
    required this.targetType,
    required this.targetPath,
    required this.groupId,
    required this.clubId,
    required this.reason,
    required this.reporterId,
    required this.createdAt,
    this.note,
    this.status = ReportStatus.open,
    this.decision,
    this.decidedBy,
    this.decidedAt,
    this.preview = '',
  });

  final String id;
  final ReportTarget targetType;

  /// e.g. `chats/g1/messages/m5`, `mediaPosts/p1`, `trainings/t1#photo0`.
  final String targetPath;
  final String groupId;
  final String clubId;
  final ReportReason reason;
  final String? note;
  final String reporterId;
  final DateTime createdAt;
  final ReportStatus status;
  final ModerationDecision? decision;
  final String? decidedBy;
  final DateTime? decidedAt;

  /// Short text preview for the queue (message text / caption); no media.
  final String preview;

  bool get isOpen => status == ReportStatus.open;

  ContentReport decide(ModerationDecision d, String by, DateTime at) => ContentReport(
    id: id,
    targetType: targetType,
    targetPath: targetPath,
    groupId: groupId,
    clubId: clubId,
    reason: reason,
    note: note,
    reporterId: reporterId,
    createdAt: createdAt,
    status: d == ModerationDecision.hidden ? ReportStatus.resolved : ReportStatus.dismissed,
    decision: d,
    decidedBy: by,
    decidedAt: at,
    preview: preview,
  );

  factory ContentReport.fromMap(String id, Map<String, dynamic> m) => ContentReport(
    id: id,
    targetType: ReportTarget.fromName(m['targetType'] as String?),
    targetPath: m['targetPath'] as String? ?? '',
    groupId: m['groupId'] as String? ?? '',
    clubId: m['clubId'] as String? ?? '',
    reason: ReportReason.fromName(m['reason'] as String?),
    note: m['note'] as String?,
    reporterId: m['reporterId'] as String? ?? '',
    createdAt: readDate(m['createdAt']),
    status: ReportStatus.fromName(m['status'] as String?),
    decision: ModerationDecision.fromName(m['decision'] as String?),
    decidedBy: m['decidedBy'] as String?,
    decidedAt: readDateOrNull(m['decidedAt']),
    preview: m['preview'] as String? ?? '',
  );
}

abstract interface class ModerationRepository {
  /// Any member of the content's group may report it (rate-limited server-side).
  Future<void> report({
    required ReportTarget targetType,
    required String targetPath,
    required String groupId,
    required ReportReason reason,
    String? note,
  });
}
