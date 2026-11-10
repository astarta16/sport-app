import 'medical_certificate.dart';

abstract interface class CertificatesRepository {
  Stream<List<MedicalCertificate>> watchForChild(String childId);
  Stream<List<MedicalCertificate>> watchForChildren(List<String> childIds);
  Future<MedicalCertificate> upload(CertificateUpload upload);
  Future<void> delete(String certId);

  /// Short-lived (5 min) access after a backend authorization check. Every
  /// call is written to the access audit log.
  Future<CertificateAccessGrant> requestAccess(String certId);
  Stream<List<CertificateAccessEntry>> watchAccessLog(String childId);
}
