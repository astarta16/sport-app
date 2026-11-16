import '../../../core/utils/dates.dart';
import '../../authentication/domain/app_user.dart';

/// v1.5 child-context conversation between a child's guardians and ONE of
/// the child's coaches (`childThreads/{childId}_{coachId}`). Other parents
/// never see it; children have no access.
class ChildThread {
  const ChildThread({required this.childId, required this.coachId, this.lastMessageAt, this.lastSenderId});

  final String childId;
  final String coachId;
  final DateTime? lastMessageAt;
  final String? lastSenderId;

  String get id => idOf(childId, coachId);

  static String idOf(String childId, String coachId) => '${childId}_$coachId';

  factory ChildThread.fromMap(Map<String, dynamic> m) => ChildThread(
    childId: m['childId'] as String? ?? '',
    coachId: m['coachId'] as String? ?? '',
    lastMessageAt: readDateOrNull(m['lastMessageAt']),
    lastSenderId: m['lastSenderId'] as String?,
  );
}

class ChildThreadMessage {
  const ChildThreadMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String text;
  final DateTime createdAt;

  static const maxLength = 2000;

  factory ChildThreadMessage.fromMap(String id, Map<String, dynamic> m) => ChildThreadMessage(
    id: id,
    senderId: m['senderId'] as String? ?? '',
    senderName: m['senderName'] as String? ?? '',
    senderRole: UserRole.fromName(m['senderRole'] as String?),
    text: m['text'] as String? ?? '',
    createdAt: readDateOrNull(m['createdAt']) ?? DateTime.now(),
  );
}

abstract interface class ChildThreadsRepository {
  /// Throws PermissionDeniedException unless the caller is a current guardian
  /// of the child or the coach while coaching the child.
  Stream<List<ChildThreadMessage>> watchMessages(String childId, String coachId);
  Future<void> send(String childId, String coachId, String text);

  /// Coach: threads about own students; parent: threads about own children.
  Stream<List<ChildThread>> watchMyThreads();
}
