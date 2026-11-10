import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/chat_message.dart';

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, groupId) {
  ref.watch(currentUidProvider);
  return ref.watch(chatRepositoryProvider).watchMessages(groupId);
});
