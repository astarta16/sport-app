import 'dart:convert';

/// One event in an iCalendar (RFC 5545) file.
class IcsEvent {
  const IcsEvent({
    required this.uid,
    required this.start,
    required this.end,
    required this.summary,
    this.location,
    this.description,
    this.cancelled = false,
    this.alarmBefore = const Duration(hours: 1),
  });

  /// Stable id, so re-importing updates the event instead of duplicating it.
  final String uid;
  final DateTime start;
  final DateTime end;
  final String summary;
  final String? location;
  final String? description;
  final bool cancelled;

  /// Reminder before the start; null = no alarm.
  final Duration? alarmBefore;
}

/// Builds `.ics` files that Google Calendar, Apple Calendar and Outlook import.
/// Times are written in UTC (`…Z`), so no VTIMEZONE block is needed.
abstract final class Ics {
  static const domain = 'sportparent.app';

  static String build(List<IcsEvent> events, {required DateTime stamp}) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Sport Parent//Beta 1.3//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
    ];
    for (final e in events) {
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${_text(e.uid)}@$domain',
        'DTSTAMP:${utc(stamp)}',
        'DTSTART:${utc(e.start)}',
        'DTEND:${utc(e.end.isAfter(e.start) ? e.end : e.start.add(const Duration(hours: 1)))}',
        'SUMMARY:${_text(e.summary)}',
        if ((e.location ?? '').trim().isNotEmpty) 'LOCATION:${_text(e.location!.trim())}',
        if ((e.description ?? '').trim().isNotEmpty) 'DESCRIPTION:${_text(e.description!.trim())}',
        'STATUS:${e.cancelled ? 'CANCELLED' : 'CONFIRMED'}',
        if (e.alarmBefore != null && !e.cancelled) ...[
          'BEGIN:VALARM',
          'ACTION:DISPLAY',
          'DESCRIPTION:${_text(e.summary)}',
          'TRIGGER:-PT${e.alarmBefore!.inMinutes}M',
          'END:VALARM',
        ],
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(fold).join('\r\n')}\r\n';
  }

  static List<int> bytes(List<IcsEvent> events, {required DateTime stamp}) => utf8.encode(build(events, stamp: stamp));

  /// 20261112T143000Z
  static String utc(DateTime d) {
    final u = d.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  /// TEXT escaping (RFC 5545 §3.3.11).
  static String _text(String s) => s
      .replaceAll('\\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\n', r'\n');

  /// Lines longer than 75 octets are folded (CRLF + space), never inside a
  /// UTF-8 sequence — Georgian letters are 3 bytes each.
  static String fold(String line) {
    if (utf8.encode(line).length <= 75) return line;
    final out = StringBuffer();
    var count = 0;
    var limit = 75;
    for (final rune in line.runes) {
      final ch = String.fromCharCode(rune);
      final n = utf8.encode(ch).length;
      if (count + n > limit) {
        out.write('\r\n ');
        count = 0;
        limit = 74; // the leading space counts
      }
      out.write(ch);
      count += n;
    }
    return out.toString();
  }

  /// training_g-football-u10_20261112-1430.ics
  static String fileName(String kind, String slug, DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    final safe = slug.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
    return '${kind}_${safe}_${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}.ics';
  }
}
