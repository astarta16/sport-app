import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/errors/app_exception.dart';
import 'package:sport_parent_app/features/authentication/data/demo_auth_repository.dart';
import 'package:sport_parent_app/features/chat/data/demo_chat_repository.dart';
import 'package:sport_parent_app/features/chat/domain/receipts.dart';
import 'package:sport_parent_app/features/contacts/data/demo_contacts_repository.dart';
import 'package:sport_parent_app/features/contacts/domain/contact.dart';
import 'package:sport_parent_app/features/demo/data/demo_backend.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v14.dart';
import 'package:sport_parent_app/features/groups/domain/group.dart';
import 'package:sport_parent_app/features/media/data/demo_media_access_repository.dart';
import 'package:sport_parent_app/features/media/domain/media_access.dart';
import 'package:sport_parent_app/features/notifications/domain/notification_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var now = DateTime(2026, 11, 10, 10);
  late DemoBackend db;
  late DemoContactsRepository contacts;
  late DemoChatRepository chat;
  late DemoMediaAccessRepository media;
  late DemoUserDirectoryRepository directory;
  const u10 = 'g-football-u10';
  const ackMsg = DemoSeedV14.ackMessage;
  const infoMsg = DemoSeedV14.infoMessage;
  const guardian2 = DemoSeedV14.secondGuardian;

  setUp(() {
    now = DateTime(2026, 11, 10, 10);
    db = DemoSeed.create(clock: () => now);
    contacts = DemoContactsRepository(db);
    chat = DemoChatRepository(db);
    media = DemoMediaAccessRepository(db);
    directory = DemoUserDirectoryRepository(db);
  });

  void as(String uid) {
    db.session = (uid: uid, phone: db.users[uid]!.phone);
  }

  group('contacts', () {
    test('coach sees every guardian of the group with phone, children and relation', () async {
      as(DemoIds.coach);
      final list = await contacts.groupContacts(u10);
      final byId = {for (final c in list) c.uid: c};
      expect(byId.keys, containsAll([DemoIds.parent, guardian2, 'parent-2', 'parent-3']));
      expect(list.every((c) => !c.isCoach), isTrue);
      expect(byId[guardian2]!.phone, '+995555000105');
      expect(byId[guardian2]!.children.single.relation, GuardianRelation.father);
      expect(byId[DemoIds.parent]!.children.single.relation, GuardianRelation.mother);
    });

    test('parent sees only the approved coach — never other parents', () async {
      as(DemoIds.parent);
      final list = await contacts.groupContacts(u10);
      expect(list.map((c) => c.uid), [DemoIds.coach]);
      expect(list.single.phone, isNotNull);
      expect((await directory.profile('parent-2'))!.phone, isNull, reason: 'parent → parent');
      expect((await directory.profile(DemoIds.coach))!.phone, isNotNull, reason: 'parent → coach');
    });

    test('unrelated parents, pending coaches and archived groups are denied', () async {
      as('parent-4'); // child-6 is not in U-10
      await expectLater(contacts.groupContacts(u10), throwsA(isA<PermissionDeniedException>()));
      as(DemoIds.pendingCoach);
      await expectLater(contacts.groupContacts(u10), throwsA(isA<PermissionDeniedException>()));
      as(DemoIds.coach);
      expect((await directory.profile('parent-4'))!.phone, isNull, reason: 'not in the coach\'s groups');
      db.groups[u10] = db.groups[u10]!.copyWith(status: GroupStatus.archived);
      await expectLater(contacts.groupContacts(u10), throwsA(isA<PermissionDeniedException>()));
    });

    test('access ends with the membership / coach assignment', () async {
      final g = db.groups[u10]!;
      db.groups[u10] = g.copyWith(
        memberChildIds: g.memberChildIds.where((c) => c != 'child-4').toList(),
        parentIds: g.parentIds.where((p) => p != 'parent-2').toList(),
      );
      as('parent-2');
      await expectLater(contacts.groupContacts(u10), throwsA(isA<PermissionDeniedException>()));
      expect((await directory.profile(DemoIds.coach))!.phone, isNull);
      as(DemoIds.coach);
      expect((await contacts.groupContacts(u10)).map((c) => c.uid), isNot(contains('parent-2')));
      db.groups[u10] = db.groups[u10]!.copyWith(coachIds: ['coach-2']);
      await expectLater(contacts.groupContacts(u10), throwsA(isA<PermissionDeniedException>()));
    });
  });

  group('read receipts', () {
    MessageReceipt receiptOf(String id) {
      final recipients = db.msgRecipients[id]!;
      return MessageReceipt.compute(id, recipients, db.msgReads[id] ?? {}, db.msgAcks[id] ?? {}, requiresAck: true);
    }

    test('snapshot = unique parent accounts at creation; guardians counted separately', () {
      final r = db.msgRecipients[ackMsg]!;
      expect(r.toSet().length, r.length);
      expect(r, containsAll([DemoIds.parent, guardian2, 'parent-2', 'parent-3']));
      expect(r, isNot(contains(DemoIds.coach)));
      expect(receiptOf(ackMsg).recipientCount, r.length);
    });

    test('marking seen is idempotent, keeps the first server time and counts each guardian once', () async {
      as(DemoIds.parent);
      await chat.markSeen(u10, [ackMsg, ackMsg]);
      final first = db.msgReads[ackMsg]![DemoIds.parent];
      now = now.add(const Duration(hours: 1));
      await chat.markSeen(u10, [ackMsg]);
      expect(db.msgReads[ackMsg]![DemoIds.parent], first);
      as(guardian2);
      await chat.markSeen(u10, [ackMsg]);
      expect(receiptOf(ackMsg).readCount, 4); // parent-2, parent-3, Nino, Davit
      expect(receiptOf(ackMsg).ackCount, 1);
    });

    test('new members are not recipients; removed parents can no longer mark', () async {
      // A message sent now snapshots the current parents only.
      as(DemoIds.coach);
      await chat.send(u10, 'New schedule', requiresAck: true);
      final msgId = db.messages[u10]!.last.id;
      final before = List.of(db.msgRecipients[msgId]!);
      // parent-4 joins afterwards.
      final g = db.groups[u10]!;
      db.groups[u10] = g.copyWith(
        memberChildIds: [...g.memberChildIds, 'child-6'],
        parentIds: [...g.parentIds, 'parent-4'],
      );
      as('parent-4');
      await chat.markSeen(u10, [msgId]);
      expect(db.msgReads[msgId]?.containsKey('parent-4') ?? false, isFalse);
      await expectLater(chat.acknowledge(u10, msgId), throwsA(isA<PermissionDeniedException>()));
      expect(db.msgRecipients[msgId], before);
      // parent-3 leaves.
      final g2 = db.groups[u10]!;
      db.groups[u10] = g2.copyWith(parentIds: g2.parentIds.where((p) => p != 'parent-3').toList());
      as('parent-3');
      await chat.markSeen(u10, [msgId]);
      expect(db.msgReads[msgId]?.containsKey('parent-3') ?? false, isFalse);
      // The coach's historical view still lists them (snapshot), others cannot read it.
      as(DemoIds.coach);
      final rows = await chat.watchRecipientStatuses(u10, msgId).first;
      expect(rows.map((r) => r.uid), contains('parent-3'));
      expect(rows.map((r) => r.uid), isNot(contains('parent-4')));
    });

    test('offline: marks fail without fake success and work after reconnecting', () async {
      as(DemoIds.parent);
      db.setOffline(true);
      await expectLater(chat.markSeen(u10, [infoMsg]), throwsA(isA<BackendUnavailableException>()));
      db.setOffline(false);
      await chat.markSeen(u10, [infoMsg]);
      expect(db.msgReads[infoMsg]!.containsKey(DemoIds.parent), isTrue);
    });

    test('hidden or deleted messages are never marked', () async {
      as(DemoIds.parent);
      final list = db.messages[u10]!;
      final i = list.indexWhere((m) => m.id == infoMsg);
      list[i] = list[i].copyWith(hidden: true);
      db.msgReads[infoMsg]!.remove(DemoIds.parent);
      await chat.markSeen(u10, [infoMsg, 'msg-does-not-exist']);
      expect(db.msgReads[infoMsg]!.containsKey(DemoIds.parent), isFalse);
    });

    test('receipt details are for the sending coach only', () async {
      as('parent-2');
      await expectLater(chat.watchRecipientStatuses(u10, ackMsg).first, throwsA(isA<PermissionDeniedException>()));
      as('coach-2');
      await expectLater(chat.watchRecipientStatuses(u10, ackMsg).first, throwsA(isA<PermissionDeniedException>()));
      as(DemoIds.coach);
      final rows = await chat.watchRecipientStatuses(u10, ackMsg).first;
      final states = {for (final r in rows) r.uid: r.state};
      expect(states['parent-2'], ReceiptState.acknowledged);
      expect(states['parent-3'], ReceiptState.seen);
      expect(states[DemoIds.parent], ReceiptState.notSeen);
    });
  });

  group('acknowledgments', () {
    test('reading never acknowledges; the button does, once, with the server time and an audit record', () async {
      as(DemoIds.parent);
      await chat.markSeen(u10, [ackMsg]);
      expect(db.msgAcks[ackMsg]!.containsKey(DemoIds.parent), isFalse);
      expect((await chat.watchPendingAcks().first).map((p) => p.messageId), contains(ackMsg));
      await chat.acknowledge(u10, ackMsg);
      final at = db.msgAcks[ackMsg]![DemoIds.parent];
      now = now.add(const Duration(minutes: 5));
      await chat.acknowledge(u10, ackMsg); // duplicate tap
      expect(db.msgAcks[ackMsg]![DemoIds.parent], at);
      expect(db.audit.where((e) => e.action == 'chat.acknowledge' && e.actorId == DemoIds.parent).length, 1);
      expect((await chat.watchPendingAcks().first).map((p) => p.messageId), isNot(contains(ackMsg)));
      final marks = await chat.watchMyMarks(u10).first;
      expect(marks.acked.containsKey(ackMsg), isTrue);
    });

    test('multiple guardians acknowledge separately; counters update in real time', () async {
      as(DemoIds.coach);
      final counts = <int>[];
      // (The demo backend has one session: emissions under a parent are empty.)
      final sub = chat.watchSentReceipts(u10).listen((m) {
        if (m[ackMsg] case final r?) counts.add(r.ackCount);
      });
      await Future<void>.delayed(Duration.zero);
      as(DemoIds.parent);
      await chat.acknowledge(u10, ackMsg);
      as(guardian2);
      await chat.acknowledge(u10, ackMsg);
      as(DemoIds.coach);
      db.commit();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(counts.first, 1);
      expect(counts.last, 3);
    });

    test('unauthorized: coach, outsider, message without request', () async {
      as(DemoIds.coach);
      await expectLater(chat.acknowledge(u10, ackMsg), throwsA(isA<PermissionDeniedException>()));
      as('parent-4');
      await expectLater(chat.acknowledge(u10, ackMsg), throwsA(isA<PermissionDeniedException>()));
      as(DemoIds.parent);
      await expectLater(chat.acknowledge(u10, infoMsg), throwsA(isA<PermissionDeniedException>()));
      as('parent-2');
      await expectLater(chat.send(u10, 'hi', requiresAck: true), throwsA(isA<PermissionDeniedException>()));
    });

    test('an acknowledgment request lands in each recipient inbox', () {
      final inbox = db.notifications.where((n) => n.type == NotificationType.ackRequested).map((n) => n.userId);
      expect(inbox, containsAll([DemoIds.parent, guardian2, 'parent-3']));
      expect(NotificationType.ackRequested.category, NotificationCategory.announcements);
    });
  });

  group('media downloads', () {
    test('a parent of the group may download; the event is logged', () async {
      as(DemoIds.parent);
      final ticket = await media.authorizeDownload(db.mediaPosts['post-1']!);
      expect(ticket.fileName, 'sportparent_photo_post-1.png');
      expect(ticket.mimeType, 'image/png');
      expect(ticket.sizeBytes, greaterThan(1000));
      expect(db.mediaDownloads.last.userId, DemoIds.parent);
      final video = await media.authorizeDownload(db.mediaPosts['post-2']!);
      expect(video.mimeType, 'video/mp4');
    });

    test('unrelated groups, hidden posts, disabled policy and ended membership are rejected', () async {
      as('parent-4'); // not in U-10 / U-12
      await expectLater(media.authorizeDownload(db.mediaPosts['post-1']!), throwsA(isA<PermissionDeniedException>()));
      as(DemoIds.parent);
      await expectLater(
        media.authorizeDownload(db.mediaPosts['post-3']!),
        throwsA(isA<PermissionDeniedException>()),
        reason: 'basketball group has downloads turned off',
      );
      db.mediaPosts['post-1'] = db.mediaPosts['post-1']!.copyWith(hidden: true);
      await expectLater(media.authorizeDownload(db.mediaPosts['post-1']!), throwsA(isA<PermissionDeniedException>()));
      final g = db.groups[u10]!;
      db.groups[u10] = g.copyWith(parentIds: g.parentIds.where((p) => p != 'parent-2').toList());
      as('parent-2');
      final before = db.mediaDownloads.length;
      await expectLater(media.authorizeDownload(db.mediaPosts['post-2']!), throwsA(isA<PermissionDeniedException>()));
      expect(db.mediaDownloads.length, before, reason: 'denied attempts are not logged as downloads');
    });

    test('download progress, cancellation and failure', () async {
      as(DemoIds.parent);
      final ticket = await media.authorizeDownload(db.mediaPosts['post-1']!);
      db.downloadChunkDelay = Duration.zero;
      final d = DemoMediaDownloader(db);
      final progress = <int>[];
      final file = await d.fetch(
        ticket,
        onProgress: (r, t) => progress.add(r * 100 ~/ t),
        cancel: DownloadCancelToken(),
      );
      expect(progress.last, 100);
      expect(file.bytes!.length, ticket.sizeBytes);
      final bytes = (await rootBundle.load(DemoMediaAccessRepository.samplePhoto)).lengthInBytes;
      expect(file.sizeBytes, bytes);

      final cancel = DownloadCancelToken();
      final f = d.fetch(
        ticket,
        onProgress: (r, t) {
          if (r * 2 >= t) cancel.cancel();
        },
        cancel: cancel,
      );
      await expectLater(f, throwsA(isA<DownloadCancelledException>()));

      db.failNextDownload = true;
      await expectLater(
        d.fetch(ticket, onProgress: (_, _) {}, cancel: DownloadCancelToken()),
        throwsA(isA<BackendUnavailableException>()),
      );
      // Retry succeeds.
      expect((await d.fetch(ticket, onProgress: (_, _) {}, cancel: DownloadCancelToken())).bytes, isNotNull);
    });

    test('playback source requires current access', () async {
      as(DemoIds.parent);
      expect((await media.playbackSource(db.mediaPosts['post-2']!)).assetPath, DemoMediaAccessRepository.sampleVideo);
      as('parent-4');
      await expectLater(media.playbackSource(db.mediaPosts['post-2']!), throwsA(isA<PermissionDeniedException>()));
      const expired = PlaybackSource(url: 'x');
      expect(expired.isExpired(now), isFalse);
      expect(PlaybackSource(url: 'x', expiresAt: now.add(const Duration(seconds: 5))).isExpired(now), isTrue);
    });
  });
}
