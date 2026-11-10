import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';

/// true = online. Demo: follows the demo "simulate offline" switch.
/// Firebase: device connectivity (Firestore keeps serving its local cache
/// while offline; writes are rejected with a clear error, never faked).
final networkOnlineProvider = StreamProvider<bool>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.watch(() => !demo.offline);
  final c = Connectivity();
  Future<bool> now() async => !(await c.checkConnectivity()).contains(ConnectivityResult.none);
  return Stream.fromFuture(
    now(),
  ).asyncExpand((first) => c.onConnectivityChanged.map((r) => !r.contains(ConnectivityResult.none)).startWith(first));
});

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
