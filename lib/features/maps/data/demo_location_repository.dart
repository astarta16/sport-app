import '../../demo/data/demo_backend.dart';
import '../domain/location_repository.dart';

class DemoLocationRepository implements LocationRepository {
  DemoLocationRepository(this.db);

  final DemoBackend db;

  @override
  Future<List<MapPlace>> search(LocationQuery query) async {
    final places = [
      for (final c in db.clubs.values) MapPlace.club(c),
      for (final v in db.venues.values) MapPlace.venue(v, club: v.clubId == null ? null : db.clubs[v.clubId]),
    ];
    return filterPlaces(places, query);
  }
}
