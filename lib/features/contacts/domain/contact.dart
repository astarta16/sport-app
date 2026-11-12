/// Relationship of a guardian to a child, when recorded.
enum GuardianRelation {
  mother,
  father,
  guardian,
  grandparent,
  other;

  static GuardianRelation? fromName(String? n) => values.where((v) => v.name == n).firstOrNull;
}

class ContactChild {
  const ContactChild({required this.id, required this.firstName, this.relation});

  final String id;
  final String firstName;
  final GuardianRelation? relation;
}

/// One entry of a group's scoped contact projection (v1.4). Built by the
/// backend from CURRENT active group relationships only: a coach gets the
/// group's parents/guardians, a parent gets the group's approved coaches.
class GroupContact {
  const GroupContact({
    required this.uid,
    required this.isCoach,
    required this.name,
    this.phone,
    this.children = const [],
  });

  final String uid;
  final bool isCoach;
  final String name;

  /// Never logged; null when the backend withholds it.
  final String? phone;

  /// Parents only: their children in this group.
  final List<ContactChild> children;

  factory GroupContact.fromMap(Map<String, dynamic> m) => GroupContact(
    uid: m['uid'] as String? ?? '',
    isCoach: m['role'] == 'coach',
    name: m['name'] as String? ?? '',
    phone: m['phone'] as String?,
    children: [
      for (final c in (m['children'] as List? ?? const []))
        ContactChild(
          id: (c as Map)['id'] as String? ?? '',
          firstName: c['firstName'] as String? ?? '',
          relation: GuardianRelation.fromName(c['relation'] as String?),
        ),
    ],
  );
}

abstract interface class ContactsRepository {
  /// Throws PermissionDeniedException when the caller has no active,
  /// authorized relationship with the group.
  Future<List<GroupContact>> groupContacts(String groupId);
}
