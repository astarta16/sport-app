import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../domain/sport.dart';

final sportsProvider = FutureProvider<List<Sport>>((ref) => ref.watch(sportsRepositoryProvider).sports());

final sportsByIdProvider = Provider<Map<String, Sport>>((ref) {
  final list = ref.watch(sportsProvider).value ?? const [];
  return {for (final s in list) s.id: s};
});
