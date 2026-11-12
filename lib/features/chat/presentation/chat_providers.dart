import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_repository.dart';
import '../../groups/presentation/groups_providers.dart';

import 'package:flutter_riverpod/legacy.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/chat_message.dart';
import '../domain/receipts.dart';

/// Page size grows when the user asks for earlier messages (pagination).
final chatLimitProvider = StateProvider.autoDispose.family<int, String>((ref, _) => 50);

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  final limit = ref.watch(chatLimitProvider(groupId));
  return ref.watch(chatRepositoryProvider).watchMessages(groupId, limit: limit);
});

/// Chat list: unread count + last message per group (v1.1 §4).
final chatSummariesProvider = StreamProvider<List<ChatSummary>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.canUseChat) {
    yield const [];
    return;
  }
  final groups = await ref.watch(myGroupsProvider.future);
  final ids = groups.map((g) => g.id).toList()..sort();
  yield* ref.watch(chatRepositoryProvider).watchSummaries(ids);
});

/// Badge on the chat icon in the top bar.
final totalChatUnreadProvider = Provider<int>(
  (ref) => (ref.watch(chatSummariesProvider).value ?? const []).fold(0, (a, s) => a + s.unread),
);

final readReceiptsProvider = StreamProvider.autoDispose.family<Map<String, DateTime>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(chatRepositoryProvider).watchReadReceipts(groupId);
});

// ── v1.4 read receipts / acknowledgments ────────────────────────────────

/// Coach: receipt summaries of own messages in the group.
final sentReceiptsProvider = StreamProvider.autoDispose.family<Map<String, MessageReceipt>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(chatRepositoryProvider).watchSentReceipts(groupId);
});

/// Coach (sender): per-parent state of one message. Key: (groupId, messageId).
final recipientStatusesProvider = StreamProvider.autoDispose.family<List<RecipientStatus>, (String, String)>((
  ref,
  key,
) {
  ref.watch(currentUidProvider);
  return ref.watch(chatRepositoryProvider).watchRecipientStatuses(key.$1, key.$2);
});

/// Parent: own read / acknowledgment marks in the group.
final myMarksProvider = StreamProvider.autoDispose.family<MyMarks, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(chatRepositoryProvider).watchMyMarks(groupId);
});

/// Parent dashboard: outstanding acknowledgment requests (no message text).
final pendingAcksProvider = StreamProvider<List<PendingAck>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isParent) return Stream.value(const []);
  return ref.watch(chatRepositoryProvider).watchPendingAcks();
});
