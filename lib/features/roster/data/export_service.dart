import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A table to export. Built only from data the coach may read (own groups);
/// never contains documents, medical details or phone numbers.
class ExportTable {
  const ExportTable({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
    required this.footer,
    required this.confidential,
    required this.pageLabel,
  });

  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<String>> rows;

  /// "Generated: …" line.
  final String footer;
  final String confidential;

  /// Localized "Page {n}" builder.
  final String Function(int page) pageLabel;
}

enum ExportFormat { pdf, csv }

class ExportService {
  ExportService._();

  /// RFC 4180 CSV with a UTF-8 BOM (Excel shows Georgian/Russian correctly).
  static Uint8List csv(ExportTable t) {
    String cell(String v) =>
        (v.contains(',') || v.contains('"') || v.contains('\n')) ? '"${v.replaceAll('"', '""')}"' : v;
    final b = StringBuffer()..writeln(t.headers.map(cell).join(','));
    for (final r in t.rows) {
      b.writeln(r.map(cell).join(','));
    }
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(b.toString())]);
  }

  static pw.ThemeData? _theme;

  /// Roboto (Latin + Cyrillic) with Noto Sans Georgian as fallback.
  static Future<pw.ThemeData> theme() async {
    if (_theme != null) return _theme!;
    final base = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final ka = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansGeorgian.ttf'));
    return _theme = pw.ThemeData.withFont(base: base, bold: base, fontFallback: [ka]);
  }

  static Future<Uint8List> pdf(ExportTable t, {pw.ThemeData? theme}) async {
    final doc = pw.Document(theme: theme ?? await ExportService.theme(), title: t.title, creator: 'Gundi');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(t.title, style: const pw.TextStyle(fontSize: 18, color: PdfColor.fromInt(0xFF0B1530))),
            pw.SizedBox(height: 2),
            pw.Text(t.subtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${t.confidential} · ${t.footer}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(t.pageLabel(ctx.pageNumber), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: t.headers,
            data: t.rows,
            headerStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1D4ED8)),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            cellAlignment: pw.Alignment.centerLeft,
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// `kind_group_YYYYMMDD-HHMM.ext` with only safe ASCII characters.
  static String fileName(String kind, String group, DateTime at, ExportFormat f) {
    String two(int n) => n.toString().padLeft(2, '0');
    final slug = group.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final stamp = '${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}';
    return '${kind}_${slug.isEmpty ? 'group' : slug}_$stamp.${f.name}';
  }
}
