import '../../../core/utils/dates.dart';

enum AccountRequestType {
  delete,
  export;

  static AccountRequestType fromName(String? n) => n == 'export' ? export : delete;
}

enum AccountRequestStatus {
  pending,
  processing,
  done,
  rejected;

  static AccountRequestStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => pending);
}

/// Data-subject request handled server-side (v1.2 account lifecycle).
class AccountRequest {
  const AccountRequest({
    required this.id,
    required this.uid,
    required this.type,
    required this.createdAt,
    this.status = AccountRequestStatus.pending,
    this.completedAt,
    this.resultPath,
  });

  final String id;
  final String uid;
  final AccountRequestType type;
  final AccountRequestStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Export file path (served through a short-lived signed URL only).
  final String? resultPath;

  factory AccountRequest.fromMap(String id, Map<String, dynamic> m) => AccountRequest(
    id: id,
    uid: m['uid'] as String? ?? '',
    type: AccountRequestType.fromName(m['type'] as String?),
    status: AccountRequestStatus.fromName(m['status'] as String?),
    createdAt: readDate(m['createdAt']),
    completedAt: readDateOrNull(m['completedAt']),
    resultPath: m['result'] as String?,
  );
}

/// What deleting the account will do to each child (shown before confirming).
class DeletionImpact {
  const DeletionImpact({required this.deletedChildren, required this.unlinkedChildren});

  /// Children whose only guardian is the user: deleted with certificates,
  /// attendance, RSVPs, feedback and photos.
  final List<String> deletedChildren;

  /// Children with another guardian: the user is only removed from them.
  final List<String> unlinkedChildren;
}

abstract interface class AccountRepository {
  Stream<List<AccountRequest>> watchMyRequests();
  Future<DeletionImpact> deletionImpact();
  Future<AccountRequest> requestDeletion();
  Future<AccountRequest> requestExport();
}
