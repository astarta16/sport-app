import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../../../core/utils/validators.dart';
import '../../notifications/domain/notification_models.dart';
import '../domain/access_policy.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Firebase Phone Auth + `users/{uid}` profile.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth, this.db, this.functions, {this.storage});

  final FirebaseStorage? storage;

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseFunctions functions;
  AuthSession? _current;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => db.collection('users').doc(uid);

  @override
  AuthSession? get currentSession => _current;

  @override
  Stream<AuthSession?> watchSession() => auth.authStateChanges().asyncExpand((user) {
    if (user == null) {
      _current = null;
      return Stream.value(null);
    }
    return _doc(user.uid).snapshots().map((snap) {
      final data = snap.data();
      return _current = AuthSession(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        user: data == null ? null : AppUser.fromMap(user.uid, data),
      );
    });
  }).mapFirebaseErrors();

  @override
  Future<String> sendCode(String phone) {
    if (Validators.phone(phone) != null) throw const AuthException('invalid-phone');
    final completer = Completer<String>();
    auth.verifyPhoneNumber(
      phoneNumber: Validators.normalizePhone(phone),
      verificationCompleted: (credential) async {
        // Android instant verification.
        await auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete('auto');
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(mapFirebaseError(e));
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future<void> verifyCode(String verificationId, String code) => guardFirebase(() async {
    if (verificationId == 'auto' && auth.currentUser != null) return;
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);
    await auth.signInWithCredential(credential);
  });

  @override
  Future<AppUser> completeRegistration(RegistrationData data) => guardFirebase(() async {
    final user = auth.currentUser ?? (throw const AuthException('not-signed-in'));
    if (!AccessPolicy.canSelfRegisterAs(data.role)) throw const PermissionDeniedException('role');
    if (!data.dataConsent) throw const ValidationException('consentRequired');
    final now = DateTime.now();
    final profile = AppUser(
      id: user.uid,
      role: data.role,
      firstName: data.firstName.trim(),
      lastName: data.lastName.trim(),
      phone: user.phoneNumber ?? '',
      createdAt: now,
      coachStatus: data.role == UserRole.coach ? CoachStatus.pending : null,
      clubIds: data.clubIds,
      sportIds: data.sportIds,
      dataConsentAt: now,
      smsConsentAt: data.smsConsent ? now : null,
    );
    await _doc(user.uid).set(profile.toMap());
    return profile;
  });

  @override
  Future<void> updateLastContext(UserContext context) =>
      guardFirebase(() => _doc(requireUid(auth)).update({'lastContext': context.toMap()}));

  @override
  Future<void> updateNotificationPrefs(NotificationPreferences prefs) =>
      guardFirebase(() => _doc(requireUid(auth)).update({'notificationPrefs': prefs.toMap()}));

  @override
  Future<void> updateProfile({required String firstName, required String lastName}) =>
      guardFirebase(() => _doc(requireUid(auth)).update({'firstName': firstName.trim(), 'lastName': lastName.trim()}));

  @override
  Future<void> updatePhoto(List<int> jpegBytes) => guardFirebase(() async {
    if (jpegBytes.length > 1024 * 1024) throw const ValidationException('avatarTooLarge');
    final uid = requireUid(auth);
    final st = storage ?? (throw const BackendUnavailableException('storage'));
    final path = 'profiles/$uid/avatar.jpg';
    await st.ref(path).putData(Uint8ListX.from(jpegBytes), SettableMetadata(contentType: 'image/jpeg'));
    await _doc(uid).update({'photoPath': path});
  });

  @override
  Future<void> removePhoto() => guardFirebase(() async {
    final uid = requireUid(auth);
    await storage?.ref('profiles/$uid/avatar.jpg').delete().catchError((_) {});
    await _doc(uid).update({'photoPath': null});
  });

  @override
  Future<void> updatePrivacy(PrivacySettings privacy) =>
      guardFirebase(() => _doc(requireUid(auth)).update({'privacy': privacy.toMap()}));

  @override
  Future<void> updateSmsConsent(bool consent) => guardFirebase(
    () => _doc(requireUid(auth)).update({'smsConsentAt': consent ? FieldValue.serverTimestamp() : null}),
  );

  @override
  Future<void> signOut() => auth.signOut();

  /// Server-side: deletes solely-owned children with all certificates.
  @override
  Future<void> deleteAccount() => guardFirebase(() async {
    await functions.httpsCallable('deleteAccount').call<void>();
    await auth.signOut();
  });

  @override
  List<DemoAccount> get demoAccounts => const [];

  @override
  List<DemoAccount> get demoAdminAccounts => const [];

  @override
  Future<void> signInAsDemo(String uid) => throw UnsupportedError('Demo accounts are not available in Firebase mode');
}

class FirebaseUserDirectoryRepository implements UserDirectoryRepository {
  FirebaseUserDirectoryRepository(this.auth, this.db, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseFunctions functions;

  /// Names come from `publicProfiles`; a parent's phone is only returned by
  /// the `getParentPhone` callable after a shared-group check.
  @override
  Future<PublicProfile?> profile(String uid) => guardFirebase(() async {
    final snap = await db.collection('publicProfiles').doc(uid).get();
    final d = snap.data();
    if (d == null) return null;
    final role = UserRole.fromName(d['role'] as String?);
    String? phone;
    if (role == UserRole.parent && uid != auth.currentUser?.uid) {
      try {
        final r = await functions.httpsCallable('getParentPhone').call<Map<String, dynamic>>({'parentUid': uid});
        phone = r.data['phone'] as String?;
      } on FirebaseFunctionsException {
        phone = null; // Not permitted — expected for parents/other groups.
      }
    }
    return PublicProfile(
      id: uid,
      firstName: d['firstName'] as String? ?? '',
      lastName: d['lastName'] as String? ?? '',
      role: role,
      phone: phone,
    );
  });

  @override
  Future<List<PublicProfile>> profiles(Iterable<String> uids) async => [for (final id in uids) ?await profile(id)];

  @override
  Future<void> setCoachStatus(String uid, CoachStatus status) =>
      guardFirebase(() => functions.httpsCallable('setCoachStatus').call<void>({'uid': uid, 'status': status.name}));
}
