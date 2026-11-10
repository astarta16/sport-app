import '../../../core/utils/dates.dart';
import '../../trainings/domain/series.dart';
import '../../trainings/domain/training.dart';

enum PlanType {
  seasonal,
  monthly,
  weekly,
  exercise,
  homework;

  static PlanType fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => weekly);
}

enum PlanStatus {
  draft,
  published,
  archived;

  static PlanStatus fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => draft);
}

enum MediaKind {
  photo,
  video,
  pdf,
  link;

  static MediaKind fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => link);
}

/// Exercise material: a private storage file (photo/video/pdf) or an https link.
class ExerciseMedia {
  const ExerciseMedia({required this.id, required this.kind, this.path, this.url, this.name});

  final String id;
  final MediaKind kind;

  /// Private `plans/{planId}/{file}` (demo: `demo-mem://` / `demo://`).
  final String? path;

  /// External https link (never executed in-app; opened in the browser).
  final String? url;
  final String? name;

  Map<String, dynamic> toMap() => {'id': id, 'kind': kind.name, 'path': path, 'url': url, 'name': name};

  factory ExerciseMedia.fromMap(Map m) => ExerciseMedia(
    id: m['id'] as String? ?? '',
    kind: MediaKind.fromName(m['kind'] as String?),
    path: m['path'] as String?,
    url: m['url'] as String?,
    name: m['name'] as String?,
  );
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    this.description = '',
    this.instructions = '',
    this.durationMin,
    this.reps,
    this.sets,
    this.restSec,
    this.media = const [],
  });

  final String id;
  final String name;
  final String description;
  final String instructions;
  final int? durationMin;
  final int? reps;
  final int? sets;
  final int? restSec;
  final List<ExerciseMedia> media;

  Exercise copyWith({
    String? name,
    String? description,
    String? instructions,
    int? durationMin,
    int? reps,
    int? sets,
    int? restSec,
    List<ExerciseMedia>? media,
    bool clearNumbers = false,
  }) => Exercise(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    instructions: instructions ?? this.instructions,
    durationMin: clearNumbers ? durationMin : (durationMin ?? this.durationMin),
    reps: clearNumbers ? reps : (reps ?? this.reps),
    sets: clearNumbers ? sets : (sets ?? this.sets),
    restSec: clearNumbers ? restSec : (restSec ?? this.restSec),
    media: media ?? this.media,
  );

  Map<String, dynamic> toMap(int order) => {
    'id': id,
    'order': order,
    'name': name,
    'description': description,
    'instructions': instructions,
    'durationMin': durationMin,
    'reps': reps,
    'sets': sets,
    'restSec': restSec,
    'media': media.map((m) => m.toMap()).toList(),
  };

  factory Exercise.fromMap(Map m) => Exercise(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    description: m['description'] as String? ?? '',
    instructions: m['instructions'] as String? ?? '',
    durationMin: (m['durationMin'] as num?)?.toInt(),
    reps: (m['reps'] as num?)?.toInt(),
    sets: (m['sets'] as num?)?.toInt(),
    restSec: (m['restSec'] as num?)?.toInt(),
    media: [for (final x in (m['media'] as List? ?? const [])) ExerciseMedia.fromMap(x as Map)],
  );
}

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.title,
    required this.type,
    required this.groupIds,
    required this.startDate,
    required this.createdBy,
    required this.createdAt,
    this.description = '',
    this.clubId = '',
    this.endDate,
    this.status = PlanStatus.draft,
    this.exercises = const [],
    this.updatedAt,
    this.publishedAt,
    this.coachName = '',
  });

  final String id;
  final String title;
  final String description;
  final PlanType type;
  final List<String> groupIds;
  final String clubId;
  final LocalDate startDate;
  final LocalDate? endDate;
  final PlanStatus status;
  final List<Exercise> exercises;
  final String createdBy;
  final String coachName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  bool get isPublished => status == PlanStatus.published;

  /// Active on [today] (published and within its period).
  bool activeOn(LocalDate today) => isPublished && startDate <= today && (endDate == null || today <= endDate!);

  TrainingPlan copyWith({PlanStatus? status, DateTime? updatedAt, DateTime? publishedAt}) => TrainingPlan(
    id: id,
    title: title,
    description: description,
    type: type,
    groupIds: groupIds,
    clubId: clubId,
    startDate: startDate,
    endDate: endDate,
    status: status ?? this.status,
    exercises: exercises,
    createdBy: createdBy,
    coachName: coachName,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    publishedAt: publishedAt ?? this.publishedAt,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'type': type.name,
    'groupIds': groupIds,
    'clubId': clubId,
    'startDate': startDate.toString(),
    'endDate': endDate?.toString(),
    'status': status.name,
    'exercises': [for (var i = 0; i < exercises.length; i++) exercises[i].toMap(i)],
    'createdBy': createdBy,
    'coachName': coachName,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'publishedAt': publishedAt,
  };

  factory TrainingPlan.fromMap(String id, Map<String, dynamic> m) {
    final ex = [for (final x in (m['exercises'] as List? ?? const [])) x as Map]
      ..sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
    return TrainingPlan(
      id: id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      type: PlanType.fromName(m['type'] as String?),
      groupIds: readStringList(m['groupIds']),
      clubId: m['clubId'] as String? ?? '',
      startDate: LocalDate.parse(m['startDate'] as String),
      endDate: m['endDate'] == null ? null : LocalDate.parse(m['endDate'] as String),
      status: PlanStatus.fromName(m['status'] as String?),
      exercises: ex.map(Exercise.fromMap).toList(),
      createdBy: m['createdBy'] as String? ?? '',
      coachName: m['coachName'] as String? ?? '',
      createdAt: readDateOrNull(m['createdAt']) ?? DateTime.now(),
      updatedAt: readDateOrNull(m['updatedAt']),
      publishedAt: readDateOrNull(m['publishedAt']),
    );
  }
}

/// Coach input; new media files are uploaded by the repository.
class PlanDraft {
  const PlanDraft({
    required this.title,
    required this.type,
    required this.groupIds,
    required this.startDate,
    this.description = '',
    this.endDate,
    this.exercises = const [],
    this.newFiles = const {},
  });

  final String title;
  final String description;
  final PlanType type;
  final List<String> groupIds;
  final LocalDate startDate;
  final LocalDate? endDate;
  final List<Exercise> exercises;

  /// Media id → file to upload (photo/video/pdf picked in the editor).
  final Map<String, PhotoUpload> newFiles;

  static const maxExercises = 50;
  static const maxMedia = 10;
  static final _https = RegExp(r'^https://[^\s<>"]+$', caseSensitive: false);

  /// Only plain https links; javascript:, data:, http: … are rejected.
  static bool isSafeLink(String url) {
    final u = Uri.tryParse(url.trim());
    return _https.hasMatch(url.trim()) && u != null && u.scheme == 'https' && u.host.isNotEmpty;
  }

  static List<String> validate(PlanDraft d, {bool publishing = false}) => [
    if (d.title.trim().isEmpty) 'planTitle',
    if (d.title.trim().length > 120) 'validationTooLong',
    if (d.description.length > 4000) 'validationTooLong',
    if (d.groupIds.isEmpty || d.groupIds.length > 10) 'planGroups',
    if (d.endDate != null && d.endDate! < d.startDate) 'planDates',
    if (publishing && d.exercises.isEmpty) 'planExercises',
    if (d.exercises.length > maxExercises) 'tooManyExercises',
    for (final e in d.exercises) ...[
      if (e.name.trim().isEmpty) 'exerciseName',
      if (e.media.length > maxMedia) 'tooManyMedia',
      for (final m in e.media)
        if (m.kind == MediaKind.link && !isSafeLink(m.url ?? '')) 'link',
    ],
  ];
}

enum ProgressStatus {
  notStarted,
  inProgress,
  completed;

  static ProgressStatus fromName(String? n) => switch (n) {
    'in_progress' => inProgress,
    'completed' => completed,
    _ => notStarted,
  };

  String get wire => switch (this) {
    notStarted => 'not_started',
    inProgress => 'in_progress',
    completed => 'completed',
  };
}

/// Self-reported by the parent; never coach-verified performance.
class ExerciseProgress {
  const ExerciseProgress({
    required this.planId,
    required this.exerciseId,
    required this.childId,
    required this.groupId,
    required this.parentId,
    required this.status,
    required this.updatedAt,
    this.viewedAt,
  });

  final String planId;
  final String exerciseId;
  final String childId;
  final String groupId;
  final String parentId;
  final ProgressStatus status;
  final DateTime updatedAt;
  final DateTime? viewedAt;

  static String docId(String planId, String exerciseId, String childId) => '${planId}_${exerciseId}_$childId';
  String get id => docId(planId, exerciseId, childId);

  Map<String, dynamic> toMap() => {
    'planId': planId,
    'exerciseId': exerciseId,
    'childId': childId,
    'groupId': groupId,
    'parentId': parentId,
    'status': status.wire,
    'updatedAt': updatedAt,
    'viewedAt': viewedAt,
  };

  factory ExerciseProgress.fromMap(Map<String, dynamic> m) => ExerciseProgress(
    planId: m['planId'] as String? ?? '',
    exerciseId: m['exerciseId'] as String? ?? '',
    childId: m['childId'] as String? ?? '',
    groupId: m['groupId'] as String? ?? '',
    parentId: m['parentId'] as String? ?? '',
    status: ProgressStatus.fromName(m['status'] as String?),
    updatedAt: readDateOrNull(m['updatedAt']) ?? DateTime.now(),
    viewedAt: readDateOrNull(m['viewedAt']),
  );
}

class PlanView {
  const PlanView({
    required this.planId,
    required this.parentId,
    required this.firstViewedAt,
    required this.lastViewedAt,
  });

  final String planId;
  final String parentId;
  final DateTime firstViewedAt;
  final DateTime lastViewedAt;
}

/// Coach summary of a plan.
class PlanStats {
  const PlanStats({required this.viewers, required this.completed, required this.total});

  final int viewers;
  final int completed;
  final int total;
}

abstract interface class TrainingPlansRepository {
  /// Coach: all plans of their groups. Parent: published plans of their
  /// children's groups (server `readerIds`).
  Stream<List<TrainingPlan>> watchPlans();
  Stream<TrainingPlan?> watchPlan(String id);
  Future<TrainingPlan> save(PlanDraft draft, {String? planId});
  Future<void> setStatus(String planId, PlanStatus status);
  Future<void> delete(String planId);

  /// Private media bytes (photo/pdf) or a short-lived URL (video).
  Future<List<int>?> loadMedia(String planId, ExerciseMedia media);

  Future<void> recordView(String planId);
  Future<void> setProgress({
    required String planId,
    required String exerciseId,
    required String childId,
    required ProgressStatus status,
  });
  Stream<List<ExerciseProgress>> watchProgress(String planId);
  Stream<PlanStats> watchStats(String planId);
}
