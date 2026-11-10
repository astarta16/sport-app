import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_repository.dart';
import '../../groups/presentation/groups_providers.dart';

import 'package:flutter_riverpod/legacy.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/chat_message.dart';

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
