import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../demo/data/demo_backend.dart';
import '../domain/certificates_repository.dart';
import '../domain/medical_certificate.dart';

class DemoCertificatesRepository implements CertificatesRepository {
  DemoCertificatesRepository(this.db);

  final DemoBackend db;

  bool _canView(String childId) {
    final c = db.children[childId];
    return c != null && AccessPolicy.canViewCertificate(db.me, c, db.groupsOfChild(childId));
  }

  List<MedicalCertificate> _forChild(String childId) =>
      db.certificates.values.where((c) => c.childId == childId).toList()
        ..sort((a, b) => b.validUntil.compareTo(a.validUntil));

  @override
  Stream<List<MedicalCertificate>> watchForChild(String childId) => db.watch(() {
    if (!_canView(childId)) throw const PermissionDeniedException('certificate');
    return _forChild(childId);
  });

  @override
  Stream<List<MedicalCertificate>> watchForChildren(List<String> childIds) => db.watch(
    () => [
      for (final id in childIds)
        if (_canView(id)) ..._forChild(id),
    ],
  );

  @override
  Future<MedicalCertificate> upload(CertificateUpload u) async {
    final child = db.requireChild(u.childId);
    if (!AccessPolicy.canUploadCertificate(db.me, child)) throw const PermissionDeniedException();
    final errors = CertificatePolicy.validateUpload(u);
    if (errors.isNotEmpty) throw ValidationException(errors.first);
    final id = db.newId('cert');
    final now = db.clock();
    final cert = MedicalCertificate(
      id: id,
      childId: u.childId,
      uploadedBy: db.me.id,
      storagePath: CertificatePolicy.storagePath(u.childId, id),
      issuedAt: u.issuedAt,
      validUntil: u.validUntil,
      consentAt: now,
      fileName: u.fileName,
      mimeType: u.mimeType,
      sizeBytes: u.bytes.length,
      createdAt: now,
    );
    db.certificateFiles[cert.storagePath] = Uint8List.fromList(u.bytes);
    db.certificates[id] = cert;
    db.commit();
    return cert;
  }

  @override
  Future<void> delete(String certId) async {
    final cert = db.certificates[certId] ?? (throw const NotFoundException());
    final child = db.requireChild(cert.childId);
    if (!AccessPolicy.canDeleteCertificate(db.me, child)) throw const PermissionDeniedException();
    db.certificateFiles.remove(cert.storagePath);
    db.certificates.remove(certId);
    _audit(cert, 'delete');
    db.commit();
  }

  void _audit(MedicalCertificate cert, String action) => db.accessLog.add(
    CertificateAccessEntry(
      certId: cert.id,
      childId: cert.childId,
      userId: db.me.id,
      userName: db.me.fullName,
      at: db.clock(),
      action: action,
    ),
  );

  /// Mirrors the `getCertificateUrl` Cloud Function: membership check,
  /// audit entry, 5-minute grant.
  @override
  Future<CertificateAccessGrant> requestAccess(String certId) async {
    final cert = db.certificates[certId] ?? (throw const NotFoundException());
    if (!_canView(cert.childId)) {
      _audit(cert, 'denied');
      db.commit();
      throw const PermissionDeniedException('certificate');
    }
    _audit(cert, 'open');
    db.commit();
    final expires = db.clock().add(CertificatePolicy.signedUrlTtl);
    return CertificateAccessGrant(
      url: Uri.parse('demo-signed://${cert.storagePath}?expires=${expires.millisecondsSinceEpoch}'),
      expiresAt: expires,
      mimeType: cert.mimeType,
      demoBytes: db.certificateFiles[cert.storagePath],
    );
  }

  @override
  Stream<List<CertificateAccessEntry>> watchAccessLog(String childId) => db.watch(() {
    final c = db.requireChild(childId);
    if (!AccessPolicy.isParentOf(db.me, c)) throw const PermissionDeniedException();
    return db.accessLog.where((e) => e.childId == childId).toList().reversed.toList();
  });
}
