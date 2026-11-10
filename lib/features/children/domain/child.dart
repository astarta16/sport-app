import '../../../core/utils/dates.dart';

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
  }) =>
      Child(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        birthDate: birthDate ?? this.birthDate,
        parentIds: parentIds ?? this.parentIds,
        userId: userId,
        sportIds: sportIds ?? this.sportIds,
        groupIds: groupIds ?? this.groupIds,
        photoConsent: photoConsent ?? this.photoConsent,
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
        photoConsent: m['photoConsent'] as bool? ?? false,
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
