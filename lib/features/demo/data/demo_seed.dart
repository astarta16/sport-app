import 'dart:convert';
import 'dart:typed_data';

import '../../../core/utils/geo.dart';
import '../../authentication/domain/app_user.dart';
import '../../chat/domain/chat_message.dart';
import '../../children/domain/child.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../notifications/domain/notification_models.dart';
import '../../payments/domain/payment.dart';
import '../../sports/domain/sport.dart';
import '../../trainings/domain/training.dart';
import 'demo_backend.dart';

/// Demo identities. All names, numbers and places are fictional.
class DemoIds {
  DemoIds._();

  static const parent = 'parent-1';
  static const coach = 'coach-1';
  static const pendingCoach = 'coach-4';
  static const otpCode = '123456';
}

/// Seeds a [DemoBackend] with realistic Georgian sample data relative to
/// [DemoBackend.clock] so schedules always look current.
class DemoSeed {
  DemoSeed._();

  static DemoBackend create({DateTime Function()? clock}) {
    final db = DemoBackend(clock: clock);
    seed(db);
    return db;
  }

  static void seed(DemoBackend db) {
    final now = db.clock();
    final today = DateTime(now.year, now.month, now.day);
    DateTime yearsAgo(int y, [int extraDays = 0]) =>
        DateTime(now.year - y, now.month, now.day).subtract(Duration(days: extraDays));

    // ── Sports ──────────────────────────────────────────────────────────
    for (final s in const [
      Sport(id: 'football', name: 'ფეხბურთი', icon: 'football'),
      Sport(id: 'basketball', name: 'კალათბურთი', icon: 'basketball'),
      Sport(id: 'swimming', name: 'ცურვა', icon: 'swimming'),
      Sport(id: 'tennis', name: 'ჩოგბურთი', icon: 'tennis'),
      Sport(id: 'wrestling', name: 'ჭიდაობა', icon: 'wrestling'),
      Sport(id: 'judo', name: 'ძიუდო', icon: 'judo'),
      Sport(id: 'rugby', name: 'რაგბი', icon: 'rugby'),
      Sport(id: 'gymnastics', name: 'ტანვარჯიში', icon: 'gymnastics'),
    ]) {
      db.sports[s.id] = s;
    }

    // ── Clubs & venues (fictional, Tbilisi + Batumi) ────────────────────
    Club club(
      String id,
      String name,
      String address,
      double lat,
      double lng,
      List<String> sports,
      String phone,
      String desc,
    ) => Club(
      id: id,
      name: name,
      address: address,
      sportIds: sports,
      location: GeoCoord(lat, lng),
      geohash: Geohash.encode(lat, lng),
      phone: phone,
      description: desc,
    );
    for (final c in [
      club(
        'club-1',
        'საბურთალოს ფეხბურთის აკადემია',
        'ვაჟა-ფშაველას გამზ. 41, თბილისი',
        41.7270,
        44.7530,
        ['football'],
        '+995 32 200 11 01',
        'ფეხბურთის აკადემია 6-დან 14 წლამდე ბავშვებისთვის. UEFA ლიცენზირებული მწვრთნელები.',
      ),
      club(
        'club-2',
        'ვაკის კალათბურთის სკოლა',
        'ჭავჭავაძის გამზ. 37, თბილისი',
        41.7085,
        44.7590,
        ['basketball'],
        '+995 32 200 11 02',
        'კალათბურთის სკოლა გოგონებისა და ბიჭებისთვის, ჯგუფები ასაკის მიხედვით.',
      ),
      club(
        'club-3',
        'ცისფერი ტალღა — საცურაო ცენტრი',
        'პეკინის ქ. 14, თბილისი',
        41.7225,
        44.7700,
        ['swimming'],
        '+995 32 200 11 03',
        '25-მეტრიანი დახურული აუზი, ცურვის სწავლება 5 წლიდან.',
      ),
      club(
        'club-4',
        'დიდუბის ჭიდაობისა და ძიუდოს კლუბი',
        'წერეთლის გამზ. 116, თბილისი',
        41.7380,
        44.7790,
        ['wrestling', 'judo'],
        '+995 32 200 11 04',
        'ქართული ჭიდაობის ტრადიციები და ძიუდო ბავშვებისთვის.',
      ),
      club(
        'club-5',
        'მთაწმინდის ჩოგბურთის კლუბი',
        'ჭონქაძის ქ. 9, თბილისი',
        41.6950,
        44.7860,
        ['tennis'],
        '+995 32 200 11 05',
        'ღია და დახურული კორტები, ინდივიდუალური და ჯგუფური ვარჯიში.',
      ),
      club(
        'club-6',
        'ისნის რაგბის აკადემია',
        'ქეთევან წამებულის გამზ. 60, თბილისი',
        41.6890,
        44.8350,
        ['rugby'],
        '+995 32 200 11 06',
        'რაგბი 8 წლიდან — გუნდური სული და ფიზიკური მომზადება.',
      ),
      club(
        'club-7',
        'გლდანის ტანვარჯიშის სკოლა',
        'ხიზანიშვილის ქ. 5, თბილისი',
        41.7900,
        44.8150,
        ['gymnastics'],
        '+995 32 200 11 07',
        'სპორტული და მხატვრული ტანვარჯიში 4 წლიდან.',
      ),
      club(
        'club-8',
        'ბათუმის ზღვისპირა ფეხბურთის სკოლა',
        'რუსთაველის ქ. 22, ბათუმი',
        41.6460,
        41.6330,
        ['football'],
        '+995 422 20 11 08',
        'ფეხბურთის სკოლა ბათუმში, ვარჯიში მთელი წლის განმავლობაში.',
      ),
    ]) {
      db.clubs[c.id] = c;
    }

    Venue venue(
      String id,
      String? clubId,
      String name,
      String address,
      double lat,
      double lng,
      List<String> sports,
      VenueType type,
    ) => Venue(
      id: id,
      clubId: clubId,
      name: name,
      address: address,
      location: GeoCoord(lat, lng),
      geohash: Geohash.encode(lat, lng),
      sportIds: sports,
      type: type,
    );
    for (final v in [
      venue('venue-1', 'club-1', 'საბურთალოს სტადიონი', 'ვაჟა-ფშაველას გამზ. 39, თბილისი', 41.7262, 44.7512, [
        'football',
      ], VenueType.stadium),
      venue('venue-2', 'club-1', 'აკადემიის ხელოვნური მოედანი', 'ნუცუბიძის ქ. 2, თბილისი', 41.7299, 44.7562, [
        'football',
      ], VenueType.field),
      venue('venue-3', 'club-2', 'ვაკის სპორტული დარბაზი', 'ჭავჭავაძის გამზ. 35, თბილისი', 41.7092, 44.7612, [
        'basketball',
      ], VenueType.hall),
      venue('venue-4', 'club-3', 'ცისფერი ტალღის აუზი', 'პეკინის ქ. 14ა, თბილისი', 41.7231, 44.7708, [
        'swimming',
      ], VenueType.pool),
      venue('venue-5', 'club-4', 'დიდუბის სპორტის სასახლე', 'წერეთლის გამზ. 118, თბილისი', 41.7395, 44.7805, [
        'wrestling',
        'judo',
      ], VenueType.hall),
      venue('venue-6', 'club-5', 'მთაწმინდის კორტები', 'ჭონქაძის ქ. 11, თბილისი', 41.6957, 44.7871, [
        'tennis',
      ], VenueType.field),
      venue('venue-7', null, 'ცენტრალური სტადიონი', 'წერეთლის გამზ. 70, თბილისი', 41.7330, 44.7870, [
        'football',
        'rugby',
      ], VenueType.stadium),
      venue('venue-8', 'club-6', 'ისნის რაგბის მოედანი', 'ქეთევან წამებულის გამზ. 62, თბილისი', 41.6883, 44.8366, [
        'rugby',
      ], VenueType.field),
      venue('venue-9', 'club-7', 'გლდანის ტანვარჯიშის დარბაზი', 'ხიზანიშვილის ქ. 5ა, თბილისი', 41.7905, 44.8160, [
        'gymnastics',
      ], VenueType.hall),
      venue('venue-10', 'club-8', 'სანაპიროს მოედანი', 'რუსთაველის ქ. 24, ბათუმი', 41.6470, 41.6345, [
        'football',
      ], VenueType.field),
    ]) {
      db.venues[v.id] = v;
    }

    // ── Users ───────────────────────────────────────────────────────────
    AppUser user(
      String id,
      UserRole role,
      String first,
      String last,
      String phone, {
      CoachStatus? status,
      List<String> clubs = const [],
      List<String> sports = const [],
    }) => AppUser(
      id: id,
      role: role,
      firstName: first,
      lastName: last,
      phone: phone,
      createdAt: now.subtract(const Duration(days: 200)),
      coachStatus: status,
      clubIds: clubs,
      sportIds: sports,
      dataConsentAt: now.subtract(const Duration(days: 200)),
      smsConsentAt: role == UserRole.parent ? now.subtract(const Duration(days: 200)) : null,
    );
    for (final u in [
      user(DemoIds.parent, UserRole.parent, 'ნინო', 'ბერიძე', '+995555000101'),
      user('parent-2', UserRole.parent, 'ეკა', 'ჯავახიშვილი', '+995555000102'),
      user('parent-3', UserRole.parent, 'ზურაბ', 'ნოზაძე', '+995555000103'),
      user('parent-4', UserRole.parent, 'სალომე', 'ქავთარაძე', '+995555000104'),
      user(
        DemoIds.coach,
        UserRole.coach,
        'გიორგი',
        'კაპანაძე',
        '+995555000201',
        status: CoachStatus.approved,
        clubs: ['club-1'],
        sports: ['football'],
      ),
      user(
        'coach-2',
        UserRole.coach,
        'თამარ',
        'ლომიძე',
        '+995555000202',
        status: CoachStatus.approved,
        clubs: ['club-2'],
        sports: ['basketball'],
      ),
      user(
        'coach-3',
        UserRole.coach,
        'დავით',
        'მაისურაძე',
        '+995555000203',
        status: CoachStatus.approved,
        clubs: ['club-3'],
        sports: ['swimming'],
      ),
      user(
        DemoIds.pendingCoach,
        UserRole.coach,
        'ლევან',
        'გელაშვილი',
        '+995555000204',
        status: CoachStatus.pending,
        clubs: ['club-5'],
        sports: ['tennis'],
      ),
    ]) {
      db.users[u.id] = u;
    }

    // ── Children ────────────────────────────────────────────────────────
    for (final c in [
      Child(
        id: 'child-1',
        firstName: 'ლუკა',
        lastName: 'ბერიძე',
        birthDate: yearsAgo(9, 40),
        parentIds: [DemoIds.parent],
        sportIds: ['football', 'swimming'],
        photoConsent: true,
      ),
      Child(
        id: 'child-2',
        firstName: 'მარიამ',
        lastName: 'ბერიძე',
        birthDate: yearsAgo(12, 100),
        parentIds: [DemoIds.parent],
        sportIds: ['basketball'],
        photoConsent: true,
      ),
      Child(
        id: 'child-3',
        firstName: 'ნიკა',
        lastName: 'ბერიძე',
        birthDate: yearsAgo(15, 20),
        parentIds: [DemoIds.parent],
        sportIds: ['tennis'],
      ),
      Child(
        id: 'child-4',
        firstName: 'დათო',
        lastName: 'ჯავახიშვილი',
        birthDate: yearsAgo(9, 200),
        parentIds: ['parent-2'],
        sportIds: ['football'],
      ),
      Child(
        id: 'child-5',
        firstName: 'ანა',
        lastName: 'ნოზაძე',
        birthDate: yearsAgo(11, 10),
        parentIds: ['parent-3'],
        sportIds: ['football', 'basketball'],
        photoConsent: true,
      ),
      Child(
        id: 'child-6',
        firstName: 'ელენე',
        lastName: 'ქავთარაძე',
        birthDate: yearsAgo(11, 150),
        parentIds: ['parent-4'],
        sportIds: ['swimming', 'basketball'],
        photoConsent: true,
      ),
      Child(
        id: 'child-7',
        firstName: 'გიგა',
        lastName: 'ნოზაძე',
        birthDate: yearsAgo(8, 60),
        parentIds: ['parent-3'],
        sportIds: ['football'],
        photoConsent: true,
      ),
    ]) {
      db.children[c.id] = c;
    }

    // ── Groups ──────────────────────────────────────────────────────────
    for (final g in const [
      Group(
        id: 'g-football-u10',
        clubId: 'club-1',
        sportId: 'football',
        coachIds: [DemoIds.coach],
        name: 'U-10 · ახალგაზრდები',
        ageMin: 8,
        ageMax: 10,
        memberChildIds: ['child-1', 'child-4', 'child-7', 'child-5'],
        scheduleNote: 'სამ, ხუთ 17:00 · შაბ 11:00',
      ),
      Group(
        id: 'g-football-u12',
        clubId: 'club-1',
        sportId: 'football',
        coachIds: [DemoIds.coach],
        name: 'U-12 · იუნიორები',
        ageMin: 11,
        ageMax: 12,
        scheduleNote: 'ორშ, ოთხ 18:00',
      ),
      Group(
        id: 'g-basket-u13',
        clubId: 'club-2',
        sportId: 'basketball',
        coachIds: ['coach-2'],
        name: 'U-13 · შერეული',
        ageMin: 10,
        ageMax: 13,
        memberChildIds: ['child-2', 'child-5', 'child-6'],
        scheduleNote: 'ორშ, ოთხ, პარ 16:30',
      ),
      Group(
        id: 'g-swim-juniors',
        clubId: 'club-3',
        sportId: 'swimming',
        coachIds: ['coach-3'],
        name: 'იუნიორები 7–12',
        ageMin: 7,
        ageMax: 12,
        memberChildIds: ['child-1', 'child-6'],
        scheduleNote: 'სამ, პარ 15:00',
      ),
      Group(
        id: 'g-tennis-teens',
        clubId: 'club-5',
        sportId: 'tennis',
        coachIds: [DemoIds.pendingCoach],
        name: 'მოზარდები 13–17',
        ageMin: 13,
        ageMax: 17,
        scheduleNote: 'სამ, შაბ 12:00',
      ),
      Group(
        id: 'g-wrestling-kids',
        clubId: 'club-4',
        sportId: 'wrestling',
        coachIds: [],
        name: 'დამწყებები 7–10',
        ageMin: 7,
        ageMax: 10,
        scheduleNote: 'ორშ, ოთხ 17:30',
      ),
      Group(
        id: 'g-batumi-u10',
        clubId: 'club-8',
        sportId: 'football',
        coachIds: [],
        name: 'U-10 ბათუმი',
        ageMin: 8,
        ageMax: 10,
        scheduleNote: 'სამ, ხუთ 18:00',
      ),
    ]) {
      db.groups[g.id] = g;
    }
    db.recomputeMemberships();

    // ── Trainings: weekly schedules from 3 weeks ago to 5 weeks ahead ───
    const descriptions = {
      'football': [
        'პასების სიზუსტე და პირველი შეხება. ბოლოს — მცირე ორმხრივი თამაში.',
        'აჩქარება მოკლე მანძილზე, კოორდინაციის კიბე და რეაქციის სავარჯიშოები.',
        'ბურთის კონტროლი, დრიბლინგი კონუსებს შორის და დარტყმა კარში.',
        'ზოგადი ფიზიკური მომზადება: ბალანსი, მოქნილობა, კორპუსის კუნთები.',
      ],
      'basketball': [
        'დრიბლინგი ორივე ხელით, ჩაგდება ფარიდან და სწრაფი გარღვევა.',
        'დაცვის პოზიცია, ფეხების მუშაობა და ბურთის მოხსნა.',
        'სროლის ტექნიკა საჯარიმო ხაზიდან და გუნდური კომბინაციები.',
      ],
      'swimming': [
        'კროლის ტექნიკა, სუნთქვის რიტმი და მოსხლეტა კედლიდან.',
        'ზურგზე ცურვა, ხელების მუშაობა და გამძლეობის სერია.',
      ],
    };
    const focusCycle = [
      [TrainingFocus.ball, TrainingFocus.technique],
      [TrainingFocus.speed],
      [TrainingFocus.ball, TrainingFocus.technique],
      [TrainingFocus.physical],
    ];
    void schedule(
      String groupId,
      String coachId,
      List<int> weekdays,
      int hour,
      int minute,
      List<String> venueIds,
      int duration,
    ) {
      final g = db.groups[groupId]!;
      var i = 0;
      for (var d = -21; d <= 35; d++) {
        final day = today.add(Duration(days: d));
        if (!weekdays.contains(day.weekday)) continue;
        final start = DateTime(day.year, day.month, day.day, hour, minute);
        final isPast = start.add(Duration(minutes: duration)).isBefore(now);
        final descs = descriptions[g.sportId]!;
        final id = 'tr-$groupId-$d';
        db.trainings[id] = Training(
          id: id,
          groupId: groupId,
          venueId: venueIds[i % venueIds.length],
          startAt: start,
          durationMin: duration,
          focus: g.sportId == 'swimming'
              ? (i.isEven ? [TrainingFocus.technique] : [TrainingFocus.physical])
              : focusCycle[i % focusCycle.length],
          description: descs[i % descs.length],
          createdBy: coachId,
          status: isPast ? TrainingStatus.done : TrainingStatus.scheduled,
          photoUrls: isPast && i % 2 == 0
              ? List.generate(3 + i % 3, (k) => 'demo://photo/${g.sportId}/$i-$k')
              : const [],
          updatedAt: now.subtract(const Duration(days: 30)),
        );
        i++;
      }
    }

    schedule('g-football-u10', DemoIds.coach, [DateTime.tuesday, DateTime.thursday], 17, 0, ['venue-1', 'venue-2'], 90);
    schedule('g-football-u10', DemoIds.coach, [DateTime.saturday], 11, 0, ['venue-1'], 90);
    schedule('g-football-u12', DemoIds.coach, [DateTime.monday, DateTime.wednesday], 18, 0, ['venue-2'], 90);
    schedule(
      'g-basket-u13',
      'coach-2',
      [DateTime.monday, DateTime.wednesday, DateTime.friday],
      16,
      30,
      ['venue-3'],
      75,
    );
    schedule('g-swim-juniors', 'coach-3', [DateTime.tuesday, DateTime.friday], 15, 0, ['venue-4'], 60);

    // One cancelled and one moved upcoming training for the U-10 group.
    final upcomingU10 =
        db.trainings.values.where((t) => t.groupId == 'g-football-u10' && t.startAt.isAfter(now)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    if (upcomingU10.length > 4) {
      final c = upcomingU10[2];
      db.trainings[c.id] = c.copyWith(status: TrainingStatus.cancelled);
      final m = upcomingU10[3];
      db.trainings[m.id] = m.copyWith(
        status: TrainingStatus.moved,
        previousStartAt: m.startAt,
        startAt: m.startAt.add(const Duration(hours: 1)),
      );
    }

    // ── Medical certificates (placeholders, no real medical data) ───────
    void cert(String id, String childId, String parentId, int validInDays, int issuedDaysAgo) {
      final c = MedicalCertificate(
        id: id,
        childId: childId,
        uploadedBy: parentId,
        storagePath: CertificatePolicy.storagePath(childId, id),
        issuedAt: today.subtract(Duration(days: issuedDaysAgo)),
        validUntil: today.add(Duration(days: validInDays)),
        consentAt: today.subtract(Duration(days: issuedDaysAgo)),
        fileName: 'cnoba_$childId.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 182 * 1024,
        createdAt: today.subtract(Duration(days: issuedDaysAgo)),
      );
      db.certificates[id] = c;
      db.certificateFiles[c.storagePath] = Uint8List.fromList(utf8.encode('DEMO CERTIFICATE PLACEHOLDER'));
    }

    cert('cert-1', 'child-1', DemoIds.parent, 120, 245);
    cert('cert-2', 'child-2', DemoIds.parent, 9, 356);
    cert('cert-4', 'child-4', 'parent-2', -6, 371);
    cert('cert-5', 'child-5', 'parent-3', 200, 165);
    cert('cert-6', 'child-6', 'parent-4', 3, 362);

    // ── Chat ────────────────────────────────────────────────────────────
    ChatMessage msg(String group, String sender, Duration ago, String text) {
      final u = db.users[sender]!;
      return ChatMessage(
        id: db.newId('msg'),
        groupId: group,
        senderId: sender,
        senderName: u.fullName,
        senderRole: u.role,
        text: text,
        createdAt: now.subtract(ago),
      );
    }

    db.messages['g-football-u10'] = [
      msg(
        'g-football-u10',
        DemoIds.coach,
        const Duration(days: 2, hours: 5),
        'გამარჯობა მშობლებო! ხვალინდელ ვარჯიშზე გთხოვთ, ბავშვებს წყალი და სათადარიგო მაისური გამოატანოთ 💧',
      ),
      msg(
        'g-football-u10',
        'parent-2',
        const Duration(days: 2, hours: 4, minutes: 35),
        'მადლობა, გიორგი! დათო ხვალ 10 წუთით დააგვიანებს.',
      ),
      msg(
        'g-football-u10',
        DemoIds.coach,
        const Duration(days: 2, hours: 4, minutes: 30),
        'არაუშავს, გავითვალისწინებ 👍',
      ),
      msg('g-football-u10', DemoIds.parent, const Duration(days: 1, hours: 8), 'შაბათის ვარჯიში ჩვეულ დროს იქნება?'),
      msg(
        'g-football-u10',
        DemoIds.coach,
        const Duration(days: 1, hours: 7, minutes: 40),
        'დიახ, 11:00-ზე საბურთალოს სტადიონზე. ვთამაშებთ ამხანაგურ მატჩს U-12-თან ⚽',
      ),
      msg(
        'g-football-u10',
        'parent-3',
        const Duration(hours: 3),
        'ანას ჯანმრთელობის ცნობა განვაახლეთ, აპლიკაციაში უკვე ატვირთულია.',
      ),
      msg(
        'g-football-u10',
        DemoIds.coach,
        const Duration(hours: 2),
        'შესანიშნავია, მადლობა! ყველას გთხოვთ, ცნობების ვადას თვალი ადევნოთ.',
      ),
    ];
    db.messages['g-basket-u13'] = [
      msg(
        'g-basket-u13',
        'coach-2',
        const Duration(days: 3),
        'პარასკევს ვარჯიშის შემდეგ მოკლე შეხვედრა გვაქვს მშობლებთან — 15 წუთი.',
      ),
      msg('g-basket-u13', 'parent-4', const Duration(days: 2, hours: 20), 'კარგი, ვიქნებით.'),
      msg('g-basket-u13', 'coach-2', const Duration(hours: 20), 'მარიამმა დღეს შესანიშნავად ითამაშა დაცვაში 👏'),
    ];
    db.messages['g-swim-juniors'] = [
      msg('g-swim-juniors', 'coach-3', const Duration(days: 4), 'შეხსენება: საცურაო ქუდი და სათვალე სავალდებულოა 🏊'),
    ];
    db.messages['g-football-u12'] = [];

    // ── Payments ────────────────────────────────────────────────────────
    db.plans['plan-football-u10'] = const PaymentPlan(
      id: 'plan-football-u10',
      groupId: 'g-football-u10',
      sportId: 'football',
      amount: 80,
      dayOfMonth: 1,
      createdBy: DemoIds.coach,
    );
    db.plans['plan-basket-u13'] = const PaymentPlan(
      id: 'plan-basket-u13',
      groupId: 'g-basket-u13',
      sportId: 'basketball',
      amount: 100,
      dayOfMonth: 1,
      createdBy: 'coach-2',
    );
    db.plans['plan-swim'] = const PaymentPlan(
      id: 'plan-swim',
      groupId: 'g-swim-juniors',
      sportId: 'swimming',
      amount: 120,
      dayOfMonth: 1,
      createdBy: 'coach-3',
    );

    void pay(
      String id,
      String child,
      String parent,
      String group,
      String sport,
      num amount,
      int dueInDays,
      PaymentStatus status,
    ) {
      final due = DateTime.utc(today.year, today.month, today.day).add(Duration(days: dueInDays));
      db.payments[id] = Payment(
        id: id,
        childId: child,
        parentId: parent,
        groupId: group,
        sportId: sport,
        amount: amount,
        dueDate: due,
        status: status,
        paidAt: status == PaymentStatus.paid ? due.subtract(const Duration(days: 2)) : null,
        createdAt: due.subtract(const Duration(days: 20)),
      );
    }

    // Paid history.
    for (final m in [1, 2]) {
      pay('pay-l-f-$m', 'child-1', DemoIds.parent, 'g-football-u10', 'football', 80, -30 * m + 5, PaymentStatus.paid);
      pay('pay-m-b-$m', 'child-2', DemoIds.parent, 'g-basket-u13', 'basketball', 100, -30 * m + 5, PaymentStatus.paid);
      pay('pay-l-s-$m', 'child-1', DemoIds.parent, 'g-swim-juniors', 'swimming', 120, -30 * m + 1, PaymentStatus.paid);
    }
    // Pending: two due in 5 days (→ one combined SMS) and one tomorrow.
    pay('pay-l-f-0', 'child-1', DemoIds.parent, 'g-football-u10', 'football', 80, 5, PaymentStatus.pending);
    pay('pay-m-b-0', 'child-2', DemoIds.parent, 'g-basket-u13', 'basketball', 100, 5, PaymentStatus.pending);
    pay('pay-l-s-0', 'child-1', DemoIds.parent, 'g-swim-juniors', 'swimming', 120, 1, PaymentStatus.pending);
    pay('pay-d-f-0', 'child-4', 'parent-2', 'g-football-u10', 'football', 80, -3, PaymentStatus.pending);
    pay('pay-a-f-0', 'child-5', 'parent-3', 'g-football-u10', 'football', 80, 5, PaymentStatus.paid);
    pay('pay-g-f-0', 'child-7', 'parent-3', 'g-football-u10', 'football', 80, 5, PaymentStatus.pending);

    // ── Inbox ───────────────────────────────────────────────────────────
    final u10 = db.groups['g-football-u10']!;
    final nextU10 = upcomingU10.isNotEmpty ? upcomingU10.first : null;
    db.notifications.addAll([
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.chatMessage,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(hours: 2)),
        route: '/chat/${u10.id}',
        args: {'group': u10.name, 'sender': 'გიორგი კაპანაძე'},
      ),
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.certificateExpiry,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(hours: 20)),
        route: '/certificates/child-2',
        args: {'child': 'მარიამ', 'days': '9'},
      ),
      if (nextU10 != null)
        AppNotification(
          id: db.newId('ntf'),
          userId: DemoIds.parent,
          type: NotificationType.newTraining,
          title: '',
          body: '',
          createdAt: now.subtract(const Duration(days: 1)),
          route: '/training/${nextU10.id}',
          read: true,
          args: {'group': u10.name},
        ),
      AppNotification(
        id: db.newId('ntf'),
        userId: DemoIds.parent,
        type: NotificationType.newPhotos,
        title: '',
        body: '',
        createdAt: now.subtract(const Duration(days: 2)),
        read: true,
        args: {'group': u10.name},
      ),
    ]);

    // ── Pending membership request for the coach to review ──────────────
    db.requests['req-1'] = MembershipRequest(
      id: 'req-1',
      parentId: 'parent-4',
      childId: 'child-6',
      clubId: 'club-1',
      groupId: 'g-football-u12',
      createdAt: now.subtract(const Duration(hours: 6)),
      childName: 'ელენე',
    );
  }
}
