import 'dart:math' as math;

/// Backend-agnostic coordinate (Firestore `GeoPoint` is converted at the edge).
class GeoCoord {
  const GeoCoord(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  factory GeoCoord.fromMap(Object? value) {
    if (value is Map) {
      return GeoCoord(
        (value['latitude'] as num).toDouble(),
        (value['longitude'] as num).toDouble(),
      );
    }
    if (value != null) {
      final dynamic v = value; // Firestore GeoPoint
      return GeoCoord((v.latitude as num).toDouble(), (v.longitude as num).toDouble());
    }
    throw const FormatException('Missing location');
  }

  Map<String, dynamic> toMap() => {'latitude': latitude, 'longitude': longitude};

  /// Great-circle distance in kilometres.
  double distanceKm(GeoCoord other) {
    const r = 6371.0;
    final dLat = _rad(other.latitude - latitude);
    final dLng = _rad(other.longitude - longitude);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(latitude)) * math.cos(_rad(other.latitude)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is GeoCoord && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Minimal geohash encoder used for Firestore range queries on `geohash`.
class Geohash {
  Geohash._();

  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double lat, double lng, {int precision = 9}) {
    var latMin = -90.0, latMax = 90.0, lngMin = -180.0, lngMax = 180.0;
    final buffer = StringBuffer();
    var bit = 0, ch = 0;
    var even = true;
    while (buffer.length < precision) {
      if (even) {
        final mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          ch = (ch << 1) | 1;
          lngMin = mid;
        } else {
          ch = ch << 1;
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          ch = (ch << 1) | 1;
          latMin = mid;
        } else {
          ch = ch << 1;
          latMax = mid;
        }
      }
      even = !even;
      if (++bit == 5) {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return buffer.toString();
  }

  /// Geohash prefix length whose cell roughly covers [radiusKm].
  static int precisionForRadius(double radiusKm) {
    if (radiusKm > 630) return 2;
    if (radiusKm > 78) return 3;
    if (radiusKm > 20) return 4;
    if (radiusKm > 2.4) return 5;
    if (radiusKm > 0.61) return 6;
    return 7;
  }
}
