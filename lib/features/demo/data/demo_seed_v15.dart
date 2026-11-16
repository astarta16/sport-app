import '../../authentication/domain/app_user.dart';
import '../../child_threads/domain/child_thread.dart';
import '../../matches/domain/match.dart';
import 'demo_backend.dart';
import 'demo_seed.dart';

/// v1.5 demo data (fictional):
/// - a finished U-10 match with a final score (3:1 win) and coach summary;
/// - a U-10 match played yesterday WITHOUT a result yet (the coach can enter it);
/// - a child-context conversation between Luka's parents and coach Giorgi.
class DemoSeedV15 {
  DemoSeedV15._();

  static const resultMatch = 'match-res-1';
  static const pendingResultMatch = 'match-past-1';

  static void seed(DemoBackend db) {
    final now = db.clock();
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int days, int h) => today.add(Duration(days: days, hours: h));

    db.matches[resultMatch] = SportMatch(
      id: resultMatch,
      groupId: 'g-football-u10',
      clubId: 'club-1',
      venueId: 'venue-1',
      startAt: at(-3, 11),
      opponentName: 'ვაკის ლომები U-10',
      matchType: MatchType.friendly,
      homeAway: HomeAway.home,
      status: MatchStatus.played,
      createdBy: DemoIds.coach,
      updatedAt: at(-3, 13),
      result: MatchResult(
        ourScore: 3,
        opponentScore: 1,
        summary: 'კარგი პასები და თავდაცვა — ყოჩაღ, გუნდო!',
        completedAt: at(-3, 13),
        recordedBy: DemoIds.coach,
      ),
    );
    db.matchResultHistory[resultMatch] = [MatchResultChange(version: 1, by: DemoIds.coach, at: at(-3, 13), to: (3, 1))];
    db.matches[pendingResultMatch] = SportMatch(
      id: pendingResultMatch,
      groupId: 'g-football-u10',
      clubId: 'club-1',
      venueId: 'venue-7',
      startAt: at(-1, 11),
      opponentName: 'საბურთალოს ვარსკვლავები U-10',
      matchType: MatchType.league,
      homeAway: HomeAway.away,
      createdBy: DemoIds.coach,
      updatedAt: at(-2, 10),
    );

    // Child-context conversation (Luka, coach Giorgi).
    final thread = ChildThread.idOf('child-1', DemoIds.coach);
    final coach = db.users[DemoIds.coach];
    final parent = db.users[DemoIds.parent];
    if (coach != null && parent != null) {
      db.childThreadMessages[thread] = [
        ChildThreadMessage(
          id: 'tmsg-seed-1',
          senderId: parent.id,
          senderName: parent.fullName,
          senderRole: UserRole.parent,
          text: 'გამარჯობა! ლუკამ მუხლი იტკინა, შაბათს შეძლებს თამაშს?',
          createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        ChildThreadMessage(
          id: 'tmsg-seed-2',
          senderId: coach.id,
          senderName: coach.fullName,
          senderRole: UserRole.coach,
          text: 'გამარჯობა! ვნახოთ ხუთშაბათის ვარჯიშზე — თუ არ სტკივა, ითამაშებს.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      db.childThreads[thread] = ChildThread(
        childId: 'child-1',
        coachId: coach.id,
        lastMessageAt: now.subtract(const Duration(days: 1)),
        lastSenderId: coach.id,
      );
    }
  }
}
