import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/firebase/bytes.dart';
import '../../../core/firebase/firebase_utils.dart';
import '../domain/certificates_repository.dart';
import '../domain/medical_certificate.dart';

/// Medical certificates: private Storage path `medical/{childId}/{certId}`
/// (no client read access at all), metadata in Firestore, file access only
/// through the `getCertificateUrl` callable (5-minute signed URL + audit).
class FirebaseCertificatesRepository implements CertificatesRepository {
  FirebaseCertificatesRepository(this.auth, this.db, this.storage, this.functions);

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseStorage storage;
  final FirebaseFunctions functions;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('medicalCertificates');

  List<MedicalCertificate> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => MedicalCertificate.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.validUntil.compareTo(a.validUntil));

  @override
  Stream<List<MedicalCertificate>> watchForChild(String childId) =>
      _col.where('childId', isEqualTo: childId).snapshots().map(_map).mapFirebaseErrors();

  @override
  Stream<List<MedicalCertificate>> watchForChildren(List<String> childIds) {
    if (childIds.isEmpty) return Stream.value(const []);
    return _col.where('childId', whereIn: childIds.take(30).toList()).snapshots().map(_map).mapFirebaseErrors();
  }

  @override
  Future<MedicalCertificate> upload(CertificateUpload u) => guardFirebase(() async {
    final errors = CertificatePolicy.validateUpload(u);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final uid = requireUid(auth);
    final ref = _col.doc();
    final path = CertificatePolicy.storagePath(u.childId, ref.id);
    await storage.ref(path).putData(Uint8ListX.from(u.bytes), SettableMetadata(contentType: u.mimeType));
    final now = DateTime.now();
    final cert = MedicalCertificate(
      id: ref.id,
      childId: u.childId,
      uploadedBy: uid,
      storagePath: path,
      issuedAt: u.issuedAt,
      validUntil: u.validUntil,
      consentAt: now,
      fileName: u.fileName,
      mimeType: u.mimeType,
      sizeBytes: u.bytes.length,
    );
    // Only the fields the security rules allow; file metadata stays in Storage.
    await ref.set({
      'childId': cert.childId,
      'uploadedBy': uid,
      'storagePath': path,
      'issuedAt': cert.issuedAt,
      'validUntil': cert.validUntil,
      'consentAt': cert.consentAt,
      'status': cert.statusOn(now).name,
      if (u.sportId != null) 'sportId': u.sportId,
    });
    if (u.replacesCertId != null) {
      // Rules allow the parent to set only replacedBy/replacedAt on the old one.
      await _col.doc(u.replacesCertId).update({'replacedBy': ref.id, 'replacedAt': now});
    }
    return cert;
  });

  @override
  Future<void> delete(String certId) =>
      guardFirebase(() => functions.httpsCallable('deleteCertificate').call<void>({'certId': certId}));

  @override
  Future<CertificateAccessGrant> requestAccess(
    String certId, {
    CertificateAccessPurpose purpose = CertificateAccessPurpose.view,
  }) => guardFirebase(() async {
    final r = await functions.httpsCallable('getCertificateUrl').call<Map<String, dynamic>>({
      'certId': certId,
      'purpose': purpose.name,
    });
    final cert = await _col.doc(certId).get();
    return CertificateAccessGrant(
      url: Uri.parse(r.data['url'] as String),
      expiresAt: DateTime.tryParse('${r.data['expiresAt']}') ?? DateTime.now().add(CertificatePolicy.signedUrlTtl),
      mimeType: cert.data()?['mimeType'] as String? ?? '',
    );
  });

  /// The audit log is admin-only in production (rules); parents see it in
  /// demo mode. Exposing it to parents needs a callable — see assumptions.
  @override
  Stream<List<CertificateAccessEntry>> watchAccessLog(String childId) => Stream.value(const []);
}
