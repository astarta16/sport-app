import '../../../core/utils/dates.dart';
import '../../authentication/domain/app_user.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.attachments = const [],
  });

  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String text;
  final List<String> attachments;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole.name,
    'text': text,
    'attachments': attachments,
    'createdAt': createdAt,
  };

  factory ChatMessage.fromMap(String groupId, String id, Map<String, dynamic> m) => ChatMessage(
    id: id,
    groupId: groupId,
    senderId: m['senderId'] as String? ?? '',
    senderName: m['senderName'] as String? ?? '',
    senderRole: UserRole.fromName(m['senderRole'] as String?),
    text: m['text'] as String? ?? '',
    attachments: readStringList(m['attachments']),
    createdAt: readDateOrNull(m['createdAt']) ?? DateTime.now(),
  );
}

class ChatValidator {
  ChatValidator._();

  static const maxLength = 2000;

  static String? validate(String text, List<String> attachments) {
    if (text.trim().isEmpty && attachments.isEmpty) return 'emptyMessage';
    if (text.length > maxLength) return 'messageTooLong';
    return null;
  }
}
