import '../../../core/utils/dates.dart';
import '../../authentication/domain/app_user.dart';

enum ChatMessageType {
  text,

  /// Coach announcement, pinned at the top (v1.1 §4).
  announcement,

  /// Server-written (cancellation, schedule change, new match …).
  system;

  static ChatMessageType fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => text);
}

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
    this.type = ChatMessageType.text,
    this.pinned = false,
    this.hidden = false,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String text;
  final List<String> attachments;
  final DateTime createdAt;
  final ChatMessageType type;
  final bool pinned;

  /// Hidden by moderation: rendered as a placeholder, content not shown.
  final bool hidden;

  bool get isSystem => type == ChatMessageType.system;
  bool get isAnnouncement => type == ChatMessageType.announcement;

  ChatMessage copyWith({bool? pinned, bool? hidden}) => ChatMessage(
    id: id,
    groupId: groupId,
    senderId: senderId,
    senderName: senderName,
    senderRole: senderRole,
    text: text,
    createdAt: createdAt,
    attachments: attachments,
    type: type,
    pinned: pinned ?? this.pinned,
    hidden: hidden ?? this.hidden,
  );

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'pinned': pinned,
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
    type: ChatMessageType.fromName(m['type'] as String?),
    pinned: m['pinned'] as bool? ?? false,
    hidden: m['hidden'] as bool? ?? false,
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
