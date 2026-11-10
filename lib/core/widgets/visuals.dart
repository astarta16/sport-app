import 'package:flutter/material.dart';

import '../../features/clubs/domain/club.dart';
import '../../features/medical_certificates/domain/medical_certificate.dart';
import '../../features/notifications/domain/notification_models.dart';
import '../../features/payments/domain/payment.dart';
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
};

String notificationBody(BuildContext context, AppNotification n) {
  final l = context.l10n;
  final a = n.args;
  if (n.body.isNotEmpty && a.isEmpty) return n.body;
  return switch (n.type) {
    NotificationType.chatMessage => l.notifBodyChat(a['sender'] ?? '', a['group'] ?? ''),
    NotificationType.certificateExpiry => l.notifBodyCert(a['child'] ?? '', a['days'] ?? ''),
    NotificationType.paymentReminder ||
    NotificationType.paymentSms => l.notifBodyPayment(a['child'] ?? '', a['amount'] ?? ''),
    _ => l.notifBodyGroup(a['group'] ?? ''),
  };
}
