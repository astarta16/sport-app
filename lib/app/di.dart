import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/authentication/domain/auth_repository.dart';
import '../features/chat/domain/chat_repository.dart';
import '../features/children/domain/children_repository.dart';
import '../features/clubs/domain/clubs_repository.dart';
import '../features/groups/domain/groups_repository.dart';
import '../features/maps/domain/location_repository.dart';
import '../features/media/domain/media_repository.dart';
import '../features/medical_certificates/domain/certificates_repository.dart';
import '../features/notifications/domain/notifications_repository.dart';
import '../features/payments/domain/payments_repository.dart';
import '../features/sports/domain/sports_repository.dart';
import '../features/trainings/domain/trainings_repository.dart';
import 'config.dart';

/// Composition root: every repository is bound in `bootstrap.dart` to either
/// the demo or the Firebase implementation behind the same interface.
Never _unbound(String name) => throw UnimplementedError('$name is not bound — see bootstrap.dart');

final appModeProvider = Provider<AppMode>((_) => AppConfig.mode);
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);
final sharedPreferencesProvider = Provider<SharedPreferences>((_) => _unbound('SharedPreferences'));

final authRepositoryProvider = Provider<AuthRepository>((_) => _unbound('AuthRepository'));
final userDirectoryRepositoryProvider = Provider<UserDirectoryRepository>((_) => _unbound('UserDirectoryRepository'));
final childrenRepositoryProvider = Provider<ChildrenRepository>((_) => _unbound('ChildrenRepository'));
final sportsRepositoryProvider = Provider<SportsRepository>((_) => _unbound('SportsRepository'));
final clubsRepositoryProvider = Provider<ClubsRepository>((_) => _unbound('ClubsRepository'));
final groupsRepositoryProvider = Provider<GroupsRepository>((_) => _unbound('GroupsRepository'));
final trainingsRepositoryProvider = Provider<TrainingsRepository>((_) => _unbound('TrainingsRepository'));
final chatRepositoryProvider = Provider<ChatRepository>((_) => _unbound('ChatRepository'));
final certificatesRepositoryProvider = Provider<CertificatesRepository>((_) => _unbound('CertificatesRepository'));
final notificationsRepositoryProvider = Provider<NotificationsRepository>((_) => _unbound('NotificationsRepository'));
final paymentsRepositoryProvider = Provider<PaymentsRepository>((_) => _unbound('PaymentsRepository'));
final locationRepositoryProvider = Provider<LocationRepository>((_) => _unbound('LocationRepository'));
final mediaRepositoryProvider = Provider<MediaRepository>((_) => _unbound('MediaRepository'));
