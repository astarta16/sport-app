import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/payment.dart';
import '../domain/payment_reminders.dart';
import '../domain/payments_repository.dart';

/// Payments are created server-side (scheduled `generateRecurringPayments`)
/// or by admins; coaches may only change `status`/`paidAt` (rules). SMS
/// reminders run in the scheduled `sendPaymentReminders` function.
class FirebasePaymentsRepository implements PaymentsRepository {
  FirebasePaymentsRepository(this.auth, this.db);

  final FirebaseAuth auth;
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('payments');

  List<Payment> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => Payment.fromMap(d.id, d.data())).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

  @override
  Stream<List<Payment>> watchMyPayments() async* {
    final me = await currentRole(auth, db);
    if (me.role == 'parent') {
      yield* _col.where('parentId', isEqualTo: me.uid).snapshots().map(_map).mapFirebaseErrors();
      return;
    }
    final groups = await db.collection('groups').where('coachIds', arrayContains: me.uid).get();
    final ids = groups.docs.map((d) => d.id).take(30).toList();
    if (ids.isEmpty) {
      yield const [];
      return;
    }
    yield* _col.where('groupId', whereIn: ids).snapshots().map(_map).mapFirebaseErrors();
  }

  @override
  Stream<List<Payment>> watchGroupPayments(String groupId) =>
      _col.where('groupId', isEqualTo: groupId).snapshots().map(_map).mapFirebaseErrors();

  @override
  Future<void> setStatus(String paymentId, PaymentStatus status) => guardFirebase(
    () => _col.doc(paymentId).update({
      'status': status.name,
      'paidAt': status == PaymentStatus.paid ? FieldValue.serverTimestamp() : null,
    }),
  );

  /// One-off charges are an admin/back-office operation in production.
  @override
  Future<int> chargeGroup({required String groupId, required num amount, required DateTime dueDate}) =>
      throw const PermissionDeniedException('chargeGroup is admin-only in production');

  @override
  Stream<List<PaymentPlan>> watchPlans(String groupId) => db
      .collection('paymentPlans')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) => s.docs.map((d) => PaymentPlan.fromMap(d.id, d.data())).toList())
      .mapFirebaseErrors();

  @override
  Future<PaymentPlan> createPlan({required String groupId, required num amount, required int dayOfMonth}) =>
      guardFirebase(() async {
        if (amount <= 0) throw const ValidationException('amountPositive');
        if (dayOfMonth < 1 || dayOfMonth > 28) throw const ValidationException('dayOfMonth');
        final group = (await db.collection('groups').doc(groupId).get()).data() ?? (throw const NotFoundException());
        final ref = db.collection('paymentPlans').doc();
        final plan = PaymentPlan(
          id: ref.id,
          groupId: groupId,
          sportId: group['sportId'] as String,
          amount: amount,
          dayOfMonth: dayOfMonth,
          createdBy: requireUid(auth),
        );
        await ref.set(plan.toMap());
        return plan;
      });

  /// Generation runs monthly in the `generateRecurringPayments` function.
  @override
  Future<int> generateRecurring(String planId, {required int year, required int month}) =>
      throw const PermissionDeniedException('generated server-side');

  @override
  Future<ReminderRunReport> runReminderJob(DateTime now) =>
      throw const PermissionDeniedException('reminders run server-side at 10:00 Asia/Tbilisi');

  /// `smsLog` is admin-only.
  @override
  Stream<List<SmsLogEntry>> watchSmsLog() => Stream.value(const []);
}
