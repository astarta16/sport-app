import '../../../core/utils/geo.dart';
import '../../clubs/domain/club.dart';

enum MapPlaceKind { club, venue }

/// A pin on the map: either a club or a venue.
class MapPlace {
  const MapPlace.club(Club this.club)
      : kind = MapPlaceKind.club,
        venue = null;
  const MapPlace.venue(Venue this.venue, {this.club}) : kind = MapPlaceKind.venue;

  final MapPlaceKind kind;
  final Club? club;
  final Venue? venue;

  String get id => kind == MapPlaceKind.club ? 'club:${club!.id}' : 'venue:${venue!.id}';
  String get name => venue?.name ?? club!.name;
  String get address => venue?.address ?? club!.address;
  GeoCoord get location => venue?.location ?? club!.location;
  List<String> get sportIds => venue?.sportIds ?? club!.sportIds;
  String? get clubId => kind == MapPlaceKind.club ? club!.id : venue!.clubId;
}

class LocationQuery {
  const LocationQuery({this.sportId, this.text = '', this.center, this.radiusKm});

  final String? sportId;
  final String text;
  final GeoCoord? center;
  final double? radiusKm;
}

/// Replaceable search port: demo filters in memory; Firestore uses
/// `array-contains` + geohash prefix ranges (spec §6.3).
abstract interface class LocationRepository {
  Future<List<MapPlace>> search(LocationQuery query);
}

/// Shared in-memory filter used by both implementations after fetching.
List<MapPlace> filterPlaces(Iterable<MapPlace> places, LocationQuery q) {
  final text = q.text.trim().toLowerCase();
  final result = places.where((p) {
    if (q.sportId != null && !p.sportIds.contains(q.sportId)) return false;
    if (text.isNotEmpty && !p.name.toLowerCase().contains(text) && !p.address.toLowerCase().contains(text)) {
      return false;
    }
    if (q.center != null && q.radiusKm != null && p.location.distanceKm(q.center!) > q.radiusKm!) return false;
    return true;
  }).toList();
  if (q.center != null) {
    result.sort((a, b) => a.location.distanceKm(q.center!).compareTo(b.location.distanceKm(q.center!)));
  }
  return result;
}
