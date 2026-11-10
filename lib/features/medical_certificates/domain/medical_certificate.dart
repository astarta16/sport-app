import '../../../core/utils/dates.dart';

enum CertificateStatus { valid, expiring, expired, missing }

class MedicalCertificate {
  const MedicalCertificate({
    required this.id,
    required this.childId,
    required this.uploadedBy,
    required this.storagePath,
    required this.issuedAt,
    required this.validUntil,
    required this.consentAt,
    this.fileName = '',
    this.mimeType = '',
    this.sizeBytes = 0,
    this.createdAt,
    this.sportId,
    this.groupId,
    this.replacedBy,
    this.replacedAt,
  });

  final String id;
  final String childId;
  final String uploadedBy;

  /// Private path `medical/{childId}/{certId}` — never a public URL.
  final String storagePath;
  final DateTime issuedAt;
  final DateTime validUntil;
  final DateTime consentAt;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final DateTime? createdAt;

  /// Sport/group the certificate applies to (v1.3); null = general.
  final String? sportId;
  final String? groupId;

  /// Set when the parent uploaded a newer certificate replacing this one.
  final String? replacedBy;
  final DateTime? replacedAt;

  bool get isReplaced => replacedBy != null;

  MedicalCertificate markReplaced(String byId, DateTime at) => MedicalCertificate(
    id: id,
    childId: childId,
    uploadedBy: uploadedBy,
    storagePath: storagePath,
    issuedAt: issuedAt,
    validUntil: validUntil,
    consentAt: consentAt,
    fileName: fileName,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    createdAt: createdAt,
    sportId: sportId,
    groupId: groupId,
    replacedBy: byId,
    replacedAt: at,
  );

  CertificateStatus statusOn(DateTime now) => CertificatePolicy.statusFor(validUntil, now);

  Map<String, dynamic> toMap({DateTime? now}) => {
    'childId': childId,
    'uploadedBy': uploadedBy,
    'storagePath': storagePath,
    'issuedAt': issuedAt,
    'validUntil': validUntil,
    'consentAt': consentAt,
    'fileName': fileName,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt,
    'status': statusOn(now ?? DateTime.now()).name,
    'sportId': sportId,
    'groupId': groupId,
    'replacedBy': replacedBy,
    'replacedAt': replacedAt,
  };

  factory MedicalCertificate.fromMap(String id, Map<String, dynamic> m) => MedicalCertificate(
    id: id,
    childId: m['childId'] as String,
    uploadedBy: m['uploadedBy'] as String? ?? '',
    storagePath: m['storagePath'] as String? ?? '',
    issuedAt: readDate(m['issuedAt']),
    validUntil: readDate(m['validUntil']),
    consentAt: readDate(m['consentAt']),
    fileName: m['fileName'] as String? ?? '',
    mimeType: m['mimeType'] as String? ?? '',
    sizeBytes: (m['sizeBytes'] as num?)?.toInt() ?? 0,
    createdAt: readDateOrNull(m['createdAt']),
    sportId: m['sportId'] as String?,
    groupId: m['groupId'] as String?,
    replacedBy: m['replacedBy'] as String?,
    replacedAt: readDateOrNull(m['replacedAt']),
  );
}

/// Upload request; validated by [CertificatePolicy.validateUpload].
class CertificateUpload {
  const CertificateUpload({
    required this.childId,
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.issuedAt,
    required this.validUntil,
    required this.consentGiven,
    this.sportId,
    this.replacesCertId,
  });

  final String childId;
  final String? sportId;

  /// Replace flow: the older certificate is marked `replacedBy` the new one.
  final String? replacesCertId;
  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final DateTime issuedAt;
  final DateTime validUntil;
  final bool consentGiven;
}

class CertificateAccessEntry {
  const CertificateAccessEntry({
    required this.certId,
    required this.childId,
    required this.userId,
    required this.userName,
    required this.at,
    required this.action,
    this.viewerRole = '',
  });

  final String certId;
  final String viewerRole;
  final String childId;
  final String userId;
  final String userName;
  final DateTime at;

  /// `open` (view) | `download` | `denied` | `delete`
  final String action;
}

enum CertificateAccessPurpose { view, download }

/// Short-lived access grant to a private file.
class CertificateAccessGrant {
  const CertificateAccessGrant({required this.url, required this.expiresAt, required this.mimeType, this.demoBytes});

  final Uri url;
  final DateTime expiresAt;
  final String mimeType;

  /// Demo mode only: placeholder content held in memory.
  final List<int>? demoBytes;
}

/// Pure business rules for certificates (spec §7).
class CertificatePolicy {
  CertificatePolicy._();

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedMimeTypes = {'image/jpeg', 'image/png', 'application/pdf'};
  static const expiringWindowDays = 14;
  static const reminderOffsetsDays = [14, 3, 0];
  static const signedUrlTtl = Duration(minutes: 5);

  static CertificateStatus statusFor(DateTime validUntil, DateTime now) {
    final days = TbilisiTime.daysBetween(now, validUntil);
    if (days < 0) return CertificateStatus.expired;
    if (days <= expiringWindowDays) return CertificateStatus.expiring;
    return CertificateStatus.valid;
  }

  /// The certificate that currently applies for [sportId]: not replaced,
  /// matching the sport (or general), latest expiry wins. Mirrors
  /// `functions/src/lib/certificates.ts`.
  static MedicalCertificate? current(Iterable<MedicalCertificate> certs, {String? sportId}) {
    final candidates = certs.where(
      (c) => !c.isReplaced && (c.sportId == null || sportId == null || c.sportId == sportId),
    );
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) {
      if (a.validUntil != b.validUntil) return a.validUntil.isAfter(b.validUntil) ? a : b;
      // Same expiry: a sport-specific certificate beats a general one.
      return (b.sportId != null && a.sportId == null) ? b : a;
    });
  }

  /// Overall status of a child (for a sport when given).
  static CertificateStatus childStatus(Iterable<MedicalCertificate> certs, DateTime now, {String? sportId}) {
    final c = current(certs, sportId: sportId);
    return c == null ? CertificateStatus.missing : c.statusOn(now);
  }

  static String? mimeFromFileName(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => null,
    };
  }

  static List<String> validateUpload(CertificateUpload u) {
    final errors = <String>[];
    if (!u.consentGiven) errors.add('consentRequired');
    if (!allowedMimeTypes.contains(u.mimeType)) errors.add('fileType');
    if (u.bytes.isEmpty) errors.add('fileEmpty');
    if (u.bytes.length > maxBytes) errors.add('fileTooLarge');
    if (!u.validUntil.isAfter(u.issuedAt)) errors.add('datesOrder');
    if (u.issuedAt.isAfter(DateTime.now().add(const Duration(days: 1)))) errors.add('issuedInFuture');
    return errors;
  }

  /// Which reminder (14 / 3 / 0 days before expiry) is due today, if any.
  static int? reminderDue(DateTime validUntil, DateTime now) {
    final days = TbilisiTime.daysBetween(now, validUntil);
    return reminderOffsetsDays.contains(days) ? days : null;
  }

  static String storagePath(String childId, String certId) => 'medical/$childId/$certId';
}
