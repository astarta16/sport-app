import 'dart:async';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../account/domain/account_request.dart';
import '../../admin/domain/admin_models.dart';
import '../../attendance/domain/attendance.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/domain/app_user.dart';
import '../../chat/domain/chat_message.dart';
import '../../children/domain/child.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../matches/domain/match.dart';
import '../../media/domain/media_post.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../moderation/domain/report.dart';
import '../../notifications/domain/notification_models.dart';
import '../../payments/domain/payment.dart';
import '../../payments/domain/payment_proof.dart';
import '../../training_plans/domain/training_plan.dart';
import '../../sports/domain/sport.dart';
import '../../trainings/domain/series.dart';
import '../../trainings/domain/training.dart';

/// In-memory stand-in for Firestore + Storage + Cloud Functions used by
/// DEMO MODE. Every demo repository goes through it and it enforces the
/// same [AccessPolicy] as the production rules, so demo behaviour matches
/// production authorization. It holds only fictional data and is never
/// constructed when the app runs in Firebase mode (see `bootstrap.dart`).
class DemoBackend {
  DemoBackend({DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final DateTime Function() clock;

  final users = <String, AppUser>{};
  final children = <String, Child>{};
  final sports = <String, Sport>{};
  final clubs = <String, Club>{};
  final venues = <String, Venue>{};
  final groups = <String, Group>{};
  final trainings = <String, Training>{};
  final certificates = <String, MedicalCertificate>{};
  final certificateFiles = <String, Uint8List>{};
  final accessLog = <CertificateAccessEntry>[];
  final messages = <String, List<ChatMessage>>{};
  final notifications = <AppNotification>[];
  final requests = <String, MembershipRequest>{};
  final payments = <String, Payment>{};
  final plans = <String, PaymentPlan>{};
  final smsLog = <SmsLogEntry>[];

  // v1.1 / v1.2 collections (see docs/data-model-v1.2.md).
  final invites = <String, GroupInvite>{};
  final matches = <String, SportMatch>{};
  final series = <String, TrainingSeries>{};
  final rsvps = <String, Rsvp>{};
  final attendance = <String, AttendanceRecord>{};
  final feedback = <String, CoachFeedback>{};
  final mediaPosts = <String, MediaPost>{};
  final reports = <String, ContentReport>{};
  final audit = <AuditEntry>[];
  final paymentAudit = <PaymentAuditEntry>[];
  final accountRequests = <String, AccountRequest>{};

  // v1.3
  final paymentProofs = <String, PaymentProof>{};
  final paymentEvents = <PaymentVerificationEvent>[];
  final receiptFiles = <String, Uint8List>{};
  final trainingPlans = <String, TrainingPlan>{};
  final exerciseProgress = <String, ExerciseProgress>{};
  final planViews = <String, PlanView>{};

  // v1.4
  /// childId → parentUid → relation name (`children/{id}.guardianRelations`).
  final guardianRelations = <String, Map<String, String>>{};

  /// messageId → recipient snapshot taken when a coach message is created
  /// (`chats/{g}/receipts/{m}.recipientIds`).
  final msgRecipients = <String, List<String>>{};

  /// messageId → uid → server time of the read / acknowledgment mark
  /// (`…/msgReads/{uid}`, `…/msgAcks/{uid}`; create-only).
  final msgReads = <String, Map<String, DateTime>>{};
  final msgAcks = <String, Map<String, DateTime>>{};

  /// Media download events (`mediaDownloads`) and the acknowledgment audit.
  final mediaDownloads = <MediaDownloadEvent>[];

  /// Demo transfer simulation: delay per 10 % chunk, and a one-shot failure.
  Duration downloadChunkDelay = const Duration(milliseconds: 40);
  bool failNextDownload = false;

  /// groupId → uid → lastReadAt (`chats/{groupId}/members/{uid}`).
  final chatReads = <String, Map<String, DateTime>>{};

  /// Server-side dedupe of notification fan-out (`notifications/{hash}`).
  final _notificationKeys = <String>{};

  /// uid|bucket|day → count (server `rateLimits`).
  final _rate = <String, int>{};

  /// Simulated loss of connectivity: reads keep serving the cache, writes
  /// fail with [BackendUnavailableException] (never a fake success).
  bool offline = false;

  /// Uploaded photo bytes keyed by `demo-mem://<id>`.
  final photos = <String, Uint8List>{};

  /// Signed-in identity (uid + phone); the profile lives in [users].
  ({String uid, String phone})? session;

  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  String newId(String prefix) => '$prefix-${++_seq}';

  /// Call after every mutation so watchers re-emit.
  void commit() => _changes.add(null);

  /// Re-evaluates [read] on every commit. Errors (e.g. permission denied)
  /// are delivered as stream errors.
  Stream<T> watch<T>(T Function() read) {
    late StreamController<T> controller;
    StreamSubscription<void>? sub;
    void emit() {
      try {
        controller.add(read());
      } catch (e, st) {
        controller.addError(e, st);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        emit();
        sub = _changes.stream.listen((_) => emit());
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  /// Call at the start of every mutation.
  void requireOnline() {
    if (offline) throw const BackendUnavailableException('offline');
  }

  void setOffline(bool value) {
    offline = value;
    commit();
  }

  /// Server-side rate limit (per user, per bucket, per Tbilisi day).
  void rateLimit(String bucket, int maxPerDay) {
    final w = TbilisiTimeX.dayKey(clock());
    final key = '${me.id}|$bucket|$w';
    final n = (_rate[key] ?? 0) + 1;
    if (n > maxPerDay) throw const ValidationException('rateLimited');
    _rate[key] = n;
  }

  AppUser? get currentUser => session == null ? null : users[session!.uid];

  AppUser get me {
    final u = currentUser;
    if (u == null) throw const AuthException('not-signed-in');
    return u;
  }

  Iterable<Group> groupsOfChild(String childId) => groups.values.where((g) => g.hasChild(childId));

  Child requireChild(String id) => children[id] ?? (throw NotFoundException('child $id'));
  Group requireGroup(String id) => groups[id] ?? (throw NotFoundException('group $id'));

  /// Server-side trigger equivalent: keeps `group.parentIds` and
  /// `child.groupIds` consistent with `memberChildIds`.
  void recomputeMemberships() {
    for (final g in groups.values.toList()) {
      final parents = <String>{for (final cid in g.memberChildIds) ...?children[cid]?.parentIds}.toList();
      groups[g.id] = g.copyWith(parentIds: parents);
    }
    for (final c in children.values.toList()) {
      final ids = groups.values.where((g) => g.hasChild(c.id)).map((g) => g.id).toList();
      children[c.id] = c.copyWith(groupIds: ids);
    }
  }

  /// Cloud-Function equivalent of a push fan-out with role-based recipient
  /// selection and per-user preferences. [dedupeKey] makes repeated
  /// deliveries of the same event a no-op (server doc id = hash of it).
  void dispatch(
    NotificationType type,
    Group group, {
    String? route,
    Map<String, String> args = const {},
    String? excludeUserId,
    Set<String>? onlyParentIds,
    String? dedupeKey,
  }) {
    final recipients = AccessPolicy.notificationRecipients(
      type: type,
      group: group,
      users: users.values,
      excludeUserId: excludeUserId,
      onlyParentIds: onlyParentIds,
    );
    for (final u in recipients) {
      // Deep-link context: the recipient's child in this group, if any.
      final childId = u.isParent
          ? group.memberChildIds.firstWhere((c) => children[c]?.parentIds.contains(u.id) ?? false, orElse: () => '')
          : '';
      notifyUser(
        u.id,
        type,
        route: route,
        args: {'group': group.name, ...args},
        groupId: group.id,
        childId: childId.isEmpty ? null : childId,
        dedupeKey: dedupeKey,
      );
    }
  }

  /// Writes one inbox entry (respecting preferences and dedupe).
  void notifyUser(
    String userId,
    NotificationType type, {
    String? route,
    Map<String, String> args = const {},
    String? groupId,
    String? childId,
    String? dedupeKey,
  }) {
    final u = users[userId];
    if (u == null || u.role == UserRole.child || !u.notificationPrefs.isEnabled(type)) return;
    if (dedupeKey != null && !_notificationKeys.add('$userId|$dedupeKey')) return;
    notifications.add(
      AppNotification(
        id: newId('ntf'),
        userId: userId,
        type: type,
        title: '',
        body: '',
        createdAt: clock(),
        route: route,
        args: args,
        groupId: groupId,
        childId: childId,
        dedupeKey: dedupeKey,
      ),
    );
  }

  /// Server-written chat line (`type: system`), e.g. on cancellation.
  void systemMessage(String groupId, String text, {String? key, Map<String, String> args = const {}}) {
    (messages[groupId] ??= []).add(
      ChatMessage(
        id: newId('msg'),
        groupId: groupId,
        senderId: 'system',
        senderName: '',
        senderRole: UserRole.admin,
        text: text,
        createdAt: clock(),
        type: ChatMessageType.system,
        systemKey: key,
        systemArgs: args,
      ),
    );
  }

  /// Append-only audit trail (server `auditLog`).
  void auditLog(
    String action,
    String targetType,
    String targetId, {
    String? clubId,
    Map<String, String> details = const {},
  }) {
    final actor = currentUser;
    audit.add(
      AuditEntry(
        id: newId('audit'),
        action: action,
        actorId: actor?.id ?? 'system',
        actorName: actor?.fullName ?? 'system',
        targetType: targetType,
        targetId: targetId,
        clubId: clubId,
        details: details,
        at: clock(),
      ),
    );
  }

  /// Unread chat messages for [uid] in [groupId] (server `userUnread`).
  int unreadFor(String uid, String groupId) {
    final since = chatReads[groupId]?[uid];
    return (messages[groupId] ?? const <ChatMessage>[])
        .where((m) => m.senderId != uid && !m.hidden && (since == null || m.createdAt.isAfter(since)))
        .length;
  }
}

extension TbilisiTimeX on DateTime {
  static String dayKey(DateTime d) {
    final w = d.toUtc().add(const Duration(hours: 4));
    return '${w.year}-${w.month}-${w.day}';
  }
}

/// A logged, authorized media download (v1.4, `mediaDownloads/{id}`).
class MediaDownloadEvent {
  const MediaDownloadEvent({
    required this.postId,
    required this.userId,
    required this.role,
    required this.groupId,
    required this.clubId,
    required this.mediaType,
    required this.at,
  });

  final String postId;
  final String userId;
  final String role;
  final String? groupId;
  final String clubId;
  final String mediaType;
  final DateTime at;
}
