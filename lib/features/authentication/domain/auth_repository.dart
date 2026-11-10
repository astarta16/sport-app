import '../../notifications/domain/notification_models.dart';
import 'app_user.dart';

/// Demo account shown on the demo login screen (empty in production).
class DemoAccount {
  const DemoAccount({required this.uid, required this.label, required this.role, required this.phone});

  final String uid;
  final String label;
  final UserRole role;
  final String phone;
}

abstract interface class AuthRepository {
  Stream<AuthSession?> watchSession();
  AuthSession? get currentSession;

  /// Sends an SMS code; returns a verification id.
  Future<String> sendCode(String phone);
  Future<void> verifyCode(String verificationId, String code);
  Future<AppUser> completeRegistration(RegistrationData data);
  Future<void> updateLastContext(UserContext context);
  Future<void> updateNotificationPrefs(NotificationPreferences prefs);
  Future<void> updateProfile({required String firstName, required String lastName});
  Future<void> signOut();

  /// Deletes the account; all medical certificates of solely-owned children
  /// are removed from storage (spec §7.4).
  Future<void> deleteAccount();

  List<DemoAccount> get demoAccounts;
  Future<void> signInAsDemo(String uid);
}

abstract interface class UserDirectoryRepository {
  /// Returns a profile with phone filled only when [AccessPolicy.canSeePhone].
  Future<PublicProfile?> profile(String uid);
  Future<List<PublicProfile>> profiles(Iterable<String> uids);

  /// Admin-only (club administrator / app admin): approve or reject coaches.
  Future<void> setCoachStatus(String uid, CoachStatus status);
}
