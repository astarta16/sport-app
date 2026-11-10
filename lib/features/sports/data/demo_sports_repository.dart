import '../../demo/data/demo_backend.dart';
import '../domain/sport.dart';
import '../domain/sports_repository.dart';

class DemoSportsRepository implements SportsRepository {
  DemoSportsRepository(this.db);

  final DemoBackend db;

  @override
  Future<List<Sport>> sports() async => db.sports.values.toList();
}
