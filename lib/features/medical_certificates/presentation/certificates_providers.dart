import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../authentication/presentation/session_providers.dart';
import '../domain/medical_certificate.dart';

final childCertificatesProvider = StreamProvider.autoDispose.family<List<MedicalCertificate>, String>((ref, childId) {
  ref.watch(currentUidProvider);
  return ref.watch(certificatesRepositoryProvider).watchForChild(childId);
});

/// Certificates for a set of children (key: sorted, comma-joined ids).
final certificatesForChildrenProvider = StreamProvider.autoDispose.family<List<MedicalCertificate>, String>((ref, key) {
  ref.watch(currentUidProvider);
  final ids = key.isEmpty ? <String>[] : key.split(',');
  return ref.watch(certificatesRepositoryProvider).watchForChildren(ids);
});

String childrenKey(Iterable<String> ids) => (ids.toList()..sort()).join(',');

final certificateAccessLogProvider = StreamProvider.autoDispose.family<List<CertificateAccessEntry>, String>((
  ref,
  childId,
) {
  ref.watch(currentUidProvider);
  return ref.watch(certificatesRepositoryProvider).watchAccessLog(childId);
});
