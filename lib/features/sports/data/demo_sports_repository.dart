import '../../demo/data/demo_backend.dart';
import '../domain/sport.dart';
import '../domain/sports_repository.dart';

class DemoSportsRepository implements SportsRepository {
  DemoSportsRepository(this.db);

  final DemoBackend db;

  List<Sport> _active() =>
      db.sports.values.where((s) => s.active).toList()
        ..sort((a, b) => a.order != b.order ? a.order - b.order : a.name.compareTo(b.name));

  @override
  Future<List<Sport>> sports() async => _active();

  @override
  Stream<List<Sport>> watchSports() => db.watch(_active);
}
