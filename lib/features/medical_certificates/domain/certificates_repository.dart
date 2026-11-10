import 'medical_certificate.dart';

abstract interface class CertificatesRepository {
  Stream<List<MedicalCertificate>> watchForChild(String childId);
  Stream<List<MedicalCertificate>> watchForChildren(List<String> childIds);
  Future<MedicalCertificate> upload(CertificateUpload upload);
  Future<void> delete(String certId);

  /// Short-lived (5 min) access after a backend authorization check. Every
  /// call is written to the access audit log.
  /// [purpose] `download` is recorded separately from `view`. Admins are
  /// never granted access.
  Future<CertificateAccessGrant> requestAccess(String certId, {CertificateAccessPurpose purpose});
  Stream<List<CertificateAccessEntry>> watchAccessLog(String childId);
}
