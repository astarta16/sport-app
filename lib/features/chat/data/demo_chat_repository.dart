import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../../trainings/domain/training.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';

class DemoChatRepository implements ChatRepository {
  DemoChatRepository(this.db);

  final DemoBackend db;

  @override
  Stream<List<ChatMessage>> watchMessages(String groupId) => db.watch(() {
        final g = db.requireGroup(groupId);
        if (!AccessPolicy.canAccessChat(db.me, g)) throw const PermissionDeniedException('chat');
        return List<ChatMessage>.of(db.messages[groupId] ?? const [])..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });

  @override
  Future<void> send(String groupId, String text, {List<PhotoUpload> attachments = const []}) async {
    final me = db.me;
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canAccessChat(me, g)) throw const PermissionDeniedException('chat');
    final keys = <String>[];
    for (final a in attachments) {
      if (!a.mimeType.startsWith('image/')) throw const ValidationException('fileType');
      if (a.bytes.length > 10 * 1024 * 1024) throw const ValidationException('fileTooLarge');
      final key = 'demo-mem://${db.newId('att')}';
      db.photos[key] = Uint8List.fromList(a.bytes);
      keys.add(key);
    }
    final error = ChatValidator.validate(text, keys);
    if (error != null) throw ValidationException(error);
    final m = ChatMessage(
      id: db.newId('msg'),
      groupId: groupId,
      senderId: me.id,
      senderName: me.fullName,
      senderRole: me.role,
      text: text.trim(),
      attachments: keys,
      createdAt: db.clock(),
    );
    (db.messages[groupId] ??= []).add(m);
    db.dispatch(NotificationType.chatMessage, g,
        route: '/chat/$groupId', excludeUserId: me.id, args: {'sender': me.fullName});
    db.commit();
  }
}
