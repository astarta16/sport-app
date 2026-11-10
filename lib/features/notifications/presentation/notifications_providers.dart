import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/notification_models.dart';

final inboxProvider = StreamProvider<List<AppNotification>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(notificationsRepositoryProvider).watchInbox();
});

final unreadCountProvider = Provider<int>(
  (ref) => (ref.watch(inboxProvider).value ?? const []).where((n) => !n.read).length,
);
