import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../../trainings/domain/training.dart';
import '../domain/match.dart';

/// `matches/{id}`. Push + system chat messages and the 1-day / 2-hour
/// reminders are sent by Cloud Functions (onMatchWritten, matchReminders).
class FirebaseMatchesRepository implements MatchesRepository {
  FirebaseMatchesRepository(this.auth, this.db, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final DateTime Function() clock;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('matches');

  @override
  Stream<List<SportMatch>> watchForGroups(List<String> groupIds) {
    if (groupIds.isEmpty) return Stream.value(const []);
    return _col
        .where('groupId', whereIn: groupIds.take(30).toList())
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => SportMatch.fromMap(d.id, d.data())).toList()
                ..sort((a, b) => a.startAt.compareTo(b.startAt)),
        )
        .mapFirebaseErrors();
  }

  @override
  Stream<SportMatch?> watchMatch(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.data() == null ? null : SportMatch.fromMap(d.id, d.data()!))
      .mapFirebaseErrors();

  @override
  Future<SportMatch> create(MatchDraft d) => guardFirebase(() async {
    final errors = MatchDraft.validate(d, now: clock());
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final group = (await db.collection('groups').doc(d.groupId).get()).data() ?? const {};
    final ref = _col.doc();
    final m = SportMatch(
      id: ref.id,
      groupId: d.groupId,
      clubId: group['clubId'] as String? ?? '',
      venueId: d.venueId,
      startAt: d.startAt,
      durationMin: d.durationMin,
      opponentName: d.opponentName.trim(),
      matchType: d.matchType,
      homeAway: d.homeAway,
      description: d.description?.trim(),
      createdBy: requireUid(auth),
      updatedAt: clock(),
    );
    await ref.set(m.toMap()..removeWhere((_, v) => v == null));
    return m;
  });

  @override
  Future<SportMatch> update(String id, MatchDraft d) => guardFirebase(() async {
    final old = SportMatch.fromMap(id, (await _col.doc(id).get()).data() ?? (throw const NotFoundException()));
    final errors = MatchDraft.validate(d, now: clock(), isEdit: true);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final moved = !d.startAt.isAtSameMomentAs(old.startAt);
    await _col.doc(id).update({
      'venueId': d.venueId,
      'startAt': d.startAt,
      'opponentName': d.opponentName.trim(),
      'matchType': d.matchType.name,
      'homeAway': d.homeAway.name,
      'description': d.description?.trim(),
      if (moved) 'status': MatchStatus.moved.name,
      if (moved) 'previousStartAt': old.startAt,
      'updatedAt': clock(),
    });
    return old.copyWith(venueId: d.venueId, startAt: d.startAt, opponentName: d.opponentName.trim());
  });

  @override
  Future<void> cancel(String id, CancelReason reason) => guardFirebase(() async {
    final error = CancelReason.validate(reason.code, reason.text);
    if (error != null) throw ValidationException(error);
    await _col.doc(id).update({
      'status': MatchStatus.cancelled.name,
      'cancelReasonCode': reason.code.name,
      'cancelReason': reason.text.trim(),
      'cancelledAt': clock(),
      'cancelledBy': requireUid(auth),
      'updatedAt': clock(),
    });
  });

  @override
  Future<void> markPlayed(String id) =>
      guardFirebase(() => _col.doc(id).update({'status': MatchStatus.played.name, 'updatedAt': clock()}));
}
