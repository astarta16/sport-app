import '../../../core/utils/dates.dart';

enum ContactRequestStatus { open, handled }

/// A student's request that their parent contacts the coach (v1.7). The
/// student never gets the coach's or the guardians' phone numbers; the
/// parent decides and uses the existing parent–coach chat / call.
class CoachContactRequest {
  const CoachContactRequest({
    required this.id,
    required this.childId,
    required this.coachId,
    required this.groupId,
    required this.topic,
    required this.createdAt,
    this.status = ContactRequestStatus.open,
    this.handledBy,
  });

  static const topics = ['question', 'absence', 'training', 'other'];

  final String id;
  final String childId;
  final String coachId;
  final String groupId;
  final String topic;
  final DateTime createdAt;
  final ContactRequestStatus status;
  final String? handledBy;

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'coachId': coachId,
    'groupId': groupId,
    'topic': topic,
    'createdAt': createdAt,
    'status': status.name,
    'handledBy': handledBy,
  };

  factory CoachContactRequest.fromMap(String id, Map<String, dynamic> m) => CoachContactRequest(
    id: id,
    childId: m['childId'] as String? ?? '',
    coachId: m['coachId'] as String? ?? '',
    groupId: m['groupId'] as String? ?? '',
    topic: m['topic'] as String? ?? 'other',
    createdAt: readDate(m['createdAt']),
    status: m['status'] == 'handled' ? ContactRequestStatus.handled : ContactRequestStatus.open,
    handledBy: m['handledBy'] as String?,
  );

  CoachContactRequest handled(String by) => CoachContactRequest(
    id: id,
    childId: childId,
    coachId: coachId,
    groupId: groupId,
    topic: topic,
    createdAt: createdAt,
    status: ContactRequestStatus.handled,
    handledBy: by,
  );
}
