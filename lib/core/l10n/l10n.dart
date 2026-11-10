import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../errors/app_exception.dart';

export '../../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeName => Localizations.localeOf(this).languageCode;
}

/// Locale-aware date/number formatting used across the UI.
class Fmt {
  Fmt(this.locale);

  factory Fmt.of(BuildContext context) => Fmt(context.localeName);

  final String locale;

  String time(DateTime d) => DateFormat.Hm(locale).format(d);
  String dayMonth(DateTime d) => DateFormat('d MMMM', locale).format(d);
  String dayMonthShort(DateTime d) => DateFormat('d MMM', locale).format(d);
  String weekdayDayMonth(DateTime d) => DateFormat('EEEE, d MMMM', locale).format(d);
  String weekdayShort(DateTime d) => DateFormat('EEE', locale).format(d);
  String fullDate(DateTime d) => DateFormat('d MMMM y', locale).format(d);
  String numericDate(DateTime d) => DateFormat('dd.MM.y', locale).format(d);
  String monthYear(DateTime d) => DateFormat('LLLL y', locale).format(d);
  String monthShort(DateTime d) => DateFormat('LLL', locale).format(d);
  String dateTime(DateTime d) => '${dayMonth(d)}, ${time(d)}';
  String money(num amount) =>
      '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: amount % 1 == 0 ? 0 : 2).format(amount)} ₾';
}

/// Maps repository errors and validation codes to localized text.
String errorText(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is PermissionDeniedException) return l.errorPermission;
  if (error is NotFoundException) return l.errorNotFound;
  if (error is BackendUnavailableException) return l.errorNetwork;
  if (error is AuthException) {
    return switch (error.code) {
      'invalid-code' => l.errorInvalidCode,
      'invalid-phone' => l.validationInvalidPhone,
      'not-signed-in' => l.errorNotSignedIn,
      _ => l.errorGeneric,
    };
  }
  if (error is ValidationException) return validationText(context, error.code) ?? l.errorGeneric;
  return l.errorGeneric;
}

String? validationText(BuildContext context, String? code) {
  if (code == null) return null;
  final l = context.l10n;
  return switch (code) {
    'required' => l.validationRequired,
    'invalidPhone' => l.validationInvalidPhone,
    'invalidOtp' => l.validationInvalidOtp,
    'tooShort' => l.validationTooShort,
    'tooLong' => l.validationTooLong,
    'invalidName' => l.validationInvalidName,
    'dateInFuture' => l.validationDateInFuture,
    'tooOldForChild' => l.validationTooOldForChild,
    'tooYoung' => l.validationTooYoung,
    'sportRequired' => l.validationSportRequired,
    'clubRequired' => l.validationClubRequired,
    'consentRequired' => l.validationConsentRequired,
    'venueRequired' => l.validationVenueRequired,
    'durationRange' => l.validationDurationRange,
    'focusRequired' => l.validationFocusRequired,
    'descriptionTooLong' => l.validationDescriptionTooLong,
    'startInPast' => l.validationStartInPast,
    'photoConsentRequired' => l.validationPhotoConsentRequired,
    'fileType' => l.validationFileType,
    'fileTooLarge' => l.validationFileTooLarge,
    'fileEmpty' => l.validationFileEmpty,
    'datesOrder' => l.validationDatesOrder,
    'issuedInFuture' => l.validationIssuedInFuture,
    'emptyMessage' => l.validationEmptyMessage,
    'messageTooLong' => l.validationMessageTooLong,
    'amountPositive' => l.validationAmountPositive,
    'dayOfMonth' => l.validationDayOfMonth,
    'alreadyMember' => l.validationAlreadyMember,
    'requestExists' => l.validationRequestExists,
    'cancelReasonRequired' => l.validationCancelReasonRequired,
    'cancelReasonTooShort' => l.validationCancelReasonTooShort,
    'weekdaysRequired' => l.validationWeekdaysRequired,
    'endBeforeStart' => l.validationEndBeforeStart,
    'seriesTooLong' => l.validationSeriesTooLong,
    'seriesOverlap' => l.validationSeriesOverlap,
    'opponentRequired' => l.validationOpponentRequired,
    'groupNameRequired' => l.validationGroupNameRequired,
    'groupAgeRange' => l.validationGroupAgeRange,
    'invalidGroupCode' => l.validationInvalidGroupCode,
    'inviteExists' => l.validationInviteExists,
    'inviteClosed' => l.validationInviteClosed,
    'linkChildRequired' => l.validationLinkChildRequired,
    'notMember' => l.validationNotMember,
    'rsvpClosed' => l.validationRsvpClosed,
    'trainingCancelled' => l.validationTrainingCancelled,
    'attendanceTooEarly' => l.validationAttendanceTooEarly,
    'feedbackEmpty' => l.validationFeedbackEmpty,
    'feedbackRating' => l.validationFeedbackRating,
    'mediaGroupsRequired' => l.validationMediaGroupsRequired,
    'videoTooLarge' => l.validationVideoTooLarge,
    'videoTooLong' => l.validationVideoTooLong,
    'avatarTooLarge' => l.validationAvatarTooLarge,
    'rateLimited' => l.validationRateLimited,
    'alreadyReported' => l.validationAlreadyReported,
    'reasonRequired' => l.validationReasonRequired,
    'locationOutsideGeorgia' => l.validationLocationOutsideGeorgia,
    'clubArchived' => l.validationClubArchived,
    'matchCancelled' => l.validationMatchCancelled,
    'cannotPin' => l.validationCannotPin,
    'ageRange' => l.validationAgeRange,
    'reportClosed' => l.validationReportClosed,
    'cannotChangeOwnRole' => l.validationCannotChangeOwnRole,
    'childNotFound' => l.validationChildNotFound,
    'planTitle' => l.validationPlanTitle,
    'planGroups' => l.validationPlanGroups,
    'planExercises' => l.validationPlanExercises,
    'planDates' => l.validationPlanDates,
    'exerciseName' => l.validationExerciseName,
    'link' => l.validationLink,
    'tooManyExercises' => l.validationTooManyExercises,
    'tooManyMedia' => l.validationTooManyMedia,
    'planNotDraft' => l.validationPlanNotDraft,
    'proofExists' => l.validationProofExists,
    'proofClosed' => l.validationProofClosed,
    'paymentClosed' => l.validationPaymentClosed,
    'receiptRequired' => l.validationReceiptRequired,
    'dateFuture' => l.validationDateFuture,
    'already-exists' => l.validationProofExists,
    'validationRequired' => l.validationRequired,
    'validationTooLong' => l.validationTooLong,
    'validationSportRequired' => l.validationSportRequired,
    'invalid-argument' || 'failed-precondition' => l.errorGeneric,
    _ => l.errorGeneric,
  };
}
