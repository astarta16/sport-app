import '../../children/domain/child.dart';
import '../../groups/domain/group.dart';
import '../../media/domain/media_post.dart';
import '../../notifications/domain/notification_models.dart';
import '../../payments/domain/payment.dart';
import 'app_user.dart';

/// Feature flags for policy decisions that are still open (spec §12).
class PolicyFlags {
  PolicyFlags._();

  /// Children 14–17 may get parent-approved accounts once legal confirms
  /// the age threshold. Until then independent child sign-in is disabled.
  static const childAccountsEnabled = false;
  static const childAccountMinAge = 14;
}

/// Single source of truth for authorization decisions on the client. The
/// same rules are enforced server-side by Firestore/Storage rules and
/// Cloud Functions; the demo backend calls these to behave identically.
class AccessPolicy {
  AccessPolicy._();

  static bool isParentOf(AppUser u, Child c) => u.isParent && c.parentIds.contains(u.id);

  static bool isCoachOf(AppUser u, Group g) => u.isApprovedCoach && g.coachIds.contains(u.id);

  static bool isParentInGroup(AppUser u, Group g) => u.isParent && g.parentIds.contains(u.id);

  static bool canViewGroup(AppUser u, Group g) =>
      u.administersClub(g.clubId) || isCoachOf(u, g) || isParentInGroup(u, g);

  /// Parents and coaches of the child's current groups. Admins are
  /// deliberately excluded: admin screens never need a child's profile
  /// (v1.2 — minimise administrative access to minors' data).
  static bool canViewChild(AppUser u, Child c, Iterable<Group> groupsOfChild) =>
      isParentOf(u, c) || groupsOfChild.any((g) => g.hasChild(c.id) && isCoachOf(u, g));

  /// Progress, attendance history and feedback of one child.
  static bool canViewProgress(AppUser u, Child c, Iterable<Group> groupsOfChild) => canViewChild(u, c, groupsOfChild);

  static bool canEditChild(AppUser u, Child c) => isParentOf(u, c);

  /// v1.6: a student account linked to this child (both directions:
  /// child.userId and the account's lastContext.childId).
  static bool isStudentOf(AppUser u, Child c) => u.isStudent && c.userId == u.id && u.lastContext.childId == c.id;

  /// v1.6 Brain Academy progress: the student, the child's parents and the
  /// coaches of the child's current groups. Admins are not included.
  static bool canViewBrainProgress(AppUser u, Child c, Iterable<Group> groups) =>
      isStudentOf(u, c) || canViewChild(u, c, groups);

  static bool canManageTrainings(AppUser u, Group g) => isCoachOf(u, g);

  static bool canViewTrainings(AppUser u, Group g) => canViewGroup(u, g);

  /// Children never have chat; parents only in their children's groups,
  /// coaches only in assigned groups (spec §8).
  static bool canAccessChat(AppUser u, Group g) {
    if (u.role == UserRole.child) return false;
    return isCoachOf(u, g) || isParentInGroup(u, g);
  }

  static bool canUploadCertificate(AppUser u, Child c) => isParentOf(u, c);

  static bool canDeleteCertificate(AppUser u, Child c) => isParentOf(u, c);

  /// Parent of the child, or an approved coach of a group the child is
  /// *currently* in — leaving the group revokes access automatically.
  static bool canViewCertificate(AppUser u, Child c, Iterable<Group> groups) =>
      isParentOf(u, c) || groups.any((g) => g.hasChild(c.id) && isCoachOf(u, g));

  /// Phone visibility: coach ↔ parents of the same group only; parents
  /// never see each other's numbers.
  /// v1.4: only CURRENT relationships in ACTIVE groups. Coach ↔ parents of
  /// the coach's groups; parent ↔ APPROVED coaches of the child's groups.
  /// Parents never see other parents; pending/suspended coaches see nothing.
  /// Mirrors functions/src/lib/v14.ts canSeeContactPhone.
  static bool canSeePhone(AppUser viewer, AppUser target, Iterable<Group> groups) {
    if (viewer.id == target.id) return true;
    final live = groups.where((g) => g.isActive);
    if (viewer.isApprovedCoach && target.isParent) {
      return live.any((g) => g.hasCoach(viewer.id) && g.hasParent(target.id));
    }
    if (viewer.isParent && target.isApprovedCoach) {
      return live.any((g) => g.hasParent(viewer.id) && g.hasCoach(target.id));
    }
    return false;
  }

  /// v1.4 parent media download (mirrors mediaDownloadDecision on the
  /// server): the owning coach always; a parent only with a child in an
  /// ACTIVE group of the post whose media policy allows downloads, and only
  /// for posts not hidden by moderation.
  static bool canDownloadMedia(AppUser u, MediaPost post, Iterable<Group> groups) {
    if (u.id == post.coachId) return true;
    if (post.hidden || !u.isParent) return false;
    final mine = groups.where((g) => g.isActive && post.groupIds.contains(g.id) && g.hasParent(u.id));
    return mine.any((g) => g.mediaDownloadsEnabled);
  }

  static bool canViewPayment(AppUser u, Payment p, Group? g) =>
      (u.isParent && p.parentId == u.id) || (g != null && (isCoachOf(u, g) || u.administersClub(g.clubId)));

  /// See group payments (coach of the group or club admin).
  static bool canManagePayments(AppUser u, Group g) => isCoachOf(u, g) || u.administersClub(g.clubId);

  /// Change authoritative payment status / verify proofs (v1.3): only coaches
  /// explicitly listed in `paymentManagerIds`, or admins of the club.
  /// Financial rights are never granted to all coaches automatically.
  static bool canVerifyPayments(AppUser u, Group g) =>
      (isCoachOf(u, g) && g.paymentManagerIds.contains(u.id)) || u.administersClub(g.clubId);

  /// Training plans (v1.3).
  static bool canManagePlan(AppUser u, Iterable<Group> groups) =>
      groups.isNotEmpty && groups.every((g) => isCoachOf(u, g));

  static bool canUploadTrainingPhotos(AppUser u, Group g) => isCoachOf(u, g);

  // ── v1.1 / v1.2 ─────────────────────────────────────────────────────

  /// Approved coach of the club (v1.1 §2: coach creates groups).
  static bool canCreateGroup(AppUser u, String clubId) => u.isApprovedCoach && u.clubIds.contains(clubId);

  static bool canInviteToGroup(AppUser u, Group g) => isCoachOf(u, g) && g.isActive;

  /// The coach-created pending child: only first/last name are visible to
  /// the coach until a parent accepts (v1.1 §2).
  static bool canSeeChildDetails(AppUser u, Child c, Iterable<Group> groups) =>
      !c.isPending && canViewChild(u, c, groups);

  static bool canManageMatches(AppUser u, Group g) => isCoachOf(u, g);

  /// Parent RSVP: own child, member of the group, before the start.
  static bool canRsvp(AppUser u, Child c, Group g, DateTime trainingStart, DateTime now) =>
      isParentOf(u, c) && g.hasChild(c.id) && now.isBefore(trainingStart);

  static bool canMarkAttendance(AppUser u, Group g) => isCoachOf(u, g);

  static bool canGiveFeedback(AppUser u, Child c, Group g) => isCoachOf(u, g) && g.hasChild(c.id);

  /// Coach of every target group.
  static bool canPublishMedia(AppUser u, Iterable<Group> targets) =>
      targets.isNotEmpty && targets.every((g) => isCoachOf(u, g));

  /// Membership in any target group, checked against *current* membership
  /// (removal from the group revokes access to its media).
  static bool canViewMedia(AppUser u, MediaPost p, Iterable<Group> allGroups) {
    if (p.hidden && p.coachId != u.id) return false;
    return allGroups.any((g) => p.groupIds.contains(g.id) && (isCoachOf(u, g) || isParentInGroup(u, g)));
  }

  /// Any member of the group may report content in it.
  static bool canReport(AppUser u, Group g) => isCoachOf(u, g) || isParentInGroup(u, g);

  static bool canModerate(AppUser u, String clubId) => u.administersClub(clubId);

  static bool canManageClub(AppUser u, String clubId) => u.administersClub(clubId);

  /// Platform admins only: catalog, roles, new clubs.
  static bool canManagePlatform(AppUser u) => u.isPlatformAdmin;

  static bool canViewAudit(AppUser u, String? clubId) =>
      u.isPlatformAdmin || (clubId != null && u.administersClub(clubId));

  /// Club admins may decide on coaches of their clubs; platform admins on all.
  static bool canDecideCoach(AppUser admin, AppUser coach) =>
      admin.isPlatformAdmin || (admin.isAdmin && coach.clubIds.any(admin.adminClubIds.contains));

  /// Role-based recipient selection for push notifications (spec §9).
  static List<AppUser> notificationRecipients({
    required NotificationType type,
    required Group group,
    required Iterable<AppUser> users,
    String? excludeUserId,
    Set<String>? onlyParentIds,
  }) {
    return users.where((u) {
      if (u.id == excludeUserId) return false;
      if (u.role == UserRole.child) return false;
      if (!u.notificationPrefs.isEnabled(type)) return false;
      final isGroupParent = isParentInGroup(u, group);
      final isGroupCoach = isCoachOf(u, group);
      return switch (type) {
        NotificationType.chatMessage => isGroupParent || isGroupCoach,
        NotificationType.inviteAnswered => isGroupCoach,
        NotificationType.certificateExpiry ||
        NotificationType.paymentReminder ||
        NotificationType.paymentSms => isGroupParent && (onlyParentIds == null || onlyParentIds.contains(u.id)),
        _ => isGroupParent,
      };
    }).toList();
  }

  /// Registration: which roles a user may self-select.
  static bool canSelfRegisterAs(UserRole role) =>
      role == UserRole.parent || role == UserRole.coach || (role == UserRole.child && PolicyFlags.childAccountsEnabled);
}
