import 'package:flutter_riverpod/misc.dart';

import '../features/authentication/data/demo_auth_repository.dart';
import '../features/chat/data/demo_chat_repository.dart';
import '../features/children/data/demo_children_repository.dart';
import '../features/clubs/data/demo_clubs_repository.dart';
import '../features/demo/data/demo_backend.dart';
import '../features/groups/data/demo_groups_repository.dart';
import '../features/maps/data/demo_location_repository.dart';
import '../features/media/data/demo_media_repository.dart';
import '../features/medical_certificates/data/demo_certificates_repository.dart';
import '../features/notifications/data/demo_notifications_repository.dart';
import '../features/payments/data/demo_payments_repository.dart';
import '../features/sports/data/demo_sports_repository.dart';
import '../features/trainings/data/demo_trainings_repository.dart';
import 'config.dart';
import 'di.dart';

/// Binds every repository to the in-memory demo backend.
List<Override> demoOverrides(DemoBackend db) => [
  appModeProvider.overrideWithValue(AppMode.demo),
  clockProvider.overrideWithValue(db.clock),
  authRepositoryProvider.overrideWithValue(DemoAuthRepository(db)),
  userDirectoryRepositoryProvider.overrideWithValue(DemoUserDirectoryRepository(db)),
  childrenRepositoryProvider.overrideWithValue(DemoChildrenRepository(db)),
  sportsRepositoryProvider.overrideWithValue(DemoSportsRepository(db)),
  clubsRepositoryProvider.overrideWithValue(DemoClubsRepository(db)),
  groupsRepositoryProvider.overrideWithValue(DemoGroupsRepository(db)),
  trainingsRepositoryProvider.overrideWithValue(DemoTrainingsRepository(db)),
  chatRepositoryProvider.overrideWithValue(DemoChatRepository(db)),
  certificatesRepositoryProvider.overrideWithValue(DemoCertificatesRepository(db)),
  notificationsRepositoryProvider.overrideWithValue(DemoNotificationsRepository(db)),
  paymentsRepositoryProvider.overrideWithValue(DemoPaymentsRepository(db)),
  locationRepositoryProvider.overrideWithValue(DemoLocationRepository(db)),
  mediaRepositoryProvider.overrideWithValue(DemoMediaRepository(db)),
];
