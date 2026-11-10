import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../errors/app_exception.dart';

/// Region of all callable Cloud Functions (see functions/src/config.ts).
const functionsRegion = 'europe-west1';

/// Maps Firebase SDK errors to typed [AppException]s.
Object mapFirebaseError(Object e) {
  final code = switch (e) {
    // FirebaseFunctionsException is a FirebaseException subtype.
    FirebaseException(:final code) => code,
    _ => null,
  };
  return switch (code) {
    'permission-denied' || 'unauthenticated' => PermissionDeniedException(code),
    'not-found' => NotFoundException(code),
    'unavailable' || 'deadline-exceeded' || 'network-request-failed' => BackendUnavailableException(code),
    'invalid-verification-code' ||
    'invalid-verification-id' ||
    'session-expired' => const AuthException('invalid-code'),
    'invalid-phone-number' => const AuthException('invalid-phone'),
    'invalid-argument' || 'failed-precondition' => ValidationException(code!),
    _ => e,
  };
}

Future<T> guardFirebase<T>(Future<T> Function() f) async {
  try {
    return await f();
  } catch (e) {
    throw mapFirebaseError(e);
  }
}

extension FirebaseStreamX<T> on Stream<T> {
  Stream<T> mapFirebaseErrors() =>
      transform(StreamTransformer.fromHandlers(handleError: (e, st, sink) => sink.addError(mapFirebaseError(e), st)));
}

/// Converts domain maps for Firestore: `{latitude, longitude}` → GeoPoint.
Map<String, dynamic> toFirestore(Map<String, dynamic> m) => m.map((k, v) {
  if (v is Map && v.length == 2 && v.containsKey('latitude') && v.containsKey('longitude')) {
    return MapEntry(k, GeoPoint((v['latitude'] as num).toDouble(), (v['longitude'] as num).toDouble()));
  }
  return MapEntry(k, v);
});

String requireUid(FirebaseAuth auth) => auth.currentUser?.uid ?? (throw const AuthException('not-signed-in'));

/// Reads the signed-in user's role-relevant profile fields.
Future<({String uid, String role, bool approvedCoach})> currentRole(FirebaseAuth auth, FirebaseFirestore db) async {
  final uid = requireUid(auth);
  final d = (await db.collection('users').doc(uid).get()).data() ?? const {};
  final role = d['role'] as String? ?? 'parent';
  return (uid: uid, role: role, approvedCoach: role == 'coach' && d['coachStatus'] == 'approved');
}

/// Calls a callable Cloud Function and returns its data as a map.
Future<Map<String, dynamic>> callFunction(dynamic functions, String name, [Map<String, dynamic> data = const {}]) =>
    guardFirebase(() async {
      // ignore: avoid_dynamic_calls
      final result = await functions.httpsCallable(name).call<Object?>(data);
      // ignore: avoid_dynamic_calls
      final d = result.data;
      return d is Map ? d.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};
    });
