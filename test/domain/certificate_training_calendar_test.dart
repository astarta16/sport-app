import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/utils/dates.dart';
import 'package:sport_parent_app/features/calendar/domain/calendar_logic.dart';
import 'package:sport_parent_app/features/medical_certificates/domain/medical_certificate.dart';
import 'package:sport_parent_app/features/trainings/domain/training.dart';

MedicalCertificate cert(DateTime until) => MedicalCertificate(
  id: 'x',
  childId: 'c',
  uploadedBy: 'p',
  storagePath: 'medical/c/x',
  issuedAt: until.subtract(const Duration(days: 365)),
  validUntil: until,
  consentAt: until,
);

Training tr(String id, DateTime start, {TrainingStatus status = TrainingStatus.scheduled}) => Training(
  id: id,
  groupId: 'g',
  venueId: 'v',
  startAt: start,
  durationMin: 60,
  focus: const [TrainingFocus.ball],
  description: '',
  createdBy: 'co',
  status: status,
);

void main() {
  final now = TbilisiTime.at(2026, 11, 10, 9);

  group('CertificatePolicy', () {
    test('status thresholds: >14 days valid, ≤14 expiring, past expired, none missing', () {
      expect(CertificatePolicy.statusFor(DateTime.utc(2026, 12, 1), now), CertificateStatus.valid);
      expect(CertificatePolicy.statusFor(DateTime.utc(2026, 11, 24), now), CertificateStatus.expiring);
      expect(CertificatePolicy.statusFor(DateTime.utc(2026, 11, 10), now), CertificateStatus.expiring);
      expect(CertificatePolicy.statusFor(DateTime.utc(2026, 11, 9), now), CertificateStatus.expired);
      expect(CertificatePolicy.childStatus(const [], now), CertificateStatus.missing);
    });

    test('child status uses the latest certificate', () {
      final s = CertificatePolicy.childStatus([cert(DateTime.utc(2026, 1, 1)), cert(DateTime.utc(2027, 6, 1))], now);
      expect(s, CertificateStatus.valid);
    });

    test('reminders fire at 14, 3 and 0 days only', () {
      expect(CertificatePolicy.reminderDue(DateTime.utc(2026, 11, 24), now), 14);
      expect(CertificatePolicy.reminderDue(DateTime.utc(2026, 11, 13), now), 3);
      expect(CertificatePolicy.reminderDue(DateTime.utc(2026, 11, 10), now), 0);
      expect(CertificatePolicy.reminderDue(DateTime.utc(2026, 11, 14), now), isNull);
    });

    test('upload validation: type, size, dates, consent', () {
      CertificateUpload up({
        String mime = 'application/pdf',
        int size = 1000,
        bool consent = true,
        int validDays = 365,
      }) => CertificateUpload(
        childId: 'c',
        bytes: List.filled(size, 1),
        fileName: 'f',
        mimeType: mime,
        issuedAt: DateTime(2026, 1, 1),
        validUntil: DateTime(2026, 1, 1).add(Duration(days: validDays)),
        consentGiven: consent,
      );
      expect(CertificatePolicy.validateUpload(up()), isEmpty);
      expect(CertificatePolicy.validateUpload(up(mime: 'image/gif')), contains('fileType'));
      expect(CertificatePolicy.validateUpload(up(size: CertificatePolicy.maxBytes + 1)), contains('fileTooLarge'));
      expect(CertificatePolicy.validateUpload(up(consent: false)), contains('consentRequired'));
      expect(CertificatePolicy.validateUpload(up(validDays: -1)), contains('datesOrder'));
      expect(CertificatePolicy.mimeFromFileName('scan.JPG'), 'image/jpeg');
      expect(CertificatePolicy.mimeFromFileName('scan.heic'), isNull);
    });
  });

  group('TrainingValidator', () {
    TrainingDraft draft({
      String venue = 'v',
      int duration = 90,
      List<TrainingFocus> focus = const [TrainingFocus.speed],
      DateTime? start,
    }) => TrainingDraft(
      groupId: 'g',
      venueId: venue,
      startAt: start ?? now.add(const Duration(days: 1)),
      durationMin: duration,
      focus: focus,
      description: 'd',
    );

    test('valid draft passes', () => expect(TrainingValidator.validate(draft(), now: now), isEmpty));

    test('errors for missing venue, bad duration, no focus, past start', () {
      expect(TrainingValidator.validate(draft(venue: ''), now: now), contains('venueRequired'));
      expect(TrainingValidator.validate(draft(duration: 10), now: now), contains('durationRange'));
      expect(TrainingValidator.validate(draft(duration: 301), now: now), contains('durationRange'));
      expect(TrainingValidator.validate(draft(focus: const []), now: now), contains('focusRequired'));
      expect(
        TrainingValidator.validate(draft(start: now.subtract(const Duration(hours: 1))), now: now),
        contains('startInPast'),
      );
      expect(
        TrainingValidator.validate(draft(start: now.subtract(const Duration(hours: 1))), now: now, isEdit: true),
        isEmpty,
      );
    });

    test('photos require consent confirmation', () {
      final d = TrainingDraft(
        groupId: 'g',
        venueId: 'v',
        startAt: now.add(const Duration(days: 1)),
        durationMin: 60,
        focus: const [TrainingFocus.ball],
        description: '',
        newPhotos: const [
          PhotoUpload(bytes: [1], fileName: 'a.jpg', mimeType: 'image/jpeg'),
        ],
      );
      expect(TrainingValidator.validate(d, now: now), contains('photoConsentRequired'));
    });
  });

  group('CalendarLogic', () {
    final local = DateTime(2026, 11, 10, 9);
    final list = [
      tr('a', DateTime(2026, 11, 10, 17)),
      tr('b', DateTime(2026, 11, 10, 15)),
      tr('c', DateTime(2026, 11, 12, 17), status: TrainingStatus.cancelled),
      tr('d', DateTime(2026, 11, 8, 17), status: TrainingStatus.done),
    ];

    test('groups by local day and sorts by time', () {
      final m = CalendarLogic.byDay(list);
      expect(CalendarLogic.onDay(m, DateTime(2026, 11, 10, 23)).map((t) => t.id), ['b', 'a']);
      expect(CalendarLogic.onDay(m, DateTime(2026, 11, 11)), isEmpty);
    });

    test('upcoming excludes finished/done and keeps cancelled visible', () {
      expect(CalendarLogic.upcoming(list, local).map((t) => t.id), ['b', 'a', 'c']);
    });

    test('this-week count ignores cancelled and done', () {
      expect(CalendarLogic.countThisWeek(list, local), 2);
    });
  });
}
