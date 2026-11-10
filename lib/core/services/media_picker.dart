import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/trainings/domain/training.dart';

/// Picks photos with client-side compression (spec §7.1: compress before
/// upload). Returns an empty list when the user cancels.
class MediaPicker {
  MediaPicker._();

  static final _picker = ImagePicker();

  static Future<List<PhotoUpload>> pickPhotos({int limit = 10}) async {
    final files = await _picker.pickMultiImage(imageQuality: 75, maxWidth: 2048, limit: limit);
    return [for (final f in files) await _toUpload(f)];
  }

  static Future<PhotoUpload?> takePhoto() async {
    final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 2048);
    return f == null ? null : _toUpload(f);
  }

  static Future<PhotoUpload?> pickOnePhoto() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 2048);
    return f == null ? null : _toUpload(f);
  }

  /// Video from camera or gallery, capped at 60 s by the picker (v1.1 §5).
  /// Transcoding to H.264/720p happens server-side in production (see
  /// docs/firebase-setup.md); size and length are validated before upload.
  static Future<PhotoUpload?> pickVideo({required bool camera}) async {
    final f = await _picker.pickVideo(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (f == null) return null;
    final bytes = await f.readAsBytes();
    final name = f.name.toLowerCase();
    final mime = name.endsWith('.mov') ? 'video/quicktime' : 'video/mp4';
    return PhotoUpload(bytes: bytes, fileName: f.name, mimeType: mime);
  }

  /// Square avatar, compressed to ≤ 512 px JPEG (v1.1 §3: ≤ 1 MB).
  static Future<PhotoUpload?> pickAvatar({required bool camera}) async {
    final f = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (f == null) return null;
    return PhotoUpload(bytes: await f.readAsBytes(), fileName: 'avatar.jpg', mimeType: 'image/jpeg');
  }

  /// PDF/JPG/PNG document from the file system (no recompression).
  static Future<PhotoUpload?> pickDocument() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (files.isEmpty) return null;
    final file = files.first;
    final ext = file.name.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    return PhotoUpload(bytes: await file.readAsBytes(), fileName: file.name, mimeType: mime);
  }

  static Future<PhotoUpload> _toUpload(XFile f) async {
    final bytes = await f.readAsBytes();
    final name = f.name.toLowerCase();
    final mime = name.endsWith('.png') ? 'image/png' : 'image/jpeg';
    return PhotoUpload(bytes: bytes, fileName: f.name, mimeType: mime);
  }
}
