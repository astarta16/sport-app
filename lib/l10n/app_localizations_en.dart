// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Gundi';

  @override
  String get appTagline => 'Your child\'s sport — in one place';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try again';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get seeAll => 'See all';

  @override
  String get today => 'Today';

  @override
  String get optional => 'Optional';

  @override
  String get demoBadge => 'DEMO';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorPermission => 'You don\'t have access to this.';

  @override
  String get errorNetwork => 'Can\'t connect. Check your internet connection.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorInvalidCode => 'The code is incorrect.';

  @override
  String get errorNotSignedIn => 'Please sign in.';

  @override
  String get errorTitle => 'Couldn\'t load';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalidPhone => 'Enter a valid mobile number (5XX XXX XXX)';

  @override
  String get validationInvalidOtp => 'The code must be 6 digits';

  @override
  String get validationTooShort => 'Too short';

  @override
  String get validationTooLong => 'Too long';

  @override
  String get validationInvalidName => 'Use letters only';

  @override
  String get validationDateInFuture => 'Date is in the future';

  @override
  String get validationTooOldForChild => 'A child must be under 18';

  @override
  String get validationTooYoung => 'Minimum age is 3';

  @override
  String get validationSportRequired => 'Choose at least one sport';

  @override
  String get validationClubRequired => 'Choose a club';

  @override
  String get validationConsentRequired => 'Consent is required to continue';

  @override
  String get validationVenueRequired => 'Choose a venue';

  @override
  String get validationDurationRange => 'Duration must be 15–300 minutes';

  @override
  String get validationFocusRequired => 'Choose at least one focus';

  @override
  String get validationDescriptionTooLong => 'Description is too long';

  @override
  String get validationStartInPast => 'That time has already passed';

  @override
  String get validationPhotoConsentRequired => 'Confirm the photo consent condition';

  @override
  String get validationFileType => 'Only JPG, PNG or PDF are allowed';

  @override
  String get validationFileTooLarge => 'File is larger than 10 MB';

  @override
  String get validationFileEmpty => 'Choose a file';

  @override
  String get validationDatesOrder => 'Expiry must be after the issue date';

  @override
  String get validationIssuedInFuture => 'Issue date is in the future';

  @override
  String get validationEmptyMessage => 'Message is empty';

  @override
  String get validationMessageTooLong => 'Message is too long';

  @override
  String get validationAmountPositive => 'Amount must be greater than 0';

  @override
  String get validationDayOfMonth => 'Day must be 1–28';

  @override
  String get validationAlreadyMember => 'Child is already in this group';

  @override
  String get validationRequestExists => 'A request is already pending';

  @override
  String get onboardingTitle1 => 'Every training in one calendar';

  @override
  String get onboardingBody1 => 'Time, place and coach — always at hand. Hear about changes instantly.';

  @override
  String get onboardingTitle2 => 'A direct line to the coach';

  @override
  String get onboardingBody2 => 'Group chat for parents and coaches, photos from every session.';

  @override
  String get onboardingTitle3 => 'Certificates and payments, safely';

  @override
  String get onboardingBody3 => 'Medical certificates in private storage, reminders for expiry dates and fees.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get phoneTitle => 'Sign in with your phone';

  @override
  String get phoneSubtitle => 'We\'ll text you a one-time code. No password needed.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get sendCode => 'Get code';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get demoOtpHint => 'Demo mode: enter 123456';

  @override
  String get demoAccountsTitle => 'Quick demo sign-in';

  @override
  String get demoAccountsSubtitle => 'Fictional data — no real SMS, payments or medical information.';

  @override
  String get demoPendingCoach => 'Coach (pending approval)';

  @override
  String get guestBrowse => 'Browse clubs without signing in';

  @override
  String get termsNote => 'By continuing you agree to the Terms and Privacy Policy.';

  @override
  String get registerTitle => 'Create your profile';

  @override
  String get chooseRole => 'Who are you?';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleParentDesc => 'Children\'s trainings, coach chat, certificates and payments';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleCoachDesc => 'Manage groups and plan trainings. Requires club approval.';

  @override
  String get roleChild => 'Child';

  @override
  String get roleChildDesc => 'Parents create profiles for under-14s. Accounts for ages 14–17 are coming soon.';

  @override
  String get soon => 'Soon';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get sportsLabel => 'Sports';

  @override
  String get clubsLabel => 'Club';

  @override
  String get consentData => 'I agree to the processing of my personal data';

  @override
  String get consentDataDetails =>
      'We process your name, phone and your child\'s training data only to provide the service. You can delete your account at any time.';

  @override
  String get consentSms => 'I agree to receive SMS payment reminders';

  @override
  String get finishRegistration => 'Finish';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get coachPendingTitle => 'Your account is under review';

  @override
  String get coachPendingBody =>
      'A club administrator verifies every coach. Until then, children\'s data stays hidden — this protects the kids.';

  @override
  String get coachPendingDemoApprove => 'Demo: approve as administrator';

  @override
  String get coachRejectedTitle => 'Request declined';

  @override
  String get coachRejectedBody => 'Please contact the club administration.';

  @override
  String get childAccountUnsupported => 'Independent child accounts aren\'t available yet. Use a parent\'s account.';

  @override
  String get signOut => 'Sign out';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navChat => 'Chat';

  @override
  String get navMap => 'Map';

  @override
  String get navProfile => 'Profile';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingDay(String name) {
    return 'Hello, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get nextTraining => 'Next training';

  @override
  String get noUpcomingTrainings => 'No upcoming trainings yet';

  @override
  String get directions => 'Directions';

  @override
  String get details => 'Details';

  @override
  String get coachLabel => 'Coach';

  @override
  String get venueLabel => 'Venue';

  @override
  String get medicalStatus => 'Medical certificate';

  @override
  String get coachMessages => 'Messages from the coach';

  @override
  String get recentPhotos => 'Training photos';

  @override
  String get paymentSummary => 'Fees';

  @override
  String get noChildrenTitle => 'Add your first child';

  @override
  String get noChildrenBody => 'Create a profile and pick a sport — we\'ll take care of the rest.';

  @override
  String get addChild => 'Add child';

  @override
  String noGroupTitle(String name) {
    return '$name isn\'t in a group yet';
  }

  @override
  String get noGroupBody => 'Find a club on the map and send a membership request.';

  @override
  String get findClub => 'Find a club';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String startsInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count hours',
      one: 'In 1 hour',
      zero: 'Starting soon',
    );
    return '$_temp0';
  }

  @override
  String get noMessages => 'No messages yet';

  @override
  String get noPhotos => 'Photos will appear after trainings';

  @override
  String get allPaid => 'All fees are paid';

  @override
  String yearsOld(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count years old', one: '1 year old');
    return '$_temp0';
  }

  @override
  String get openChat => 'Open chat';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusMoved => 'Rescheduled';

  @override
  String get statusDone => 'Done';

  @override
  String get focusTechnique => 'Technique';

  @override
  String get focusSpeed => 'Speed';

  @override
  String get focusPhysical => 'Conditioning';

  @override
  String get focusBall => 'Ball work';

  @override
  String durationMinutes(int count) {
    return '$count min';
  }

  @override
  String get trainingTitle => 'Training';

  @override
  String get trainingDescription => 'Description';

  @override
  String get trainingFocus => 'Focus';

  @override
  String get trainingPhotos => 'Photos';

  @override
  String movedFrom(String date) {
    return 'Moved from $date';
  }

  @override
  String get cancelledBanner => 'This training was cancelled';

  @override
  String get newTraining => 'New training';

  @override
  String get editTraining => 'Edit training';

  @override
  String get cancelTraining => 'Cancel training';

  @override
  String get cancelTrainingConfirm => 'Cancel this training? Parents in the group will be notified.';

  @override
  String get keepTraining => 'No, keep it';

  @override
  String get rescheduleTraining => 'Reschedule';

  @override
  String get markDone => 'Mark as done';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Start time';

  @override
  String get durationLabel => 'Duration';

  @override
  String get trainingSaved => 'Training saved and parents notified';

  @override
  String get trainingCancelled => 'Training cancelled';

  @override
  String get trainingRescheduled => 'Training rescheduled';

  @override
  String get trainingMarkedDone => 'Marked as done';

  @override
  String get photoConsentTitle => 'Photo consent';

  @override
  String photoConsentMissing(String names) {
    return 'No consent for: $names. These children must not appear in photos.';
  }

  @override
  String get photoConsentAllGiven => 'Every child in the group has parental photo consent.';

  @override
  String get photoConsentConfirm => 'I confirm no child without consent appears in these photos';

  @override
  String get selectVenue => 'Choose a venue';

  @override
  String get descriptionHint => 'What will you practise? e.g. passing, shooting…';

  @override
  String get groupLabel => 'Group';

  @override
  String get photosAdded => 'Photos added';

  @override
  String get customDuration => 'Other';

  @override
  String get saveTraining => 'Save training';

  @override
  String trainingFromTo(String start, String end) {
    return '$start – $end';
  }

  @override
  String get trainingHistory => 'Training history';

  @override
  String get upcoming => 'Upcoming trainings';

  @override
  String get noTrainingsDay => 'No trainings on this day';

  @override
  String get allChildren => 'All children';

  @override
  String get coachHomeSubtitle => 'Today across your groups';

  @override
  String groupMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count children', one: '1 child');
    return '$_temp0';
  }

  @override
  String get roster => 'Group roster';

  @override
  String get noGroupsCoach => 'No groups assigned yet. Contact your club administrator.';

  @override
  String get membershipRequests => 'Membership requests';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Decline';

  @override
  String get requestApproved => 'Child added to the group';

  @override
  String get requestRejected => 'Request declined';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String removeFromGroupConfirm(String name) {
    return 'Remove $name from the group? Your access to their data and certificates ends automatically.';
  }

  @override
  String get parentsLabel => 'Parents';

  @override
  String get call => 'Call';

  @override
  String get viewCertificate => 'Open certificate';

  @override
  String ageRange(int min, int max) {
    return 'Ages $min–$max';
  }

  @override
  String get statMembers => 'Members';

  @override
  String get statThisWeek => 'This week';

  @override
  String get statCertAlerts => 'Certificate alerts';

  @override
  String wantsToJoin(String child, String group) {
    return '$child wants to join $group';
  }

  @override
  String get todayTrainings => 'Today & upcoming';

  @override
  String get selectGroupTitle => 'Choose a group';

  @override
  String get chatEmpty => 'Start the conversation with your group';

  @override
  String get typeMessage => 'Message…';

  @override
  String get chatGroups => 'Group chats';

  @override
  String get chatNotAllowed => 'Chat is only available to parents and coaches.';

  @override
  String get chatPrivacyNote =>
      'Only the group\'s coaches and parents are here. Phone numbers stay hidden from other parents.';

  @override
  String get noChats => 'Chats appear once a child joins a group';

  @override
  String get photoAttachment => 'Photo';

  @override
  String get searchPlaces => 'Search by name or address';

  @override
  String get allSports => 'All';

  @override
  String get venueStadium => 'Stadium';

  @override
  String get venueHall => 'Sports hall';

  @override
  String get venueField => 'Field';

  @override
  String get venuePool => 'Pool';

  @override
  String get clubLabel => 'Club';

  @override
  String get groupsLabel => 'Groups';

  @override
  String get requestMembership => 'Request membership';

  @override
  String get requestSent => 'Request sent to the coach';

  @override
  String get selectChild => 'Choose a child';

  @override
  String get openInMaps => 'Open in maps app';

  @override
  String get mapNoResults => 'No places match this filter';

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get clubDetails => 'Club page';

  @override
  String get noGroupsInClub => 'No groups in this club yet';

  @override
  String get signInToJoin => 'Sign in to request membership';

  @override
  String get mapAttribution => '© OpenStreetMap';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count places', one: '1 place');
    return '$_temp0';
  }

  @override
  String get certificatesTitle => 'Medical certificates';

  @override
  String get certValid => 'Valid';

  @override
  String get certExpiring => 'Expiring';

  @override
  String get certExpired => 'Expired';

  @override
  String get certMissing => 'Missing';

  @override
  String validUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String issuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String get uploadCertificate => 'Upload certificate';

  @override
  String get certConsentTitle => 'Before you upload';

  @override
  String get certConsentWhat => 'What is processed';

  @override
  String get certConsentWhatBody =>
      'The certificate file, issue date and expiry date. Health data is a special category protected by law.';

  @override
  String get certConsentWho => 'Who can access it';

  @override
  String get certConsentWhoBody =>
      'You and the coaches of groups your child currently trains in. Coaches see the status; opening the file is a separate, logged action.';

  @override
  String get certConsentDelete => 'How it\'s deleted';

  @override
  String get certConsentDeleteBody =>
      'Delete it at any time. Deleting your account removes all certificates. Leaving a group ends the coach\'s access.';

  @override
  String get certConsentAgree => 'I consent to processing the certificate as described above';

  @override
  String get takePhoto => 'Camera';

  @override
  String get fromGallery => 'Gallery';

  @override
  String get pickDocument => 'File (PDF)';

  @override
  String get issueDate => 'Issue date';

  @override
  String get expiryDate => 'Valid until';

  @override
  String get fileRequirements => 'JPG, PNG or PDF · max 10 MB';

  @override
  String get certUploaded => 'Certificate uploaded';

  @override
  String get deleteCertificate => 'Delete certificate';

  @override
  String get deleteCertificateConfirm => 'Delete this certificate? The file is removed from storage permanently.';

  @override
  String get certDeleted => 'Certificate deleted';

  @override
  String get openFile => 'Open file';

  @override
  String accessExpiresIn(int minutes) {
    return 'Temporary access · expires in $minutes min';
  }

  @override
  String get accessExpired => 'Access expired. Open it again.';

  @override
  String get demoDocument => 'Demo document';

  @override
  String get demoDocumentBody =>
      'Demo mode never stores real medical files. In production the file opens via a 5-minute signed link.';

  @override
  String get accessLog => 'Access log';

  @override
  String accessLogOpen(String name) {
    return '$name — opened';
  }

  @override
  String accessLogDenied(String name) {
    return '$name — denied';
  }

  @override
  String accessLogDelete(String name) {
    return '$name — deleted';
  }

  @override
  String get noCertificates => 'No certificate uploaded yet';

  @override
  String certExpiresIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expires in $count days',
      one: 'Expires tomorrow',
      zero: 'Expires today',
    );
    return '$_temp0';
  }

  @override
  String certExpiredAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expired $count days ago',
      one: 'Expired 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get certRemindersNote => 'You\'ll be reminded 14 and 3 days before expiry and on the day itself.';

  @override
  String fileSelected(String name) {
    return 'Selected: $name';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'You\'re all caught up';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get notifNewTraining => 'New training';

  @override
  String get notifTrainingChanged => 'Training changed';

  @override
  String get notifTrainingReminder => 'Training in 2 hours';

  @override
  String get notifChatMessage => 'New message';

  @override
  String get notifCertificateExpiry => 'Certificate expiring';

  @override
  String get notifNewPhotos => 'New photos';

  @override
  String get notifPaymentReminder => 'Payment reminder';

  @override
  String get notifPaymentSms => 'SMS payment reminders';

  @override
  String notifBodyGroup(String group) {
    return 'Group: $group';
  }

  @override
  String notifBodyChat(String sender, String group) {
    return '$sender · $group';
  }

  @override
  String notifBodyCert(String child, String days) {
    return '$child — $days days left';
  }

  @override
  String notifBodyPayment(String child, String amount) {
    return '$child — $amount ₾';
  }

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get notificationSettingsHint => 'Choose which notifications you receive.';

  @override
  String get pushDemoNote => 'Demo mode sends no push notifications — they appear in-app instead.';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get paymentPending => 'Pending';

  @override
  String get paymentPaid => 'Paid';

  @override
  String get paymentCancelled => 'Cancelled';

  @override
  String get paymentOverdue => 'Overdue';

  @override
  String get totalDue => 'Total due';

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String paidOn(String date) {
    return 'Paid $date';
  }

  @override
  String get markPaid => 'Mark paid';

  @override
  String get markPending => 'Mark pending';

  @override
  String get cancelPayment => 'Cancel';

  @override
  String get chargeGroup => 'One-off charge';

  @override
  String get chargeGroupHint => 'A payment is created for every child in the group.';

  @override
  String get recurringPlans => 'Monthly fee';

  @override
  String get createPlan => 'Create plan';

  @override
  String get amountLabel => 'Amount (₾)';

  @override
  String get dayOfMonthLabel => 'Day of month';

  @override
  String everyMonthOn(String amount, int day) {
    return '$amount ₾ · every month on day $day';
  }

  @override
  String get generateThisMonth => 'Generate this month';

  @override
  String generated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments created',
      one: '1 payment created',
    );
    return '$_temp0';
  }

  @override
  String get runReminders => 'Run SMS reminders';

  @override
  String remindersReport(int sent, int skipped) {
    return 'Sent $sent · skipped $skipped · re-running never duplicates';
  }

  @override
  String get smsLog => 'SMS log';

  @override
  String get smsMockNote => 'Demo: a mock SMS provider is used. No real SMS is sent.';

  @override
  String get noPayments => 'No payments yet';

  @override
  String get paymentHistory => 'History';

  @override
  String nextDue(String date) {
    return 'Next due $date';
  }

  @override
  String get paymentUpdated => 'Status updated';

  @override
  String chargeCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments created',
      one: '1 payment created',
    );
    return '$_temp0';
  }

  @override
  String get reminderSchedule => 'SMS: 5 days before and the day before, 10:00 (Tbilisi)';

  @override
  String get myChildren => 'My children';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageLabel => 'Language';

  @override
  String get switchDemoAccount => 'Switch demo account';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Your account and all certificates will be permanently deleted. This can\'t be undone.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyBody => 'Children\'s data is visible only to parents and approved coaches of their group.';

  @override
  String get childProfile => 'Child profile';

  @override
  String get birthDateLabel => 'Date of birth';

  @override
  String get ownAccountTitle => 'Own account (14+)';

  @override
  String get ownAccountDisabled => 'Will be enabled once the age and consent policy is legally confirmed.';

  @override
  String get photoConsentLabel => 'Consent to training photos';

  @override
  String get photoConsentHelp => 'Without consent your child must not appear in coach photos.';

  @override
  String get removeChild => 'Remove child';

  @override
  String removeChildConfirm(String name) {
    return 'Delete $name\'s profile? Certificates will be deleted too.';
  }

  @override
  String get childSaved => 'Profile saved';

  @override
  String get requestPending => 'Pending';

  @override
  String get pendingRequests => 'Sent requests';

  @override
  String get roleLabel => 'Role';

  @override
  String get approvedCoach => 'Verified coach';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get modeDemo => 'Demo mode';

  @override
  String get modeFirebase => 'Firebase';

  @override
  String groupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count groups', one: '1 group');
    return '$_temp0';
  }

  @override
  String get notInGroup => 'No group';

  @override
  String get firebaseNotConfiguredTitle => 'Firebase isn\'t configured';

  @override
  String get firebaseNotConfiguredBody =>
      'Run `flutterfire configure`, or start in demo mode with --dart-define=APP_MODE=demo';
}
