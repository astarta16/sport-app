import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/features/roster/data/export_service.dart';
import 'package:sport_parent_app/l10n/app_localizations.dart';

Map<String, dynamic> arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

/// `{name}` placeholders (ignores ICU plural/select bodies' literal text).
Set<String> placeholders(String s) =>
    RegExp(r'(?<![=\w])\{(\w+)(?=\}|,)').allMatches(s).map((m) => m.group(1)!).toSet()
      ..removeAll(const {'other', 'one', 'few', 'many', 'zero', 'two'});

final _georgian = RegExp('[Ⴀ-ჿ]');
final _cyrillic = RegExp('[Ѐ-ӿ]');
final _literal = RegExp(
  r"'(?:[^'\\]|\\.)*'"
  '|'
  r'"(?:[^"\\]|\\.)*"',
);

void main() {
  final langs = ['ka', 'en', 'ru'];
  final files = {for (final l in langs) l: arb(l)};
  Set<String> keys(String l) => files[l]!.keys.where((k) => !k.startsWith('@')).toSet();

  test('ka, en and ru have exactly the same keys', () {
    for (final l in ['en', 'ru']) {
      expect(keys(l).difference(keys('ka')), isEmpty, reason: 'extra keys in $l');
      expect(keys('ka').difference(keys(l)), isEmpty, reason: 'missing keys in $l');
    }
    expect(keys('ka').length, greaterThan(900));
  });

  test('no empty values and no ru fallbacks to English', () {
    for (final l in langs) {
      for (final k in keys(l)) {
        expect((files[l]![k] as String).trim(), isNotEmpty, reason: '$l.$k');
      }
    }
    final missing = jsonDecode(File('tool/l10n_missing_ru.json').readAsStringSync()) as List;
    expect(missing, isEmpty, reason: 'keys still falling back to English in ru');
  });

  test('placeholders match across languages', () {
    for (final k in keys('ka')) {
      final ka = placeholders(files['ka']![k] as String);
      for (final l in ['en', 'ru']) {
        expect(placeholders(files[l]![k] as String), ka, reason: '$l.$k');
      }
    }
  });

  test('values are in the right script (catches copy-paste mistakes)', () {
    final notGeorgian = <String>[];
    final notRussian = <String>[];
    final scriptInEn = <String>[];
    // Brand names, units and codes may legitimately stay Latin.
    bool hasLetters(String s) => RegExp(r'[A-Za-zႠ-ჿЀ-ӿ]{3,}').hasMatch(s.replaceAll(RegExp(r'\{[^}]*\}'), ''));
    for (final k in keys('ka')) {
      final ka = files['ka']![k] as String, en = files['en']![k] as String, ru = files['ru']![k] as String;
      if (hasLetters(ka) && !_georgian.hasMatch(ka) && ka != en) notGeorgian.add(k);
      if (hasLetters(ru) && !_cyrillic.hasMatch(ru) && ru != en) notRussian.add(k);
      if (_georgian.hasMatch(en) || _cyrillic.hasMatch(en)) scriptInEn.add(k);
    }
    expect(notGeorgian, isEmpty);
    expect(notRussian, isEmpty);
    // Native language names are shown in their own script in every locale.
    expect(scriptInEn.where((k) => !const {'languageGeorgian', 'languageRussian'}.contains(k)), isEmpty);
  });

  test('every locale loads and plural/select messages format', () async {
    for (final l in langs) {
      final loc = await AppLocalizations.delegate.load(Locale(l));
      expect(loc.localeName, l);
      // A few placeholder/plural strings across features.
      expect(loc.attendanceSummary(1, 2, 3, 4), isNotEmpty);
      expect(loc.planCompletion('2', 5), contains('5'));
    }
  });

  test('no hardcoded Georgian/Russian UI text in presentation or admin code', () {
    final offenders = <String>[];
    final dirs = [Directory('lib/admin'), Directory('lib/core/widgets'), Directory('lib/features')];
    for (final d in dirs) {
      for (final f in d.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final p = f.path;
        if (!p.contains('/presentation/') && !p.startsWith('lib/admin') && !p.startsWith('lib/core/widgets')) continue;
        if (p.endsWith('language_selector.dart')) continue; // native language names
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//')) continue;
          for (final m in _literal.allMatches(line)) {
            final lit = m.group(0)!;
            if (_georgian.hasMatch(lit) || _cyrillic.hasMatch(lit)) offenders.add('$p:${i + 1}: $lit');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('CSV export is UTF-8 with BOM and escapes cells', () {
    final t = ExportTable(
      title: 'სია',
      subtitle: '',
      headers: const ['სახელი', 'Note'],
      rows: const [
        ['ლუკა', 'a, "b"'],
        ['Анна', 'x'],
      ],
      footer: '',
      confidential: '',
      pageLabel: (n) => '$n',
    );
    final bytes = ExportService.csv(t);
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes.sublist(3));
    expect(text, contains('ლუკა,"a, ""b"""'));
    expect(text, contains('Анна,x'));
  });

  test('PDF export embeds the Georgian font and renders ka/ru/en', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await rootBundle.load('assets/fonts/NotoSansGeorgian.ttf');
    final t = ExportTable(
      title: 'დასწრების ფურცელი · Посещаемость',
      subtitle: 'U-10',
      headers: const ['სახელი', 'Статус', 'Status'],
      rows: [
        for (var i = 0; i < 80; i++) ['ბავშვი $i', 'Присутствовал', 'present'],
      ],
      footer: 'შექმნილია',
      confidential: 'კონფიდენციალური',
      pageLabel: (n) => 'გვ. $n',
    );
    final pdf = await ExportService.pdf(t);
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
    expect(pdf.length, greaterThan(10000), reason: 'fonts are embedded');
    final raw = latin1.decode(pdf, allowInvalid: true);
    expect(raw, contains('NotoSansGeorgian'));
  });

  test('export filename has kind, slug and timestamp', () {
    final n = ExportService.fileName('roster', 'U-10 ფეხბურთი', DateTime(2026, 11, 10, 9, 5), ExportFormat.pdf);
    expect(n, startsWith('roster_'));
    expect(n, contains('20261110-0905'));
    expect(n, endsWith('.pdf'));
  });
}
