import '../../../core/utils/dates.dart';

enum PaymentStatus {
  pending,
  paid,
  cancelled;

  static PaymentStatus fromName(String? n) =>
      PaymentStatus.values.firstWhere((s) => s.name == n, orElse: () => PaymentStatus.pending);
}

class PaymentReminders {
  const PaymentReminders({this.d5SentAt, this.d1SentAt});

  final DateTime? d5SentAt;
  final DateTime? d1SentAt;

  Map<String, dynamic> toMap() => {'d5SentAt': d5SentAt, 'd1SentAt': d1SentAt};

  factory PaymentReminders.fromMap(Object? m) {
    if (m is! Map) return const PaymentReminders();
    return PaymentReminders(d5SentAt: readDateOrNull(m['d5SentAt']), d1SentAt: readDateOrNull(m['d1SentAt']));
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.groupId,
    required this.sportId,
    required this.amount,
    required this.dueDate,
    this.currency = 'GEL',
    this.status = PaymentStatus.pending,
    this.reminders = const PaymentReminders(),
    this.paidAt,
    this.createdAt,
    this.planId,
  });

  final String id;
  final String childId;
  final String parentId;
  final String groupId;
  final String sportId;
  final num amount;
  final String currency;
  final DateTime dueDate;
  final PaymentStatus status;
  final PaymentReminders reminders;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final String? planId;

  bool isOverdue(DateTime now) => status == PaymentStatus.pending && TbilisiTime.daysBetween(now, dueDate) < 0;

  Payment copyWith({PaymentStatus? status, PaymentReminders? reminders, DateTime? paidAt, bool clearPaidAt = false}) =>
      Payment(
        id: id,
        childId: childId,
        parentId: parentId,
        groupId: groupId,
        sportId: sportId,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        status: status ?? this.status,
        reminders: reminders ?? this.reminders,
        paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
        createdAt: createdAt,
        planId: planId,
      );

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'parentId': parentId,
    'groupId': groupId,
    'sportId': sportId,
    'amount': amount,
    'currency': currency,
    'dueDate': dueDate,
    'status': status.name,
    'reminders': reminders.toMap(),
    'paidAt': paidAt,
    'createdAt': createdAt,
    'planId': planId,
  };

  factory Payment.fromMap(String id, Map<String, dynamic> m) => Payment(
    id: id,
    childId: m['childId'] as String,
    parentId: m['parentId'] as String,
    groupId: m['groupId'] as String,
    sportId: m['sportId'] as String,
    amount: m['amount'] as num? ?? 0,
    currency: m['currency'] as String? ?? 'GEL',
    dueDate: readDate(m['dueDate']),
    status: PaymentStatus.fromName(m['status'] as String?),
    reminders: PaymentReminders.fromMap(m['reminders']),
    paidAt: readDateOrNull(m['paidAt']),
    createdAt: readDateOrNull(m['createdAt']),
    planId: m['planId'] as String?,
  );
}

/// Recurring charge for a group (e.g. every month on day 1).
class PaymentPlan {
  const PaymentPlan({
    required this.id,
    required this.groupId,
    required this.sportId,
    required this.amount,
    required this.dayOfMonth,
    required this.createdBy,
    this.currency = 'GEL',
    this.active = true,
  });

  final String id;
  final String groupId;
  final String sportId;
  final num amount;
  final String currency;
  final int dayOfMonth;
  final bool active;
  final String createdBy;

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'sportId': sportId,
    'amount': amount,
    'currency': currency,
    'dayOfMonth': dayOfMonth,
    'active': active,
    'createdBy': createdBy,
  };

  factory PaymentPlan.fromMap(String id, Map<String, dynamic> m) => PaymentPlan(
    id: id,
    groupId: m['groupId'] as String,
    sportId: m['sportId'] as String,
    amount: m['amount'] as num? ?? 0,
    currency: m['currency'] as String? ?? 'GEL',
    dayOfMonth: (m['dayOfMonth'] as num?)?.toInt() ?? 1,
    active: m['active'] as bool? ?? true,
    createdBy: m['createdBy'] as String? ?? '',
  );

  /// Deterministic id so regeneration for the same month is idempotent.
  String paymentIdFor(String childId, int year, int month) =>
      '${id}_${childId}_$year-${month.toString().padLeft(2, '0')}';

  DateTime dueDateFor(int year, int month) {
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    return DateTime.utc(year, month, dayOfMonth > lastDay ? lastDay : dayOfMonth);
  }
}

class SmsLogEntry {
  const SmsLogEntry({
    required this.id,
    required this.at,
    required this.maskedPhone,
    required this.text,
    required this.status,
    required this.provider,
    required this.paymentIds,
    required this.kind,
    this.providerResponse,
  });

  final String id;
  final DateTime at;
  final String maskedPhone;
  final String text;

  /// `sent` | `failed` | `skipped`
  final String status;
  final String provider;
  final String? providerResponse;
  final List<String> paymentIds;

  /// `d5` | `d1`
  final String kind;
}
