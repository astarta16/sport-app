import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../admin/domain/admin_models.dart';
import '../../authentication/domain/app_user.dart';
import '../../groups/domain/group.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../../trainings/domain/training.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../../organizations/domain/organization.dart';
import '../domain/receipts.dart';

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
    bool requiresAck = false,
  }) async {
    db.requireOnline();
    db.requireGroupModule(groupId, OrgModule.communication);
    if (requiresAck) db.requireGroupModule(groupId, OrgModule.messageAcks);
    final me = db.me;
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canAccessChat(me, g)) throw const PermissionDeniedException('chat');
    if (announcement && !AccessPolicy.isCoachOf(me, g)) throw const PermissionDeniedException('announcement');
    if (requiresAck && !AccessPolicy.isCoachOf(me, g)) throw const PermissionDeniedException('requiresAck');
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
      requiresAck: requiresAck,
    );
    (db.messages[groupId] ??= []).add(m);
    snapshotRecipients(db, g, m);
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

  // ── v1.4 read receipts / acknowledgments (mirror of the server model) ──

  /// Server side of `createReceipt`: unique parent accounts of the group at
  /// creation time; acknowledgment requests go to their inbox.
  static void snapshotRecipients(DemoBackend db, Group g, ChatMessage m) {
    if (m.senderRole != UserRole.coach || m.isSystem) return;
    final ids = <String>{
      for (final p in g.parentIds)
        if (p != m.senderId && (db.users[p]?.isParent ?? false)) p,
    }.toList()..sort();
    db.msgRecipients[m.id] = ids;
    if (m.requiresAck) {
      for (final p in ids) {
        db.notifyUser(
          p,
          NotificationType.ackRequested,
          route: '/chat/${g.id}',
          args: {'group': g.name, 'groupId': g.id, 'messageId': m.id},
          groupId: g.id,
          dedupeKey: 'ack:${g.id}:${m.id}',
        );
      }
    }
  }

  ChatMessage? _message(String groupId, String messageId) =>
      (db.messages[groupId] ?? const <ChatMessage>[]).where((m) => m.id == messageId).firstOrNull;

  @override
  Stream<Map<String, MessageReceipt>> watchSentReceipts(String groupId) => db.watch(() {
    final me = db.me;
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(me, g)) return const <String, MessageReceipt>{};
    return {
      for (final m in db.messages[groupId] ?? const <ChatMessage>[])
        if (m.senderId == me.id && db.msgRecipients.containsKey(m.id))
          m.id: MessageReceipt.compute(
            m.id,
            db.msgRecipients[m.id]!,
            db.msgReads[m.id] ?? const {},
            db.msgAcks[m.id] ?? const {},
            requiresAck: m.requiresAck,
          ),
    };
  });

  @override
  Stream<List<RecipientStatus>> watchRecipientStatuses(String groupId, String messageId) => db.watch(() {
    final me = db.me;
    final g = db.requireGroup(groupId);
    final m = _message(groupId, messageId);
    if (m == null) throw const NotFoundException('message');
    if (!AccessPolicy.isCoachOf(me, g) || m.senderId != me.id) throw const PermissionDeniedException('receipts');
    final reads = db.msgReads[messageId] ?? const <String, DateTime>{};
    final acks = db.msgAcks[messageId] ?? const <String, DateTime>{};
    return [
      for (final uid in db.msgRecipients[messageId] ?? const <String>[])
        RecipientStatus(
          uid: uid,
          name: db.users[uid]?.fullName ?? '—',
          readAt: reads[uid] ?? acks[uid],
          ackAt: acks[uid],
        ),
    ];
  });

  @override
  Stream<MyMarks> watchMyMarks(String groupId) => db.watch(() {
    final me = db.me;
    final ids = (db.messages[groupId] ?? const <ChatMessage>[]).map((m) => m.id);
    return MyMarks(
      read: {
        for (final id in ids)
          if (db.msgReads[id]?.containsKey(me.id) ?? false) id,
      },
      acked: {for (final id in ids) id: ?db.msgAcks[id]?[me.id]},
      ackRequested: {
        for (final m in db.messages[groupId] ?? const <ChatMessage>[])
          if (m.requiresAck && (db.msgRecipients[m.id]?.contains(me.id) ?? false)) m.id,
      },
    );
  });

  /// Same checks as the `msgReads` / `msgAcks` rules.
  bool _canMark(String groupId, String messageId) {
    final me = db.me;
    final g = db.groups[groupId];
    if (g == null || !g.isActive || !AccessPolicy.isParentInGroup(me, g)) return false;
    final m = _message(groupId, messageId);
    if (m == null || m.hidden) return false;
    return db.msgRecipients[messageId]?.contains(me.id) ?? false;
  }

  @override
  Future<void> markSeen(String groupId, List<String> messageIds) async {
    db.requireOnline();
    final me = db.me;
    var changed = false;
    for (final id in messageIds.toSet()) {
      if (!_canMark(groupId, id)) continue;
      final reads = db.msgReads[id] ??= {};
      if (reads.containsKey(me.id)) continue; // create-only: never moved
      reads[me.id] = db.clock();
      changed = true;
    }
    if (changed) db.commit();
  }

  @override
  Future<void> acknowledge(String groupId, String messageId) async {
    db.requireOnline();
    db.requireGroupModule(groupId, OrgModule.messageAcks);
    final me = db.me;
    final m = _message(groupId, messageId);
    if (m == null) throw const NotFoundException('message');
    if (!m.requiresAck || !_canMark(groupId, messageId)) throw const PermissionDeniedException('acknowledge');
    final acks = db.msgAcks[messageId] ??= {};
    if (acks.containsKey(me.id)) return; // duplicate: the first record stands
    final now = db.clock();
    acks[me.id] = now;
    (db.msgReads[messageId] ??= {}).putIfAbsent(me.id, () => now);
    db.audit.add(
      AuditEntry(
        id: db.newId('audit'),
        action: 'chat.acknowledge',
        actorId: me.id,
        actorName: me.fullName,
        targetType: 'chatMessage',
        targetId: '$groupId/$messageId',
        clubId: db.groups[groupId]?.clubId,
        at: now,
      ),
    );
    db.commit();
  }

  @override
  Stream<List<PendingAck>> watchPendingAcks() => db.watch(() {
    final me = db.currentUser;
    if (me == null || !me.isParent) return const <PendingAck>[];
    return [
      for (final e in db.messages.entries)
        for (final m in e.value)
          if (m.requiresAck &&
              !m.hidden &&
              (db.msgRecipients[m.id]?.contains(me.id) ?? false) &&
              (db.groups[e.key]?.hasParent(me.id) ?? false) &&
              !(db.msgAcks[m.id]?.containsKey(me.id) ?? false))
            PendingAck(
              groupId: e.key,
              messageId: m.id,
              eventId: m.systemArgs['eventId'],
              eventType: m.systemArgs['eventType'],
            ),
    ];
  });
}
