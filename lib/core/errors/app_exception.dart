/// Typed failures raised by repositories. The UI maps [code] to a localized
/// message; repositories must never surface raw backend errors to users.
sealed class AppException implements Exception {
  const AppException(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => '$runtimeType($code${detail == null ? '' : ': $detail'})';
}

/// The current user is not allowed to perform the action. Raised both by the
/// demo backend and when Firestore/Functions return `permission-denied`.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([String? detail]) : super('permission-denied', detail);
}

class ValidationException extends AppException {
  const ValidationException(super.code, [super.detail]);
}

class NotFoundException extends AppException {
  const NotFoundException([String? detail]) : super('not-found', detail);
}

class AuthException extends AppException {
  const AuthException(super.code, [super.detail]);
}

class BackendUnavailableException extends AppException {
  const BackendUnavailableException([String? detail]) : super('unavailable', detail);
}
