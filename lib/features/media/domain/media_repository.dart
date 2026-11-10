import 'dart:typed_data';

/// Loads private media (training photos, chat attachments) by reference.
/// Production reads from Firebase Storage with the user's credentials (rules
/// enforce group membership); no public download URLs are stored.
abstract interface class MediaRepository {
  Future<Uint8List?> load(String ref);
}
