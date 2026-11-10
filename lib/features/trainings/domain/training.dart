import '../../../core/utils/dates.dart';

/// Fixed list so filtering and statistics stay simple (spec §5).
enum TrainingFocus {
  technique,
  speed,
  physical,
  ball;

  static TrainingFocus? fromName(String n) {
    for (final f in TrainingFocus.values) {
      if (f.name == n) return f;
    }
    return null;
  }
}

enum TrainingStatus {
  scheduled,
  cancelled,
  moved,
  done;

  static TrainingStatus fromName(String? n) =>
      TrainingStatus.values.firstWhere((s) => s.name == n, orElse: () => TrainingStatus.scheduled);

  bool get isActive => this == scheduled || this == moved;
}

class Training {
  const Training({
    required this.id,
    required this.groupId,
    required this.venueId,
    required this.startAt,
    required this.durationMin,
    required this.focus,
    required this.description,
    required this.createdBy,
    this.photoUrls = const [],
    this.status = TrainingStatus.scheduled,
    this.updatedAt,
    this.previousStartAt,
  });

  final String id;
  final String groupId;
  final String venueId;
  final DateTime startAt;
  final int durationMin;
  final List<TrainingFocus> focus;
  final String description;

  /// Storage paths / demo keys — never public URLs.
  final List<String> photoUrls;
  final TrainingStatus status;
  final String createdBy;
  final DateTime? updatedAt;
  final DateTime? previousStartAt;

  DateTime get endAt => startAt.add(Duration(minutes: durationMin));

  Training copyWith({
    String? venueId,
    DateTime? startAt,
    int? durationMin,
    List<TrainingFocus>? focus,
    String? description,
    List<String>? photoUrls,
    TrainingStatus? status,
    DateTime? updatedAt,
    DateTime? previousStartAt,
  }) => Training(
    id: id,
    groupId: groupId,
    venueId: venueId ?? this.venueId,
    startAt: startAt ?? this.startAt,
    durationMin: durationMin ?? this.durationMin,
    focus: focus ?? this.focus,
    description: description ?? this.description,
    createdBy: createdBy,
    photoUrls: photoUrls ?? this.photoUrls,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
    previousStartAt: previousStartAt ?? this.previousStartAt,
  );

  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'venueId': venueId,
    'startAt': startAt,
    'durationMin': durationMin,
    'focus': focus.map((f) => f.name).toList(),
    'description': description,
    'photoUrls': photoUrls,
    'status': status.name,
    'createdBy': createdBy,
    'updatedAt': updatedAt,
    'previousStartAt': previousStartAt,
  };

  factory Training.fromMap(String id, Map<String, dynamic> m) => Training(
    id: id,
    groupId: m['groupId'] as String,
    venueId: m['venueId'] as String? ?? '',
    startAt: readDate(m['startAt']),
    durationMin: (m['durationMin'] as num?)?.toInt() ?? 60,
    focus: readStringList(m['focus']).map(TrainingFocus.fromName).whereType<TrainingFocus>().toList(),
    description: m['description'] as String? ?? '',
    photoUrls: readStringList(m['photoUrls']),
    status: TrainingStatus.fromName(m['status'] as String?),
    createdBy: m['createdBy'] as String? ?? '',
    updatedAt: readDateOrNull(m['updatedAt']),
    previousStartAt: readDateOrNull(m['previousStartAt']),
  );
}

/// Form input for create/edit (spec §6.2).
class TrainingDraft {
  const TrainingDraft({
    required this.groupId,
    required this.venueId,
    required this.startAt,
    required this.durationMin,
    required this.focus,
    required this.description,
    this.newPhotos = const [],
    this.photoConsentConfirmed = false,
  });

  final String groupId;
  final String venueId;
  final DateTime startAt;
  final int durationMin;
  final List<TrainingFocus> focus;
  final String description;
  final List<PhotoUpload> newPhotos;
  final bool photoConsentConfirmed;
}

class PhotoUpload {
  const PhotoUpload({required this.bytes, required this.fileName, required this.mimeType});

  final List<int> bytes;
  final String fileName;
  final String mimeType;
}

/// Pure validation for the training form; returns error codes.
class TrainingValidator {
  TrainingValidator._();

  static const minDuration = 15;
  static const maxDuration = 300;

  static List<String> validate(TrainingDraft d, {required DateTime now, bool isEdit = false}) {
    final errors = <String>[];
    if (d.venueId.isEmpty) errors.add('venueRequired');
    if (d.durationMin < minDuration || d.durationMin > maxDuration) errors.add('durationRange');
    if (d.focus.isEmpty) errors.add('focusRequired');
    if (d.description.trim().length > 1000) errors.add('descriptionTooLong');
    if (!isEdit && d.startAt.isBefore(now.subtract(const Duration(minutes: 5)))) errors.add('startInPast');
    if (d.newPhotos.isNotEmpty && !d.photoConsentConfirmed) errors.add('photoConsentRequired');
    return errors;
  }
}
