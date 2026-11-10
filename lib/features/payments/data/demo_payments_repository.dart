import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/payment.dart';
import '../domain/payment_reminders.dart';
import '../domain/payments_repository.dart';

class DemoPaymentsRepository implements PaymentsRepository {
  DemoPaymentsRepository(this.db, {SmsProvider? smsProvider}) : sms = smsProvider ?? MockSmsProvider();

  final DemoBackend db;

  /// Always a mock in demo mode — no real SMS can be sent.
  final SmsProvider sms;

  int _byDue(Payment a, Payment b) => b.dueDate.compareTo(a.dueDate);

  @override
  Stream<List<Payment>> watchMyPayments() => db.watch(() {
        final me = db.me;
        return db.payments.values.where((p) => AccessPolicy.canViewPayment(me, p, db.groups[p.groupId])).toList()
          ..sort(_byDue);
      });

  @override
  Stream<List<Payment>> watchGroupPayments(String groupId) => db.watch(() {
        final g = db.requireGroup(groupId);
        if (!AccessPolicy.canManagePayments(db.me, g)) throw const PermissionDeniedException();
        return db.payments.values.where((p) => p.groupId == groupId).toList()..sort(_byDue);
      });

  @override
  Future<void> setStatus(String paymentId, PaymentStatus status) async {
    final p = db.payments[paymentId] ?? (throw const NotFoundException());
    if (!AccessPolicy.canManagePayments(db.me, db.requireGroup(p.groupId))) throw const PermissionDeniedException();
    db.payments[paymentId] = p.copyWith(
      status: status,
      paidAt: status == PaymentStatus.paid ? db.clock() : null,
      clearPaidAt: status != PaymentStatus.paid,
    );
    db.commit();
  }

  @override
  Future<int> chargeGroup({required String groupId, required num amount, required DateTime dueDate}) async {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canManagePayments(db.me, g)) throw const PermissionDeniedException();
    if (amount <= 0) throw const ValidationException('amountPositive');
    var created = 0;
    for (final childId in g.memberChildIds) {
      final child = db.children[childId];
      if (child == null || child.parentIds.isEmpty) continue;
      final id = db.newId('pay');
      db.payments[id] = Payment(
        id: id,
        childId: childId,
        parentId: child.parentIds.first,
        groupId: groupId,
        sportId: g.sportId,
        amount: amount,
        dueDate: DateTime.utc(dueDate.year, dueDate.month, dueDate.day),
        createdAt: db.clock(),
      );
      created++;
    }
    db.commit();
    return created;
  }

  @override
  Stream<List<PaymentPlan>> watchPlans(String groupId) => db.watch(() {
        final g = db.requireGroup(groupId);
        if (!AccessPolicy.canManagePayments(db.me, g)) throw const PermissionDeniedException();
        return db.plans.values.where((p) => p.groupId == groupId).toList();
      });

  @override
  Future<PaymentPlan> createPlan({required String groupId, required num amount, required int dayOfMonth}) async {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canManagePayments(db.me, g)) throw const PermissionDeniedException();
    if (amount <= 0) throw const ValidationException('amountPositive');
    if (dayOfMonth < 1 || dayOfMonth > 28) throw const ValidationException('dayOfMonth');
    final plan = PaymentPlan(
      id: db.newId('plan'),
      groupId: groupId,
      sportId: g.sportId,
      amount: amount,
      dayOfMonth: dayOfMonth,
      createdBy: db.me.id,
    );
    db.plans[plan.id] = plan;
    db.commit();
    return plan;
  }

  @override
  Future<int> generateRecurring(String planId, {required int year, required int month}) async {
    final plan = db.plans[planId] ?? (throw const NotFoundException());
    final g = db.requireGroup(plan.groupId);
    if (!AccessPolicy.canManagePayments(db.me, g)) throw const PermissionDeniedException();
    if (!plan.active) return 0;
    var created = 0;
    for (final childId in g.memberChildIds) {
      final child = db.children[childId];
      if (child == null || child.parentIds.isEmpty) continue;
      final id = plan.paymentIdFor(childId, year, month);
      if (db.payments.containsKey(id)) continue; // idempotent
      db.payments[id] = Payment(
        id: id,
        childId: childId,
        parentId: child.parentIds.first,
        groupId: g.id,
        sportId: plan.sportId,
        amount: plan.amount,
        currency: plan.currency,
        dueDate: plan.dueDateFor(year, month),
        createdAt: db.clock(),
        planId: plan.id,
      );
      created++;
    }
    db.commit();
    return created;
  }

  @override
  Future<ReminderRunReport> runReminderJob(DateTime now) async {
    final ledger = _DemoLedger(db);
    final service = PaymentReminderService(provider: sms, ledger: ledger, smsEnabled: true);
    final report = await service.run(
      now: now,
      payments: db.payments.values.toList(),
      recipientOf: (parentId) {
        final u = db.users[parentId];
        if (u == null) return null;
        return ReminderRecipient(
          phone: u.phone,
          smsEnabled: u.notificationPrefs.isEnabled(NotificationType.paymentSms),
          hasSmsConsent: u.smsConsentAt != null,
        );
      },
      lineOf: (p) => ReminderLine(
        child: db.children[p.childId]?.firstName ?? '',
        sport: db.sports[p.sportId]?.name ?? p.sportId,
        amount: p.amount,
      ),
    );
    // Push goes out together with the SMS (free channel).
    for (final pid in ledger.claimedPaymentIds) {
      final p = db.payments[pid]!;
      final g = db.groups[p.groupId];
      if (g == null) continue;
      db.dispatch(NotificationType.paymentReminder, g,
          route: '/payments', onlyParentIds: {p.parentId}, args: {'amount': '${p.amount}', 'child': db.children[p.childId]?.firstName ?? ''});
    }
    db.commit();
    return report;
  }

  @override
  Stream<List<SmsLogEntry>> watchSmsLog() => db.watch(() => db.smsLog.reversed.toList());
}

class _DemoLedger implements ReminderLedger {
  _DemoLedger(this.db);

  final DemoBackend db;
  final claimedPaymentIds = <String>[];

  @override
  Future<bool> claim(String paymentId, ReminderKind kind, DateTime at) async {
    final p = db.payments[paymentId];
    if (p == null || p.status != PaymentStatus.pending) return false;
    final r = p.reminders;
    if (kind == ReminderKind.d5 && r.d5SentAt != null) return false;
    if (kind == ReminderKind.d1 && r.d1SentAt != null) return false;
    db.payments[paymentId] = p.copyWith(
      reminders: kind == ReminderKind.d5
          ? PaymentReminders(d5SentAt: at, d1SentAt: r.d1SentAt)
          : PaymentReminders(d5SentAt: r.d5SentAt, d1SentAt: at),
    );
    claimedPaymentIds.add(paymentId);
    return true;
  }

  @override
  Future<void> release(String paymentId, ReminderKind kind) async {
    final p = db.payments[paymentId];
    if (p == null) return;
    final r = p.reminders;
    db.payments[paymentId] = p.copyWith(
      reminders: kind == ReminderKind.d5
          ? PaymentReminders(d1SentAt: r.d1SentAt)
          : PaymentReminders(d5SentAt: r.d5SentAt),
    );
    claimedPaymentIds.remove(paymentId);
  }

  @override
  Future<void> log(SmsLogEntry entry) async => db.smsLog.add(entry);
}
