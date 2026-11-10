import '../../children/domain/child.dart';
import '../../groups/domain/group.dart';
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

  static bool canViewGroup(AppUser u, Group g) => u.isAdmin || isCoachOf(u, g) || isParentInGroup(u, g);

  static bool canViewChild(AppUser u, Child c, Iterable<Group> groupsOfChild) =>
      u.isAdmin || isParentOf(u, c) || groupsOfChild.any((g) => g.hasChild(c.id) && isCoachOf(u, g));

  static bool canEditChild(AppUser u, Child c) => isParentOf(u, c);

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
  static bool canSeePhone(AppUser viewer, AppUser target, Iterable<Group> groups) {
    if (viewer.id == target.id || viewer.isAdmin) return true;
    if (viewer.isApprovedCoach && target.isParent) {
      return groups.any((g) => g.hasCoach(viewer.id) && g.hasParent(target.id));
    }
    if (viewer.isParent && target.isCoach) {
      return groups.any((g) => g.hasParent(viewer.id) && g.hasCoach(target.id));
    }
    return false;
  }

  static bool canViewPayment(AppUser u, Payment p, Group? g) =>
      (u.isParent && p.parentId == u.id) || (g != null && isCoachOf(u, g)) || u.isAdmin;

  static bool canManagePayments(AppUser u, Group g) => isCoachOf(u, g) || u.isAdmin;

  static bool canUploadTrainingPhotos(AppUser u, Group g) => isCoachOf(u, g);

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
        NotificationType.certificateExpiry ||
        NotificationType.paymentReminder ||
        NotificationType.paymentSms =>
          isGroupParent && (onlyParentIds == null || onlyParentIds.contains(u.id)),
        _ => isGroupParent,
      };
    }).toList();
  }

  /// Registration: which roles a user may self-select.
  static bool canSelfRegisterAs(UserRole role) =>
      role == UserRole.parent || role == UserRole.coach || (role == UserRole.child && PolicyFlags.childAccountsEnabled);
}
