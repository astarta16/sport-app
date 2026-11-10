import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/firebase/firebase_utils.dart';
import '../domain/report.dart';

/// Reports go through the `createReport` callable (membership check + rate
/// limit 20/day server-side).
class FirebaseModerationRepository implements ModerationRepository {
  FirebaseModerationRepository(this.functions);

  final FirebaseFunctions functions;

  @override
  Future<void> report({
    required ReportTarget targetType,
    required String targetPath,
    required String groupId,
    required ReportReason reason,
    String? note,
  }) => callFunction(functions, 'createReport', {
    'targetType': targetType.name,
    'targetPath': targetPath,
    'groupId': groupId,
    'reason': reason.name,
    'note': note,
  });
}
