import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/features/chat/data/demo_chat_repository.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed_v14.dart';
import 'package:sport_parent_app/features/media/data/demo_media_access_repository.dart' show DemoMediaAccessRepository;

import '../responsive/responsive_screens_test.dart' show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors;
import 'fake_video_engine.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  const phone = Size(390, 844);
  const u10 = 'g-football-u10';
  const ackMsg = DemoSeedV14.ackMessage;

  setUp(() {
    FakeVideoEngine.created.clear();
    FakeVideoEngine.failNextInit = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (_) async => 'dev.fluttercommunity.plus/share/unavailable',
    );
    m.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    m.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  Future<void> tap(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f.first);
    await pumpFrames(tester, 2);
    await tester.tap(f.first);
    await pumpFrames(tester);
  }

  group('acknowledgment + read receipts', () {
    testWidgets('parent: push/list do not mark read; open chat marks seen; ack only by button', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'home', ['/parent/home']);
      expect(find.byKey(const Key('dashboard-acks')), findsOneWidget, reason: 'outstanding request on dashboard');
      // The inbox entry exists, but a notification never marks a message read.
      expect(db.msgReads[ackMsg]!.containsKey(DemoIds.parent), isFalse);
      await visit(tester, 'chat list', ['/chats']);
      await pumpFrames(tester, 10);
      expect(db.msgReads[ackMsg]!.containsKey(DemoIds.parent), isFalse, reason: 'chat list does not mark');

      await visit(tester, 'chat', ['/chat/$u10']);
      await pumpFrames(tester, 10); // > debounce
      expect(db.msgReads[ackMsg]!.containsKey(DemoIds.parent), isTrue, reason: 'visible in the open chat');
      expect(db.msgAcks[ackMsg]!.containsKey(DemoIds.parent), isFalse, reason: 'seen ≠ acknowledged');
      expect(find.byKey(const Key('ack-required-$ackMsg')), findsOneWidget);
      await tap(tester, 'ack-$ackMsg');
      expect(db.msgAcks[ackMsg]!.containsKey(DemoIds.parent), isTrue);
      expect(find.byKey(const Key('acked-$ackMsg')), findsOneWidget);
      expect(find.byKey(const Key('ack-$ackMsg')), findsNothing);
      expectNoLayoutErrors();

      await visit(tester, 'home', ['/parent/home']);
      // Davit (second guardian) has not acknowledged, but Nino's banner is gone.
      expect(find.byKey(const Key('dashboard-acks')), findsNothing);
    });

    testWidgets('coach: counters on own message, details per parent, compose with acknowledgment', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.coach);
      await visit(tester, 'chat', ['/chat/$u10']);
      final total = db.msgRecipients[ackMsg]!.length;
      final label = find.byKey(const Key('receipt-$ackMsg'));
      expect(label, findsOneWidget);
      final text = (tester.widget<Text>(find.descendant(of: label, matching: find.byType(Text))).data)!;
      expect(text, contains('2/$total'), reason: 'seen');
      expect(text, contains('1/$total'), reason: 'acknowledged');
      await tap(tester, 'receipt-$ackMsg');
      expect(find.byKey(const Key('receipt-list')), findsOneWidget);
      expect(find.byKey(const Key('receipt-row-parent-2')), findsOneWidget);
      expect(find.byKey(const Key('receipt-row-${DemoSeedV14.secondGuardian}')), findsOneWidget);
      expect(find.byKey(const Key('receipt-ack-count')), findsOneWidget);
      expectNoLayoutErrors();

      // Real time: a guardian acknowledges while the coach looks at the list.
      const g2 = DemoSeedV14.secondGuardian;
      expect(tester.widget<Text>(find.byKey(const Key('receipt-state-$g2'))).data, 'არ უნახავს');
      db.session = (uid: g2, phone: db.users[g2]!.phone);
      await DemoChatRepository(db).acknowledge(u10, ackMsg);
      db.session = (uid: DemoIds.coach, phone: db.users[DemoIds.coach]!.phone);
      db.commit();
      await pumpFrames(tester);
      expect(tester.widget<Text>(find.byKey(const Key('receipt-state-$g2'))).data, 'დადასტურებულია');
      expect(db.msgReads[ackMsg]!.containsKey(g2), isTrue, reason: 'acknowledged implies seen');

      await visit(tester, 'chat', ['/chat/$u10']);
      await tap(tester, 'chat-ack-toggle');
      await tester.enterText(find.byKey(const Key('chat-input')), 'Tomorrow: training in the gym');
      await tap(tester, 'chat-send');
      final sent = db.messages[u10]!.last;
      expect(sent.requiresAck, isTrue);
      expect(db.msgRecipients[sent.id], isNotEmpty);
      expectNoLayoutErrors();
    });
  });

  group('contacts', () {
    testWidgets('coach → guardians of a student with call buttons; parent → coach only', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.coach);
      await visit(tester, 'roster', ['/students?groupId=$u10']);
      await tap(tester, 'roster-contacts-child-1');
      expect(find.byKey(const Key('contact-${DemoIds.parent}')), findsOneWidget);
      expect(find.byKey(const Key('contact-${DemoSeedV14.secondGuardian}')), findsOneWidget);
      expect(find.byKey(const Key('call-${DemoSeedV14.secondGuardian}')), findsOneWidget);
      expect(find.byKey(const Key('contact-parent-2')), findsNothing, reason: 'filtered to this student');
      expectNoLayoutErrors();
      await visit(tester, 'details', ['/children/child-1/progress']);
      expect(find.byKey(const Key('guardians-child-1')), findsOneWidget);

      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'child', ['/children/child-1']);
      await tap(tester, 'contact-coach-$u10');
      expect(find.byKey(const Key('contact-${DemoIds.coach}')), findsOneWidget);
      expect(find.byKey(const Key('call-${DemoIds.coach}')), findsOneWidget);
      expect(find.byKey(const Key('contact-parent-2')), findsNothing);
      expect(find.byKey(const Key('contact-${DemoSeedV14.secondGuardian}')), findsNothing);
      expectNoLayoutErrors();
    });
  });

  group('video player', () {
    testWidgets('play, ±10 s, seek after metadata, buffering, lifecycle pause, fullscreen', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'video', ['/media/post-2']);
      await pumpFrames(tester);
      final e = FakeVideoEngine.created.last;
      expect(e.source.assetPath, DemoMediaAccessRepository.sampleVideo);
      expect(find.byKey(const Key('video-progress')), findsOneWidget);
      await tap(tester, 'video-play');
      expect(e.state.playing, isTrue);
      await tap(tester, 'video-forward');
      await tap(tester, 'video-forward');
      await tap(tester, 'video-back');
      expect(e.seeks, [const Duration(seconds: 10), const Duration(seconds: 20), const Duration(seconds: 10)]);
      await tester.drag(find.byKey(const Key('video-progress')), const Offset(2000, 0));
      await pumpFrames(tester);
      expect(e.seeks.last, FakeVideoEngine.length, reason: 'seek is clamped to the duration');
      e.setBuffering(true);
      await pumpFrames(tester, 2);
      expect(find.byKey(const Key('video-buffering')), findsOneWidget);
      await tap(tester, 'video-play'); // must not crash while buffering
      e.setBuffering(false);
      await tap(tester, 'video-play');
      expect(e.state.playing, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpFrames(tester, 2);
      expect(e.state.playing, isFalse, reason: 'paused in the background');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tap(tester, 'video-fullscreen');
      expect(find.byKey(const Key('video-fullscreen-page')), findsOneWidget);
      await tap(tester, 'video-exit-fullscreen');
      expect(find.byKey(const Key('video-fullscreen-page')), findsNothing);
      expectNoLayoutErrors();
      await visit(tester, 'away', ['/parent/home']);
      expect(e.disposed, isTrue, reason: 'player released when leaving');
    });

    testWidgets('playback error → retry re-requests the source', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      FakeVideoEngine.failNextInit = true;
      await visit(tester, 'video', ['/media/post-2']);
      await pumpFrames(tester);
      expect(find.byKey(const Key('video-error')), findsOneWidget);
      await tap(tester, 'video-retry');
      await pumpFrames(tester);
      expect(find.byKey(const Key('video-progress')), findsOneWidget);
      expect(FakeVideoEngine.created.length, 2);
      FakeVideoEngine.created.last.fail();
      await pumpFrames(tester, 2);
      expect(find.byKey(const Key('video-error')), findsOneWidget, reason: 'runtime errors surface too');
      expectNoLayoutErrors();
    });
  });

  group('downloads', () {
    testWidgets('parent downloads an authorized photo; the notice explains the local copy', (tester) async {
      final db = await boot(tester, phone);
      db.downloadChunkDelay = Duration.zero;
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'photo', ['/media/post-1']);
      await tap(tester, 'media-download');
      expect(find.byKey(const Key('download-notice')), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('download-start')));
        for (var i = 0; i < 60; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      });
      await pumpFrames(tester, 3);
      expect(find.textContaining('sportparent_photo_post-1.png'), findsWidgets);
      expect(db.mediaDownloads.last.userId, DemoIds.parent);
      expectNoLayoutErrors();
    });

    testWidgets('cancel, failure + retry, and policy-off groups', (tester) async {
      final db = await boot(tester, phone);
      db.downloadChunkDelay = const Duration(milliseconds: 200);
      await signInAs(tester, db, DemoIds.parent);
      await visit(tester, 'video', ['/media/post-2']);
      await tap(tester, 'media-download');

      /// Tap, then let real time pass while pumping (the transfer uses real timers).
      Future<void> tapFor(String key, int ms) => tester.runAsync(() async {
        await tester.tap(find.byKey(Key(key)));
        for (var t = 0; t < ms; t += 25) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
      });

      await tapFor('download-start', 500);
      expect(find.byKey(const Key('download-progress')), findsOneWidget);
      expect(find.byKey(const Key('download-percent')), findsOneWidget);
      await tapFor('download-cancel', 600);
      expect(find.byKey(const Key('download-cancelled')), findsOneWidget);
      expect(find.byKey(const Key('download-progress')), findsNothing);

      db.failNextDownload = true;
      await tapFor('download-start', 1500);
      expect(find.byKey(const Key('download-error')), findsOneWidget);
      db.downloadChunkDelay = Duration.zero;
      await tapFor('download-retry', 1500);
      await pumpFrames(tester, 3);
      expect(find.textContaining('sportparent_video_post-2.mp4'), findsWidgets);

      await visit(tester, 'basket', ['/media/post-3']);
      expect(find.byKey(const Key('media-download')), findsNothing);
      expect(find.byKey(const Key('media-download-off')), findsOneWidget);
      expectNoLayoutErrors();
    });
  });
}
