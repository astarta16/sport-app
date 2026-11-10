import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/notification_models.dart';

/// Inbox query: page size (pagination) and optional category filter.
typedef InboxQuery = ({int limit, NotificationCategory? category});

final inboxPageProvider = StreamProvider.autoDispose.family<List<AppNotification>, InboxQuery>((ref, q) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(notificationsRepositoryProvider).watchInbox(limit: q.limit, category: q.category);
});

/// Latest notifications (dashboard previews).
final inboxProvider = StreamProvider<List<AppNotification>>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(const []);
  return ref.watch(notificationsRepositoryProvider).watchInbox(limit: 30);
});

final unreadCountStreamProvider = StreamProvider<int>((ref) {
  if (ref.watch(currentUidProvider) == null) return Stream.value(0);
  return ref.watch(notificationsRepositoryProvider).watchUnreadCount();
});

final unreadCountProvider = Provider<int>((ref) => ref.watch(unreadCountStreamProvider).value ?? 0);
