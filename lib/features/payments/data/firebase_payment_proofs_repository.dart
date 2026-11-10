import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/payment_proof.dart';

/// Receipt goes to private Storage `receipts/{uid}/{proofId}/{file}` (resumable
/// upload with progress), then `submitPaymentProof` records it in a server
/// transaction. Decisions go through `reviewPaymentProof`; receipts are read
/// via the short-lived `getReceiptUrl`.
class FirebasePaymentProofsRepository implements PaymentProofsRepository {
  FirebasePaymentProofsRepository(this.auth, this.db, this.storage, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  final FirebaseFunctions functions;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('paymentProofs');

  List<PaymentProof> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => PaymentProof.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  @override
  Future<PaymentProof> submit(PaymentProofDraft d, {void Function(double progress)? onProgress}) =>
      guardFirebase(() async {
        final errors = PaymentProofDraft.validate(d, now: DateTime.now());
        if (errors.isNotEmpty) throw ValidationException(errors.first);
        final uid = requireUid(auth);
        final proofId = _col.doc().id;
        final path = 'receipts/$uid/$proofId/${d.receipt.fileName}';
        final task = storage
            .ref(path)
            .putData(Uint8ListX.from(d.receipt.bytes), SettableMetadata(contentType: d.receipt.mimeType));
        final sub = task.snapshotEvents.listen((s) {
          if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
        });
        try {
          await task;
        } finally {
          await sub.cancel();
        }
        final r = await callFunction(functions, 'submitPaymentProof', {
          'proofId': proofId,
          'paymentId': d.paymentId,
          'paidOn': d.paidOn.toIso8601String().substring(0, 10),
          'reference': d.reference,
          'note': d.note,
          'receiptPath': path,
          'receiptMime': d.receipt.mimeType,
          'receiptSize': d.receipt.bytes.length,
        });
        final id = r['proofId'] as String? ?? proofId;
        final snap = await _col.doc(id).get();
        return PaymentProof.fromMap(id, snap.data() ?? const {});
      });

  @override
  Stream<List<PaymentProof>> watchForPayment(String paymentId) {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    // Parents can only query their own proofs (rules); reviewers use the queue.
    return _col
        .where('paymentId', isEqualTo: paymentId)
        .where('parentId', isEqualTo: uid)
        .snapshots()
        .map(_map)
        .mapFirebaseErrors();
  }

  @override
  Stream<List<PaymentProof>> watchReviewQueue({String? groupId}) {
    var q = _col.where('status', whereIn: const ['submitted', 'under_review']);
    if (groupId != null) q = q.where('groupId', isEqualTo: groupId);
    return q.snapshots().map(_map).mapFirebaseErrors();
  }

  @override
  Future<void> startReview(String proofId) => callFunction(functions, 'startPaymentReview', {'proofId': proofId});

  @override
  Future<void> review(String proofId, {required bool approve, String? reason}) => callFunction(
    functions,
    'reviewPaymentProof',
    {'proofId': proofId, 'decision': approve ? 'approve' : 'reject', 'reason': reason},
  );

  @override
  Future<ReceiptAccess> openReceipt(String proofId) async {
    final r = await callFunction(functions, 'getReceiptUrl', {'proofId': proofId});
    return ReceiptAccess(mimeType: r['mimeType'] as String? ?? '', url: Uri.tryParse(r['url'] as String? ?? ''));
  }

  @override
  Stream<List<PaymentVerificationEvent>> watchEvents(String paymentId) => db
      .collection('paymentVerificationEvents')
      .where('paymentId', isEqualTo: paymentId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => PaymentVerificationEvent.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.at.compareTo(a.at)),
      )
      .mapFirebaseErrors();
}
