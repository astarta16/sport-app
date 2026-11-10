import 'package:intl/intl.dart';

import '../../../core/utils/dates.dart';
import '../../../core/utils/validators.dart';
import 'payment.dart';

enum ReminderKind { d5, d1 }

/// Pure decision logic for SMS payment reminders (spec §14.2), evaluated on
/// Tbilisi calendar days.
class PaymentReminderPlanner {
  PaymentReminderPlanner._();

  static ReminderKind? dueReminder(Payment p, DateTime now) {
    if (p.status != PaymentStatus.pending) return null;
    final days = TbilisiTime.daysBetween(now, p.dueDate);
    // Rule 7: a payment created fewer than 5 days before due never hits
    // days == 5, so only the day-before reminder is sent.
    if (days == 5 && p.reminders.d5SentAt == null) return ReminderKind.d5;
    if (days == 1 && p.reminders.d1SentAt == null) return ReminderKind.d1;
    return null;
  }

  /// The job runs daily at 10:00 Asia/Tbilisi.
  static DateTime nextRunAfter(DateTime now) {
    final w = TbilisiTime.wallClock(now);
    var run = TbilisiTime.at(w.year, w.month, w.day, 10);
    if (!run.isAfter(now)) run = TbilisiTime.at(w.year, w.month, w.day + 1, 10);
    return run;
  }
}

/// SMS templates (spec §14.3). Only name, sport, amount and date — never
/// health or other sensitive data. Georgian is UCS-2: keep them short.
class SmsTemplates {
  SmsTemplates._();

  static final _date = DateFormat('dd.MM');

  static String _amount(num a) => a == a.roundToDouble() ? a.toInt().toString() : a.toStringAsFixed(2);

  static String single(ReminderKind kind, {required String child, required String sport, required num amount, required DateTime due}) {
    final date = _date.format(TbilisiTime.wallClock(due));
    return switch (kind) {
      ReminderKind.d5 => 'შეხსენება: $child-ს $sport-ის გადასახადი ${_amount(amount)} ₾ გადასახდელია $date-მდე.',
      ReminderKind.d1 => 'შეხსენება: ხვალ $date ბოლო დღეა $child-ს $sport-ის გადასახადის (${_amount(amount)} ₾) გადასახდელად.',
    };
  }

  /// One combined SMS when a parent has several payments due the same day.
  static String combined(ReminderKind kind, List<ReminderLine> lines, DateTime due) {
    final date = _date.format(TbilisiTime.wallClock(due));
    final items = lines.map((l) => '${l.child} (${l.sport}) ${_amount(l.amount)} ₾').join(', ');
    return switch (kind) {
      ReminderKind.d5 => 'შეხსენება: $date-მდე გადასახდელია: $items.',
      ReminderKind.d1 => 'შეხსენება: ხვალ $date ბოლო დღეა: $items.',
    };
  }

  /// UCS-2 single-segment limit is 70 chars, 67 per segment when split.
  static int segmentsFor(String text) => text.length <= 70 ? 1 : (text.length / 67).ceil();
}

class ReminderLine {
  const ReminderLine({required this.child, required this.sport, required this.amount});

  final String child;
  final String sport;
  final num amount;
}

class SmsResult {
  const SmsResult({required this.ok, this.response});

  final bool ok;
  final String? response;
}

/// Abstract SMS gateway. Real providers live server-side only (Cloud
/// Functions + Secret Manager); the app ships the mock for demo mode.
abstract interface class SmsProvider {
  String get name;
  Future<SmsResult> send(String phone, String text);
}

class MockSmsProvider implements SmsProvider {
  final List<({String phone, String text})> sent = [];

  @override
  String get name => 'mock';

  @override
  Future<SmsResult> send(String phone, String text) async {
    sent.add((phone: phone, text: text));
    return SmsResult(ok: true, response: 'mock-${sent.length}');
  }
}

/// Persistence port making the job idempotent: [claim] must atomically set
/// `reminders.d5SentAt` / `d1SentAt` only if still empty (a Firestore
/// transaction server-side), so a double run never sends twice.
abstract interface class ReminderLedger {
  Future<bool> claim(String paymentId, ReminderKind kind, DateTime at);
  Future<void> release(String paymentId, ReminderKind kind);
  Future<void> log(SmsLogEntry entry);
}

class ReminderRecipient {
  const ReminderRecipient({required this.phone, required this.smsEnabled, required this.hasSmsConsent});

  final String phone;
  final bool smsEnabled;
  final bool hasSmsConsent;
}

class ReminderRunReport {
  const ReminderRunReport({required this.sent, required this.skipped, required this.failed, required this.claimed});

  final int sent;
  final int skipped;
  final int failed;
  final int claimed;
}

class PaymentReminderService {
  PaymentReminderService({required this.provider, required this.ledger, this.smsEnabled = false});

  final SmsProvider provider;
  final ReminderLedger ledger;

  /// Global kill-switch: real sending requires explicit activation.
  final bool smsEnabled;

  Future<ReminderRunReport> run({
    required DateTime now,
    required List<Payment> payments,
    required ReminderRecipient? Function(String parentId) recipientOf,
    required ReminderLine Function(Payment p) lineOf,
  }) async {
    var sent = 0, skipped = 0, failed = 0, claimed = 0;

    final batches = <(String, ReminderKind, DateTime), List<Payment>>{};
    for (final p in payments) {
      final kind = PaymentReminderPlanner.dueReminder(p, now);
      if (kind == null) continue;
      final key = (p.parentId, kind, TbilisiTime.calendarDay(p.dueDate));
      (batches[key] ??= []).add(p);
    }

    for (final entry in batches.entries) {
      final (parentId, kind, due) = entry.key;
      final mine = <Payment>[];
      for (final p in entry.value) {
        if (await ledger.claim(p.id, kind, now)) mine.add(p);
      }
      if (mine.isEmpty) continue;
      claimed += mine.length;

      final recipient = recipientOf(parentId);
      final lines = mine.map(lineOf).toList();
      final text = lines.length == 1
          ? SmsTemplates.single(kind, child: lines.first.child, sport: lines.first.sport, amount: lines.first.amount, due: due)
          : SmsTemplates.combined(kind, lines, due);

      if (recipient == null || !smsEnabled || !recipient.smsEnabled || !recipient.hasSmsConsent) {
        skipped++;
        await ledger.log(_entry(now, recipient?.phone ?? '', text, 'skipped', mine, kind, null));
        continue;
      }
      final result = await provider.send(recipient.phone, text);
      if (result.ok) {
        sent++;
        await ledger.log(_entry(now, recipient.phone, text, 'sent', mine, kind, result.response));
      } else {
        failed++;
        for (final p in mine) {
          await ledger.release(p.id, kind);
        }
        await ledger.log(_entry(now, recipient.phone, text, 'failed', mine, kind, result.response));
      }
    }
    return ReminderRunReport(sent: sent, skipped: skipped, failed: failed, claimed: claimed);
  }

  SmsLogEntry _entry(DateTime now, String phone, String text, String status, List<Payment> ps, ReminderKind kind, String? resp) =>
      SmsLogEntry(
        id: '${now.millisecondsSinceEpoch}_${ps.first.id}_${kind.name}',
        at: now,
        maskedPhone: phone.isEmpty ? '' : Validators.maskPhone(phone),
        text: text,
        status: status,
        provider: provider.name,
        providerResponse: resp,
        paymentIds: ps.map((p) => p.id).toList(),
        kind: kind.name,
      );
}
