import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/utils/geo.dart';
import 'package:sport_parent_app/features/authentication/domain/app_user.dart';
import 'package:sport_parent_app/features/chat/domain/chat_message.dart';
import 'package:sport_parent_app/features/children/domain/child.dart';
import 'package:sport_parent_app/features/clubs/domain/club.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/medical_certificates/domain/medical_certificate.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';
import 'package:sport_parent_app/features/payments/domain/payment.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 10, 8);

  test('AppUser round-trips, including prefs and lastContext', () {
    final u = AppUser(
      id: 'u1',
      role: UserRole.coach,
      firstName: 'გიორგი',
      lastName: 'კაპანაძე',
      phone: '+995555000201',
      createdAt: t0,
      coachStatus: CoachStatus.pending,
      clubIds: const ['c1'],
      sportIds: const ['football'],
      lastContext: const UserContext(childId: 'k', sportId: 's', groupId: 'g'),
      notificationPrefs: const NotificationPreferences().toggle(NotificationType.chatMessage, false),
      dataConsentAt: t0,
    );
    final back = AppUser.fromMap('u1', u.toMap());
    expect(back.role, UserRole.coach);
    expect(back.coachStatus, CoachStatus.pending);
    expect(back.lastContext, u.lastContext);
    expect(back.notificationPrefs.isEnabled(NotificationType.chatMessage), isFalse);
    expect(back.notificationPrefs.isEnabled(NotificationType.newTraining), isTrue);
    expect(back.isApprovedCoach, isFalse);
  });

  test('parent toMap never contains coachStatus (rules reject it)', () {
    final u = AppUser(id: 'p', role: UserRole.parent, firstName: 'ა', lastName: 'ბ', phone: '', createdAt: t0);
    expect(u.toMap().containsKey('coachStatus'), isFalse);
  });

  test('Child round-trip', () {
    final c = Child(
      id: 'c1',
      firstName: 'ლუკა',
      lastName: 'ბერიძე',
      birthDate: DateTime.utc(2017, 3, 1),
      parentIds: const ['p1'],
      sportIds: const ['football'],
      groupIds: const ['g1'],
      photoConsent: true,
    );
    final b = Child.fromMap('c1', c.toMap());
    expect(b.fullName, 'ლუკა ბერიძე');
    expect(b.parentIds, ['p1']);
    expect(b.photoConsent, isTrue);
  });

  test('Club/Venue round-trip incl. geopoint-like objects', () {
    final club = const Club(
      id: 'k',
      name: 'კლუბი',
      address: 'მის.',
      sportIds: ['football'],
      location: GeoCoord(41.7, 44.8),
      geohash: 'sp',
    );
    expect(Club.fromMap('k', club.toMap()).location, const GeoCoord(41.7, 44.8));
    final venueMap = {
      'name': 'სტადიონი',
      'address': 'a',
      'geohash': 'x',
      'sportIds': ['football'],
      'type': 'stadium',
      'location': _FakeGeoPoint(41.1, 44.2),
    };
    final v = Venue.fromMap('v', venueMap);
    expect(v.type, VenueType.stadium);
    expect(v.location.latitude, 41.1);
  });

  test('Group round-trip', () {
    const g = Group(
      id: 'g',
      clubId: 'c',
      sportId: 's',
      coachIds: ['co'],
      name: 'U-10',
      ageMin: 8,
      ageMax: 10,
      memberChildIds: ['k1'],
      parentIds: ['p1'],
    );
    final b = Group.fromMap('g', g.toMap());
    expect(b.hasCoach('co'), isTrue);
    expect(b.hasParent('p1'), isTrue);
    expect(b.hasChild('k1'), isTrue);
  });

  test('Training round-trip ignores unknown focus values', () {
    final t = Training(
      id: 't',
      groupId: 'g',
      venueId: 'v',
      startAt: t0,
      durationMin: 90,
      focus: const [TrainingFocus.ball, TrainingFocus.speed],
      description: 'd',
      createdBy: 'co',
      status: TrainingStatus.moved,
      previousStartAt: t0.subtract(const Duration(hours: 1)),
    );
    final map = t.toMap();
    expect(map['focus'], ['ball', 'speed']);
    map['focus'] = [...map['focus'] as List, 'juggling'];
    final b = Training.fromMap('t', map);
    expect(b.focus, [TrainingFocus.ball, TrainingFocus.speed]);
    expect(b.status, TrainingStatus.moved);
    expect(b.endAt, t0.add(const Duration(minutes: 90)));
  });

  test('MedicalCertificate stores status and path, never a URL', () {
    final c = MedicalCertificate(
      id: 'x',
      childId: 'c',
      uploadedBy: 'p',
      storagePath: CertificatePolicy.storagePath('c', 'x'),
      issuedAt: t0,
      validUntil: t0.add(const Duration(days: 300)),
      consentAt: t0,
    );
    final m = c.toMap(now: t0);
    expect(m['storagePath'], 'medical/c/x');
    expect(m['status'], 'valid');
    expect(m.values.whereType<String>().any((v) => v.startsWith('http')), isFalse);
    expect(MedicalCertificate.fromMap('x', m).validUntil, c.validUntil);
  });

  test('Payment round-trip with reminders', () {
    final p = Payment(
      id: 'p',
      childId: 'c',
      parentId: 'pa',
      groupId: 'g',
      sportId: 's',
      amount: 80,
      dueDate: t0,
      reminders: PaymentReminders(d5SentAt: t0),
    );
    final b = Payment.fromMap('p', p.toMap());
    expect(b.currency, 'GEL');
    expect(b.reminders.d5SentAt, t0);
    expect(b.reminders.d1SentAt, isNull);
    expect(b.status, PaymentStatus.pending);
  });

  test('ChatMessage and MembershipRequest round-trip', () {
    final m = ChatMessage(
      id: 'm',
      groupId: 'g',
      senderId: 'u',
      senderName: 'n',
      senderRole: UserRole.coach,
      text: 'hi',
      createdAt: t0,
    );
    expect(ChatMessage.fromMap('g', 'm', m.toMap()).senderRole, UserRole.coach);
    final r = MembershipRequest(id: 'r', parentId: 'p', childId: 'c', clubId: 'k', createdAt: t0, childName: 'ლუკა');
    final rb = MembershipRequest.fromMap('r', r.toMap());
    expect(rb.childName, 'ლუკა');
    expect(rb.withStatus(RequestStatus.approved).status, RequestStatus.approved);
  });

  test('PaymentPlan ids are deterministic and due dates clamp to month end', () {
    const plan = PaymentPlan(id: 'pl', groupId: 'g', sportId: 's', amount: 80, dayOfMonth: 31, createdBy: 'c');
    expect(plan.paymentIdFor('k', 2026, 2), 'pl_k_2026-02');
    expect(plan.dueDateFor(2026, 2), DateTime.utc(2026, 2, 28));
  });
}

class _FakeGeoPoint {
  _FakeGeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
