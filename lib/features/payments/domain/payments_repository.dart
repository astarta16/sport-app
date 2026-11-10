import 'payment.dart';
import 'payment_reminders.dart';

abstract interface class PaymentsRepository {
  Stream<List<Payment>> watchMyPayments();
  Stream<List<Payment>> watchGroupPayments(String groupId);
  Future<void> setStatus(String paymentId, PaymentStatus status);

  /// One-off charge: creates a payment for every child in the group.
  Future<int> chargeGroup({required String groupId, required num amount, required DateTime dueDate});
  Stream<List<PaymentPlan>> watchPlans(String groupId);
  Future<PaymentPlan> createPlan({required String groupId, required num amount, required int dayOfMonth});

  /// Idempotent monthly generation for a plan. Returns number created.
  Future<int> generateRecurring(String planId, {required int year, required int month});

  /// Server-side in production (scheduled function). Demo runs it locally
  /// with the mock SMS provider.
  Future<ReminderRunReport> runReminderJob(DateTime now);
  Stream<List<SmsLogEntry>> watchSmsLog();
}
