import 'dart:typed_data';

extension Uint8ListX on Uint8List {
  static Uint8List from(List<int> bytes) => bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}
