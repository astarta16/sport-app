import 'dart:async';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../account/domain/account_request.dart';
import '../../admin/domain/admin_models.dart';
import '../../attendance/domain/attendance.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/domain/app_user.dart';
import '../../brain_academy/domain/brain_models.dart';
import '../../chat/domain/chat_message.dart';
import '../../child_threads/domain/child_thread.dart';
import '../../children/domain/child.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../matches/domain/match.dart';
import '../../media/domain/media_post.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../moderation/domain/report.dart';
import '../../organizations/domain/organization.dart';
import '../../organizations/domain/scheduling.dart';
import '../../organizations/domain/coach_contact.dart';
import '../../organizations/domain/platform.dart';
import '../../brain_academy/domain/scoring.dart';
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

  // v1.5
  /// matchId → result corrections, newest first (`matches/{id}/resultHistory`).
  final matchResultHistory = <String, List<MatchResultChange>>{};

  /// `childThreads/{childId}_{coachId}` and their messages.
  final childThreads = <String, ChildThread>{};
  final childThreadMessages = <String, List<ChildThreadMessage>>{};

  // v1.6 Brain Academy (`brainResults`, `brainAssignments`).
  final brainResults = <GameResult>[];
  final brainAssignments = <String, ChallengeAssignment>{};

  // v1.7 multi-tenant SaaS (see docs/multi-tenant-architecture.md).
  /// `orgConfigs/{clubId}`; a club without one uses [OrgConfig.legacy].
  final orgConfigs = <String, OrgConfig>{};

  /// `clubs/{clubId}/orgMembers/{uid}` keyed `clubId|uid`.
  final memberships = <String, OrgMembership>{};
  final programs = <String, SportsProgram>{};
  final rooms = <String, Room>{};
  final bookings = <String, Booking>{};

  /// `clubs/{clubId}/leaderboardConsents/{childId}` keyed `clubId|childId`.
  final leaderboardConsents = <String, LeaderboardConsent>{};

  /// Append-only RSVP history (`rsvps/{id}/history`).
  final rsvpHistory = <RsvpHistoryEntry>[];

  /// Student → parent "please contact my coach" requests.
  final coachContactRequests = <String, CoachContactRequest>{};

  OrgConfig orgConfig(String clubId) => orgConfigs[clubId] ?? OrgConfig.legacy(clubId);

  // v1.8 platform collections.
  final packages = <String, SubscriptionPackage>{for (final p in SubscriptionPackage.builtIns) p.id: p};
  final templates = <String, OrgTemplate>{for (final t in OrgTemplate.builtIns) t.id: t};
  final invitations = <String, OrgInvitation>{};
  final configHistory = <ConfigHistoryEntry>[];

  /// Server-side feature flag check (same as the `moduleOn()` rule), at the
  /// backend's clock (trials, scheduled rollouts, subscription end dates).
  void requireModule(String? clubId, OrgModule m) {
    if (clubId == null || clubId.isEmpty) return;
    if (!orgConfig(clubId).isEnabled(m, now: clock())) throw ValidationException('moduleDisabled:${m.name}');
  }

  bool moduleOn(String? clubId, OrgModule m) =>
      clubId == null || clubId.isEmpty || orgConfig(clubId).isEnabled(m, now: clock());

  /// Child-level data (certificates, payments of a child): allowed when at
  /// least one organization of the child's groups has the feature on.
  void requireChildModule(String childId, OrgModule m) {
    final orgs = {
      for (final g in groups.values)
        if (g.hasChild(childId)) g.clubId,
    };
    if (orgs.isNotEmpty && !orgs.any((o) => moduleOn(o, m))) throw ValidationException('moduleDisabled:${m.name}');
  }

  /// Module on for at least one organization of the group.
  void requireGroupModule(String groupId, OrgModule m) => requireModule(clubOfGroup(groupId), m);

  /// Writes a configuration change with optimistic concurrency: a stale
  /// [expectedVersion] throws [ConfigConflictException]; every change gets a
  /// new version, a history entry (who / when / why / what) and an audit line.
  OrgConfig saveConfig(OrgConfig next, {int? expectedVersion, required String reason, required String action}) {
    final old = orgConfig(next.orgId);
    if (expectedVersion != null && expectedVersion != old.version) throw ConfigConflictException(old.version);
    final changes = <String>[
      for (final m in OrgModule.values) ...[
        if (!old.allowedModules.contains(m) && next.allowedModules.contains(m)) 'entitle:${m.name}',
        if (old.allowedModules.contains(m) && !next.allowedModules.contains(m)) 'revoke:${m.name}',
        if (!old.enabledModules.contains(m) && next.enabledModules.contains(m)) '+${m.name}',
        if (old.enabledModules.contains(m) && !next.enabledModules.contains(m)) '-${m.name}',
      ],
      if (old.packageId != next.packageId) 'package:${old.packageId}→${next.packageId}',
      if (old.subscription.status != next.subscription.status)
        'subscription:${old.subscription.status.name}→${next.subscription.status.name}',
      if (old.status != next.status) 'status:${old.status.name}→${next.status.name}',
      if (old.rollout.length != next.rollout.length ||
          old.rollout.entries.any((e) => next.rollout[e.key]?.state != e.value.state))
        'rollout',
      if (old.branding.primaryColor != next.branding.primaryColor ||
          old.branding.names.toString() != next.branding.names.toString())
        'branding',
      if (old.settings.coachesCanBookRooms != next.settings.coachesCanBookRooms) 'settings',
    ];
    final saved = next.copyWith(
      version: old.version + 1,
      updatedAt: clock(),
      updatedBy: currentUser?.id ?? 'system',
      changeReason: reason,
    );
    orgConfigs[next.orgId] = saved;
    configHistory.add(
      ConfigHistoryEntry(
        orgId: next.orgId,
        version: saved.version,
        at: clock(),
        by: currentUser?.id ?? 'system',
        reason: reason,
        changes: changes,
      ),
    );
    auditLog(action, 'club', next.orgId, clubId: next.orgId, details: {'reason': reason, 'changes': changes.join(',')});
    return saved;
  }

  /// Current usage of one organization (limits are checked against it).
  OrgUsage usageOf(String orgId) {
    final groupsOf = groups.values.where((g) => g.clubId == orgId).toList();
    final ids = {for (final g in groupsOf) g.id};
    final monthStart = DateTime(clock().year, clock().month);
    return OrgUsage(
      coaches: users.values.where((u) => u.isCoach && u.clubIds.contains(orgId)).length,
      students: {for (final g in groupsOf) ...g.memberChildIds}.length,
      groups: groupsOf.length,
      rooms: rooms.values.where((r) => r.orgId == orgId && r.status != RoomStatus.archived).length,
      // Demo storage: 2 MB per media post (synthetic, labelled in the UI).
      storageMb: mediaPosts.values.where((p) => p.groupIds.any(ids.contains)).length * 2,
      notificationsThisMonth: notifications
          .where((n) => ids.contains(n.groupId) && !n.createdAt.isBefore(monthStart))
          .length,
      smsThisMonth: 0,
    );
  }

  /// A child joining a group counts against the student limit only when it
  /// is new to the organization.
  void requireStudentCapacity(String orgId, String childId) {
    final already = groups.values.any((g) => g.clubId == orgId && g.hasChild(childId));
    if (!already) requireWithinLimit(orgId, 'students');
  }

  /// Package limit check before adding [adding] of [kind].
  void requireWithinLimit(String? orgId, String kind, {int adding = 1}) {
    if (orgId == null || orgId.isEmpty || !orgConfigs.containsKey(orgId)) return;
    final l = orgConfig(orgId).limits;
    final u = usageOf(orgId);
    final (used, max) = switch (kind) {
      'students' => (u.students, l.maxStudents),
      'coaches' => (u.coaches, l.maxCoaches),
      'groups' => (u.groups, l.maxGroups),
      _ => (u.rooms, l.maxRooms),
    };
    if (used + adding > max) throw ValidationException('limit${kind[0].toUpperCase()}${kind.substring(1)}');
  }

  /// Keeps a room reservation in step with its training (shared source of
  /// truth). Rejects the change when the room is not free at the new time.
  void moveLinkedBooking(String eventId, DateTime start, int durationMin) {
    final b = bookings.values.where((x) => x.eventId == eventId && x.isActive).firstOrNull;
    if (b == null) return;
    final room = rooms[b.roomId];
    if (room == null) return;
    final cfg = orgConfig(b.orgId);
    final moved = b.copyWith(
      startAt: start,
      endAt: start.add(Duration(minutes: durationMin)),
      updatedAt: clock(),
    );
    final conflicts = ConflictChecker.check(
      moved,
      room: room,
      existing: bookings.values.where((x) => x.orgId == b.orgId),
      timezone: cfg.timezone,
      bufferMin: cfg.bookingBufferMin,
    );
    if (ConflictChecker.isBlocked(conflicts)) throw const ValidationException('roomConflict');
    bookings[b.id] = moved;
  }

  /// Organization of a group (tenant id).
  String? clubOfGroup(String groupId) => groups[groupId]?.clubId;

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
    // v1.8: no notifications for a tenant with notifications or the
    // notification's own feature switched off.
    final org = groupId == null ? null : clubOfGroup(groupId);
    if (org != null && (!moduleOn(org, OrgModule.notifications) || !moduleOn(org, moduleOfNotification(type)))) return;
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
  void systemMessage(
    String groupId,
    String text, {
    String? key,
    Map<String, String> args = const {},
    bool requiresAck = false,
  }) {
    (messages[groupId] ??= []).add(
      ChatMessage(
        requiresAck: requiresAck,
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

  /// v1.7 material schedule change of a training or match: a system notice
  /// that reuses the "გავეცანი" acknowledgment flow (recipient snapshot =
  /// current parents of the group). Acknowledging it never sets an RSVP.
  void announceScheduleChange(
    Group g, {
    required String eventId,
    required String eventType,
    required int version,
    required String text,
    required String route,
    Map<String, String> args = const {},
  }) {
    systemMessage(
      g.id,
      text,
      key: 'eventRescheduled',
      args: {...args, 'eventId': eventId, 'eventType': eventType, 'version': '$version'},
      requiresAck: true,
    );
    final m = messages[g.id]!.last;
    final ids = <String>{
      for (final p in g.parentIds)
        if (users[p]?.isParent ?? false) p,
    }.toList()..sort();
    msgRecipients[m.id] = ids;
    for (final p in ids) {
      notifyUser(
        p,
        NotificationType.ackRequested,
        route: route,
        args: {'group': g.name, 'groupId': g.id, 'messageId': m.id, ...args},
        groupId: g.id,
        dedupeKey: 'sched:$eventId:$version',
      );
    }
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

/// Feature that a notification type belongs to (notifications of a
/// disabled feature are never sent).
OrgModule moduleOfNotification(NotificationType t) => switch (t) {
  NotificationType.newTraining ||
  NotificationType.trainingChanged ||
  NotificationType.trainingReminder ||
  NotificationType.scheduleChanged => OrgModule.trainings,
  NotificationType.newMatch ||
  NotificationType.matchChanged ||
  NotificationType.matchReminder ||
  NotificationType.matchResult => OrgModule.matches,
  NotificationType.chatMessage || NotificationType.announcement => OrgModule.communication,
  NotificationType.ackRequested => OrgModule.notifications,
  NotificationType.certificateExpiry => OrgModule.medicalCertificates,
  NotificationType.newPhotos || NotificationType.newMedia => OrgModule.media,
  NotificationType.paymentReminder || NotificationType.paymentSms => OrgModule.paymentReminders,
  NotificationType.paymentProofSubmitted ||
  NotificationType.paymentProofApproved ||
  NotificationType.paymentProofRejected => OrgModule.paymentReceipts,
  NotificationType.trainingPlanPublished => OrgModule.trainingPlans,
  NotificationType.attendanceRecorded || NotificationType.feedbackAdded => OrgModule.attendance,
  _ => OrgModule.notifications,
};
