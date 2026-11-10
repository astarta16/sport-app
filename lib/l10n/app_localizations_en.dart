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

  @override
  String get chatTooltip => 'Chats';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get actionAdd => 'Add';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonHint => 'Briefly describe the reason';

  @override
  String get loadMore => 'Load more';

  @override
  String get loadEarlier => 'Earlier messages';

  @override
  String get all => 'All';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get report => 'Report';

  @override
  String get send => 'Send';

  @override
  String get search => 'Search';

  @override
  String get create => 'Create';

  @override
  String get remove => 'Remove';

  @override
  String get statusLabel => 'Status';

  @override
  String get offlineBanner => 'You\'re offline — showing saved data. Changes can\'t be saved.';

  @override
  String get backOnline => 'Back online';

  @override
  String get permissionDeniedTitle => 'Access restricted';

  @override
  String get permissionDeniedBody => 'You don\'t have permission to view this page.';

  @override
  String get validationCancelReasonRequired => 'Choose a cancellation reason';

  @override
  String get validationCancelReasonTooShort => 'The reason must be at least 5 characters';

  @override
  String get validationWeekdaysRequired => 'Choose at least one weekday';

  @override
  String get validationEndBeforeStart => 'End date is before the start date';

  @override
  String get validationSeriesTooLong => 'A schedule can last at most 1 year';

  @override
  String get validationSeriesOverlap => 'This group already has a schedule on these days at this time';

  @override
  String get validationOpponentRequired => 'Enter the opponent team';

  @override
  String get validationGroupNameRequired => 'Enter a group name';

  @override
  String get validationGroupAgeRange => 'Ages 3–18, minimum ≤ maximum';

  @override
  String get validationInvalidGroupCode => 'Invalid code or the group isn\'t active';

  @override
  String get validationInviteExists => 'An invitation is already pending';

  @override
  String get validationInviteClosed => 'This invitation is already closed';

  @override
  String get validationLinkChildRequired => 'Choose a child';

  @override
  String get validationNotMember => 'The child isn\'t in this group';

  @override
  String get validationRsvpClosed => 'The training has started — the response can\'t be changed';

  @override
  String get validationTrainingCancelled => 'The training is cancelled';

  @override
  String get validationAttendanceTooEarly => 'Attendance can be marked from one hour before the start';

  @override
  String get validationFeedbackEmpty => 'Rate at least one category or write a comment';

  @override
  String get validationFeedbackRating => 'Rating must be 1–5';

  @override
  String get validationMediaGroupsRequired => 'Choose at least one group';

  @override
  String get validationVideoTooLarge => 'The video is larger than 100 MB';

  @override
  String get validationVideoTooLong => 'The video is longer than 60 seconds';

  @override
  String get validationAvatarTooLarge => 'The photo is larger than 1 MB';

  @override
  String get validationRateLimited => 'Too many attempts. Please try again later.';

  @override
  String get validationAlreadyReported => 'You\'ve already reported this';

  @override
  String get validationReasonRequired => 'Give a reason (at least 5 characters)';

  @override
  String get validationLocationOutsideGeorgia => 'The location is outside Georgia';

  @override
  String get validationClubArchived => 'The club is archived';

  @override
  String get validationMatchCancelled => 'The match is cancelled';

  @override
  String get validationCannotPin => 'System messages can\'t be pinned';

  @override
  String get validationAgeRange => 'Age must be 3–18';

  @override
  String get validationReportClosed => 'This report is already resolved';

  @override
  String get validationCannotChangeOwnRole => 'You can\'t change your own role';

  @override
  String get validationChildNotFound => 'Child not found';

  @override
  String get cancelReasonTitle => 'Reason for cancelling';

  @override
  String get cancelReasonHint => 'A reason is required — parents will see it in the calendar and chat.';

  @override
  String get cancelReasonIllness => 'Illness';

  @override
  String get cancelReasonWeather => 'Weather';

  @override
  String get cancelReasonVenueBusy => 'Venue unavailable';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get cancelReasonTextLabel => 'Details (5–300 characters)';

  @override
  String get cancelAction => 'Cancel it';

  @override
  String cancelledWithReason(String reason) {
    return 'Cancelled: $reason';
  }

  @override
  String get trainingCancelledSnack => 'Training cancelled, parents notified';

  @override
  String get matchTitle => 'Match';

  @override
  String get matchesTitle => 'Matches';

  @override
  String get nextMatch => 'Next match';

  @override
  String get newMatch => 'New match';

  @override
  String get editMatch => 'Edit match';

  @override
  String get matchOpponent => 'Opponent';

  @override
  String matchVs(String opponent) {
    return 'vs $opponent';
  }

  @override
  String get matchType => 'Type';

  @override
  String get matchTypeFriendly => 'Friendly';

  @override
  String get matchTypeLeague => 'League';

  @override
  String get matchTypeTournament => 'Tournament';

  @override
  String get matchHomeAway => 'Ground';

  @override
  String get matchHome => 'Home';

  @override
  String get matchAway => 'Away';

  @override
  String get matchNeutral => 'Neutral';

  @override
  String get matchComment => 'Comment';

  @override
  String get matchSaved => 'Match saved, parents notified';

  @override
  String get matchCancelledSnack => 'Match cancelled, parents notified';

  @override
  String get matchPlayed => 'Played';

  @override
  String get markPlayed => 'Mark as played';

  @override
  String get cancelMatch => 'Cancel match';

  @override
  String get matchBadge => 'Match';

  @override
  String get noMatches => 'No matches planned';

  @override
  String get seriesTitle => 'Training schedule';

  @override
  String get seriesNew => 'Recurring schedule';

  @override
  String get seriesEdit => 'Change schedule';

  @override
  String get seriesWeekdays => 'Weekdays';

  @override
  String get seriesStartTime => 'Start time';

  @override
  String get seriesStartDate => 'Start date';

  @override
  String get seriesEndDate => 'End date';

  @override
  String get seriesNoEnd => 'No end date';

  @override
  String seriesSummary(String days, String time) {
    return '$days · $time';
  }

  @override
  String get seriesSaved => 'Schedule saved — trainings are in the calendar';

  @override
  String get seriesEnded => 'Schedule ended';

  @override
  String get seriesEndAction => 'End schedule';

  @override
  String get seriesEndConfirm =>
      'Later trainings will be removed. Trainings parents already responded to will be cancelled with a reason.';

  @override
  String get seriesNone => 'No recurring schedule yet';

  @override
  String get seriesRecurringBadge => 'From schedule';

  @override
  String get editScopeTitle => 'Which trainings should change?';

  @override
  String get editScopeThis => 'Only this training';

  @override
  String get editScopeFuture => 'This and following trainings';

  @override
  String get seriesHorizonNote => 'Trainings are created 8 weeks ahead and extended automatically.';

  @override
  String seriesConflicts(int count) {
    return '$count dates skipped — a training already exists at that time';
  }

  @override
  String get rsvpTitle => 'Coming to training?';

  @override
  String get rsvpYes => 'Will attend';

  @override
  String get rsvpNo => 'Can\'t attend';

  @override
  String get rsvpMaybe => 'Not sure yet';

  @override
  String get rsvpReasonHint => 'Reason (optional)';

  @override
  String get rsvpSaved => 'Response sent to the coach';

  @override
  String get rsvpClosedNote => 'The training has started — the response is final.';

  @override
  String get rsvpNotice => 'A response isn\'t attendance — the coach records actual attendance.';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceExcused => 'Excused';

  @override
  String get attendanceNotMarked => 'Not marked';

  @override
  String get attendanceMarkAllPresent => 'Mark the rest present';

  @override
  String attendanceSummary(int present, int absent, int excused, int unmarked) {
    return '$present present · $absent absent · $excused excused · $unmarked not marked';
  }

  @override
  String get attendanceRecorded => 'Recorded attendance';

  @override
  String get attendanceOpen => 'Take attendance';

  @override
  String attendanceRsvpLabel(String answer) {
    return 'Parent said: $answer';
  }

  @override
  String get attendanceGroupStats => 'Group attendance';

  @override
  String get attendanceThisMonth => 'This month';

  @override
  String attendanceRate(int percent) {
    return '$percent%';
  }

  @override
  String get attendanceNoData => 'No attendance recorded yet';

  @override
  String get attendanceHistory => 'Attendance history';

  @override
  String get attendanceMonthly => 'Monthly attendance';

  @override
  String get attendanceUpcomingResponses => 'Upcoming trainings';

  @override
  String get responsesTitle => 'Parent responses';

  @override
  String responsesCount(int yes, int no, int maybe) {
    return '$yes yes · $no no · $maybe unsure';
  }

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressTrainings => 'Trainings attended';

  @override
  String get progressRate => 'Attendance';

  @override
  String get progressTrend => 'Attendance trend';

  @override
  String get progressFeedback => 'Coach feedback';

  @override
  String get progressNoFeedback => 'No coach feedback yet';

  @override
  String get progressAchievements => 'Achievements';

  @override
  String get progressPrivacyNote => 'Only you and the child\'s coaches see this. No rankings are published.';

  @override
  String get feedbackTechnique => 'Technique';

  @override
  String get feedbackDiscipline => 'Discipline';

  @override
  String get feedbackTeamwork => 'Teamwork';

  @override
  String get feedbackEffort => 'Effort';

  @override
  String get feedbackImprovement => 'Improvement';

  @override
  String get feedbackAdd => 'Add feedback';

  @override
  String get feedbackComment => 'Comment for the parent';

  @override
  String get feedbackCommentHint => 'Keep it constructive and age-appropriate';

  @override
  String get feedbackSaved => 'Feedback shared with the parent';

  @override
  String get achFirstTraining => 'First training';

  @override
  String achAttended(int count) {
    return '$count trainings';
  }

  @override
  String get achPerfectMonth => 'Perfect month';

  @override
  String get achStreak => '3-month streak';

  @override
  String get achLocked => 'Not yet';

  @override
  String get invitesTitle => 'Invitations';

  @override
  String get invitesEmpty => 'No new invitations';

  @override
  String inviteFrom(String child, String group) {
    return '$child is invited to $group';
  }

  @override
  String get inviteLinkTitle => 'Which child is this invitation for?';

  @override
  String get inviteLinkHint => 'If the child is already registered, pick them — no duplicate will be created.';

  @override
  String inviteAsNew(String name) {
    return 'Add as a new child ($name)';
  }

  @override
  String get inviteMediaConsent => 'I agree that my child may appear in team photos and videos';

  @override
  String get inviteAccepted => 'Child added to the group';

  @override
  String get inviteDeclined => 'Invitation declined';

  @override
  String inviteBanner(int count) {
    return '$count new group invitations';
  }

  @override
  String get inviteStatusSent => 'Sent';

  @override
  String get inviteStatusAccepted => 'Accepted';

  @override
  String get inviteStatusDeclined => 'Declined';

  @override
  String get inviteStatusRevoked => 'Revoked';

  @override
  String get inviteRevoke => 'Revoke invitation';

  @override
  String get groupCode => 'Group code';

  @override
  String get groupCodeHint => 'Parents enter the code in their child\'s profile — you approve the request.';

  @override
  String groupCodeShareText(String group, String code) {
    return 'Join the group \"$group\" in the Gundi app. Code: $code';
  }

  @override
  String get joinGroup => 'Join a group with a code';

  @override
  String get joinGroupCodeLabel => '6-character code';

  @override
  String joinGroupSent(String group) {
    return 'Request sent to \"$group\"';
  }

  @override
  String get leaveGroup => 'Leave group';

  @override
  String leaveGroupConfirm(String child, String group) {
    return '$child will leave \"$group\". The coach will no longer see their data or certificate.';
  }

  @override
  String get leftGroup => 'The child left the group';

  @override
  String get membershipTitle => 'Groups and requests';

  @override
  String get newGroup => 'New group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupAgeFrom => 'Age from';

  @override
  String get groupAgeTo => 'Age to';

  @override
  String get groupClub => 'Club';

  @override
  String get groupSport => 'Sport';

  @override
  String groupCreated(String code) {
    return 'Group created. Code: $code';
  }

  @override
  String get addChildTitle => 'Add a child';

  @override
  String get addChildByCode => 'By code';

  @override
  String get addChildBySearch => 'By search';

  @override
  String get addChildManual => 'Manually';

  @override
  String get addChildSearchHint => 'Child\'s first or last name';

  @override
  String get addChildSearchNote => 'The invitation goes to the parent. The child joins only after the parent confirms.';

  @override
  String get addChildManualNote => 'The parent gets an invitation. Until they confirm you only see the name.';

  @override
  String get parentPhone => 'Parent\'s phone';

  @override
  String get inviteSent => 'Invitation sent to the parent';

  @override
  String get invitesSent => 'Sent invitations';

  @override
  String birthYearShort(int year) {
    return 'born $year';
  }

  @override
  String get pendingParentBadge => 'Waiting for parent';

  @override
  String get noSearchResults => 'No results';

  @override
  String get requestViaCode => 'via code';

  @override
  String get mediaTitle => 'Media';

  @override
  String get mediaRecent => 'Recent photos & videos';

  @override
  String get mediaTakePhoto => 'Take photo';

  @override
  String get mediaRecordVideo => 'Record video';

  @override
  String get mediaFromGallery => 'From gallery';

  @override
  String get mediaCaption => 'Caption';

  @override
  String get mediaGroups => 'Who can see it';

  @override
  String get mediaConsentConfirm => 'I confirm: children without parental consent don\'t appear in this media';

  @override
  String get mediaPublish => 'Publish';

  @override
  String get mediaPublished => 'Published — group parents were notified';

  @override
  String get mediaEmpty => 'No media yet';

  @override
  String mediaVideo(int seconds) {
    return 'Video · ${seconds}s';
  }

  @override
  String get mediaNoDownload => 'Downloading is disabled to protect children\'s privacy.';

  @override
  String get mediaDelete => 'Delete media';

  @override
  String get mediaHidden => 'Hidden by moderation';

  @override
  String get mediaLimits => 'Photo ≤ 10 MB · video ≤ 60 s and 100 MB';

  @override
  String mediaConsentMissing(int count, String names) {
    return '$count children have no media consent: $names';
  }

  @override
  String get reportTitle => 'Report';

  @override
  String get reportReasonInappropriate => 'Inappropriate';

  @override
  String get reportReasonPrivacy => 'Privacy';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportNote => 'Comment (optional)';

  @override
  String get reportSent => 'Report sent to the administrators';

  @override
  String get messageHidden => 'Message hidden by moderation';

  @override
  String get chatsEmpty => 'Chats appear once your child joins a group';

  @override
  String get chatAnnouncement => 'Announcement';

  @override
  String get chatAnnouncementToggle => 'Send as announcement (pinned)';

  @override
  String get chatPin => 'Pin';

  @override
  String get chatUnpin => 'Unpin';

  @override
  String get chatPinned => 'Pinned';

  @override
  String chatReadBy(int count) {
    return 'Read by $count';
  }

  @override
  String get chatSendFailed => 'Not sent';

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatSending => 'Sending…';

  @override
  String get chatNoMessages => 'No messages yet';

  @override
  String get chatSystem => 'System';

  @override
  String unreadCount(int count) {
    return '$count unread';
  }

  @override
  String get notifNewMatch => 'New match';

  @override
  String get notifMatchChanged => 'Match changed';

  @override
  String get notifMatchReminder => 'Match reminder';

  @override
  String get notifGroupInvite => 'Group invitation';

  @override
  String get notifInviteAnswered => 'Invitation answered';

  @override
  String get notifAttendanceRecorded => 'Attendance recorded';

  @override
  String get notifFeedbackAdded => 'Coach feedback';

  @override
  String get notifAnnouncement => 'Announcement';

  @override
  String get notifNewMedia => 'New photo/video';

  @override
  String get notifScheduleChanged => 'Schedule changed';

  @override
  String notifBodyMatch(String opponent, String group) {
    return '$opponent · $group';
  }

  @override
  String notifBodyInvite(String child, String group) {
    return '$child → $group';
  }

  @override
  String notifBodyChild(String child) {
    return '$child';
  }

  @override
  String notifBodyCancelled(String group, String reason) {
    return '$group · $reason';
  }

  @override
  String get catTrainings => 'Trainings';

  @override
  String get catMatches => 'Matches';

  @override
  String get catInvitations => 'Invitations';

  @override
  String get catAttendance => 'Attendance';

  @override
  String get catPayments => 'Payments';

  @override
  String get catChat => 'Chat';

  @override
  String get catCertificates => 'Certificates';

  @override
  String get catAnnouncements => 'Announcements';

  @override
  String get notificationsEmptyCategory => 'Nothing in this category';

  @override
  String get paymentsOutstanding => 'Outstanding';

  @override
  String get paymentsPaidTotal => 'Paid';

  @override
  String get paymentsOverdueTotal => 'Overdue';

  @override
  String get paymentsFilterChild => 'Child';

  @override
  String get paymentsFilterSport => 'Sport';

  @override
  String get paymentsReminderPrefs => 'Reminder settings';

  @override
  String get paymentsNoOnline => 'Online payment isn\'t available yet — pay as your club instructs.';

  @override
  String get paymentCancelReason => 'Cancellation reason';

  @override
  String get paymentAudit => 'Change history';

  @override
  String paymentAuditLine(String actor, String from, String to) {
    return '$actor: $from → $to';
  }

  @override
  String paymentSummaryMonth(String month) {
    return '$month — summary';
  }

  @override
  String get paymentTitleLabel => 'Title (optional)';

  @override
  String paymentChildren(int count) {
    return '$count children';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get profilePhotoChange => 'Change photo';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoUpdated => 'Photo updated';

  @override
  String get privacySettingsTitle => 'Privacy';

  @override
  String get privacyPhotoVisible => 'Show my photo to my groups\' coaches/parents';

  @override
  String get privacyAnalytics => 'Anonymous diagnostics (crash reports)';

  @override
  String get consentsTitle => 'Consents';

  @override
  String consentDataGiven(String date) {
    return 'Data processing — $date';
  }

  @override
  String get consentSmsToggle => 'SMS payment reminders';

  @override
  String consentMedia(String child) {
    return 'Media: $child';
  }

  @override
  String get dataExport => 'Export my data';

  @override
  String get dataExportHint =>
      'You\'ll get a JSON file with your and your children\'s data (without medical file contents).';

  @override
  String get dataExportReady => 'Export ready';

  @override
  String get dataExportRequested => 'Export requested';

  @override
  String get accountRequests => 'Requests';

  @override
  String get requestStatusPending => 'Pending';

  @override
  String get requestStatusProcessing => 'Processing';

  @override
  String get requestStatusDone => 'Done';

  @override
  String get requestStatusRejected => 'Rejected';

  @override
  String get deleteImpactTitle => 'What deletion does';

  @override
  String deleteImpactDeleted(String names) {
    return 'Deleted (you\'re the only guardian): $names';
  }

  @override
  String deleteImpactUnlinked(String names) {
    return 'Kept with the other guardian: $names';
  }

  @override
  String get deleteImpactPayments => 'Payment history is kept anonymised for the club\'s accounting.';

  @override
  String get retentionTitle => 'Retention and deletion';

  @override
  String get retentionBody =>
      'Deleting the account removes your profile, photos, and — for children you are the only guardian of — certificates (with files), attendance and feedback. Children with another guardian are not deleted.';

  @override
  String get weekSchedule => 'This week';

  @override
  String get weekEmpty => 'No trainings this week';

  @override
  String get attendanceTile => 'Attendance';

  @override
  String attendanceTileValue(int percent) {
    return '$percent% this month';
  }

  @override
  String get progressShort => 'Progress';

  @override
  String get importantTitle => 'Important';

  @override
  String get coachFab => 'Add';

  @override
  String get addTrainingOne => 'One-off training';

  @override
  String get addSeries => 'Recurring schedule';

  @override
  String get addMatch => 'Match';

  @override
  String get addMedia => 'Photo / video';

  @override
  String get addChildToGroup => 'Invite a child';

  @override
  String get newVenue => 'New location on map';

  @override
  String get venuePickHint => 'Tap the map to drop a pin';

  @override
  String get venueNearby => 'Locations already nearby (200 m):';

  @override
  String get venueUseExisting => 'Use existing';

  @override
  String get venueName => 'Location name';

  @override
  String get venueAddress => 'Address';

  @override
  String get venueUnverified => 'Unverified';

  @override
  String get venueSaved => 'Location saved';

  @override
  String get mapLayerVenues => 'Places';

  @override
  String get mapLayerTrainings => 'Trainings';

  @override
  String get mapLayerMatches => 'Matches';

  @override
  String get mapToday => 'Today';

  @override
  String get mapThisWeek => 'This week';

  @override
  String get sportCategoryTeam => 'Team';

  @override
  String get sportCategoryCombat => 'Combat';

  @override
  String get sportCategoryOther => 'Other';

  @override
  String sportAgeMin(int age) {
    return 'Min. age: $age';
  }

  @override
  String get sportRequiresCert => 'Medical certificate required';

  @override
  String get demoOffline => 'Simulate offline';

  @override
  String get demoOfflineHint => 'Writes fail — the app shows a proper error.';

  @override
  String aboutVersion(String version, String env) {
    return 'Version $version · $env';
  }

  @override
  String get adminUseWeb => 'The admin panel is available on the web.';

  @override
  String get adminTitle => 'Gundi · Admin';

  @override
  String get adminSignInTitle => 'Admin dashboard';

  @override
  String get adminSignInBody => 'Administrators only. Permissions are checked on the server.';

  @override
  String get adminDemoAccounts => 'Demo accounts';

  @override
  String get adminDemoTryParent => 'Check: parent account (access denied)';

  @override
  String get adminPhoneSignIn => 'Sign in with phone';

  @override
  String get adminFirebaseLoginNote =>
      'Phone sign-in on the web needs Firebase reCAPTCHA configuration (see docs/firebase-setup.md).';

  @override
  String get adminRolePlatform => 'Platform admin';

  @override
  String get adminRoleClub => 'Club admin';

  @override
  String adminScopeClubs(String clubs) {
    return 'Clubs: $clubs';
  }

  @override
  String get adminNavDashboard => 'Overview';

  @override
  String get adminNavCoaches => 'Coaches';

  @override
  String get adminNavClubs => 'Clubs';

  @override
  String get adminNavSports => 'Sports';

  @override
  String get adminNavGroups => 'Groups';

  @override
  String get adminNavModeration => 'Moderation';

  @override
  String get adminNavAudit => 'Audit log';

  @override
  String get adminNavAdmins => 'Administrators';

  @override
  String get adminStatParents => 'Parents';

  @override
  String get adminStatChildren => 'Children';

  @override
  String get adminStatCoaches => 'Coaches';

  @override
  String get adminStatClubs => 'Clubs';

  @override
  String get adminStatGroups => 'Active groups';

  @override
  String get adminStatTrainings => 'Trainings (7 days)';

  @override
  String get adminStatMatches => 'Upcoming matches';

  @override
  String get adminStatPendingCoaches => 'Coach applications';

  @override
  String get adminStatPendingRequests => 'Membership requests';

  @override
  String get adminStatReports => 'Open reports';

  @override
  String get adminNeedsAttention => 'Needs attention';

  @override
  String get adminSearch => 'Search…';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminColName => 'Name';

  @override
  String get adminColStatus => 'Status';

  @override
  String get adminColClubs => 'Clubs';

  @override
  String get adminColSports => 'Sports';

  @override
  String get adminColGroups => 'Groups';

  @override
  String get adminColApplied => 'Applied';

  @override
  String get adminColActions => 'Actions';

  @override
  String get adminColAddress => 'Address';

  @override
  String get adminColMembers => 'Members';

  @override
  String get adminColCoach => 'Coach';

  @override
  String get adminColSchedule => 'Schedule';

  @override
  String get adminColRequests => 'Requests';

  @override
  String get adminColUpcoming => 'Upcoming trainings';

  @override
  String get adminColCategory => 'Category';

  @override
  String get adminColAgeMin => 'Min. age';

  @override
  String get adminColCert => 'Certificate';

  @override
  String get adminColActive => 'Active';

  @override
  String get adminColWhen => 'When';

  @override
  String get adminColActor => 'Actor';

  @override
  String get adminColAction => 'Action';

  @override
  String get adminColTarget => 'Target';

  @override
  String get adminColDetails => 'Details';

  @override
  String get adminColReason => 'Reason';

  @override
  String get adminColContent => 'Content';

  @override
  String adminPageOf(int pageStart, int pageEnd, int total) {
    return '$pageStart–$pageEnd of $total';
  }

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminSuspend => 'Suspend';

  @override
  String get adminRevoke => 'Revoke access';

  @override
  String get adminReinstate => 'Reinstate';

  @override
  String get adminReasonTitle => 'Reason (required)';

  @override
  String get adminCoachStatusPending => 'Pending';

  @override
  String get adminCoachStatusApproved => 'Approved';

  @override
  String get adminCoachStatusRejected => 'Rejected';

  @override
  String get adminCoachStatusSuspended => 'Suspended';

  @override
  String get adminCoachStatusRevoked => 'Revoked';

  @override
  String get adminCoachUpdated => 'Coach status updated';

  @override
  String get adminAssignClub => 'Assign to club';

  @override
  String get adminUnassignClub => 'Remove from club';

  @override
  String get adminNewClub => 'New club';

  @override
  String get adminEditClub => 'Edit club';

  @override
  String get adminArchive => 'Archive';

  @override
  String get adminRestore => 'Restore';

  @override
  String get adminArchived => 'Archived';

  @override
  String get adminLat => 'Latitude';

  @override
  String get adminLng => 'Longitude';

  @override
  String get adminPhone => 'Phone';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminSaved => 'Saved';

  @override
  String get adminNewSport => 'New sport';

  @override
  String get adminEditSport => 'Edit sport';

  @override
  String get adminSportId => 'Identifier (latin)';

  @override
  String get adminSportOrder => 'Order';

  @override
  String get adminReadOnly => 'Read-only — only platform admins can edit.';

  @override
  String get adminHide => 'Hide';

  @override
  String get adminKeep => 'Keep';

  @override
  String get adminReportOpen => 'Open';

  @override
  String get adminReportResolved => 'Hidden';

  @override
  String get adminReportDismissed => 'Kept';

  @override
  String get adminModerationEmpty => 'No reports';

  @override
  String get adminModerationNote =>
      'Media opens only through short-lived signed links. Children\'s personal data isn\'t shown here.';

  @override
  String get adminMakeClubAdmin => 'Make club admin';

  @override
  String get adminRemoveAdmin => 'Remove admin rights';

  @override
  String get adminRoleUpdated => 'Role updated';

  @override
  String get adminGrantHint =>
      'The first platform admin is granted only via the server script (functions/scripts/grant-platform-admin.mjs).';

  @override
  String get adminNotAdminTitle => 'You are not an administrator';

  @override
  String get adminNotAdminBody => 'This account can\'t use the admin dashboard. Please use the mobile app.';

  @override
  String get adminChildDataNote => 'Admins don\'t see children\'s names or medical data — only counts.';

  @override
  String get adminEmpty => 'No records';
}
