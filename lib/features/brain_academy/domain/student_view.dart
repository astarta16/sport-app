import '../../children/domain/child.dart';
import '../../groups/domain/group.dart';
import '../../matches/domain/match.dart';
import '../../training_plans/domain/training_plan.dart';
import '../../trainings/domain/training.dart';
import '../../attendance/domain/attendance.dart';
import '../../clubs/domain/club.dart';

/// Everything a student may see about themselves (v1.6). Deliberately has
/// no payments, certificates, chat, phone numbers or other children.
class StudentView {
  const StudentView({
    required this.child,
    required this.groups,
    required this.coachNames,
    required this.trainings,
    required this.matches,
    required this.plans,
    required this.attendance,
    this.venues = const {},
  });

  final Child child;
  final List<Group> groups;

  /// coachId → display name (no contact data).
  final Map<String, String> coachNames;
  final List<Training> trainings;
  final List<SportMatch> matches;

  /// Published plans of the student's groups.
  final List<TrainingPlan> plans;

  /// Coach-recorded attendance of this child only.
  final List<AttendanceRecord> attendance;

  /// v1.7: public venue data of the student's own events only (name,
  /// address, map pin) — never other venues or private data.
  final Map<String, Venue> venues;
}

abstract interface class StudentRepository {
  /// The signed-in student's own view; PermissionDeniedException otherwise.
  Stream<StudentView> watchMyView();
}
