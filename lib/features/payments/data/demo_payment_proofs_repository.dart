import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/domain/app_user.dart';
import '../../demo/data/demo_backend.dart';
import '../../groups/domain/group.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/payment.dart';
import '../domain/payment_proof.dart';

/// Demo stand-in for `submitPaymentProof` / `reviewPaymentProof` /
/// `getReceiptUrl`. The parent's claim never changes the authoritative
/// status; decisions are serialized (a second decision fails) like the
/// server transaction.
class DemoPaymentProofsRepository implements PaymentProofsRepository {
  DemoPaymentProofsRepository(this.db);

  final DemoBackend db;

  Payment _payment(String id) => db.payments[id] ?? (throw const NotFoundException('payment'));

  List<String> _reviewers(Group g) => {
    ...g.paymentManagerIds.where((id) => g.coachIds.contains(id) && (db.users[id]?.isApprovedCoach ?? false)),
    ...db.users.values.where((u) => u.administersClub(g.clubId) && !u.isPlatformAdmin).map((u) => u.id),
  }.toList();

  void _event(PaymentProof p, String action, {String? reason}) {
    final me = db.me;
    db.paymentEvents.add(
      PaymentVerificationEvent(
        id: db.newId('pev'),
        paymentId: p.paymentId,
        proofId: p.id,
        action: PaymentVerificationEvent.actionFrom(action),
        actorId: me.id,
        actorName: me.fullName,
        at: db.clock(),
        reason: reason,
      ),
    );
  }

  @override
  Future<PaymentProof> submit(PaymentProofDraft d, {void Function(double progress)? onProgress}) async {
    db.requireOnline();
    final me = db.me;
    final pay = _payment(d.paymentId);
    if (!me.isParent || pay.parentId != me.id) throw const PermissionDeniedException('payment');
    final errors = PaymentProofDraft.validate(d, now: db.clock());
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    if (pay.status != PaymentStatus.pending) throw const ValidationException('paymentClosed');
    final open = db.paymentProofs.values.any((p) => p.paymentId == pay.id && p.status.isOpen);
    if (open) throw const ValidationException('proofExists');
    db.rateLimit('proof', 10);
    // Simulated resumable upload with progress.
    for (final step in [0.25, 0.5, 0.75, 1.0]) {
      onProgress?.call(step);
      await Future<void>.delayed(Duration.zero);
    }
    final id = db.newId('proof');
    final path = 'receipts/${me.id}/$id/${d.receipt.fileName}';
    db.receiptFiles[path] = Uint8List.fromList(d.receipt.bytes);
    final resubmission = db.paymentProofs.values.any((p) => p.paymentId == pay.id && p.status == ProofStatus.rejected);
    for (final old
        in db.paymentProofs.values.where((p) => p.paymentId == pay.id && p.status == ProofStatus.rejected).toList()) {
      db.paymentProofs[old.id] = old.decide(
        ProofStatus.superseded,
        by: me.id,
        at: db.clock(),
        reason: old.rejectionReason,
      );
    }
    final g = db.requireGroup(pay.groupId);
    final proof = PaymentProof(
      id: id,
      paymentId: pay.id,
      groupId: pay.groupId,
      clubId: g.clubId,
      childId: pay.childId,
      parentId: me.id,
      paidOn: d.paidOn,
      reference: (d.reference ?? '').trim().isEmpty ? null : d.reference!.trim(),
      note: (d.note ?? '').trim().isEmpty ? null : d.note!.trim(),
      receiptPath: path,
      receiptMime: d.receipt.mimeType,
      receiptSize: d.receipt.bytes.length,
      submittedAt: db.clock(),
    );
    db.paymentProofs[id] = proof;
    db.payments[pay.id] = pay.copyWith(
      verification: PaymentVerification(state: VerificationState.proofSubmitted, proofId: id, updatedAt: db.clock()),
    );
    _event(proof, resubmission ? 'resubmitted' : 'submitted');
    db.auditLog(
      resubmission ? 'payment.proofResubmitted' : 'payment.proofSubmitted',
      'payment',
      pay.id,
      clubId: g.clubId,
    );
    final child = db.children[pay.childId];
    for (final r in _reviewers(g)) {
      db.notifyUser(
        r,
        NotificationType.paymentProofSubmitted,
        route: '/payments/review',
        args: {'child': child?.firstName ?? '', 'amount': '${pay.amount} ₾', 'group': g.name},
        groupId: g.id,
        dedupeKey: 'proof:$id:submitted',
      );
    }
    db.commit();
    return proof;
  }

  bool _canSeeProof(AppUser me, PaymentProof p) {
    final g = db.groups[p.groupId];
    return p.parentId == me.id || (g != null && AccessPolicy.canVerifyPayments(me, g));
  }

  @override
  Stream<List<PaymentProof>> watchForPayment(String paymentId) => db.watch(() {
    final me = db.me;
    return db.paymentProofs.values.where((p) => p.paymentId == paymentId && _canSeeProof(me, p)).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  });

  @override
  Stream<List<PaymentProof>> watchReviewQueue({String? groupId}) => db.watch(() {
    final me = db.me;
    return db.paymentProofs.values.where((p) {
      if (!p.status.isOpen || (groupId != null && p.groupId != groupId)) return false;
      final g = db.groups[p.groupId];
      return g != null && AccessPolicy.canVerifyPayments(me, g);
    }).toList()..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  });

  PaymentProof _reviewable(String proofId) {
    final p = db.paymentProofs[proofId] ?? (throw const NotFoundException('proof'));
    final g = db.requireGroup(p.groupId);
    if (!AccessPolicy.canVerifyPayments(db.me, g)) throw const PermissionDeniedException('payments');
    return p;
  }

  @override
  Future<void> startReview(String proofId) async {
    db.requireOnline();
    final p = _reviewable(proofId);
    if (p.status != ProofStatus.submitted) return;
    db.paymentProofs[proofId] = PaymentProof.fromMap(proofId, {..._map(p), 'status': 'under_review'});
    final pay = _payment(p.paymentId);
    db.payments[pay.id] = pay.copyWith(
      verification: PaymentVerification(state: VerificationState.underReview, proofId: proofId, updatedAt: db.clock()),
    );
    _event(p, 'review_started');
    db.commit();
  }

  @override
  Future<void> review(String proofId, {required bool approve, String? reason}) async {
    db.requireOnline();
    final me = db.me;
    final p = _reviewable(proofId);
    // Transaction equivalent: only an open proof can be decided once.
    if (!p.status.isOpen) throw const ValidationException('proofClosed');
    final r = (reason ?? '').trim();
    if (!approve && r.length < 5) throw const ValidationException('reasonRequired');
    final pay = _payment(p.paymentId);
    if (pay.status != PaymentStatus.pending) throw const ValidationException('paymentClosed');
    final g = db.requireGroup(p.groupId);
    final now = db.clock();
    db.paymentProofs[proofId] = p.decide(
      approve ? ProofStatus.approved : ProofStatus.rejected,
      by: me.id,
      byName: me.fullName,
      at: now,
      reason: approve ? null : r,
    );
    if (approve) {
      db.payments[pay.id] = pay.copyWith(
        status: PaymentStatus.paid,
        paidAt: p.paidOn,
        verifiedBy: me.id,
        verifiedAt: now,
        verification: PaymentVerification(proofId: proofId, updatedAt: now),
      );
      db.paymentAudit.add(
        PaymentAuditEntry(
          id: db.newId('paud'),
          paymentId: pay.id,
          groupId: pay.groupId,
          from: pay.status,
          to: PaymentStatus.paid,
          actorId: me.id,
          actorName: me.fullName,
          at: now,
          reason: 'proof $proofId',
        ),
      );
    } else {
      db.payments[pay.id] = pay.copyWith(
        verification: PaymentVerification(
          state: VerificationState.rejected,
          proofId: proofId,
          rejectionReason: r,
          updatedAt: now,
        ),
      );
    }
    _event(p, approve ? 'approved' : 'rejected', reason: approve ? null : r);
    db.auditLog(
      approve ? 'payment.proofApproved' : 'payment.proofRejected',
      'payment',
      pay.id,
      clubId: g.clubId,
      details: {if (!approve) 'reason': r},
    );
    final child = db.children[pay.childId];
    db.notifyUser(
      p.parentId,
      approve ? NotificationType.paymentProofApproved : NotificationType.paymentProofRejected,
      route: '/payments',
      args: {'child': child?.firstName ?? '', 'amount': '${pay.amount} ₾', 'reason': r},
      childId: pay.childId,
      groupId: g.id,
      dedupeKey: 'proof:$proofId:${approve ? 'approved' : 'rejected'}',
    );
    db.commit();
  }

  @override
  Future<ReceiptAccess> openReceipt(String proofId) async {
    final p = db.paymentProofs[proofId] ?? (throw const NotFoundException('proof'));
    final me = db.me;
    if (!_canSeeProof(me, p)) throw const PermissionDeniedException('receipt');
    if (me.id != p.parentId) {
      _event(p, 'viewed');
      db.auditLog('receipt.view', 'paymentProof', proofId, clubId: p.clubId);
      db.commit();
    }
    return ReceiptAccess(mimeType: p.receiptMime, bytes: db.receiptFiles[p.receiptPath]);
  }

  @override
  Stream<List<PaymentVerificationEvent>> watchEvents(String paymentId) => db.watch(() {
    final me = db.me;
    final pay = _payment(paymentId);
    final g = db.groups[pay.groupId];
    if (pay.parentId != me.id && (g == null || !AccessPolicy.canVerifyPayments(me, g))) {
      throw const PermissionDeniedException();
    }
    return db.paymentEvents.where((e) => e.paymentId == paymentId).toList()..sort((a, b) => b.at.compareTo(a.at));
  });

  static Map<String, dynamic> _map(PaymentProof p) => {
    'paymentId': p.paymentId,
    'groupId': p.groupId,
    'clubId': p.clubId,
    'childId': p.childId,
    'parentId': p.parentId,
    'paidOn': p.paidOn,
    'reference': p.reference,
    'note': p.note,
    'receiptPath': p.receiptPath,
    'receiptMime': p.receiptMime,
    'receiptSize': p.receiptSize,
    'status': p.status.wire,
    'submittedAt': p.submittedAt,
  };
}
