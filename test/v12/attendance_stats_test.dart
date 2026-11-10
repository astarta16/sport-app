import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/utils/dates.dart';
import 'package:sport_parent_app/features/attendance/domain/attendance.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';

void main() {
  AttendanceRecord rec(String t, AttendanceStatus s) => AttendanceRecord(
    trainingId: t,
    groupId: 'g',
    childId: 'c',
    status: s,
    markedBy: 'coach',
    markedAt: DateTime.utc(2026),
  );

  test('only recorded attendance counts; rates per Tbilisi month', () {
    final starts = {
      't1': TbilisiTime.at(2026, 9, 1, 18),
      't2': TbilisiTime.at(2026, 9, 3, 18),
      't3': TbilisiTime.at(2026, 9, 30, 21), // still September in Tbilisi
      't4': TbilisiTime.at(2026, 10, 1, 18),
    };
    final s = AttendanceStats.compute([
      rec('t1', AttendanceStatus.present),
      rec('t2', AttendanceStatus.absent),
      rec('t3', AttendanceStatus.excused),
      rec('t4', AttendanceStatus.present),
    ], starts);
    expect(s.totalPresent, 2);
    expect(s.months.first.recorded, 3);
    expect(s.months.first.rate, closeTo(1 / 3, 1e-9));
    expect(s.months.last.rate, 1);
    expect(s.achievements.map((a) => a.kind), [AchievementKind.firstTraining]);
  });

  test('milestones, perfect month and 3-month streak', () {
    final starts = <String, DateTime>{};
    final records = <AttendanceRecord>[];
    var n = 0;
    for (final month in [8, 9, 10]) {
      for (var d = 1; d <= 4; d++) {
        final id = 't${n++}';
        starts[id] = TbilisiTime.at(2026, month, d * 5, 17);
        records.add(rec(id, AttendanceStatus.present));
      }
    }
    final s = AttendanceStats.compute(records, starts);
    final kinds = s.achievements.map((a) => a.kind).toList();
    expect(kinds, containsAll([AchievementKind.firstTraining, AchievementKind.attended5, AchievementKind.attended10]));
    expect(kinds.where((k) => k == AchievementKind.perfectMonth), hasLength(3));
    expect(kinds, contains(AchievementKind.streak3Months));
  });

  test('records for unknown trainings are ignored (no fabricated stats)', () {
    final s = AttendanceStats.compute([rec('ghost', AttendanceStatus.present)], const {});
    expect(s.recorded, 0);
    expect(s.rate, isNull);
  });

  test('feedback validation', () {
    expect(CoachFeedback.validate(const {}, ''), 'feedbackEmpty');
    expect(CoachFeedback.validate(const {FeedbackCategory.effort: 6}, null), 'feedbackRating');
    expect(CoachFeedback.validate(const {FeedbackCategory.effort: 5}, 'კარგი'), isNull);
  });

  test('notification categories and preferences per category', () {
    expect(NotificationType.newMatch.category, NotificationCategory.matches);
    expect(NotificationType.groupInvite.category, NotificationCategory.invitations);
    const prefs = NotificationPreferences();
    final off = prefs.toggleCategory(NotificationCategory.matches, false);
    expect(off.isEnabled(NotificationType.matchReminder), isFalse);
    expect(off.isEnabled(NotificationType.newTraining), isTrue);
    expect(off.isCategoryEnabled(NotificationCategory.matches), isFalse);
  });
}
