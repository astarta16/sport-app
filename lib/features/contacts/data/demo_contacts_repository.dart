import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/contact.dart';

/// Demo mirror of the `getGroupContacts` callable (same policy as the server).
class DemoContactsRepository implements ContactsRepository {
  DemoContactsRepository(this.db);

  final DemoBackend db;

  @override
  Future<List<GroupContact>> groupContacts(String groupId) async {
    final me = db.me;
    final g = db.requireGroup(groupId);
    if (!g.isActive) throw const PermissionDeniedException('contacts');
    if (AccessPolicy.isCoachOf(me, g)) {
      return [
        for (final pid in g.parentIds)
          if (db.users[pid] case final p? when p.isParent)
            GroupContact(
              uid: p.id,
              isCoach: false,
              name: p.fullName,
              phone: p.phone,
              children: [
                for (final cid in g.memberChildIds)
                  if (db.children[cid] case final c? when c.parentIds.contains(p.id))
                    ContactChild(
                      id: c.id,
                      firstName: c.firstName,
                      relation: GuardianRelation.fromName(db.guardianRelations[c.id]?[p.id]),
                    ),
              ],
            ),
      ];
    }
    if (AccessPolicy.isParentInGroup(me, g)) {
      return [
        for (final cid in g.coachIds)
          if (db.users[cid] case final c? when c.isApprovedCoach)
            GroupContact(uid: c.id, isCoach: true, name: c.fullName, phone: c.phone),
      ];
    }
    throw const PermissionDeniedException('contacts');
  }
}
