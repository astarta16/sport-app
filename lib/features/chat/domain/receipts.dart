/// v1.4 per-message read receipts and acknowledgments.
///
/// Model (Firestore): the server snapshots the recipients of each coach
/// message into `chats/{g}/receipts/{m}` (readable only by the sending
/// coach); each recipient parent creates at most one
/// `…/messages/{m}/msgReads/{uid}` and, when asked, one `…/msgAcks/{uid}`,
/// both stamped with the server time and immutable.
library;

enum ReceiptState { notSeen, seen, acknowledged }

class MessageReceipt {
  const MessageReceipt({
    required this.messageId,
    required this.recipientIds,
    required this.readCount,
    required this.ackCount,
    required this.requiresAck,
  });

  final String messageId;

  /// Unique parent accounts at creation time (guardians counted separately).
  final List<String> recipientIds;
  final int readCount;
  final int ackCount;
  final bool requiresAck;

  int get recipientCount => recipientIds.length;

  factory MessageReceipt.fromMap(String id, Map<String, dynamic> m) => MessageReceipt(
    messageId: id,
    recipientIds: [for (final x in (m['recipientIds'] as List? ?? const [])) x.toString()],
    readCount: (m['readCount'] as num?)?.toInt() ?? 0,
    ackCount: (m['ackCount'] as num?)?.toInt() ?? 0,
    requiresAck: m['requiresAck'] as bool? ?? false,
  );

  /// Counts over the snapshot only; an acknowledgment implies "seen".
  static MessageReceipt compute(
    String messageId,
    List<String> recipientIds,
    Map<String, DateTime> reads,
    Map<String, DateTime> acks, {
    required bool requiresAck,
  }) {
    final r = recipientIds.toSet();
    final seen = {...reads.keys.where(r.contains), ...acks.keys.where(r.contains)};
    return MessageReceipt(
      messageId: messageId,
      recipientIds: recipientIds,
      readCount: seen.length,
      ackCount: acks.keys.where(r.contains).length,
      requiresAck: requiresAck,
    );
  }
}

/// One row of the coach's detail screen.
class RecipientStatus {
  const RecipientStatus({required this.uid, required this.name, this.readAt, this.ackAt});

  final String uid;
  final String name;
  final DateTime? readAt;
  final DateTime? ackAt;

  ReceiptState get state => ackAt != null
      ? ReceiptState.acknowledged
      : readAt != null
      ? ReceiptState.seen
      : ReceiptState.notSeen;
}

/// The signed-in parent's own marks in one group chat.
class MyMarks {
  const MyMarks({this.read = const {}, this.acked = const {}, this.ackRequested = const {}});

  final Set<String> read;
  final Map<String, DateTime> acked;

  /// Messages for which this parent is in the snapshot and an
  /// acknowledgment was requested.
  final Set<String> ackRequested;
}

/// An outstanding acknowledgment request (dashboard: group only, no content).
class PendingAck {
  const PendingAck({required this.groupId, required this.messageId, this.eventId, this.eventType});

  final String groupId;
  final String messageId;

  /// v1.7: set when the acknowledgment is for a training/match schedule change.
  final String? eventId;

  /// `training` or `match` (with [eventId]).
  final String? eventType;
}
