import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../../../core/utils/geo.dart';
import '../../clubs/domain/club.dart';
import '../domain/location_repository.dart';

/// Firestore location search: `array-contains` sport filter server-side,
/// geohash prefix range for "nearby" (spec §6.3), then the shared in-memory
/// text/distance filter.
class FirebaseLocationRepository implements LocationRepository {
  FirebaseLocationRepository(this.db);

  final FirebaseFirestore db;

  Query<Map<String, dynamic>> _query(String col, LocationQuery q) {
    Query<Map<String, dynamic>> query = db.collection(col);
    if (q.sportId != null) query = query.where('sportIds', arrayContains: q.sportId);
    if (q.center != null && q.radiusKm != null) {
      final prefix = Geohash.encode(
        q.center!.latitude,
        q.center!.longitude,
        precision: Geohash.precisionForRadius(q.radiusKm!),
      );
      query = query.orderBy('geohash').startAt([prefix]).endAt(['$prefix']);
    }
    return query;
  }

  @override
  Future<List<MapPlace>> search(LocationQuery q) => guardFirebase(() async {
    final results = await Future.wait([_query('clubs', q).get(), _query('venues', q).get()]);
    final clubs = {for (final d in results[0].docs) d.id: Club.fromMap(d.id, d.data())};
    final places = [
      for (final c in clubs.values) MapPlace.club(c),
      for (final d in results[1].docs)
        () {
          final v = Venue.fromMap(d.id, d.data());
          return MapPlace.venue(v, club: clubs[v.clubId]);
        }(),
    ];
    return filterPlaces(places, q);
  });
}
