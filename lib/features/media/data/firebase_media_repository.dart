import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../domain/media_repository.dart';

/// Downloads private media with the signed-in user's credentials; Storage
/// rules allow it only for members of the relevant group.
class FirebaseMediaRepository implements MediaRepository {
  FirebaseMediaRepository(this.storage);

  final FirebaseStorage storage;

  @override
  Future<Uint8List?> load(String ref) async {
    try {
      return await storage.ref(ref).getData(10 * 1024 * 1024);
    } on FirebaseException {
      return null;
    }
  }
}
