import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../../../core/utils/validators.dart';
import '../domain/child.dart';
import '../domain/children_repository.dart';

class FirebaseChildrenRepository implements ChildrenRepository {
  FirebaseChildrenRepository(this.auth, this.db, {this.storage, DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final DateTime Function() clock;
  final FirebaseStorage? storage;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('children');

  @override
  Stream<List<Child>> watchMyChildren() => _col
      .where('parentIds', arrayContains: requireUid(auth))
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => Child.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.birthDate.compareTo(b.birthDate)),
      )
      .mapFirebaseErrors();

  @override
  Stream<Child?> watchChild(String childId) => _col
      .doc(childId)
      .snapshots()
      .map((d) => d.data() == null ? null : Child.fromMap(d.id, d.data()!))
      .mapFirebaseErrors();

  /// Provable query: children whose server-managed `coachIds` contain me.
  @override
  Stream<List<Child>> watchGroupMembers(String groupId) => _col
      .where('coachIds', arrayContains: requireUid(auth))
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => Child.fromMap(d.id, d.data())).where((c) => c.groupIds.contains(groupId)).toList()
              ..sort((a, b) => a.firstName.compareTo(b.firstName)),
      )
      .mapFirebaseErrors();

  @override
  Future<Child> addChild(ChildDraft d) => guardFirebase(() async {
    for (final v in [
      Validators.name(d.firstName),
      Validators.name(d.lastName),
      Validators.birthDate(d.birthDate, clock()),
    ]) {
      if (v != null) throw ValidationException(v);
    }
    final uid = requireUid(auth);
    final ref = _col.doc();
    final child = Child(
      id: ref.id,
      firstName: d.firstName.trim(),
      lastName: d.lastName.trim(),
      birthDate: d.birthDate,
      parentIds: [uid],
      sportIds: d.sportIds,
      photoConsent: d.photoConsent,
    );
    await ref.set({
      'firstName': child.firstName,
      'lastName': child.lastName,
      'birthDate': child.birthDate,
      'parentIds': child.parentIds,
      'sportIds': child.sportIds,
      'photoConsent': child.photoConsent,
    });
    return child;
  });

  /// Only parent-editable fields; memberships are server-managed.
  @override
  Future<void> updateChild(Child c) => guardFirebase(
    () => _col.doc(c.id).update({
      'firstName': c.firstName,
      'lastName': c.lastName,
      'birthDate': c.birthDate,
      'sportIds': c.sportIds,
      'photoConsent': c.photoConsent,
    }),
  );

  @override
  Future<void> removeChild(String childId) => guardFirebase(() => _col.doc(childId).delete());

  @override
  Future<void> setChildPhoto(String childId, List<int>? jpegBytes) => guardFirebase(() async {
    final st = storage ?? (throw const BackendUnavailableException('storage'));
    final path = 'childPhotos/$childId/avatar.jpg';
    if (jpegBytes == null) {
      await st.ref(path).delete().catchError((_) {});
      await _col.doc(childId).update({'photoPath': null});
      return;
    }
    if (jpegBytes.length > 1024 * 1024) throw const ValidationException('avatarTooLarge');
    await st.ref(path).putData(Uint8ListX.from(jpegBytes), SettableMetadata(contentType: 'image/jpeg'));
    await _col.doc(childId).update({'photoPath': path});
  });

  @override
  Future<void> setMediaConsent(String childId, bool consent) => guardFirebase(
    () => _col.doc(childId).update({'photoConsent': consent, 'mediaConsent': consent, 'mediaConsentAt': clock()}),
  );
}
