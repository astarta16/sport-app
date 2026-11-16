import '../../matches/domain/match.dart';
import '../../trainings/domain/training.dart';
import 'attendance.dart';

/// A training or a match, as seen by RSVP, attendance and the student
/// schedule (v1.7: both event types share one workflow).
class ScheduledEvent {
  const ScheduledEvent({
    required this.id,
    required this.type,
    required this.groupId,
    required this.venueId,
    required this.startAt,
    required this.durationMin,
    required this.version,
    required this.active,
    required this.cancelled,
    this.title = '',
    this.previousStartAt,
    this.previousVenueId,
    this.cancelReason,
  });

  factory ScheduledEvent.training(Training t) => ScheduledEvent(
    id: t.id,
    type: EventType.training,
    groupId: t.groupId,
    venueId: t.venueId,
    startAt: t.startAt,
    durationMin: t.durationMin,
    version: t.scheduleVersion,
    active: t.status.isActive,
    cancelled: t.status == TrainingStatus.cancelled,
    title: t.description,
    previousStartAt: t.previousStartAt,
    previousVenueId: t.previousVenueId,
    cancelReason: t.cancelReason,
  );

  factory ScheduledEvent.match(SportMatch m) => ScheduledEvent(
    id: m.id,
    type: EventType.match,
    groupId: m.groupId,
    venueId: m.venueId,
    startAt: m.startAt,
    durationMin: m.durationMin,
    version: m.scheduleVersion,
    active: m.status.isActive,
    cancelled: m.status == MatchStatus.cancelled,
    title: m.opponentName,
    previousStartAt: m.previousStartAt,
    previousVenueId: m.previousVenueId,
    cancelReason: m.cancelReason,
  );

  final String id;
  final EventType type;
  final String groupId;
  final String venueId;
  final DateTime startAt;
  final int durationMin;
  final int version;
  final bool active;
  final bool cancelled;

  /// Training description or match opponent.
  final String title;
  final DateTime? previousStartAt;
  final String? previousVenueId;
  final String? cancelReason;

  DateTime get endAt => startAt.add(Duration(minutes: durationMin));

  /// Date, time or place changed after creation.
  bool get rescheduled => version > 1 || previousStartAt != null || previousVenueId != null;

  String get route => type == EventType.match ? '/match/$id' : '/training/$id';
}
