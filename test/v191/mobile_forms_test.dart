import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_parent_app/app/routes.dart';
import 'package:sport_parent_app/features/demo/data/demo_seed.dart';

import '../responsive/responsive_screens_test.dart'
    show boot, signInAs, visit, pumpFrames, expectNoLayoutErrors, routerOf;
import '../v17/v17_ui_test.dart' show tapKey, scrollTo;

const phone = Size(390, 844);

/// Opens [route] on top of [base] so that "back" has somewhere to go.
Future<void> _open(WidgetTester tester, String base, String route) async {
  await visit(tester, 'base', [base]);
  routerOf(tester).push(route);
  await pumpFrames(tester);
}

/// The app bar back button (goes through PopScope like system back).
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await pumpFrames(tester);
}

/// Scrolls [key] into view even when it is only in the list's cache area
/// (the offline banner shrinks the viewport), then taps it.
Future<void> _tapAnywhere(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key), skipOffstage: false);
  await tester.ensureVisible(f);
  await pumpFrames(tester, 2);
  await tester.tap(find.byKey(Key(key)));
  await pumpFrames(tester);
}

/// Accepts the date picker's preselected date.
Future<void> _pickDate(WidgetTester tester, String key) async {
  await tapKey(tester, key);
  await tester.tap(find.byType(TextButton).last); // OK
  await pumpFrames(tester);
}

Future<void> _toCertificateForm(WidgetTester tester) async {
  await _open(tester, Routes.parentHome, Routes.uploadCertificate('child-1'));
  await tapKey(tester, 'cert-consent');
  await tapKey(tester, 'cert-consent-continue');
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('M25 unsaved-changes guard', () {
    testWidgets('clean form leaves without asking', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await _open(tester, Routes.parentHome, Routes.newChild);
      expect(find.byKey(const Key('child-first-name')), findsOneWidget);
      await _back(tester);
      expect(find.byKey(const Key('unsaved-dialog')), findsNothing);
      expect(find.byKey(const Key('child-first-name')), findsNothing);
      expectNoLayoutErrors();
    });

    testWidgets('dirty form: Stay keeps the input, Discard leaves', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await _open(tester, Routes.parentHome, Routes.newChild);
      await tester.enterText(find.byKey(const Key('child-first-name')), 'Nino');
      await pumpFrames(tester, 2);

      await _back(tester);
      expect(find.byKey(const Key('unsaved-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('unsaved-stay')));
      await pumpFrames(tester);
      expect(find.byKey(const Key('unsaved-dialog')), findsNothing);
      expect(find.text('Nino'), findsOneWidget, reason: 'Stay keeps the typed text');

      await _back(tester);
      await tester.tap(find.byKey(const Key('unsaved-discard')));
      await pumpFrames(tester);
      expect(find.byKey(const Key('child-first-name')), findsNothing, reason: 'Discard leaves the form');
      expectNoLayoutErrors();
    });

    testWidgets('coach match form is guarded too', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.coach);
      await _open(tester, Routes.coachHome, Routes.newMatch('g-football-u10'));
      await tester.enterText(find.byKey(const Key('match-opponent')), 'Dinamo');
      await pumpFrames(tester, 2);
      await _back(tester);
      expect(find.byKey(const Key('unsaved-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('unsaved-discard')));
      await pumpFrames(tester);
      expect(find.byKey(const Key('match-opponent')), findsNothing);
      expectNoLayoutErrors();
    });
  });

  group('M20 certificate upload', () {
    testWidgets('file card after picking; remove brings the pickers back', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await _toCertificateForm(tester);
      expect(find.byKey(const Key('cert-pick-camera')), findsOneWidget);
      expect(find.byKey(const Key('cert-pick-gallery')), findsOneWidget);
      expect(find.byKey(const Key('cert-pick-file')), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'PDF.*\b10\b')),
        findsOneWidget,
        reason: 'limit read from CertificatePolicy.maxBytes',
      );
      expect(find.byKey(const Key('cert-who-can-see')), findsOneWidget);

      await tapKey(tester, 'cert-demo-file');
      expect(find.byKey(const Key('cert-file-card')), findsOneWidget);
      expect(find.text('cnoba.pdf'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^4 ')), findsOneWidget);
      expect(find.byKey(const Key('cert-pick-camera')), findsNothing);

      await tapKey(tester, 'cert-file-remove');
      expect(find.byKey(const Key('cert-file-card')), findsNothing);
      expect(find.byKey(const Key('cert-pick-camera')), findsOneWidget);
      expectNoLayoutErrors();
    });

    testWidgets('failed upload: inline error, inputs kept, Retry succeeds and leaves without a prompt', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      final before = db.certificates.length;
      await _toCertificateForm(tester);
      await tapKey(tester, 'cert-demo-file');
      await _pickDate(tester, 'cert-issued');
      await _pickDate(tester, 'cert-valid-until');

      db.setOffline(true);
      await pumpFrames(tester);
      await _tapAnywhere(tester, 'cert-submit');
      await pumpFrames(tester);
      await scrollTo(tester, 'cert-upload-error');
      expect(find.byKey(const Key('cert-upload-error')), findsOneWidget);
      expect(find.byKey(const Key('cert-file-card'), skipOffstage: false), findsOneWidget, reason: 'the file is kept');
      expect(db.certificates.length, before);

      db.setOffline(false);
      await pumpFrames(tester);
      await tester.tap(
        find.descendant(of: find.byKey(const Key('cert-upload-error')), matching: find.byType(TextButton)),
      );
      await pumpFrames(tester, 12);
      expect(db.certificates.length, before + 1);
      expect(find.byKey(const Key('unsaved-dialog')), findsNothing, reason: 'saving never triggers the guard');
      expect(find.byKey(const Key('cert-submit')), findsNothing, reason: 'back on the previous screen');
      expectNoLayoutErrors();
    });

    testWidgets('picked file blocks back until discarded', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await _toCertificateForm(tester);
      await tapKey(tester, 'cert-demo-file');
      await _back(tester);
      expect(find.byKey(const Key('unsaved-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('unsaved-stay')));
      await pumpFrames(tester);
      expect(find.byKey(const Key('cert-file-card')), findsOneWidget);
      expectNoLayoutErrors();
    });
  });

  group('M22/M24 payment receipt', () {
    testWidgets('gallery option, preview card with remove, inline error with retry', (tester) async {
      final db = await boot(tester, phone);
      await signInAs(tester, db, DemoIds.parent);
      await _open(tester, Routes.parentHome, Routes.paymentProof('pay-l-f-0'));
      await scrollTo(tester, 'proof-pick-gallery');
      expect(find.byKey(const Key('proof-pick-camera')), findsOneWidget);
      expect(find.byKey(const Key('proof-pick-file')), findsOneWidget);

      await tapKey(tester, 'proof-demo-receipt');
      expect(find.byKey(const Key('proof-file-card')), findsOneWidget);
      expect(find.text('qvitari.pdf'), findsOneWidget);
      await tapKey(tester, 'proof-file-remove');
      expect(find.byKey(const Key('proof-file-card')), findsNothing);

      await tapKey(tester, 'proof-demo-receipt');
      await tester.enterText(find.byKey(const Key('proof-reference')), 'TBC-1');
      db.setOffline(true);
      await pumpFrames(tester);
      await _tapAnywhere(tester, 'proof-submit');
      await pumpFrames(tester, 12);
      await scrollTo(tester, 'proof-error');
      expect(find.byKey(const Key('proof-error')), findsOneWidget);
      expect(
        find.byKey(const Key('proof-file-card'), skipOffstage: false),
        findsOneWidget,
        reason: 'the receipt is kept',
      );
      expect(find.byType(SnackBar), findsNothing, reason: 'no double message');

      db.setOffline(false);
      await pumpFrames(tester);
      await tester.tap(find.descendant(of: find.byKey(const Key('proof-error')), matching: find.byType(TextButton)));
      await pumpFrames(tester, 20);
      expect(db.paymentProofs.values.where((p) => p.paymentId == 'pay-l-f-0'), isNotEmpty);
      expect(find.byKey(const Key('proof-error')), findsNothing);
      expectNoLayoutErrors();
    });
  });
}
