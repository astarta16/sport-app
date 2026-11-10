import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/club.dart';

final clubsProvider = FutureProvider<List<Club>>((ref) => ref.watch(clubsRepositoryProvider).clubs());

final clubsByIdProvider = Provider<Map<String, Club>>((ref) {
  final list = ref.watch(clubsProvider).value ?? const [];
  return {for (final c in list) c.id: c};
});

final venuesProvider = FutureProvider<List<Venue>>((ref) => ref.watch(clubsRepositoryProvider).venues());

final venuesByIdProvider = Provider<Map<String, Venue>>((ref) {
  final list = ref.watch(venuesProvider).value ?? const [];
  return {for (final v in list) v.id: v};
});

final myMembershipRequestsProvider = StreamProvider<List<MembershipRequest>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(clubsRepositoryProvider).watchMyRequests();
});

final incomingRequestsProvider = StreamProvider<List<MembershipRequest>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(clubsRepositoryProvider).watchIncomingRequests();
});
