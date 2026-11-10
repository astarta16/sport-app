import '../../../core/utils/dates.dart';
import '../../trainings/domain/training.dart';
import 'payment.dart';

/// Verification workflow next to the authoritative payment status (v1.3).
/// A parent's claim never marks a payment paid; only a reviewer does.
enum VerificationState {
  none,
  proofSubmitted,
  underReview,
  rejected;

  static VerificationState fromName(String? n) => switch (n) {
    'proof_submitted' => proofSubmitted,
    'under_review' => underReview,
    'rejected' => rejected,
    _ => none,
  };

  String get wire => switch (this) {
    none => 'none',
    proofSubmitted => 'proof_submitted',
    underReview => 'under_review',
    rejected => 'rejected',
  };
}

class PaymentVerification {
  const PaymentVerification({this.state = VerificationState.none, this.proofId, this.rejectionReason, this.updatedAt});

  final VerificationState state;
  final String? proofId;
  final String? rejectionReason;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'state': state.wire,
    'proofId': proofId,
    'rejectionReason': rejectionReason,
    'updatedAt': updatedAt,
  };

  factory PaymentVerification.fromMap(Object? m) {
    if (m is! Map) return const PaymentVerification();
    return PaymentVerification(
      state: VerificationState.fromName(m['state'] as String?),
      proofId: m['proofId'] as String?,
      rejectionReason: m['rejectionReason'] as String?,
      updatedAt: readDateOrNull(m['updatedAt']),
    );
  }
}

/// What the UI shows: pending | proof_submitted | under_review | paid |
/// rejected | cancelled.
enum PaymentDisplayState { pending, proofSubmitted, underReview, paid, rejected, cancelled }

PaymentDisplayState displayStateOf(Payment p) => switch (p.status) {
  PaymentStatus.paid => PaymentDisplayState.paid,
  PaymentStatus.cancelled => PaymentDisplayState.cancelled,
  PaymentStatus.pending => switch (p.verification.state) {
    VerificationState.proofSubmitted => PaymentDisplayState.proofSubmitted,
    VerificationState.underReview => PaymentDisplayState.underReview,
    VerificationState.rejected => PaymentDisplayState.rejected,
    VerificationState.none => PaymentDisplayState.pending,
  },
};

enum ProofStatus {
  submitted,
  underReview,
  approved,
  rejected,
  superseded;

  static ProofStatus fromName(String? n) => switch (n) {
    'under_review' => underReview,
    'approved' => approved,
    'rejected' => rejected,
    'superseded' => superseded,
    _ => submitted,
  };

  String get wire => switch (this) {
    underReview => 'under_review',
    _ => name,
  };

  bool get isOpen => this == submitted || this == underReview;
}

class PaymentProof {
  const PaymentProof({
    required this.id,
    required this.paymentId,
    required this.groupId,
    required this.clubId,
    required this.childId,
    required this.parentId,
    required this.paidOn,
    required this.receiptPath,
    required this.receiptMime,
    required this.receiptSize,
    required this.submittedAt,
    this.reference,
    this.note,
    this.status = ProofStatus.submitted,
    this.decidedBy,
    this.decidedByName,
    this.decidedAt,
    this.rejectionReason,
  });

  final String id;
  final String paymentId;
  final String groupId;
  final String clubId;
  final String childId;
  final String parentId;
  final DateTime paidOn;
  final String? reference;
  final String? note;

  /// Private `receipts/{parentId}/{proofId}/{file}` — never a public URL.
  final String receiptPath;
  final String receiptMime;
  final int receiptSize;
  final ProofStatus status;
  final DateTime submittedAt;
  final String? decidedBy;
  final String? decidedByName;
  final DateTime? decidedAt;
  final String? rejectionReason;

  static const maxReceiptBytes = 10 * 1024 * 1024;
  static const allowedMime = {'image/jpeg', 'image/png', 'application/pdf'};

  PaymentProof decide(ProofStatus s, {required String by, String? byName, required DateTime at, String? reason}) =>
      PaymentProof(
        id: id,
        paymentId: paymentId,
        groupId: groupId,
        clubId: clubId,
        childId: childId,
        parentId: parentId,
        paidOn: paidOn,
        reference: reference,
        note: note,
        receiptPath: receiptPath,
        receiptMime: receiptMime,
        receiptSize: receiptSize,
        submittedAt: submittedAt,
        status: s,
        decidedBy: by,
        decidedByName: byName,
        decidedAt: at,
        rejectionReason: reason,
      );

  factory PaymentProof.fromMap(String id, Map<String, dynamic> m) => PaymentProof(
    id: id,
    paymentId: m['paymentId'] as String? ?? '',
    groupId: m['groupId'] as String? ?? '',
    clubId: m['clubId'] as String? ?? '',
    childId: m['childId'] as String? ?? '',
    parentId: m['parentId'] as String? ?? '',
    paidOn: m['paidOn'] is String ? DateTime.parse(m['paidOn'] as String) : readDate(m['paidOn']),
    reference: m['reference'] as String?,
    note: m['note'] as String?,
    receiptPath: m['receiptPath'] as String? ?? '',
    receiptMime: m['receiptMime'] as String? ?? '',
    receiptSize: (m['receiptSize'] as num?)?.toInt() ?? 0,
    status: ProofStatus.fromName(m['status'] as String?),
    submittedAt: readDateOrNull(m['submittedAt']) ?? DateTime.now(),
    decidedBy: m['decidedBy'] as String?,
    decidedByName: m['decidedByName'] as String?,
    decidedAt: readDateOrNull(m['decidedAt']),
    rejectionReason: m['rejectionReason'] as String?,
  );
}

class PaymentProofDraft {
  const PaymentProofDraft({
    required this.paymentId,
    required this.paidOn,
    required this.receipt,
    this.reference,
    this.note,
  });

  final String paymentId;
  final DateTime paidOn;
  final PhotoUpload receipt;
  final String? reference;
  final String? note;

  static List<String> validate(PaymentProofDraft d, {required DateTime now}) => [
    if (d.receipt.bytes.isEmpty) 'receiptRequired',
    if (d.receipt.bytes.isNotEmpty && !PaymentProof.allowedMime.contains(d.receipt.mimeType)) 'fileType',
    if (d.receipt.bytes.length > PaymentProof.maxReceiptBytes) 'fileTooLarge',
    if (d.paidOn.isAfter(now.add(const Duration(days: 1)))) 'dateFuture',
    if ((d.reference ?? '').length > 60) 'validationTooLong',
    if ((d.note ?? '').length > 300) 'validationTooLong',
  ];
}

enum VerificationAction { submitted, resubmitted, reviewStarted, approved, rejected, viewed }

class PaymentVerificationEvent {
  const PaymentVerificationEvent({
    required this.id,
    required this.paymentId,
    required this.proofId,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.at,
    this.reason,
  });

  final String id;
  final String paymentId;
  final String proofId;
  final VerificationAction action;
  final String actorId;
  final String actorName;
  final DateTime at;
  final String? reason;

  static VerificationAction actionFrom(String? n) => switch (n) {
    'resubmitted' => VerificationAction.resubmitted,
    'review_started' => VerificationAction.reviewStarted,
    'approved' => VerificationAction.approved,
    'rejected' => VerificationAction.rejected,
    'viewed' => VerificationAction.viewed,
    _ => VerificationAction.submitted,
  };

  factory PaymentVerificationEvent.fromMap(String id, Map<String, dynamic> m) => PaymentVerificationEvent(
    id: id,
    paymentId: m['paymentId'] as String? ?? '',
    proofId: m['proofId'] as String? ?? '',
    action: actionFrom(m['action'] as String?),
    actorId: m['actorId'] as String? ?? '',
    actorName: m['actorName'] as String? ?? '',
    at: readDate(m['at']),
    reason: m['reason'] as String?,
  );
}

/// Receipt bytes / short-lived URL for authorized viewers.
class ReceiptAccess {
  const ReceiptAccess({required this.mimeType, this.url, this.bytes});

  final String mimeType;
  final Uri? url;
  final List<int>? bytes;
}

abstract interface class PaymentProofsRepository {
  Future<PaymentProof> submit(PaymentProofDraft draft, {void Function(double progress)? onProgress});
  Stream<List<PaymentProof>> watchForPayment(String paymentId);

  /// Open proofs the signed-in reviewer may decide (payment managers / club admins).
  Stream<List<PaymentProof>> watchReviewQueue({String? groupId});
  Future<void> startReview(String proofId);
  Future<void> review(String proofId, {required bool approve, String? reason});
  Future<ReceiptAccess> openReceipt(String proofId);
  Stream<List<PaymentVerificationEvent>> watchEvents(String paymentId);
}
