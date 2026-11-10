import 'package:flutter_test/flutter_test.dart';
import 'package:sport_parent_app/core/utils/dates.dart';
import 'package:sport_parent_app/core/utils/geo.dart';
import 'package:sport_parent_app/core/utils/validators.dart';

void main() {
  group('TbilisiTime', () {
    test('calendar day uses UTC+4', () {
      // 21:30 UTC on Jan 1 is already Jan 2 01:30 in Tbilisi.
      expect(TbilisiTime.calendarDay(DateTime.utc(2026, 1, 1, 21, 30)), DateTime.utc(2026, 1, 2));
      expect(TbilisiTime.calendarDay(DateTime.utc(2026, 1, 1, 19, 59)), DateTime.utc(2026, 1, 1));
    });

    test('daysBetween counts Tbilisi calendar days', () {
      final from = TbilisiTime.at(2026, 3, 10, 10);
      expect(TbilisiTime.daysBetween(from, DateTime.utc(2026, 3, 15)), 5);
      expect(TbilisiTime.daysBetween(from, DateTime.utc(2026, 3, 11)), 1);
      expect(TbilisiTime.daysBetween(from, DateTime.utc(2026, 3, 9)), -1);
    });

    test('at() builds the instant for a Tbilisi wall-clock time', () {
      expect(TbilisiTime.at(2026, 5, 1, 10), DateTime.utc(2026, 5, 1, 6));
    });
  });

  test('ageInYears handles birthdays not yet reached', () {
    expect(ageInYears(DateTime(2012, 6, 15), DateTime(2026, 6, 14)), 13);
    expect(ageInYears(DateTime(2012, 6, 15), DateTime(2026, 6, 15)), 14);
  });

  test('readDate accepts DateTime, ISO, millis and toDate() objects', () {
    final d = DateTime.utc(2026, 1, 2, 3);
    expect(readDate(d), d);
    expect(readDate(d.toIso8601String()), d);
    expect(readDate(d.millisecondsSinceEpoch).isAtSameMomentAs(d), isTrue);
    expect(readDate(_FakeTimestamp(d)), d);
    expect(() => readDate(null), throwsFormatException);
  });

  group('Validators', () {
    test('phone accepts Georgian mobile numbers in any common format', () {
      for (final v in ['555 12 34 56', '+995555123456', '995 555-12-34-56', '00995555123456']) {
        expect(Validators.phone(v), isNull, reason: v);
        expect(Validators.normalizePhone(v), '+995555123456');
      }
    });

    test('phone rejects invalid numbers', () {
      expect(Validators.phone(''), 'required');
      expect(Validators.phone('322123456'), 'invalidPhone'); // landline
      expect(Validators.phone('55512'), 'invalidPhone');
    });

    test('otp must be 6 digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12345'), 'invalidOtp');
      expect(Validators.otp(''), 'required');
    });

    test('names accept Georgian letters', () {
      expect(Validators.name('ნინო'), isNull);
      expect(Validators.name('ანა-მარია'), isNull);
      expect(Validators.name('a'), 'tooShort');
      expect(Validators.name('Nino1'), 'invalidName');
    });

    test('child birth date bounds', () {
      final now = DateTime(2026, 11, 10);
      expect(Validators.birthDate(DateTime(2017, 1, 1), now), isNull);
      expect(Validators.birthDate(null, now), 'required');
      expect(Validators.birthDate(DateTime(2027, 1, 1), now), 'dateInFuture');
      expect(Validators.birthDate(DateTime(2005, 1, 1), now), 'tooOldForChild');
    });

    test('formatting and masking never leak the full number', () {
      expect(Validators.formatPhone('+995555123456'), '+995 555 12 34 56');
      final masked = Validators.maskPhone('+995555123456');
      expect(masked.endsWith('56'), isTrue);
      expect(masked.contains('5551234'), isFalse);
    });
  });

  group('Geo', () {
    test('distance Tbilisi → Batumi ≈ 280 km', () {
      final d = const GeoCoord(41.7151, 44.7871).distanceKm(const GeoCoord(41.6460, 41.6330));
      expect(d, closeTo(262, 25));
    });

    test('geohash encodes a known point', () {
      expect(Geohash.encode(57.64911, 10.40744, precision: 11), 'u4pruydqqvj');
    });
  });
}

class _FakeTimestamp {
  _FakeTimestamp(this._d);

  final DateTime _d;
  DateTime toDate() => _d;
}
