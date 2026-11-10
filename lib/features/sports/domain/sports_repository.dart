import 'sport.dart';

abstract interface class SportsRepository {
  /// Active sports, ordered (catalog managed by platform admins).
  Future<List<Sport>> sports();
  Stream<List<Sport>> watchSports();
}
