import '../../trainings/domain/training.dart';
import 'chat_message.dart';

abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages(String groupId);
  Future<void> send(String groupId, String text, {List<PhotoUpload> attachments = const []});
}
