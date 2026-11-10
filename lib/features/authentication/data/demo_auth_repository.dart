import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../account/data/demo_account_repository.dart';
import '../../../core/utils/validators.dart';
import '../../demo/data/demo_backend.dart';
import '../../demo/data/demo_seed.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/access_policy.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this.db);

  final DemoBackend db;

  AuthSession? _read() {
    final s = db.session;
    if (s == null) return null;
    return AuthSession(uid: s.uid, phone: s.phone, user: db.users[s.uid]);
  }

  @override
  AuthSession? get currentSession => _read();

  @override
  Stream<AuthSession?> watchSession() => db.watch(_read);

  @override
  Future<String> sendCode(String phone) async {
    if (Validators.phone(phone) != null) throw const AuthException('invalid-phone');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'demo:${Validators.normalizePhone(phone)}';
  }

  @override
  Future<void> verifyCode(String verificationId, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code != DemoIds.otpCode) throw const AuthException('invalid-code');
    final phone = verificationId.replaceFirst('demo:', '');
    final existing = db.users.values.where((u) => u.phone == phone).firstOrNull;
    db.session = (uid: existing?.id ?? 'user-${phone.substring(phone.length - 6)}', phone: phone);
    db.commit();
  }

  @override
  Future<AppUser> completeRegistration(RegistrationData data) async {
    final s = db.session ?? (throw const AuthException('not-signed-in'));
    if (!AccessPolicy.canSelfRegisterAs(data.role)) throw const PermissionDeniedException('role');
    if (!data.dataConsent) throw const ValidationException('consentRequired');
    for (final v in [Validators.name(data.firstName), Validators.name(data.lastName)]) {
      if (v != null) throw ValidationException(v);
    }
    if (data.sportIds.isEmpty) throw const ValidationException('sportRequired');
    if (data.role == UserRole.coach && data.clubIds.isEmpty) throw const ValidationException('clubRequired');
    final now = db.clock();
    final user = AppUser(
      id: s.uid,
      role: data.role,
      firstName: data.firstName.trim(),
      lastName: data.lastName.trim(),
      phone: s.phone,
      createdAt: now,
      coachStatus: data.role == UserRole.coach ? CoachStatus.pending : null,
      clubIds: data.clubIds,
      sportIds: data.sportIds,
      dataConsentAt: now,
      smsConsentAt: data.smsConsent ? now : null,
    );
    db.users[user.id] = user;
    db.commit();
    return user;
  }

  @override
  Future<void> updateLastContext(UserContext context) async {
    final me = db.me;
    db.users[me.id] = me.copyWith(lastContext: context);
    db.commit();
  }

  @override
  Future<void> updateNotificationPrefs(NotificationPreferences prefs) async {
    final me = db.me;
    db.users[me.id] = me.copyWith(notificationPrefs: prefs);
    db.commit();
  }

  @override
  Future<void> updateProfile({required String firstName, required String lastName}) async {
    for (final v in [Validators.name(firstName), Validators.name(lastName)]) {
      if (v != null) throw ValidationException(v);
    }
    final me = db.me;
    db.users[me.id] = me.copyWith(firstName: firstName.trim(), lastName: lastName.trim());
    db.commit();
  }

  @override
  Future<void> updatePhoto(List<int> jpegBytes) async {
    db.requireOnline();
    if (jpegBytes.isEmpty) throw const ValidationException('fileEmpty');
    if (jpegBytes.length > 1024 * 1024) throw const ValidationException('avatarTooLarge');
    final me = db.me;
    final path = 'profiles/${me.id}/avatar.jpg';
    db.photos[path] = Uint8List.fromList(jpegBytes);
    db.users[me.id] = me.copyWith(photoPath: path);
    db.commit();
  }

  @override
  Future<void> removePhoto() async {
    db.requireOnline();
    final me = db.me;
    if (me.photoPath != null) db.photos.remove(me.photoPath);
    db.users[me.id] = me.copyWith(clearPhoto: true);
    db.commit();
  }

  @override
  Future<void> updatePrivacy(PrivacySettings privacy) async {
    db.requireOnline();
    final me = db.me;
    db.users[me.id] = me.copyWith(privacy: privacy);
    db.commit();
  }

  @override
  Future<void> updateSmsConsent(bool consent) async {
    db.requireOnline();
    final me = db.me;
    db.users[me.id] = AppUser.fromMap(me.id, {
      ...me.toMap(),
      'smsConsentAt': consent ? db.clock() : null,
      'adminRole': me.adminRole?.name,
      'adminClubIds': me.adminClubIds,
      'coachStatusReason': me.coachStatusReason,
    });
    db.commit();
  }

  @override
  Future<void> signOut() async {
    db.session = null;
    db.commit();
  }

  @override
  Future<void> deleteAccount() async {
    db.requireOnline();
    DemoAccountDeletion.run(db, db.me.id);
    db.session = null;
    db.commit();
  }

  @override
  List<DemoAccount> get demoAccounts => [
    for (final id in [DemoIds.parent, DemoIds.coach, DemoIds.pendingCoach])
      if (db.users[id] != null)
        DemoAccount(uid: id, label: db.users[id]!.fullName, role: db.users[id]!.role, phone: db.users[id]!.phone),
  ];

  /// Admin demo accounts are offered only by the admin web app.
  @override
  List<DemoAccount> get demoAdminAccounts => [
    for (final id in [DemoIds.platformAdmin, DemoIds.clubAdmin])
      if (db.users[id] != null)
        DemoAccount(uid: id, label: db.users[id]!.fullName, role: db.users[id]!.role, phone: db.users[id]!.phone),
  ];

  @override
  Future<void> signInAsDemo(String uid) async {
    final u = db.users[uid] ?? (throw NotFoundException(uid));
    db.session = (uid: u.id, phone: u.phone);
    db.commit();
  }
}

class DemoUserDirectoryRepository implements UserDirectoryRepository {
  DemoUserDirectoryRepository(this.db);

  final DemoBackend db;

  @override
  Future<PublicProfile?> profile(String uid) async {
    final target = db.users[uid];
    if (target == null) return null;
    final me = db.me;
    final phoneVisible = AccessPolicy.canSeePhone(me, target, db.groups.values);
    return PublicProfile(
      id: target.id,
      firstName: target.firstName,
      lastName: target.lastName,
      role: target.role,
      phone: phoneVisible ? target.phone : null,
    );
  }

  @override
  Future<List<PublicProfile>> profiles(Iterable<String> uids) async => [for (final id in uids) ?await profile(id)];

  /// Demo shortcut acting as the club administrator. Production calls the
  /// admin-only `setCoachStatus` Cloud Function.
  @override
  Future<void> setCoachStatus(String uid, CoachStatus status) async {
    final u = db.users[uid] ?? (throw NotFoundException(uid));
    db.users[uid] = u.copyWith(coachStatus: status);
    db.commit();
  }
}
