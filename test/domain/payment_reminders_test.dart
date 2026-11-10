import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/utils/dates.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/payments/domain/payment_reminders.dart';

Payment pay(
  String id,
  DateTime due, {
  String parent = 'p1',
  PaymentStatus status = PaymentStatus.pending,
  PaymentReminders? r,
}) => Payment(
  id: id,
  childId: 'c-$id',
  parentId: parent,
  groupId: 'g',
  sportId: 'football',
  amount: 80,
  dueDate: due,
  status: status,
  reminders: r ?? const PaymentReminders(),
);

class MemoryLedger implements ReminderLedger {
  final claims = <String>{};
  final logs = <SmsLogEntry>[];

  @override
  Future<bool> claim(String paymentId, ReminderKind kind, DateTime at) async => claims.add('$paymentId/${kind.name}');

  @override
  Future<void> release(String paymentId, ReminderKind kind) async => claims.remove('$paymentId/${kind.name}');

  @override
  Future<void> log(SmsLogEntry entry) async => logs.add(entry);
}

class FailingProvider implements SmsProvider {
  @override
  String get name => 'failing';

  @override
  Future<SmsResult> send(String phone, String text) async => const SmsResult(ok: false, response: '500');
}

void main() {
  // 10:00 Asia/Tbilisi on 10 Nov 2026.
  final now = TbilisiTime.at(2026, 11, 10, 10);

  group('PaymentReminderPlanner (Tbilisi days)', () {
    test('5 days before → d5, 1 day before → d1', () {
      expect(PaymentReminderPlanner.dueReminder(pay('a', DateTime.utc(2026, 11, 15)), now), ReminderKind.d5);
      expect(PaymentReminderPlanner.dueReminder(pay('b', DateTime.utc(2026, 11, 11)), now), ReminderKind.d1);
      expect(PaymentReminderPlanner.dueReminder(pay('c', DateTime.utc(2026, 11, 13)), now), isNull);
    });

    test('already sent, paid or cancelled → nothing', () {
      expect(
        PaymentReminderPlanner.dueReminder(
          pay('a', DateTime.utc(2026, 11, 15), r: PaymentReminders(d5SentAt: now)),
          now,
        ),
        isNull,
      );
      expect(
        PaymentReminderPlanner.dueReminder(pay('a', DateTime.utc(2026, 11, 15), status: PaymentStatus.paid), now),
        isNull,
      );
      expect(
        PaymentReminderPlanner.dueReminder(pay('a', DateTime.utc(2026, 11, 11), status: PaymentStatus.cancelled), now),
        isNull,
      );
    });

    test('late in the Tbilisi evening still counts as the same Tbilisi day', () {
      // 23:30 Tbilisi = 19:30 UTC on 10 Nov.
      final late = TbilisiTime.at(2026, 11, 10, 23, 30);
      expect(PaymentReminderPlanner.dueReminder(pay('a', DateTime.utc(2026, 11, 11)), late), ReminderKind.d1);
      // 00:30 Tbilisi on 11 Nov = 20:30 UTC on 10 Nov: due day itself → nothing.
      final afterMidnight = TbilisiTime.at(2026, 11, 11, 0, 30);
      expect(PaymentReminderPlanner.dueReminder(pay('a', DateTime.utc(2026, 11, 11)), afterMidnight), isNull);
    });

    test('created later than 5 days before due → only the d1 reminder', () {
      final p = pay('a', DateTime.utc(2026, 11, 13)); // created with 3 days left
      final daysLeft = [for (var d = 0; d < 3; d++) PaymentReminderPlanner.dueReminder(p, now.add(Duration(days: d)))];
      expect(daysLeft, [null, null, ReminderKind.d1]);
    });

    test('job runs daily at 10:00 Tbilisi', () {
      expect(PaymentReminderPlanner.nextRunAfter(TbilisiTime.at(2026, 11, 10, 9)), TbilisiTime.at(2026, 11, 10, 10));
      expect(PaymentReminderPlanner.nextRunAfter(TbilisiTime.at(2026, 11, 10, 10)), TbilisiTime.at(2026, 11, 11, 10));
    });
  });

  group('SmsTemplates', () {
    test('single reminder contains only name, sport, amount and date', () {
      final t = SmsTemplates.single(
        ReminderKind.d5,
        child: 'ლუკა',
        sport: 'ფეხბურთი',
        amount: 80,
        due: DateTime.utc(2026, 11, 15),
      );
      expect(t, 'შეხსენება: ლუკა-ს ფეხბურთი-ის გადასახადი 80 ₾ გადასახდელია 15.11-მდე.');
      expect(SmsTemplates.segmentsFor(t), 1);
    });

    test('combined reminder lists all children', () {
      final t = SmsTemplates.combined(ReminderKind.d1, const [
        ReminderLine(child: 'ლუკა', sport: 'ფეხბურთი', amount: 80),
        ReminderLine(child: 'მარიამ', sport: 'კალათბურთი', amount: 100),
      ], DateTime.utc(2026, 11, 11));
      expect(t, contains('ლუკა (ფეხბურთი) 80 ₾'));
      expect(t, contains('მარიამ (კალათბურთი) 100 ₾'));
    });
  });

  group('PaymentReminderService (idempotency)', () {
    ReminderRecipient? recipient(String _) =>
        const ReminderRecipient(phone: '+995555000101', smsEnabled: true, hasSmsConsent: true);
    ReminderLine line(Payment p) => ReminderLine(child: p.childId, sport: 'ფეხბურთი', amount: p.amount);

    test('a second run on the same day sends nothing', () async {
      final ledger = MemoryLedger();
      final sms = MockSmsProvider();
      final service = PaymentReminderService(provider: sms, ledger: ledger, smsEnabled: true);
      final ps = [pay('a', DateTime.utc(2026, 11, 15)), pay('b', DateTime.utc(2026, 11, 11), parent: 'p2')];

      final r1 = await service.run(now: now, payments: ps, recipientOf: recipient, lineOf: line);
      final r2 = await service.run(now: now, payments: ps, recipientOf: recipient, lineOf: line);
      expect(r1.sent, 2);
      expect(r2.sent, 0);
      expect(sms.sent, hasLength(2));
    });

    test('same parent, same day → one combined SMS', () async {
      final sms = MockSmsProvider();
      final service = PaymentReminderService(provider: sms, ledger: MemoryLedger(), smsEnabled: true);
      final due = DateTime.utc(2026, 11, 15);
      final r = await service.run(
        now: now,
        payments: [pay('a', due), pay('b', due)],
        recipientOf: recipient,
        lineOf: line,
      );
      expect(r.sent, 1);
      expect(r.claimed, 2);
      expect(sms.sent.single.text, contains('c-a'));
      expect(sms.sent.single.text, contains('c-b'));
    });

    test('kill-switch, opt-out and missing consent skip sending but still claim', () async {
      final sms = MockSmsProvider();
      final ledger = MemoryLedger();
      final off = PaymentReminderService(provider: sms, ledger: ledger);
      final r = await off.run(
        now: now,
        payments: [pay('a', DateTime.utc(2026, 11, 15))],
        recipientOf: recipient,
        lineOf: line,
      );
      expect(r.sent, 0);
      expect(r.skipped, 1);
      expect(sms.sent, isEmpty);
      expect(ledger.logs.single.status, 'skipped');

      final optedOut = PaymentReminderService(provider: sms, ledger: MemoryLedger(), smsEnabled: true);
      final r2 = await optedOut.run(
        now: now,
        payments: [pay('a', DateTime.utc(2026, 11, 15))],
        recipientOf: (_) => const ReminderRecipient(phone: '+995555000101', smsEnabled: false, hasSmsConsent: true),
        lineOf: line,
      );
      expect(r2.skipped, 1);
      expect(sms.sent, isEmpty);
    });

    test('provider failure releases the claim so a later run can retry', () async {
      final ledger = MemoryLedger();
      final service = PaymentReminderService(provider: FailingProvider(), ledger: ledger, smsEnabled: true);
      final r = await service.run(
        now: now,
        payments: [pay('a', DateTime.utc(2026, 11, 15))],
        recipientOf: recipient,
        lineOf: line,
      );
      expect(r.failed, 1);
      expect(ledger.claims, isEmpty);
      expect(ledger.logs.single.status, 'failed');
    });

    test('SMS log stores masked phone numbers only', () async {
      final ledger = MemoryLedger();
      final service = PaymentReminderService(provider: MockSmsProvider(), ledger: ledger, smsEnabled: true);
      await service.run(
        now: now,
        payments: [pay('a', DateTime.utc(2026, 11, 15))],
        recipientOf: recipient,
        lineOf: line,
      );
      expect(ledger.logs.single.maskedPhone, isNot(contains('555000101')));
      expect(ledger.logs.single.provider, 'mock');
    });
  });
}
