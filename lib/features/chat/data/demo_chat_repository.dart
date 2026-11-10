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

  void _guard(String groupId) {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canAccessChat(db.me, g)) throw const PermissionDeniedException('chat');
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String groupId, {int limit = 50}) => db.watch(() {
    _guard(groupId);
    final all = List<ChatMessage>.of(db.messages[groupId] ?? const [])
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all.length <= limit ? all : all.sublist(all.length - limit);
  });

  @override
  Future<void> send(
    String groupId,
    String text, {
    List<PhotoUpload> attachments = const [],
    bool announcement = false,
  }) async {
    db.requireOnline();
    final me = db.me;
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canAccessChat(me, g)) throw const PermissionDeniedException('chat');
    if (announcement && !AccessPolicy.isCoachOf(me, g)) throw const PermissionDeniedException('announcement');
    db.rateLimit('chat', 500);
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
      type: announcement ? ChatMessageType.announcement : ChatMessageType.text,
      pinned: announcement,
    );
    (db.messages[groupId] ??= []).add(m);
    // Sending implies having read everything before it.
    (db.chatReads[groupId] ??= {})[me.id] = db.clock();
    db.dispatch(
      announcement ? NotificationType.announcement : NotificationType.chatMessage,
      g,
      route: '/chat/$groupId',
      excludeUserId: me.id,
      args: {'sender': me.fullName},
      dedupeKey: 'msg:${m.id}',
    );
    db.commit();
  }

  @override
  Future<void> setPinned(String groupId, String messageId, bool pinned) async {
    db.requireOnline();
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException('pin');
    final list = db.messages[groupId] ?? const [];
    final i = list.indexWhere((m) => m.id == messageId);
    if (i < 0) throw const NotFoundException();
    if (list[i].isSystem) throw const ValidationException('cannotPin');
    list[i] = list[i].copyWith(pinned: pinned);
    db.commit();
  }

  @override
  Future<void> markRead(String groupId) async {
    final me = db.currentUser;
    if (me == null) return;
    final g = db.groups[groupId];
    if (g == null || !AccessPolicy.canAccessChat(me, g)) return;
    final prev = db.chatReads[groupId]?[me.id];
    if (prev != null && db.unreadFor(me.id, groupId) == 0) return;
    (db.chatReads[groupId] ??= {})[me.id] = db.clock();
    db.commit();
  }

  @override
  Stream<List<ChatSummary>> watchSummaries(List<String> groupIds) => db.watch(() {
    final me = db.me;
    return [
      for (final id in groupIds)
        if (db.groups[id] != null && AccessPolicy.canAccessChat(me, db.groups[id]!))
          ChatSummary(
            groupId: id,
            unread: db.unreadFor(me.id, id),
            lastMessage: (db.messages[id] ?? const <ChatMessage>[])
                .where((m) => !m.hidden)
                .fold<ChatMessage?>(null, (a, m) => a == null || m.createdAt.isAfter(a.createdAt) ? m : a),
          ),
    ];
  });

  @override
  Stream<Map<String, DateTime>> watchReadReceipts(String groupId) => db.watch(() {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException('receipts');
    return Map.of(db.chatReads[groupId] ?? const {});
  });
}
