import 'sport.dart';

abstract interface class SportsRepository {
  Future<List<Sport>> sports();
}
