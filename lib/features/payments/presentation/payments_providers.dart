import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/payment.dart';

final myPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(paymentsRepositoryProvider).watchMyPayments();
});

final groupPaymentsProvider = StreamProvider.autoDispose.family<List<Payment>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(paymentsRepositoryProvider).watchGroupPayments(groupId);
});

final groupPlansProvider = StreamProvider.autoDispose.family<List<PaymentPlan>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(paymentsRepositoryProvider).watchPlans(groupId);
});

final smsLogProvider = StreamProvider.autoDispose<List<SmsLogEntry>>(
  (ref) => ref.watch(paymentsRepositoryProvider).watchSmsLog(),
);

/// Sum of pending amounts.
num pendingTotal(Iterable<Payment> ps) =>
    ps.where((p) => p.status == PaymentStatus.pending).fold<num>(0, (s, p) => s + p.amount);
