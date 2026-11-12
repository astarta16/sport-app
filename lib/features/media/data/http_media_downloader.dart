// Network transfer for authorized downloads. dart:io only exists on mobile /
// desktop; the web build (admin) gets the stub, which is never used there.
export 'http_media_downloader_stub.dart' if (dart.library.io) 'http_media_downloader_io.dart';
