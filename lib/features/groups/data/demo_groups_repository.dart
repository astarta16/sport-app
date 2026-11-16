import 'dart:math';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../authentication/domain/access_policy.dart';
import '../../children/domain/child.dart';
import '../../clubs/domain/club.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../../payments/domain/payment.dart';
import '../domain/group.dart';
import '../domain/groups_repository.dart';

class DemoGroupsRepository implements GroupsRepository {
  DemoGroupsRepository(this.db, {Random? random}) : _random = random ?? Random(7);

  final DemoBackend db;
  final Random _random;

  @override
  Stream<List<Group>> watchMyGroups() => db.watch(() {
    final me = db.me;
    return db.groups.values.where((g) => AccessPolicy.canViewGroup(me, g)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  });

  @override
  Stream<Group?> watchGroup(String id) => db.watch(() {
    final g = db.groups[id];
    if (g == null) return null;
    if (!AccessPolicy.canViewGroup(db.me, g)) throw const PermissionDeniedException();
    return g;
  });

  /// Public info only — member/parent lists and codes are stripped.
  @override
  Future<List<Group>> clubGroups(String clubId) async => db.groups.values
      .where((g) => g.clubId == clubId && g.isActive)
      .map((g) => g.copyWith(memberChildIds: const [], parentIds: const [], inviteCode: ''))
      .toList();

  @override
  Future<void> removeMember(String groupId, String childId) async {
    db.requireOnline();
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException();
    db.groups[groupId] = g.copyWith(memberChildIds: g.memberChildIds.where((c) => c != childId).toList());
    db.recomputeMemberships();
    db.auditLog('group.removeMember', 'group', groupId, clubId: g.clubId, details: {'childId': childId});
    db.commit();
  }

  String _uniqueCode() {
    final used = db.groups.values.map((g) => g.inviteCode).toSet();
    while (true) {
      final c = InviteCodes.generate(_random.nextInt);
      if (!used.contains(c)) return c;
    }
  }

  @override
  Future<Group> createGroup(GroupDraft d) async {
    db.requireOnline();
    final me = db.me;
    if (!AccessPolicy.canCreateGroup(me, d.clubId)) throw const PermissionDeniedException('club');
    final club = db.clubs[d.clubId];
    if (club == null || club.archived) throw const ValidationException('clubArchived');
    final errors = GroupDraft.validate(d);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    db.requireWithinLimit(d.clubId, 'groups');
    final g = Group(
      id: db.newId('g'),
      clubId: d.clubId,
      sportId: d.sportId,
      coachIds: [me.id],
      name: d.name.trim(),
      ageMin: d.ageMin,
      ageMax: d.ageMax,
      scheduleNote: d.scheduleNote,
      inviteCode: _uniqueCode(),
      createdBy: me.id,
    );
    db.groups[g.id] = g;
    db.auditLog('group.create', 'group', g.id, clubId: g.clubId, details: {'name': g.name});
    db.commit();
    return g;
  }

  Group _coachGroup(String groupId) {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.canInviteToGroup(db.me, g)) throw const PermissionDeniedException('not coach of group');
    return g;
  }

  /// Registered parent with this phone, if any — used only to address the
  /// invite. Nothing is linked until that parent accepts.
  String? _parentByPhone(String phone) {
    final n = Validators.normalizePhone(phone);
    for (final u in db.users.values) {
      if (u.isParent && Validators.normalizePhone(u.phone) == n) return u.id;
    }
    return null;
  }

  GroupInvite _send(
    Group g, {
    required String? childId,
    required String first,
    required String last,
    required String phone,
  }) {
    db.rateLimit('invite', 30);
    final dup = db.invites.values.any(
      (i) =>
          i.groupId == g.id &&
          i.status == InviteStatus.sent &&
          ((childId != null && i.childId == childId) || (i.phone == phone && i.childFirstName == first)),
    );
    if (dup) throw const ValidationException('inviteExists');
    final parentId = _parentByPhone(phone);
    final invite = GroupInvite(
      id: db.newId('inv'),
      groupId: g.id,
      clubId: g.clubId,
      sportId: g.sportId,
      groupName: g.name,
      childId: childId,
      childFirstName: first,
      childLastName: last,
      phone: phone,
      parentId: parentId,
      createdBy: db.me.id,
      createdAt: db.clock(),
    );
    db.invites[invite.id] = invite;
    if (parentId != null) {
      db.notifyUser(
        parentId,
        NotificationType.groupInvite,
        route: '/invites',
        args: {'group': g.name, 'child': first},
        groupId: g.id,
        dedupeKey: 'invite:${invite.id}',
      );
    } else {
      // Unregistered parent: SMS invite through the mock provider only.
      db.smsLog.add(
        SmsLogEntry(
          id: db.newId('sms'),
          at: db.clock(),
          maskedPhone: Validators.maskPhone(phone),
          text: 'მოწვევა ჯგუფში ${g.name}',
          status: 'sent',
          provider: 'mock',
          paymentIds: const [],
          kind: 'invite',
        ),
      );
    }
    return invite;
  }

  @override
  Future<GroupInvite> inviteExistingChild({required String groupId, required String childId}) async {
    db.requireOnline();
    final g = _coachGroup(groupId);
    final c = db.requireChild(childId);
    if (g.hasChild(childId)) throw const ValidationException('alreadyMember');
    if (c.parentIds.isEmpty) throw const ValidationException('childNotFound');
    final parent = db.users[c.parentIds.first]!;
    final i = _send(g, childId: c.id, first: c.firstName, last: c.lastName, phone: parent.phone);
    db.commit();
    return i;
  }

  @override
  Future<GroupInvite> invitePendingChild({required String groupId, required PendingChildDraft child}) async {
    db.requireOnline();
    final g = _coachGroup(groupId);
    final phone = Validators.normalizePhone(child.parentPhone);
    if (Validators.phone(phone) != null) throw const ValidationException('invalidPhone');
    if (child.firstName.trim().isEmpty || child.lastName.trim().isEmpty) throw const ValidationException('required');
    final c = Child(
      id: db.newId('child'),
      firstName: child.firstName.trim(),
      lastName: child.lastName.trim(),
      birthDate: child.birthDate,
      parentIds: const [],
      sportIds: [g.sportId],
      status: ChildStatus.pendingParent,
      createdByCoachId: db.me.id,
    );
    final invite = _send(g, childId: null, first: c.firstName, last: c.lastName, phone: phone);
    db.children[c.id] = c;
    db.invites[invite.id] = GroupInvite(
      id: invite.id,
      groupId: invite.groupId,
      clubId: invite.clubId,
      sportId: invite.sportId,
      groupName: invite.groupName,
      childId: c.id,
      childFirstName: invite.childFirstName,
      childLastName: invite.childLastName,
      phone: invite.phone,
      parentId: invite.parentId,
      createdBy: invite.createdBy,
      createdAt: invite.createdAt,
    );
    db.commit();
    return db.invites[invite.id]!;
  }

  @override
  Future<List<ChildSearchResult>> searchChildren(String query, {required String groupId}) async {
    final g = _coachGroup(groupId);
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    return db.children.values
        .where((c) => !c.isPending && !g.hasChild(c.id) && c.fullName.toLowerCase().contains(q))
        .take(20)
        .map(
          (c) => ChildSearchResult(
            childId: c.id,
            firstName: c.firstName,
            lastName: c.lastName,
            birthYear: c.birthDate.year,
          ),
        )
        .toList();
  }

  @override
  Stream<List<GroupInvite>> watchGroupInvites(String groupId) => db.watch(() {
    final g = db.requireGroup(groupId);
    if (!AccessPolicy.isCoachOf(db.me, g)) throw const PermissionDeniedException();
    return db.invites.values.where((i) => i.groupId == groupId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<void> revokeInvite(String inviteId) async {
    db.requireOnline();
    final i = db.invites[inviteId] ?? (throw const NotFoundException());
    _coachGroup(i.groupId);
    if (i.status != InviteStatus.sent) throw const ValidationException('inviteClosed');
    db.invites[inviteId] = i.copyWith(status: InviteStatus.revoked, decidedAt: db.clock());
    _discardPendingChild(i.childId);
    db.commit();
  }

  void _discardPendingChild(String? childId) {
    final c = childId == null ? null : db.children[childId];
    if (c != null && c.isPending && c.parentIds.isEmpty) db.children.remove(c.id);
  }

  bool _addressedToMe(GroupInvite i) {
    final me = db.me;
    return me.isParent &&
        (i.parentId == me.id || Validators.normalizePhone(i.phone) == Validators.normalizePhone(me.phone));
  }

  @override
  Stream<List<GroupInvite>> watchMyInvites() => db.watch(() {
    final me = db.currentUser;
    if (me == null || !me.isParent) return const <GroupInvite>[];
    return db.invites.values.where(_addressedToMe).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<void> respondInvite(
    String inviteId, {
    required bool accept,
    String? linkedChildId,
    bool mediaConsent = false,
  }) async {
    db.requireOnline();
    final me = db.me;
    final i = db.invites[inviteId] ?? (throw const NotFoundException());
    if (!_addressedToMe(i)) throw const PermissionDeniedException('invite');
    if (i.status != InviteStatus.sent) throw const ValidationException('inviteClosed');
    final g = db.requireGroup(i.groupId);
    if (!accept) {
      db.invites[inviteId] = i.copyWith(status: InviteStatus.declined, decidedAt: db.clock(), parentId: me.id);
      _discardPendingChild(i.childId);
      _tellCoach(g, i, accepted: false);
      db.commit();
      return;
    }
    late String childId;
    if (linkedChildId != null) {
      // Link one of MY children (explicit parent choice) — no duplicate record.
      final mine = db.requireChild(linkedChildId);
      if (!AccessPolicy.isParentOf(me, mine)) throw const PermissionDeniedException('not your child');
      childId = mine.id;
      if (i.childId != null && i.childId != childId) _discardPendingChild(i.childId);
    } else {
      final c = i.childId == null ? null : db.children[i.childId];
      if (c == null) throw const ValidationException('linkChildRequired');
      if (c.isPending) {
        db.children[c.id] = Child(
          id: c.id,
          firstName: c.firstName,
          lastName: c.lastName,
          birthDate: c.birthDate,
          parentIds: [me.id],
          sportIds: c.sportIds,
          photoConsent: mediaConsent,
          mediaConsentAt: db.clock(),
          createdByCoachId: c.createdByCoachId,
        );
      } else if (!AccessPolicy.isParentOf(me, c)) {
        throw const PermissionDeniedException('not your child');
      }
      childId = c.id;
    }
    final child = db.children[childId]!;
    db.children[childId] = child.copyWith(
      photoConsent: mediaConsent,
      mediaConsentAt: db.clock(),
      sportIds: child.sportIds.contains(g.sportId) ? null : [...child.sportIds, g.sportId],
    );
    if (!g.hasChild(childId)) {
      db.requireStudentCapacity(g.clubId, childId);
      db.groups[g.id] = g.copyWith(memberChildIds: [...g.memberChildIds, childId]);
    }
    db.recomputeMemberships();
    db.invites[inviteId] = i.copyWith(
      status: InviteStatus.accepted,
      decidedAt: db.clock(),
      linkedChildId: childId,
      parentId: me.id,
    );
    _tellCoach(db.groups[g.id]!, i, accepted: true);
    db.commit();
  }

  void _tellCoach(Group g, GroupInvite i, {required bool accepted}) {
    for (final c in g.coachIds) {
      db.notifyUser(
        c,
        NotificationType.inviteAnswered,
        route: '/group/${g.id}',
        args: {'group': g.name, 'child': i.childFirstName, 'kind': accepted ? 'accepted' : 'declined'},
        groupId: g.id,
        dedupeKey: 'inviteAnswer:${i.id}',
      );
    }
  }

  @override
  Future<String> joinByCode({required String code, required String childId}) async {
    db.requireOnline();
    final me = db.me;
    final child = db.requireChild(childId);
    if (!AccessPolicy.isParentOf(me, child)) throw const PermissionDeniedException();
    db.rateLimit('joinCode', 20);
    final c = InviteCodes.normalize(code);
    if (!InviteCodes.isValid(c)) throw const ValidationException('invalidGroupCode');
    final g = db.groups.values.where((g) => g.inviteCode == c && g.isActive).firstOrNull;
    if (g == null) throw const ValidationException('invalidGroupCode');
    if (g.hasChild(childId)) throw const ValidationException('alreadyMember');
    final dup = db.requests.values.any(
      (r) => r.childId == childId && r.groupId == g.id && r.status == RequestStatus.pending,
    );
    if (dup) throw const ValidationException('requestExists');
    final r = MembershipRequest(
      id: db.newId('req'),
      parentId: me.id,
      childId: childId,
      clubId: g.clubId,
      groupId: g.id,
      createdAt: db.clock(),
      childName: child.firstName,
      source: 'code',
    );
    db.requests[r.id] = r;
    db.commit();
    return g.name;
  }

  @override
  Future<void> leaveGroup({required String groupId, required String childId}) async {
    db.requireOnline();
    final me = db.me;
    final child = db.requireChild(childId);
    if (!AccessPolicy.isParentOf(me, child)) throw const PermissionDeniedException();
    final g = db.requireGroup(groupId);
    if (!g.hasChild(childId)) throw const ValidationException('notMember');
    db.groups[groupId] = g.copyWith(memberChildIds: g.memberChildIds.where((c) => c != childId).toList());
    db.recomputeMemberships();
    db.commit();
  }
}
