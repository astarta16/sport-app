import 'dart:typed_data';

import '../../demo/data/demo_backend.dart';
import '../domain/media_repository.dart';

class DemoMediaRepository implements MediaRepository {
  DemoMediaRepository(this.db);

  final DemoBackend db;

  /// `demo://` placeholders return null so the UI draws a branded tile.
  @override
  Future<Uint8List?> load(String ref) async => db.photos[ref];
}
