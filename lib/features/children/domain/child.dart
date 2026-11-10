import '../../../core/utils/dates.dart';

enum ChildStatus {
  active,

  /// Created by a coach; waits for a parent to accept the invite (v1.1 §2).
  pendingParent;

  static ChildStatus fromName(String? n) => n == 'pendingParent' ? pendingParent : active;
}

class Child {
  const Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.parentIds,
    this.userId,
    this.sportIds = const [],
    this.groupIds = const [],
    this.photoConsent = false,
    this.status = ChildStatus.active,
    this.createdByCoachId,
    this.photoPath,
    this.mediaConsentAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final List<String> parentIds;

  /// Own account (14–17 only, parent-approved). Disabled by policy for now.
  final String? userId;
  final List<String> sportIds;
  final List<String> groupIds;

  /// Parent consent for the child to appear in training photos (spec §8).
  final bool photoConsent;
  final ChildStatus status;
  final String? createdByCoachId;

  /// Optional avatar uploaded by a parent (`childPhotos/{id}/avatar.jpg`).
  final String? photoPath;
  final DateTime? mediaConsentAt;

  bool get isPending => status == ChildStatus.pendingParent;

  /// v1.1 name for [photoConsent]: consent to appear in photos and videos.
  bool get mediaConsent => photoConsent;

  String get fullName => '$firstName $lastName';
  int ageOn(DateTime now) => ageInYears(birthDate, now);

  Child copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    List<String>? parentIds,
    List<String>? sportIds,
    List<String>? groupIds,
    bool? photoConsent,
    ChildStatus? status,
    String? photoPath,
    DateTime? mediaConsentAt,
  }) => Child(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    birthDate: birthDate ?? this.birthDate,
    parentIds: parentIds ?? this.parentIds,
    userId: userId,
    sportIds: sportIds ?? this.sportIds,
    groupIds: groupIds ?? this.groupIds,
    photoConsent: photoConsent ?? this.photoConsent,
    status: status ?? this.status,
    createdByCoachId: createdByCoachId,
    photoPath: photoPath ?? this.photoPath,
    mediaConsentAt: mediaConsentAt ?? this.mediaConsentAt,
  );

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': birthDate,
    'parentIds': parentIds,
    'userId': userId,
    'sportIds': sportIds,
    'groupIds': groupIds,
    'photoConsent': photoConsent,
    'mediaConsent': photoConsent,
    'mediaConsentAt': mediaConsentAt,
    'status': status.name,
    'createdByCoachId': createdByCoachId,
    'photoPath': photoPath,
  };

  factory Child.fromMap(String id, Map<String, dynamic> m) => Child(
    id: id,
    firstName: m['firstName'] as String? ?? '',
    lastName: m['lastName'] as String? ?? '',
    birthDate: readDate(m['birthDate']),
    parentIds: readStringList(m['parentIds']),
    userId: m['userId'] as String?,
    sportIds: readStringList(m['sportIds']),
    groupIds: readStringList(m['groupIds']),
    photoConsent: m['mediaConsent'] as bool? ?? m['photoConsent'] as bool? ?? false,
    status: ChildStatus.fromName(m['status'] as String?),
    createdByCoachId: m['createdByCoachId'] as String?,
    photoPath: m['photoPath'] as String?,
    mediaConsentAt: readDateOrNull(m['mediaConsentAt']),
  );
}

class ChildDraft {
  const ChildDraft({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.sportIds,
    this.photoConsent = false,
  });

  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final List<String> sportIds;
  final bool photoConsent;
}
