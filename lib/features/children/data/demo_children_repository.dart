import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/child.dart';
import '../domain/children_repository.dart';

class DemoChildrenRepository implements ChildrenRepository {
  DemoChildrenRepository(this.db);

  final DemoBackend db;

  int _byName(Child a, Child b) => a.birthDate.compareTo(b.birthDate);

  @override
  Stream<List<Child>> watchMyChildren() => db.watch(() {
        final me = db.me;
        return db.children.values.where((c) => AccessPolicy.isParentOf(me, c)).toList()..sort(_byName);
      });

  @override
  Stream<Child?> watchChild(String childId) => db.watch(() {
        final c = db.children[childId];
        if (c == null) return null;
        if (!AccessPolicy.canViewChild(db.me, c, db.groupsOfChild(c.id))) throw const PermissionDeniedException();
        return c;
      });

  @override
  Stream<List<Child>> watchGroupMembers(String groupId) => db.watch(() {
        final g = db.requireGroup(groupId);
        if (!AccessPolicy.isCoachOf(db.me, g) && !db.me.isAdmin) throw const PermissionDeniedException();
        return g.memberChildIds.map((id) => db.children[id]).whereType<Child>().toList()
          ..sort((a, b) => a.firstName.compareTo(b.firstName));
      });

  @override
  Future<Child> addChild(ChildDraft d) async {
    final me = db.me;
    if (!me.isParent) throw const PermissionDeniedException('only parents add children');
    for (final v in [Validators.name(d.firstName), Validators.name(d.lastName), Validators.birthDate(d.birthDate, db.clock())]) {
      if (v != null) throw ValidationException(v);
    }
    if (d.sportIds.isEmpty) throw const ValidationException('sportRequired');
    final child = Child(
      id: db.newId('child'),
      firstName: d.firstName.trim(),
      lastName: d.lastName.trim(),
      birthDate: d.birthDate,
      parentIds: [me.id],
      sportIds: d.sportIds,
      photoConsent: d.photoConsent,
    );
    db.children[child.id] = child;
    db.commit();
    return child;
  }

  @override
  Future<void> updateChild(Child child) async {
    final existing = db.requireChild(child.id);
    if (!AccessPolicy.canEditChild(db.me, existing)) throw const PermissionDeniedException();
    // Parents may not change memberships or co-parents from the client.
    db.children[child.id] = child.copyWith(parentIds: existing.parentIds, groupIds: existing.groupIds);
    db.commit();
  }

  @override
  Future<void> removeChild(String childId) async {
    final c = db.requireChild(childId);
    if (!AccessPolicy.canEditChild(db.me, c)) throw const PermissionDeniedException();
    for (final cert in db.certificates.values.where((x) => x.childId == childId).toList()) {
      db.certificateFiles.remove(cert.storagePath);
      db.certificates.remove(cert.id);
    }
    db.children.remove(childId);
    for (final g in db.groups.values.toList()) {
      db.groups[g.id] = g.copyWith(memberChildIds: g.memberChildIds.where((id) => id != childId).toList());
    }
    db.recomputeMemberships();
    db.commit();
  }
}
