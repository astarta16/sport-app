import '../../../core/utils/dates.dart';
import '../../trainings/domain/training.dart';

enum MediaType {
  photo,
  video;

  static MediaType fromName(String? n) => n == 'video' ? video : photo;
}

/// Coach photo/video shared with selected groups (v1.1 §5).
class MediaPost {
  const MediaPost({
    required this.id,
    required this.coachId,
    required this.groupIds,
    required this.type,
    required this.storagePath,
    required this.createdAt,
    this.clubId = '',
    this.thumbPath,
    this.caption,
    this.durationSec,
    this.hidden = false,
    this.coachName = '',
  });

  final String id;
  final String coachId;
  final String coachName;
  final List<String> groupIds;
  final String clubId;
  final MediaType type;

  /// Private storage path / demo key — never a public URL.
  final String storagePath;
  final String? thumbPath;
  final String? caption;
  final int? durationSec;
  final DateTime createdAt;

  /// Hidden by moderation.
  final bool hidden;

  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 100 * 1024 * 1024;
  static const maxVideoSeconds = 60;
  static const maxCaption = 300;

  MediaPost copyWith({bool? hidden}) => MediaPost(
    id: id,
    coachId: coachId,
    coachName: coachName,
    groupIds: groupIds,
    clubId: clubId,
    type: type,
    storagePath: storagePath,
    thumbPath: thumbPath,
    caption: caption,
    durationSec: durationSec,
    createdAt: createdAt,
    hidden: hidden ?? this.hidden,
  );

  Map<String, dynamic> toMap() => {
    'coachId': coachId,
    'coachName': coachName,
    'groupIds': groupIds,
    'clubId': clubId,
    'type': type.name,
    'storagePath': storagePath,
    'thumbPath': thumbPath,
    'caption': caption,
    'durationSec': durationSec,
    'createdAt': createdAt,
    'consentConfirmed': true,
  };

  factory MediaPost.fromMap(String id, Map<String, dynamic> m) => MediaPost(
    id: id,
    coachId: m['coachId'] as String? ?? '',
    coachName: m['coachName'] as String? ?? '',
    groupIds: readStringList(m['groupIds']),
    clubId: m['clubId'] as String? ?? '',
    type: MediaType.fromName(m['type'] as String?),
    storagePath: m['storagePath'] as String? ?? '',
    thumbPath: m['thumbPath'] as String?,
    caption: m['caption'] as String?,
    durationSec: (m['durationSec'] as num?)?.toInt(),
    createdAt: readDate(m['createdAt']),
    hidden: m['hidden'] as bool? ?? false,
  );

  /// Error code or null.
  static String? validateUpload({
    required MediaType type,
    required String mimeType,
    required int bytes,
    int? durationSec,
    required List<String> groupIds,
    required bool consentConfirmed,
    String? caption,
  }) {
    if (groupIds.isEmpty) return 'mediaGroupsRequired';
    if (!consentConfirmed) return 'photoConsentRequired';
    if (bytes <= 0) return 'fileEmpty';
    if ((caption ?? '').length > maxCaption) return 'validationTooLong';
    if (type == MediaType.photo) {
      if (!mimeType.startsWith('image/')) return 'fileType';
      if (bytes > maxPhotoBytes) return 'fileTooLarge';
    } else {
      if (!mimeType.startsWith('video/')) return 'fileType';
      if (bytes > maxVideoBytes) return 'videoTooLarge';
      if (durationSec != null && durationSec > maxVideoSeconds) return 'videoTooLong';
    }
    return null;
  }
}

class MediaUpload {
  const MediaUpload({required this.type, required this.file, this.durationSec});

  final MediaType type;
  final PhotoUpload file;
  final int? durationSec;
}

abstract interface class MediaPostsRepository {
  /// Posts visible to the signed-in user (parents: their children's groups).
  Stream<List<MediaPost>> watchForGroups(List<String> groupIds);
  Stream<List<MediaPost>> watchByCoach(String coachId);
  Future<MediaPost> publish({
    required MediaUpload upload,
    required List<String> groupIds,
    required bool consentConfirmed,
    String? caption,
  });
  Future<void> delete(String postId);
}
