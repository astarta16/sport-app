import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../../notifications/domain/notification_models.dart';
import '../../trainings/domain/training.dart';
import '../domain/match.dart';

class DemoMatchesRepository implements MatchesRepository {
  DemoMatchesRepository(this.db);

  final DemoBackend db;

  @override
  Stream<List<SportMatch>> watchForGroups(List<String> groupIds) => db.watch(() {
    final me = db.me;
    final visible = groupIds.where((id) {
      final g = db.groups[id];
      return g != null && AccessPolicy.canViewTrainings(me, g);
    }).toSet();
    return db.matches.values.where((m) => visible.contains(m.groupId)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  });

  @override
  Stream<SportMatch?> watchMatch(String id) => db.watch(() {
    final m = db.matches[id];
    if (m == null) return null;
    if (!AccessPolicy.canViewTrainings(db.me, db.requireGroup(m.groupId))) throw const PermissionDeniedException();
    return m;
  });

  void _guard(String groupId) {
    if (!AccessPolicy.canManageMatches(db.me, db.requireGroup(groupId))) {
      throw const PermissionDeniedException('not coach of group');
    }
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Future<SportMatch> create(MatchDraft d) async {
    db.requireOnline();
    _guard(d.groupId);
    final errors = MatchDraft.validate(d, now: db.clock());
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final g = db.groups[d.groupId]!;
    final m = SportMatch(
      id: db.newId('match'),
      groupId: d.groupId,
      clubId: g.clubId,
      venueId: d.venueId,
      startAt: d.startAt,
      durationMin: d.durationMin,
      opponentName: d.opponentName.trim(),
      matchType: d.matchType,
      homeAway: d.homeAway,
      description: d.description?.trim(),
      createdBy: db.me.id,
      updatedAt: db.clock(),
    );
    db.matches[m.id] = m;
    db.dispatch(
      NotificationType.newMatch,
      g,
      route: '/match/${m.id}',
      args: {'opponent': m.opponentName},
      dedupeKey: 'match:${m.id}:created',
    );
    db.systemMessage(
      g.id,
      'დაემატა თამაში: ${m.opponentName}, ${_fmt(m.startAt)}',
      key: 'matchCreated',
      args: {'opponent': m.opponentName, 'when': _fmt(m.startAt)},
    );
    db.commit();
    return m;
  }

  @override
  Future<SportMatch> update(String id, MatchDraft d) async {
    db.requireOnline();
    final old = db.matches[id] ?? (throw const NotFoundException());
    _guard(old.groupId);
    if (old.status == MatchStatus.cancelled) throw const ValidationException('matchCancelled');
    final errors = MatchDraft.validate(d, now: db.clock(), isEdit: true);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final moved = !d.startAt.isAtSameMomentAs(old.startAt);
    final m = old.copyWith(
      venueId: d.venueId,
      startAt: d.startAt,
      opponentName: d.opponentName.trim(),
      matchType: d.matchType,
      homeAway: d.homeAway,
      description: d.description?.trim(),
      status: moved ? MatchStatus.moved : old.status,
      previousStartAt: moved ? old.startAt : null,
      updatedAt: db.clock(),
    );
    db.matches[id] = m;
    if (moved || d.venueId != old.venueId) {
      final g = db.groups[old.groupId]!;
      db.dispatch(
        NotificationType.matchChanged,
        g,
        route: '/match/$id',
        args: {'opponent': m.opponentName, 'kind': 'moved'},
        dedupeKey: 'match:$id:moved:${d.startAt.millisecondsSinceEpoch}:${d.venueId}',
      );
      if (moved) {
        db.systemMessage(
          g.id,
          'თამაში გადაიდო: ${_fmt(old.startAt)} → ${_fmt(m.startAt)}',
          key: 'matchMoved',
          args: {'from': _fmt(old.startAt), 'to': _fmt(m.startAt)},
        );
      }
    }
    db.commit();
    return m;
  }

  @override
  Future<void> cancel(String id, CancelReason reason) async {
    db.requireOnline();
    final m = db.matches[id] ?? (throw const NotFoundException());
    _guard(m.groupId);
    final error = CancelReason.validate(reason.code, reason.text);
    if (error != null) throw ValidationException(error);
    if (m.status == MatchStatus.cancelled) return;
    db.matches[id] = m.copyWith(
      status: MatchStatus.cancelled,
      cancelReasonCode: reason.code,
      cancelReason: reason.text.trim(),
      cancelledAt: db.clock(),
      cancelledBy: db.me.id,
      updatedAt: db.clock(),
    );
    final g = db.groups[m.groupId]!;
    db.dispatch(
      NotificationType.matchChanged,
      g,
      route: '/match/$id',
      args: {'opponent': m.opponentName, 'kind': 'cancelled', 'reason': reason.text.trim()},
      dedupeKey: 'match:$id:cancelled',
    );
    db.systemMessage(
      g.id,
      'თამაში (${m.opponentName}) გაუქმდა. მიზეზი: ${reason.text.trim()}',
      key: 'matchCancelled',
      args: {'opponent': m.opponentName, 'reason': reason.text.trim()},
    );
    db.commit();
  }

  @override
  Future<void> markPlayed(String id) async {
    db.requireOnline();
    final m = db.matches[id] ?? (throw const NotFoundException());
    _guard(m.groupId);
    db.matches[id] = m.copyWith(status: MatchStatus.played, updatedAt: db.clock());
    db.commit();
  }
}
