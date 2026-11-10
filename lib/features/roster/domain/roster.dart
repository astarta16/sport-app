import '../../attendance/domain/attendance.dart';
import '../../children/domain/child.dart';
import '../../medical_certificates/domain/medical_certificate.dart';

/// One row of the coach's student roster (own groups only).
class RosterEntry {
  const RosterEntry({
    required this.child,
    required this.groupId,
    required this.groupName,
    required this.age,
    required this.certStatus,
    this.cert,
    this.attendanceRate,
    this.recorded = 0,
  });

  final Child child;
  final String groupId;
  final String groupName;
  final int age;
  final CertificateStatus certStatus;

  /// Current certificate for the group's sport (status/expiry only shown).
  final MedicalCertificate? cert;
  final double? attendanceRate;
  final int recorded;
}

enum RosterSort { name, age, attendance, certificate }

enum RosterFilter { all, certIssues, lowAttendance }

/// Pure search/sort/filter so it can be unit-tested.
class RosterQuery {
  const RosterQuery({this.search = '', this.sort = RosterSort.name, this.filter = RosterFilter.all});

  final String search;
  final RosterSort sort;
  final RosterFilter filter;

  static const lowAttendance = 0.7;

  List<RosterEntry> apply(Iterable<RosterEntry> rows) {
    final q = search.trim().toLowerCase();
    final list = rows.where((r) {
      if (q.isNotEmpty && !r.child.fullName.toLowerCase().contains(q)) return false;
      return switch (filter) {
        RosterFilter.all => true,
        RosterFilter.certIssues => r.certStatus != CertificateStatus.valid,
        RosterFilter.lowAttendance => r.attendanceRate != null && r.attendanceRate! < lowAttendance,
      };
    }).toList();
    int byName(RosterEntry a, RosterEntry b) => a.child.fullName.compareTo(b.child.fullName);
    list.sort(switch (sort) {
      RosterSort.name => byName,
      RosterSort.age => (a, b) => a.age != b.age ? a.age - b.age : byName(a, b),
      RosterSort.attendance => (a, b) => (a.attendanceRate ?? -1).compareTo(b.attendanceRate ?? -1),
      RosterSort.certificate =>
        (a, b) => _certRank(a.certStatus) != _certRank(b.certStatus)
            ? _certRank(a.certStatus) - _certRank(b.certStatus)
            : byName(a, b),
    });
    return list;
  }

  static int _certRank(CertificateStatus s) => switch (s) {
    CertificateStatus.missing => 0,
    CertificateStatus.expired => 1,
    CertificateStatus.expiring => 2,
    CertificateStatus.valid => 3,
  };
}

/// Builds roster rows from data the coach can already read.
List<RosterEntry> buildRoster({
  required List<Child> members,
  required String groupId,
  required String groupName,
  required String sportId,
  required List<MedicalCertificate> certs,
  required List<AttendanceRecord> attendance,
  required Map<String, DateTime> trainingStarts,
  required DateTime now,
}) => [
  for (final c in members)
    () {
      final mine = certs.where((x) => x.childId == c.id).toList();
      final current = CertificatePolicy.current(mine, sportId: sportId);
      final stats = AttendanceStats.compute(attendance.where((a) => a.childId == c.id), trainingStarts);
      return RosterEntry(
        child: c,
        groupId: groupId,
        groupName: groupName,
        age: c.ageOn(now),
        certStatus: current == null ? CertificateStatus.missing : current.statusOn(now),
        cert: current,
        attendanceRate: stats.rate,
        recorded: stats.recorded,
      );
    }(),
];
