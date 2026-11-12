import '../../trainings/domain/training.dart';
import 'chat_message.dart';
import 'receipts.dart';

/// Group chat summary for the chat list (v1.1 §4).
class ChatSummary {
  const ChatSummary({required this.groupId, required this.unread, this.lastMessage});

  final String groupId;
  final int unread;
  final ChatMessage? lastMessage;
}

abstract interface class ChatRepository {
  /// Newest [limit] messages, oldest first (pagination: raise [limit]).
  Stream<List<ChatMessage>> watchMessages(String groupId, {int limit = 50});
  Future<void> send(
    String groupId,
    String text, {
    List<PhotoUpload> attachments = const [],
    bool announcement = false,
    bool requiresAck = false,
  });

  /// Coach only: pin/unpin an announcement.
  Future<void> setPinned(String groupId, String messageId, bool pinned);

  /// Writes `chats/{groupId}/members/{uid}.lastReadAt`.
  Future<void> markRead(String groupId);

  /// Unread counts per group + last message (server-maintained `userUnread`).
  Stream<List<ChatSummary>> watchSummaries(List<String> groupIds);

  /// When each member last read the chat (read receipts for the coach).
  Stream<Map<String, DateTime>> watchReadReceipts(String groupId);

  // ── v1.4 read receipts / acknowledgments ──────────────────────────────

  /// Coach: receipt summaries of the coach's own messages in [groupId].
  Stream<Map<String, MessageReceipt>> watchSentReceipts(String groupId);

  /// Coach (sender only): per-parent state of one message.
  Stream<List<RecipientStatus>> watchRecipientStatuses(String groupId, String messageId);

  /// Parent: own read / acknowledgment marks in [groupId].
  Stream<MyMarks> watchMyMarks(String groupId);

  /// Parent: records that these messages were visibly shown in the open
  /// chat. Idempotent; messages the parent may not mark are skipped.
  Future<void> markSeen(String groupId, List<String> messageIds);

  /// Parent: explicit acknowledgment (never automatic).
  Future<void> acknowledge(String groupId, String messageId);

  /// Parent: outstanding acknowledgment requests across all groups.
  Stream<List<PendingAck>> watchPendingAcks();
}
