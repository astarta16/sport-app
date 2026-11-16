import 'package:flutter/material.dart';

import '../../features/chat/domain/chat_message.dart';

import '../../features/sports/domain/sport.dart';

import '../../features/moderation/domain/report.dart';

import '../../features/matches/domain/match.dart';

import '../../features/attendance/domain/attendance.dart';

import '../../features/clubs/domain/club.dart';
import '../../features/medical_certificates/domain/medical_certificate.dart';
import '../../features/notifications/domain/notification_models.dart';
import '../../features/payments/domain/payment.dart';
import '../../features/trainings/domain/series.dart';
import '../../features/trainings/domain/training.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Visual identity for each sport (icon + accent colour).
class SportVisuals {
  SportVisuals._();

  static IconData icon(String key) => switch (key) {
    'football' => Icons.sports_soccer_rounded,
    'basketball' => Icons.sports_basketball_rounded,
    'swimming' => Icons.pool_rounded,
    'tennis' => Icons.sports_tennis_rounded,
    'wrestling' => Icons.sports_kabaddi_rounded,
    'judo' => Icons.sports_martial_arts_rounded,
    'rugby' => Icons.sports_rugby_rounded,
    'gymnastics' => Icons.sports_gymnastics_rounded,
    _ => Icons.sports_rounded,
  };

  static Color color(String key) => switch (key) {
    'football' => const Color(0xFF16A34A),
    'basketball' => const Color(0xFFF97316),
    'swimming' => const Color(0xFF0EA5E9),
    'tennis' => const Color(0xFFA3B800),
    'wrestling' => const Color(0xFFDC2626),
    'judo' => const Color(0xFF7C3AED),
    'rugby' => const Color(0xFF92400E),
    'gymnastics' => const Color(0xFFDB2777),
    _ => AppColors.blue,
  };

  static LinearGradient gradient(String key) {
    final c = color(key);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(c, Colors.black, 0.25)!, c, Color.lerp(c, Colors.white, 0.18)!],
    );
  }
}

class StatusVisual {
  const StatusVisual(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static StatusVisual certificate(BuildContext context, CertificateStatus s) {
    final l = context.l10n;
    return switch (s) {
      CertificateStatus.valid => StatusVisual(l.certValid, AppColors.success, Icons.verified_rounded),
      CertificateStatus.expiring => StatusVisual(l.certExpiring, AppColors.warning, Icons.warning_amber_rounded),
      CertificateStatus.expired => StatusVisual(l.certExpired, AppColors.danger, Icons.error_rounded),
      CertificateStatus.missing => StatusVisual(l.certMissing, AppColors.neutral, Icons.remove_circle_outline_rounded),
    };
  }

  static StatusVisual training(BuildContext context, TrainingStatus s) {
    final l = context.l10n;
    return switch (s) {
      TrainingStatus.scheduled => StatusVisual(l.statusScheduled, AppColors.blue, Icons.event_available_rounded),
      TrainingStatus.cancelled => StatusVisual(l.statusCancelled, AppColors.danger, Icons.event_busy_rounded),
      TrainingStatus.moved => StatusVisual(l.statusMoved, AppColors.warning, Icons.update_rounded),
      TrainingStatus.done => StatusVisual(l.statusDone, AppColors.success, Icons.task_alt_rounded),
    };
  }

  static StatusVisual payment(BuildContext context, Payment p, DateTime now) {
    final l = context.l10n;
    if (p.isOverdue(now)) return StatusVisual(l.paymentOverdue, AppColors.danger, Icons.error_outline_rounded);
    return switch (p.status) {
      PaymentStatus.pending => StatusVisual(l.paymentPending, AppColors.warning, Icons.schedule_rounded),
      PaymentStatus.paid => StatusVisual(l.paymentPaid, AppColors.success, Icons.check_circle_rounded),
      PaymentStatus.cancelled => StatusVisual(l.paymentCancelled, AppColors.neutral, Icons.block_rounded),
    };
  }
}

String focusLabel(BuildContext context, TrainingFocus f) {
  final l = context.l10n;
  return switch (f) {
    TrainingFocus.technique => l.focusTechnique,
    TrainingFocus.speed => l.focusSpeed,
    TrainingFocus.physical => l.focusPhysical,
    TrainingFocus.ball => l.focusBall,
  };
}

IconData focusIcon(TrainingFocus f) => switch (f) {
  TrainingFocus.technique => Icons.auto_fix_high_rounded,
  TrainingFocus.speed => Icons.bolt_rounded,
  TrainingFocus.physical => Icons.fitness_center_rounded,
  TrainingFocus.ball => Icons.sports_soccer_rounded,
};

String venueTypeLabel(BuildContext context, VenueType t) {
  final l = context.l10n;
  return switch (t) {
    VenueType.stadium => l.venueStadium,
    VenueType.hall => l.venueHall,
    VenueType.field => l.venueField,
    VenueType.pool => l.venuePool,
  };
}

IconData venueTypeIcon(VenueType t) => switch (t) {
  VenueType.stadium => Icons.stadium_rounded,
  VenueType.hall => Icons.home_work_rounded,
  VenueType.field => Icons.grass_rounded,
  VenueType.pool => Icons.pool_rounded,
};

String notificationTitle(BuildContext context, NotificationType t) {
  final l = context.l10n;
  return switch (t) {
    NotificationType.newTraining => l.notifNewTraining,
    NotificationType.trainingChanged => l.notifTrainingChanged,
    NotificationType.trainingReminder => l.notifTrainingReminder,
    NotificationType.chatMessage => l.notifChatMessage,
    NotificationType.certificateExpiry => l.notifCertificateExpiry,
    NotificationType.newPhotos => l.notifNewPhotos,
    NotificationType.paymentReminder => l.notifPaymentReminder,
    NotificationType.paymentSms => l.notifPaymentSms,
    NotificationType.newMatch => l.notifNewMatch,
    NotificationType.matchChanged => l.notifMatchChanged,
    NotificationType.matchReminder => l.notifMatchReminder,
    NotificationType.groupInvite => l.notifGroupInvite,
    NotificationType.inviteAnswered => l.notifInviteAnswered,
    NotificationType.attendanceRecorded => l.notifAttendanceRecorded,
    NotificationType.feedbackAdded => l.notifFeedbackAdded,
    NotificationType.announcement => l.notifAnnouncement,
    NotificationType.newMedia => l.notifNewMedia,
    NotificationType.scheduleChanged => l.notifScheduleChanged,
    NotificationType.paymentProofSubmitted => l.notifPaymentProofSubmitted,
    NotificationType.paymentProofApproved => l.notifPaymentProofApproved,
    NotificationType.paymentProofRejected => l.notifPaymentProofRejected,
    NotificationType.trainingPlanPublished => l.notifTrainingPlanPublished,
    NotificationType.ackRequested => l.notifAckRequested,
    NotificationType.matchResult => l.notifMatchResult,
    NotificationType.childMessage => l.notifChildMessage,
  };
}

IconData notificationIcon(NotificationType t) => switch (t) {
  NotificationType.newTraining => Icons.event_rounded,
  NotificationType.trainingChanged => Icons.update_rounded,
  NotificationType.trainingReminder => Icons.alarm_rounded,
  NotificationType.chatMessage => Icons.chat_bubble_rounded,
  NotificationType.certificateExpiry => Icons.health_and_safety_rounded,
  NotificationType.newPhotos => Icons.photo_library_rounded,
  NotificationType.paymentReminder => Icons.payments_rounded,
  NotificationType.paymentSms => Icons.sms_rounded,
  NotificationType.newMatch ||
  NotificationType.matchChanged ||
  NotificationType.matchReminder => Icons.emoji_events_rounded,
  NotificationType.groupInvite || NotificationType.inviteAnswered => Icons.group_add_rounded,
  NotificationType.attendanceRecorded => Icons.fact_check_rounded,
  NotificationType.feedbackAdded => Icons.insights_rounded,
  NotificationType.announcement => Icons.campaign_rounded,
  NotificationType.newMedia => Icons.video_library_rounded,
  NotificationType.scheduleChanged => Icons.event_repeat_rounded,
  NotificationType.paymentProofSubmitted => Icons.receipt_long_rounded,
  NotificationType.paymentProofApproved => Icons.verified_rounded,
  NotificationType.paymentProofRejected => Icons.report_gmailerrorred_rounded,
  NotificationType.trainingPlanPublished => Icons.assignment_rounded,
  NotificationType.ackRequested => Icons.task_alt_rounded,
  NotificationType.matchResult => Icons.scoreboard_rounded,
  NotificationType.childMessage => Icons.forum_rounded,
};

String notificationBody(BuildContext context, AppNotification n) {
  final l = context.l10n;
  final a = n.args;
  if (n.body.isNotEmpty && a.isEmpty) return n.body;
  return switch (n.type) {
    NotificationType.chatMessage => l.notifBodyChat(a['sender'] ?? '', a['group'] ?? ''),
    NotificationType.certificateExpiry when a['days'] == '0' => l.notifBodyCertExpired(a['child'] ?? ''),
    NotificationType.certificateExpiry => l.notifBodyCertDays(a['child'] ?? '', a['days'] ?? ''),
    NotificationType.paymentProofRejected => l.notifBodyProofRejected(a['child'] ?? '', a['reason'] ?? ''),
    NotificationType.paymentProofSubmitted ||
    NotificationType.paymentProofApproved => l.notifBodyProof(a['child'] ?? '', a['amount'] ?? ''),
    NotificationType.trainingPlanPublished => l.notifBodyPlan(a['title'] ?? '', a['group'] ?? ''),
    NotificationType.paymentReminder ||
    NotificationType.paymentSms => l.notifBodyPayment(a['child'] ?? '', a['amount'] ?? ''),
    NotificationType.trainingChanged || NotificationType.matchChanged when a['reason'] != null => l.notifBodyCancelled(
      a['opponent'] ?? a['group'] ?? '',
      a['reason']!,
    ),
    NotificationType.newMatch ||
    NotificationType.matchChanged ||
    NotificationType.matchReminder => l.notifBodyMatch(a['opponent'] ?? '', a['group'] ?? ''),
    NotificationType.groupInvite ||
    NotificationType.inviteAnswered => l.notifBodyInvite(a['child'] ?? '', a['group'] ?? ''),
    NotificationType.attendanceRecorded || NotificationType.feedbackAdded => l.notifBodyChild(a['child'] ?? ''),
    NotificationType.newMedia => a['coach'] ?? l.notifBodyGroup(a['group'] ?? ''),
    NotificationType.ackRequested when n.body.isNotEmpty => n.body,
    NotificationType.matchResult => l.notifBodyMatchResult(a['opponent'] ?? '', a['our'] ?? '', a['their'] ?? ''),
    NotificationType.childMessage => [
      a['child'],
      a['sender'],
    ].whereType<String>().where((x) => x.isNotEmpty).join(' · '),
    _ => l.notifBodyGroup(a['group'] ?? ''),
  };
}

String notificationCategoryLabel(BuildContext context, NotificationCategory c) {
  final l = context.l10n;
  return switch (c) {
    NotificationCategory.trainings => l.catTrainings,
    NotificationCategory.matches => l.catMatches,
    NotificationCategory.invitations => l.catInvitations,
    NotificationCategory.attendance => l.catAttendance,
    NotificationCategory.payments => l.catPayments,
    NotificationCategory.chat => l.catChat,
    NotificationCategory.certificates => l.catCertificates,
    NotificationCategory.announcements => l.catAnnouncements,
  };
}

IconData notificationCategoryIcon(NotificationCategory c) => switch (c) {
  NotificationCategory.trainings => Icons.event_rounded,
  NotificationCategory.matches => Icons.emoji_events_rounded,
  NotificationCategory.invitations => Icons.group_add_rounded,
  NotificationCategory.attendance => Icons.fact_check_rounded,
  NotificationCategory.payments => Icons.payments_rounded,
  NotificationCategory.chat => Icons.chat_bubble_rounded,
  NotificationCategory.certificates => Icons.health_and_safety_rounded,
  NotificationCategory.announcements => Icons.campaign_rounded,
};

/// Free-text cancel reason; the fixed system reason written by the series
/// engine is shown in the reader's language.
String cancelReasonText(BuildContext context, String reason) =>
    reason == RecurrenceEngine.scheduleChangedReason ? context.l10n.sysScheduleReason : reason;

String cancelReasonLabel(BuildContext context, CancelReasonCode c) {
  final l = context.l10n;
  return switch (c) {
    CancelReasonCode.illness => l.cancelReasonIllness,
    CancelReasonCode.weather => l.cancelReasonWeather,
    CancelReasonCode.venueBusy => l.cancelReasonVenueBusy,
    CancelReasonCode.other => l.cancelReasonOther,
  };
}

String matchTypeLabel(BuildContext context, MatchType t) {
  final l = context.l10n;
  return switch (t) {
    MatchType.friendly => l.matchTypeFriendly,
    MatchType.league => l.matchTypeLeague,
    MatchType.tournament => l.matchTypeTournament,
  };
}

String homeAwayLabel(BuildContext context, HomeAway h) {
  final l = context.l10n;
  return switch (h) {
    HomeAway.home => l.matchHome,
    HomeAway.away => l.matchAway,
    HomeAway.neutral => l.matchNeutral,
  };
}

String rsvpLabel(BuildContext context, RsvpResponse r) {
  final l = context.l10n;
  return switch (r) {
    RsvpResponse.yes => l.rsvpYes,
    RsvpResponse.no => l.rsvpNo,
    RsvpResponse.maybe => l.rsvpMaybe,
  };
}

Color rsvpColor(RsvpResponse r) => switch (r) {
  RsvpResponse.yes => AppColors.success,
  RsvpResponse.no => AppColors.danger,
  RsvpResponse.maybe => AppColors.warning,
};

String attendanceLabel(BuildContext context, AttendanceStatus? s) {
  final l = context.l10n;
  return switch (s) {
    AttendanceStatus.present => l.attendancePresent,
    AttendanceStatus.absent => l.attendanceAbsent,
    AttendanceStatus.excused => l.attendanceExcused,
    null => l.attendanceNotMarked,
  };
}

Color attendanceColor(AttendanceStatus? s) => switch (s) {
  AttendanceStatus.present => AppColors.success,
  AttendanceStatus.absent => AppColors.danger,
  AttendanceStatus.excused => AppColors.warning,
  null => AppColors.neutral,
};

String feedbackLabel(BuildContext context, FeedbackCategory c) {
  final l = context.l10n;
  return switch (c) {
    FeedbackCategory.technique => l.feedbackTechnique,
    FeedbackCategory.discipline => l.feedbackDiscipline,
    FeedbackCategory.teamwork => l.feedbackTeamwork,
    FeedbackCategory.effort => l.feedbackEffort,
    FeedbackCategory.improvement => l.feedbackImprovement,
  };
}

String achievementLabel(BuildContext context, AchievementKind k) {
  final l = context.l10n;
  return switch (k) {
    AchievementKind.firstTraining => l.achFirstTraining,
    AchievementKind.attended5 => l.achAttended(5),
    AchievementKind.attended10 => l.achAttended(10),
    AchievementKind.attended25 => l.achAttended(25),
    AchievementKind.attended50 => l.achAttended(50),
    AchievementKind.attended100 => l.achAttended(100),
    AchievementKind.perfectMonth => l.achPerfectMonth,
    AchievementKind.streak3Months => l.achStreak,
  };
}

IconData achievementIcon(AchievementKind k) => switch (k) {
  AchievementKind.firstTraining => Icons.flag_rounded,
  AchievementKind.perfectMonth => Icons.star_rounded,
  AchievementKind.streak3Months => Icons.local_fire_department_rounded,
  _ => Icons.military_tech_rounded,
};

String reportReasonLabel(BuildContext context, ReportReason r) {
  final l = context.l10n;
  return switch (r) {
    ReportReason.inappropriate => l.reportReasonInappropriate,
    ReportReason.privacy => l.reportReasonPrivacy,
    ReportReason.spam => l.reportReasonSpam,
    ReportReason.other => l.reportReasonOther,
  };
}

String sportCategoryLabel(BuildContext context, SportCategory c) {
  final l = context.l10n;
  return switch (c) {
    SportCategory.team => l.sportCategoryTeam,
    SportCategory.combat => l.sportCategoryCombat,
    SportCategory.other => l.sportCategoryOther,
  };
}

/// Short Georgian/English weekday names for 1 (Mon) … 7 (Sun).
String weekdayShortName(BuildContext context, int weekday) =>
    Fmt.of(context).weekdayShort(DateTime.utc(2024, 1, weekday)); // 2024-01-01 is a Monday

/// System chat line in the reader's language (server/demo store a key + args).
/// Renders a system chat message in the reader's language. Accepts both the
/// demo argument shape (`when`/`from`/`to`) and the Cloud Functions shape
/// (`date`/`time`/`opponent`/`reasonCode`/`reason`, key `newMatch`).
String systemMessageText(BuildContext context, ChatMessage m) {
  final l = context.l10n;
  final a = m.systemArgs;
  final serverWhen = [a['date'], a['time']].whereType<String>().where((x) => x.isNotEmpty).join(' ');
  final when = a['when'] ?? serverWhen;
  final code = CancelReasonCode.fromName(a['reasonCode']);
  final reason = [
    if (code != null && code != CancelReasonCode.other) cancelReasonLabel(context, code),
    if ((a['reason'] ?? '').isNotEmpty) cancelReasonText(context, a['reason']!),
  ].join(' — ');
  return switch (m.systemKey) {
    'trainingCancelled' => l.sysTrainingCancelled(when, reason),
    'trainingMoved' => l.sysTrainingMoved(a['from'] ?? '', a['to'] ?? when),
    'matchCreated' || 'newMatch' => l.sysMatchCreated(a['opponent'] ?? '', when),
    'matchMoved' => l.sysMatchMoved(a['from'] ?? a['opponent'] ?? '', a['to'] ?? when),
    'matchCancelled' => l.sysMatchCancelled(a['opponent'] ?? '', reason),
    'scheduleCreated' => l.sysScheduleCreated,
    'scheduleChanged' => l.sysScheduleChanged(a['from'] ?? ''),
    'planPublished' => l.sysPlanPublished(a['title'] ?? ''),
    _ => m.text,
  };
}
