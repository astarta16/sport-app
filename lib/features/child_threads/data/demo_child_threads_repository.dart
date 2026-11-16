import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/app_user.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/child_thread.dart';

/// Demo mirror of the `childThreads` rules + onChildThreadMessageCreated.
class DemoChildThreadsRepository implements ChildThreadsRepository {
  DemoChildThreadsRepository(this.db);

  final DemoBackend db;

  /// Coaches currently coaching the child (approved, of an active group with the child).
  Set<String> coachesOf(String childId) => {
    for (final g in db.groups.values)
      if (g.isActive && g.hasChild(childId))
        for (final c in g.coachIds)
          if (db.users[c]?.isApprovedCoach ?? false) c,
  };

  bool canUse(AppUser me, String childId, String coachId) {
    final child = db.children[childId];
    if (child == null || !coachesOf(childId).contains(coachId)) return false;
    if (me.isParent) return child.parentIds.contains(me.id);
    return me.isApprovedCoach && me.id == coachId;
  }

  @override
  Stream<List<ChildThreadMessage>> watchMessages(String childId, String coachId) => db.watch(() {
    if (!canUse(db.me, childId, coachId)) throw const PermissionDeniedException('thread');
    return List.of(db.childThreadMessages[ChildThread.idOf(childId, coachId)] ?? const <ChildThreadMessage>[]);
  });

  @override
  Future<void> send(String childId, String coachId, String text) async {
    db.requireOnline();
    final me = db.me;
    if (!canUse(me, childId, coachId)) throw const PermissionDeniedException('thread');
    final t = text.trim();
    if (t.isEmpty) throw const ValidationException('emptyMessage');
    if (t.length > ChildThreadMessage.maxLength) throw const ValidationException('messageTooLong');
    final id = ChildThread.idOf(childId, coachId);
    final now = db.clock();
    final m = ChildThreadMessage(
      id: db.newId('tmsg'),
      senderId: me.id,
      senderName: me.fullName,
      senderRole: me.role,
      text: t,
      createdAt: now,
    );
    (db.childThreadMessages[id] ??= []).add(m);
    db.childThreads[id] = ChildThread(childId: childId, coachId: coachId, lastMessageAt: now, lastSenderId: me.id);
    final child = db.children[childId]!;
    for (final u in {coachId, ...child.parentIds}) {
      if (u == me.id) continue;
      db.notifyUser(
        u,
        NotificationType.childMessage,
        route: '/student/$childId/coach/$coachId',
        args: {'child': child.firstName, 'sender': me.fullName, 'childId': childId, 'coachId': coachId},
        childId: childId,
        dedupeKey: 'thread:$id:${m.id}',
      );
    }
    db.commit();
  }

  @override
  Stream<List<ChildThread>> watchMyThreads() => db.watch(() {
    final me = db.currentUser;
    if (me == null) return const <ChildThread>[];
    return db.childThreads.values.where((t) => canUse(me, t.childId, t.coachId)).toList()
      ..sort((a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0)));
  });
}
