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
  String get validationInvalidPhone =>
      'Enter a valid mobile number (5XX XXX XXX)';

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
  String get validationPhotoConsentRequired =>
      'Confirm the photo consent condition';

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
  String get onboardingBody1 =>
      'Time, place and coach — always at hand. Hear about changes instantly.';

  @override
  String get onboardingTitle2 => 'A direct line to the coach';

  @override
  String get onboardingBody2 =>
      'Group chat for parents and coaches, photos from every session.';

  @override
  String get onboardingTitle3 => 'Certificates and payments, safely';

  @override
  String get onboardingBody3 =>
      'Medical certificates in private storage, reminders for expiry dates and fees.';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get phoneTitle => 'Sign in with your phone';

  @override
  String get phoneSubtitle =>
      'We\'ll text you a one-time code. No password needed.';

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
  String get demoAccountsSubtitle =>
      'Fictional data — no real SMS, payments or medical information.';

  @override
  String get demoPendingCoach => 'Coach (pending approval)';

  @override
  String get guestBrowse => 'Browse clubs without signing in';

  @override
  String get termsNote =>
      'By continuing you agree to the Terms and Privacy Policy.';

  @override
  String get registerTitle => 'Create your profile';

  @override
  String get chooseRole => 'Who are you?';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleParentDesc =>
      'Children\'s trainings, coach chat, certificates and payments';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleCoachDesc =>
      'Manage groups and plan trainings. Requires club approval.';

  @override
  String get roleChild => 'Child';

  @override
  String get roleChildDesc =>
      'Parents create profiles for under-14s. Accounts for ages 14–17 are coming soon.';

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
  String get childAccountUnsupported =>
      'Independent child accounts aren\'t available yet. Use a parent\'s account.';

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
  String get noChildrenBody =>
      'Create a profile and pick a sport — we\'ll take care of the rest.';

  @override
  String get addChild => 'Add child';

  @override
  String noGroupTitle(String name) {
    return '$name isn\'t in a group yet';
  }

  @override
  String get noGroupBody =>
      'Find a club on the map and send a membership request.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years old',
      one: '1 year old',
    );
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
  String get cancelTrainingConfirm =>
      'Cancel this training? Parents in the group will be notified.';

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
  String get photoConsentAllGiven =>
      'Every child in the group has parental photo consent.';

  @override
  String get photoConsentConfirm =>
      'I confirm no child without consent appears in these photos';

  @override
  String get selectVenue => 'Choose a venue';

  @override
  String get descriptionHint =>
      'What will you practise? e.g. passing, shooting…';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String get roster => 'Group roster';

  @override
  String get noGroupsCoach =>
      'No groups assigned yet. Contact your club administrator.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
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
  String get certConsentAgree =>
      'I consent to processing the certificate as described above';

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
  String get deleteCertificateConfirm =>
      'Delete this certificate? The file is removed from storage permanently.';

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
  String get certRemindersNote =>
      'You\'ll be reminded 14 and 3 days before expiry and on the day itself.';

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
  String get notificationSettingsHint =>
      'Choose which notifications you receive.';

  @override
  String get pushDemoNote =>
      'Demo mode sends no push notifications — they appear in-app instead.';

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
  String get chargeGroupHint =>
      'A payment is created for every child in the group.';

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
  String get smsMockNote =>
      'Demo: a mock SMS provider is used. No real SMS is sent.';

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
  String get reminderSchedule =>
      'SMS: 5 days before and the day before, 10:00 (Tbilisi)';

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
  String get privacyBody =>
      'Children\'s data is visible only to parents and approved coaches of their group.';

  @override
  String get childProfile => 'Child profile';

  @override
  String get birthDateLabel => 'Date of birth';

  @override
  String get ownAccountTitle => 'Own account (14+)';

  @override
  String get ownAccountDisabled =>
      'Will be enabled once the age and consent policy is legally confirmed.';

  @override
  String get photoConsentLabel => 'Consent to training photos';

  @override
  String get photoConsentHelp =>
      'Without consent your child must not appear in coach photos.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '1 group',
    );
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
  String get offlineBanner =>
      'You\'re offline — showing saved data. Changes can\'t be saved.';

  @override
  String get backOnline => 'Back online';

  @override
  String get permissionDeniedTitle => 'Access restricted';

  @override
  String get permissionDeniedBody =>
      'You don\'t have permission to view this page.';

  @override
  String get validationCancelReasonRequired => 'Choose a cancellation reason';

  @override
  String get validationCancelReasonTooShort =>
      'The reason must be at least 5 characters';

  @override
  String get validationWeekdaysRequired => 'Choose at least one weekday';

  @override
  String get validationEndBeforeStart => 'End date is before the start date';

  @override
  String get validationSeriesTooLong => 'A schedule can last at most 1 year';

  @override
  String get validationSeriesOverlap =>
      'This group already has a schedule on these days at this time';

  @override
  String get validationOpponentRequired => 'Enter the opponent team';

  @override
  String get validationGroupNameRequired => 'Enter a group name';

  @override
  String get validationGroupAgeRange => 'Ages 3–18, minimum ≤ maximum';

  @override
  String get validationInvalidGroupCode =>
      'Invalid code or the group isn\'t active';

  @override
  String get validationInviteExists => 'An invitation is already pending';

  @override
  String get validationInviteClosed => 'This invitation is already closed';

  @override
  String get validationLinkChildRequired => 'Choose a child';

  @override
  String get validationNotMember => 'The child isn\'t in this group';

  @override
  String get validationRsvpClosed =>
      'The training has started — the response can\'t be changed';

  @override
  String get validationTrainingCancelled => 'The training is cancelled';

  @override
  String get validationAttendanceTooEarly =>
      'Attendance can be marked from one hour before the start';

  @override
  String get validationFeedbackEmpty =>
      'Rate at least one category or write a comment';

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
  String get validationRateLimited =>
      'Too many attempts. Please try again later.';

  @override
  String get validationAlreadyReported => 'You\'ve already reported this';

  @override
  String get validationReasonRequired =>
      'Give a reason (at least 5 characters)';

  @override
  String get validationLocationOutsideGeorgia =>
      'The location is outside Georgia';

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
  String get cancelReasonHint =>
      'A reason is required — parents will see it in the calendar and chat.';

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
  String get seriesHorizonNote =>
      'Trainings are created 8 weeks ahead and extended automatically.';

  @override
  String seriesConflicts(int count) {
    return '$count dates skipped — a training already exists at that time';
  }

  @override
  String get rsvpTitle => 'Coming to training?';

  @override
  String get rsvpYes => 'Will attend';

  @override
  String get rsvpNo => 'Will not attend';

  @override
  String get rsvpMaybe => 'Not sure yet';

  @override
  String get rsvpReasonHint => 'Reason (optional)';

  @override
  String get rsvpSaved => 'Response sent to the coach';

  @override
  String get rsvpClosedNote =>
      'The training has started — the response is final.';

  @override
  String get rsvpNotice =>
      'A response isn\'t attendance — the coach records actual attendance.';

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
  String get progressPrivacyNote =>
      'Only you and the child\'s coaches see this. No rankings are published.';

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
  String get inviteLinkHint =>
      'If the child is already registered, pick them — no duplicate will be created.';

  @override
  String inviteAsNew(String name) {
    return 'Add as a new child ($name)';
  }

  @override
  String get inviteMediaConsent =>
      'I agree that my child may appear in team photos and videos';

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
  String get groupCodeHint =>
      'Parents enter the code in their child\'s profile — you approve the request.';

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
  String get addChildSearchNote =>
      'The invitation goes to the parent. The child joins only after the parent confirms.';

  @override
  String get addChildManualNote =>
      'The parent gets an invitation. Until they confirm you only see the name.';

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
  String get mediaConsentConfirm =>
      'I confirm: children without parental consent don\'t appear in this media';

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
  String get mediaNoDownload =>
      'Downloading is disabled to protect children\'s privacy.';

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
  String get paymentsNoOnline =>
      'Online payment isn\'t available yet — pay as your club instructs.';

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
  String get privacyPhotoVisible =>
      'Show my photo to my groups\' coaches/parents';

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
  String get deleteImpactPayments =>
      'Payment history is kept anonymised for the club\'s accounting.';

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
  String get adminSignInBody =>
      'Administrators only. Permissions are checked on the server.';

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
  String get adminNotAdminBody =>
      'This account can\'t use the admin dashboard. Please use the mobile app.';

  @override
  String get adminChildDataNote =>
      'Admins don\'t see children\'s names or medical data — only counts.';

  @override
  String get adminEmpty => 'No records';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageGeorgian => 'ქართული';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChanged => 'Language changed';

  @override
  String get languageHint =>
      'The language doesn\'t depend on your phone\'s language. Text written by coaches isn\'t translated.';

  @override
  String get certCurrent => 'Current certificate';

  @override
  String get certReplace => 'Replace certificate';

  @override
  String get certReplaced => 'Replaced by a newer one';

  @override
  String get certPreview => 'Preview';

  @override
  String get certDownload => 'Download';

  @override
  String certExpiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String certAppliesTo(String sport) {
    return 'Applies to: $sport';
  }

  @override
  String get certAllSports => 'All sports';

  @override
  String get certSportLabel => 'Which sport it covers';

  @override
  String get certTakePhoto => 'Take a photo';

  @override
  String get certChooseFile => 'Choose a file';

  @override
  String get certSensitiveWarning =>
      'Medical documents are sensitive. Don\'t share them and delete the file when you no longer need it.';

  @override
  String get certDownloadConfirm => 'Download';

  @override
  String get certAccessLogged => 'This access is recorded in the security log';

  @override
  String get certAccessHistory => 'Access history';

  @override
  String certAccessView(String who, String when) {
    return '$who — viewed, $when';
  }

  @override
  String certAccessDownload(String who, String when) {
    return '$who — downloaded, $when';
  }

  @override
  String get certPdfPreview => 'PDF document';

  @override
  String get certSavedTemp =>
      'The file is stored temporarily and removed from the app after sharing.';

  @override
  String get certNoAdminAccess =>
      'Administrators can\'t see medical documents — only statuses.';

  @override
  String get rosterTitle => 'Students';

  @override
  String get rosterSearch => 'Search students';

  @override
  String get rosterSortName => 'By name';

  @override
  String get rosterSortAge => 'By age';

  @override
  String get rosterSortAttendance => 'By attendance';

  @override
  String get rosterSortCert => 'By certificate';

  @override
  String get rosterFilterAll => 'All';

  @override
  String get rosterFilterCertIssues => 'Certificate issues';

  @override
  String get rosterFilterLowAttendance => 'Low attendance';

  @override
  String get rosterEmptyFilter => 'No students match this filter';

  @override
  String get rosterStudentDetail => 'Student';

  @override
  String rosterAttendanceRate(int percent) {
    return 'Attendance $percent%';
  }

  @override
  String get rosterNoAttendance => 'No attendance yet';

  @override
  String rosterCount(int count) {
    return '$count students';
  }

  @override
  String get attendanceSave => 'Save';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String attendanceUnsaved(int count) {
    return '$count unsaved changes';
  }

  @override
  String get attendanceDiscard => 'Discard';

  @override
  String get attendanceEditNote =>
      'You can edit recorded attendance — every change is saved.';

  @override
  String get attendanceByStudent => 'By student';

  @override
  String get attendanceByGroup => 'By group';

  @override
  String get attendanceReportTitle => 'Attendance report';

  @override
  String attendanceSessions(int count) {
    return '$count trainings';
  }

  @override
  String get attendanceMarkAll => 'All';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportRoster => 'Student list';

  @override
  String get exportTrainingSheet => 'Training attendance sheet';

  @override
  String get exportMonthly => 'Monthly attendance report';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportIncludeCompliance =>
      'Include certificate status (only if needed)';

  @override
  String get exportWarning =>
      'The file contains children\'s personal data. Share it only with people who need it and delete it afterwards.';

  @override
  String get exportConfirm => 'I understand, export';

  @override
  String exportReady(String name) {
    return 'File ready: $name';
  }

  @override
  String get exportChooseTraining => 'Choose a training';

  @override
  String get exportChooseMonth => 'Choose a month';

  @override
  String get exportColStudent => 'Student';

  @override
  String get exportColGroup => 'Group';

  @override
  String get exportColDate => 'Date';

  @override
  String get exportColStatus => 'Attendance';

  @override
  String get exportColAge => 'Age';

  @override
  String get exportColCert => 'Certificate';

  @override
  String get exportColRate => 'Attendance %';

  @override
  String exportGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String get exportConfidential => 'Confidential — internal use only';

  @override
  String exportPage(int n) {
    return 'Page $n';
  }

  @override
  String get plansTitle => 'Training plans';

  @override
  String get plansEmpty => 'No training plans yet';

  @override
  String get planNew => 'New plan';

  @override
  String get planEdit => 'Edit plan';

  @override
  String get planTitleLabel => 'Title';

  @override
  String get planDescription => 'Description';

  @override
  String get planType => 'Plan type';

  @override
  String get planTypeSeasonal => 'Seasonal';

  @override
  String get planTypeMonthly => 'Monthly';

  @override
  String get planTypeWeekly => 'Weekly';

  @override
  String get planTypeExercise => 'Individual exercise';

  @override
  String get planTypeHomework => 'Homework';

  @override
  String get planGroups => 'Groups';

  @override
  String get planStart => 'Start';

  @override
  String get planEnd => 'End';

  @override
  String get planStatusDraft => 'Draft';

  @override
  String get planStatusPublished => 'Published';

  @override
  String get planStatusArchived => 'Archived';

  @override
  String get planSaveDraft => 'Save draft';

  @override
  String get planPublish => 'Publish';

  @override
  String get planArchive => 'Archive';

  @override
  String get planUnpublish => 'Back to draft';

  @override
  String get planPublished => 'Plan published — parents were notified';

  @override
  String get planSaved => 'Plan saved';

  @override
  String get planArchived => 'Plan archived';

  @override
  String get planExercises => 'Exercises';

  @override
  String get planAddExercise => 'Add exercise';

  @override
  String get planNoExercises => 'Add at least one exercise';

  @override
  String planViews(int count) {
    return 'Viewed by $count parents';
  }

  @override
  String planCompletion(String done, int total) {
    return 'Completed: $done / $total';
  }

  @override
  String get planSelfReported =>
      'Completion is self-reported by parents — not verified by the coach.';

  @override
  String planPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String planOpenEnded(String start) {
    return 'From $start';
  }

  @override
  String get planHomeworkDue => 'Homework before the next training';

  @override
  String get planActive => 'Active plans';

  @override
  String get planDraftsOnlyCoach => 'Parents can\'t see drafts';

  @override
  String get exerciseName => 'Exercise name';

  @override
  String get exerciseDescription => 'Description';

  @override
  String get exerciseInstructions => 'Instructions';

  @override
  String get exerciseDuration => 'Duration (min)';

  @override
  String get exerciseReps => 'Repetitions';

  @override
  String get exerciseSets => 'Sets';

  @override
  String get exerciseRest => 'Rest (sec)';

  @override
  String get exerciseMedia => 'Media';

  @override
  String get exerciseAddLink => 'Add link';

  @override
  String get exerciseLinkHint => 'https://…';

  @override
  String get exerciseLinkInvalid => 'The link must start with https://';

  @override
  String get exerciseOpenLink => 'Open link';

  @override
  String get exerciseExternalWarning =>
      'The link opens in your browser. The app doesn\'t share your data with it.';

  @override
  String get exerciseMoveUp => 'Move up';

  @override
  String get exerciseMoveDown => 'Move down';

  @override
  String get exerciseRemove => 'Remove';

  @override
  String exerciseSummary(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String exerciseMinutes(int n) {
    return '$n min';
  }

  @override
  String exerciseRestSec(int n) {
    return 'Rest $n s';
  }

  @override
  String get progressNotStarted => 'Not started';

  @override
  String get progressInProgress => 'In progress';

  @override
  String get progressCompleted => 'Completed';

  @override
  String progressFor(String child) {
    return '$child\'s progress';
  }

  @override
  String get validationPlanTitle => 'Enter a title';

  @override
  String get validationPlanGroups => 'Choose at least one group';

  @override
  String get validationPlanExercises => 'Add at least one exercise';

  @override
  String get validationPlanDates => 'The end is before the start';

  @override
  String get validationExerciseName => 'Enter the exercise name';

  @override
  String get validationLink => 'Invalid link (https:// only)';

  @override
  String get validationTooManyExercises => 'At most 50 exercises';

  @override
  String get validationTooManyMedia => 'At most 10 items per exercise';

  @override
  String get validationPlanNotDraft =>
      'Only drafts can be edited before publishing';

  @override
  String get payProofAction => 'Mark as paid / submit proof';

  @override
  String get payProofTitle => 'Payment confirmation';

  @override
  String get payProofDate => 'Payment date';

  @override
  String get payProofReference => 'Transaction / reference number';

  @override
  String get payProofNote => 'Note';

  @override
  String get payProofReceipt => 'Receipt (JPG, PNG or PDF, up to 10 MB)';

  @override
  String get payProofSubmit => 'Submit for verification';

  @override
  String get payProofSubmitted => 'Submitted — the coach will verify it';

  @override
  String payProofUploading(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get payProofHint =>
      'Your confirmation doesn\'t mark the payment as paid by itself — an authorized coach or club admin verifies it.';

  @override
  String get payStateAwaiting => 'Awaiting verification';

  @override
  String get payStateUnderReview => 'Under review';

  @override
  String get payStateRejected => 'Rejected';

  @override
  String get payStatePaid => 'Paid';

  @override
  String payRejectedReason(String reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String get payResubmit => 'Submit again';

  @override
  String paySubmittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String get payViewReceipt => 'View receipt';

  @override
  String payVerifiedBy(String name, String date) {
    return 'Verified by $name, $date';
  }

  @override
  String get payReviewQueue => 'Payment confirmations';

  @override
  String get payReviewEmpty => 'Nothing to verify';

  @override
  String get payApprove => 'Approve';

  @override
  String get payReject => 'Reject';

  @override
  String get payApproved => 'Payment approved — the parent was notified';

  @override
  String get payRejectedSnack => 'Rejected — the parent was told why';

  @override
  String get payRejectReasonTitle => 'Reason for rejecting';

  @override
  String get payNotReviewer =>
      'Only assigned coaches and club admins can verify payments.';

  @override
  String get payHistory => 'History';

  @override
  String get payEventSubmitted => 'Submitted';

  @override
  String get payEventResubmitted => 'Resubmitted';

  @override
  String get payEventReviewStarted => 'Review started';

  @override
  String get payEventApproved => 'Approved';

  @override
  String get payEventRejected => 'Rejected';

  @override
  String get payEventViewed => 'Receipt viewed';

  @override
  String get payPaymentManagers => 'Payment reviewers';

  @override
  String payProofFor(String child, String amount, String due) {
    return '$child · $amount · $due';
  }

  @override
  String get validationProofExists =>
      'A confirmation for this payment is already being reviewed';

  @override
  String get validationProofClosed =>
      'This confirmation has already been decided';

  @override
  String get validationPaymentClosed => 'This payment is already closed';

  @override
  String get validationReceiptRequired => 'Attach a receipt';

  @override
  String get validationDateFuture => 'The date is in the future';

  @override
  String get notifPaymentProofSubmitted => 'Payment confirmation to verify';

  @override
  String get notifPaymentProofApproved => 'Payment approved';

  @override
  String get notifPaymentProofRejected => 'Payment confirmation rejected';

  @override
  String get notifTrainingPlanPublished => 'New training plan';

  @override
  String notifBodyPlan(String title, String group) {
    return '$title · $group';
  }

  @override
  String notifBodyProof(String child, String amount) {
    return '$child · $amount';
  }

  @override
  String notifBodyProofRejected(String child, String reason) {
    return '$child · $reason';
  }

  @override
  String notifBodyCertDays(String child, String days) {
    return '$child — $days days left';
  }

  @override
  String notifBodyCertExpired(String child) {
    return '$child — the certificate has expired';
  }

  @override
  String sysTrainingCancelled(String when, String reason) {
    return 'Training cancelled ($when). Reason: $reason';
  }

  @override
  String sysTrainingMoved(String from, String to) {
    return 'Training moved: $from → $to';
  }

  @override
  String sysMatchCreated(String opponent, String when) {
    return 'New match: $opponent, $when';
  }

  @override
  String sysMatchMoved(String from, String to) {
    return 'Match moved: $from → $to';
  }

  @override
  String sysMatchCancelled(String opponent, String reason) {
    return 'Match ($opponent) cancelled. Reason: $reason';
  }

  @override
  String get sysScheduleCreated => 'A training schedule was added';

  @override
  String sysScheduleChanged(String from) {
    return 'The training schedule changes from $from';
  }

  @override
  String sysPlanPublished(String title) {
    return 'Training plan published: $title';
  }

  @override
  String get sysScheduleReason => 'Schedule changed';

  @override
  String get adminNavCompliance => 'Certificates';

  @override
  String get adminNavAttendance => 'Attendance';

  @override
  String get adminNavPlans => 'Training plans';

  @override
  String get adminNavPayments => 'Payments';

  @override
  String get adminNavSettings => 'Settings';

  @override
  String get adminComplianceNote =>
      'Status counts only — no documents or children\'s names.';

  @override
  String get adminColValid => 'Valid';

  @override
  String get adminColExpiring => 'Expiring';

  @override
  String get adminColExpired => 'Expired';

  @override
  String get adminColMissing => 'Missing';

  @override
  String get adminColRate => 'Attendance';

  @override
  String get adminColSessions => 'Trainings';

  @override
  String get adminColPlans => 'Plans';

  @override
  String get adminColPlanType => 'Type';

  @override
  String get adminColAmount => 'Amount';

  @override
  String get adminColSubmitted => 'Submitted';

  @override
  String get adminColReviewers => 'Reviewers';

  @override
  String get adminPaymentQueueNote =>
      'Receipts open through a temporary link and every view is logged.';

  @override
  String get adminSetReviewers => 'Assign reviewers';

  @override
  String get adminLanguage => 'Interface language';

  @override
  String get adminRosterNote => 'Student counts per group — without names.';

  @override
  String get adminMonth => 'Month';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get exportSchedule => 'Export schedule to calendar';

  @override
  String get calendarNothingToExport => 'No upcoming trainings to export';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsCoachTitle => 'Coach contact';

  @override
  String get contactsParentsTitle => 'Parents and guardians';

  @override
  String contactCallName(String name) {
    return 'Call $name';
  }

  @override
  String get contactNoPhone => 'No phone number';

  @override
  String get contactCoachAction => 'Contact coach';

  @override
  String get contactParentsAction => 'Parents\' contacts';

  @override
  String get contactPrivacyCoach =>
      'Only coaches of this group see these numbers. Use them for team matters only.';

  @override
  String get contactPrivacyParent =>
      'The coach of your child\'s group. Other parents\' numbers are never shown.';

  @override
  String contactParentOf(String names) {
    return 'Parent of $names';
  }

  @override
  String get contactsEmpty => 'No contacts available';

  @override
  String get relationMother => 'Mother';

  @override
  String get relationFather => 'Father';

  @override
  String get relationGuardian => 'Guardian';

  @override
  String get relationGrandparent => 'Grandparent';

  @override
  String get relationOther => 'Other relative';

  @override
  String receiptSeenBy(int read, int total) {
    return 'Seen by $read of $total parents';
  }

  @override
  String receiptSeenShort(int read, int total) {
    return 'Seen: $read/$total';
  }

  @override
  String receiptAckShort(int acked, int total) {
    return 'Acknowledged: $acked/$total';
  }

  @override
  String get receiptsTitle => 'Message status';

  @override
  String get receiptNotSeen => 'Not seen';

  @override
  String get receiptSeen => 'Seen';

  @override
  String get receiptAcknowledged => 'Acknowledged';

  @override
  String receiptSeenAt(String time) {
    return 'Seen $time';
  }

  @override
  String receiptAckAt(String time) {
    return 'Acknowledged $time';
  }

  @override
  String get receiptPrivacy =>
      'Only you can see who read this message. Parents who joined later are not counted.';

  @override
  String get chatAckToggle => 'Require acknowledgment';

  @override
  String get chatAckRequired => 'Acknowledgment required';

  @override
  String get chatAckButton => 'Acknowledged';

  @override
  String get chatAckDone => 'Confirmed';

  @override
  String get chatAckSent => 'Acknowledgment sent';

  @override
  String get dashboardAcksTitle => 'Waiting for your confirmation';

  @override
  String dashboardAcksBody(int count, String groups) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0 · $groups';
  }

  @override
  String get notifAckRequested => 'Please confirm you have read this';

  @override
  String get videoPlay => 'Play';

  @override
  String get videoPause => 'Pause';

  @override
  String get videoBack10 => 'Back 10 seconds';

  @override
  String get videoForward10 => 'Forward 10 seconds';

  @override
  String get videoFullscreen => 'Full screen';

  @override
  String get videoExitFullscreen => 'Exit full screen';

  @override
  String get videoLoading => 'Loading video…';

  @override
  String get videoBuffering => 'Buffering…';

  @override
  String get videoError => 'The video could not be played.';

  @override
  String get videoPosition => 'Video position';

  @override
  String get downloadAction => 'Download';

  @override
  String get downloadTitle => 'Download media';

  @override
  String get downloadNotice =>
      'Downloading saves a copy on your device. It cannot be removed remotely, so please share it responsibly.';

  @override
  String downloadProgress(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get downloadFailed =>
      'Download failed. Check your connection and try again.';

  @override
  String downloadDone(String name) {
    return 'Ready: $name. Choose where to keep it.';
  }

  @override
  String get downloadDenied => 'You no longer have access to this file.';

  @override
  String get downloadStorageError =>
      'The file could not be saved on this device.';

  @override
  String get downloadPolicyOff => 'Downloads are turned off for this group.';

  @override
  String get adminNavMediaDownloads => 'Media downloads';

  @override
  String get adminMediaPolicy => 'Parents may download photos and videos';

  @override
  String get adminMediaDownloadsNote =>
      'Authorized downloads of coach photos and videos. A downloaded copy cannot be revoked.';

  @override
  String get adminColPost => 'Post';

  @override
  String get adminColUser => 'User';

  @override
  String get adminColDownloads => 'Downloads';

  @override
  String get studentProfileTitle => 'Student profile';

  @override
  String get studentProfileOpen => 'Profile';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabTrainings => 'Trainings';

  @override
  String get tabPlans => 'Plans';

  @override
  String get tabMedia => 'Media';

  @override
  String get tabMatches => 'Matches';

  @override
  String get profileSportsGroups => 'Sports and groups';

  @override
  String get profileCoaches => 'Coaches';

  @override
  String get profileUpcomingTrainings => 'Upcoming trainings';

  @override
  String get profileUpcomingMatches => 'Upcoming matches';

  @override
  String get profileTrainingHistory => 'Training history';

  @override
  String get profileAttendance => 'Attendance';

  @override
  String get profileHomework => 'Homework';

  @override
  String get profileMatchResults => 'Match results';

  @override
  String get profileCertificate => 'Medical certificate';

  @override
  String get profilePayments => 'Payments';

  @override
  String get profileEmpty => 'Nothing here yet';

  @override
  String get profileCoachScope => 'Only data from your groups is shown.';

  @override
  String contactCoachAbout(String child) {
    return 'Message the coach about $child';
  }

  @override
  String threadAbout(String child) {
    return 'About: $child';
  }

  @override
  String threadPrivacy(String child) {
    return 'Only $child\'s parents and this coach see this conversation.';
  }

  @override
  String get threadEmpty => 'No messages yet. Write the first one.';

  @override
  String get threadsTitle => 'Messages about students';

  @override
  String get chooseCoach => 'Choose a coach';

  @override
  String get notifChildMessage => 'Message about a child';

  @override
  String get matchResultEnter => 'Enter result';

  @override
  String get matchResultCorrect => 'Correct result';

  @override
  String get matchResultTitle => 'Final score';

  @override
  String get matchResultOurTeam => 'Our team';

  @override
  String get matchResultOpponent => 'Opponent';

  @override
  String get matchResultSummary => 'Summary (optional)';

  @override
  String matchResultFinishedAt(String time) {
    return 'Finished: $time';
  }

  @override
  String get matchWin => 'Win';

  @override
  String get matchDraw => 'Draw';

  @override
  String get matchLoss => 'Loss';

  @override
  String get matchResultCorrected => 'Corrected';

  @override
  String get matchResultSaved => 'Result saved';

  @override
  String get matchResultHistory => 'Correction history';

  @override
  String get matchResultLatest => 'Latest result';

  @override
  String get matchResultNotice =>
      'Parents are notified when the first result is saved. Corrections are logged.';

  @override
  String get notifMatchResult => 'Match result';

  @override
  String notifBodyMatchResult(String opponent, String our, String their) {
    return '$opponent: $our–$their';
  }

  @override
  String get validationResultScore => 'Enter scores from 0 to 999.';

  @override
  String get validationResultNotStarted =>
      'You can enter the result once the match has started.';

  @override
  String get validationResultCancelled => 'A cancelled match has no result.';

  @override
  String get validationResultCompletedAt =>
      'The finish time must be between the match start and now.';

  @override
  String get payDownloadReceipt => 'Download receipt';

  @override
  String get payProofNotFound =>
      'The request was not found or has already been handled.';

  @override
  String get payEventDownloaded => 'Receipt downloaded by a reviewer';

  @override
  String get roleStudent => 'Student';

  @override
  String get continueAsStudent => 'Continue as Student';

  @override
  String get studentDemoNote =>
      'Student sign-in is available in demo mode only.';

  @override
  String studentWelcome(String name) {
    return 'Hi, $name! Ready to play?';
  }

  @override
  String get studentNavHome => 'Home';

  @override
  String get studentNavBrain => 'Brain Academy';

  @override
  String get studentNavProgress => 'Progress';

  @override
  String get studentMySports => 'My sports';

  @override
  String get studentMyCoach => 'My coach';

  @override
  String get studentNextTraining => 'Next training';

  @override
  String get studentNoTraining => 'No training planned';

  @override
  String get studentUpcomingMatches => 'Upcoming matches';

  @override
  String get studentMatchResults => 'Match results';

  @override
  String get studentPlans => 'My training plans';

  @override
  String get studentHomework => 'Homework';

  @override
  String get studentAttendance => 'My attendance';

  @override
  String studentAttendanceRate(int percent) {
    return 'I came to $percent% of trainings';
  }

  @override
  String get studentAchievements => 'Achievements';

  @override
  String get studentNothing => 'Nothing yet';

  @override
  String get studentChallenges => 'Coach challenges';

  @override
  String challengeDue(String date) {
    return 'Due $date';
  }

  @override
  String get challengeDone => 'Done';

  @override
  String get challengeOpen => 'To do';

  @override
  String get challengeOverdue => 'Overdue';

  @override
  String get brainAcademy => 'Brain Academy';

  @override
  String get brainTagline => 'Train your brain like an athlete';

  @override
  String get brainNotIq =>
      'Points are for practice and fun — this is not an IQ test.';

  @override
  String get gameMemoryMatch => 'Memory Match';

  @override
  String get gameLogicQuest => 'Logic Quest';

  @override
  String get gameSmartPlay => 'Smart Play';

  @override
  String get gameQuickMind => 'Quick Mind';

  @override
  String get gameSequenceMaster => 'Sequence Master';

  @override
  String get gamePathFinder => 'Path Finder';

  @override
  String get gameDescMemory => 'Find matching sports cards';

  @override
  String get gameDescLogic => 'Crack the shape patterns';

  @override
  String get gameDescSmart => 'Choose the best move on the pitch';

  @override
  String get gameDescQuick => 'Spot the right symbol fast';

  @override
  String get gameDescSequence => 'Remember and repeat';

  @override
  String get gameDescPath => 'Guide the ball to the goal';

  @override
  String get gameHowToMemory =>
      'Tap two cards. Matching cards stay open. Find all pairs in as few tries as you can.';

  @override
  String get gameHowToLogic =>
      'Look at the row and pick the shape that belongs where the “?” is.';

  @override
  String get gameHowToSmart =>
      'You have the ball (yellow ring). Pick the best pass or move, then read why.';

  @override
  String get gameHowToQuick =>
      'The target is shown on top. Tap the same shape in the same colour before time runs out.';

  @override
  String get gameHowToSequence =>
      'Watch the colours light up, then tap them in the same order. The row grows every round.';

  @override
  String get gameHowToPath =>
      'Use the arrows or swipe to move the ball to the goal. Walls and cones block the way.';

  @override
  String get diffEasy => 'Easy';

  @override
  String get diffMedium => 'Medium';

  @override
  String get diffHard => 'Hard';

  @override
  String gameLevel(int level) {
    return 'Level $level';
  }

  @override
  String get gameStart => 'Start game';

  @override
  String get gamePause => 'Pause';

  @override
  String get gameResume => 'Resume';

  @override
  String get gameRestart => 'Restart';

  @override
  String get gameQuit => 'Quit';

  @override
  String get gamePaused => 'Game paused';

  @override
  String gameScore(int score) {
    return 'Score: $score';
  }

  @override
  String gameTime(String time) {
    return 'Time: $time';
  }

  @override
  String gameAttempts(int count) {
    return 'Tries: $count';
  }

  @override
  String gameAccuracy(int percent) {
    return 'Accuracy: $percent%';
  }

  @override
  String get gameComplete => 'Well done!';

  @override
  String get gameTryAgain => 'Good try! Play again?';

  @override
  String get gameNextLevel => 'Next level';

  @override
  String get gamePlayAgain => 'Play again';

  @override
  String get gameNewBadge => 'New badge!';

  @override
  String gameBestScore(int score) {
    return 'Best: $score';
  }

  @override
  String get gameCorrect => 'Correct!';

  @override
  String get gameWrong => 'Not quite — keep going';

  @override
  String get gameSaveFailed => 'The result could not be saved.';

  @override
  String gameRound(int n, int total) {
    return 'Round $n/$total';
  }

  @override
  String get gameWatch => 'Watch carefully…';

  @override
  String get gameYourTurn => 'Your turn!';

  @override
  String gameLives(int n) {
    return 'Lives: $n';
  }

  @override
  String gameMoves(int n) {
    return 'Moves: $n';
  }

  @override
  String get gameSound => 'Sound effects';

  @override
  String get gameInstructions => 'How to play';

  @override
  String get gameChooseDifficulty => 'Choose difficulty';

  @override
  String get gameTimeUp => 'Time\'s up';

  @override
  String get logicWhatsMissing => 'Which one is missing?';

  @override
  String get spQuestion => 'You have the ball. What is the best move?';

  @override
  String spPassTo(String n) {
    return 'Pass to #$n';
  }

  @override
  String spPassBack(String n) {
    return 'Pass back to #$n';
  }

  @override
  String get spDribble => 'Dribble forward';

  @override
  String get spShoot => 'Shoot';

  @override
  String get spHold => 'Hold the ball';

  @override
  String get spNext => 'Next';

  @override
  String get spExplain1 =>
      '#7 is free on the wing — the defender is right in front of you, so dribbling is risky.';

  @override
  String get spExplain2 => 'You are close to goal with a clear path — shoot!';

  @override
  String get spExplain3 =>
      'Two opponents are pressing — a safe pass back to #4 keeps the ball.';

  @override
  String get spExplain4 => '#10 is marked; #11 is in open space.';

  @override
  String get spExplain5 =>
      'A pass to #9 would be cut out; #10 is free and can turn.';

  @override
  String get spExplain6 =>
      'An opponent covers #5 on the left — the pass right to #6 is safe.';

  @override
  String get spExplain7 =>
      'The middle is blocked by two defenders; #7 is free on the wing.';

  @override
  String get spExplain8 =>
      'The angle is too tight to shoot and #9 is covered; #10 is in a better spot.';

  @override
  String get spExplain9 =>
      'Three opponents crowd the middle — switching play to #2 opens space.';

  @override
  String get mazeGoal => 'Goal';

  @override
  String get mazeUp => 'Up';

  @override
  String get mazeDown => 'Down';

  @override
  String get mazeLeft => 'Left';

  @override
  String get mazeRight => 'Right';

  @override
  String get brainProgressTitle => 'My progress';

  @override
  String brainPlays(int n) {
    return '$n games played';
  }

  @override
  String get brainNoPlays => 'Not played yet';

  @override
  String get brainRecentScores => 'Recent scores';

  @override
  String get brainBadges => 'Badges';

  @override
  String brainUnlocked(String level) {
    return 'Unlocked: $level';
  }

  @override
  String get badgeFirstGame => 'First game';

  @override
  String get badgeExplorer => 'Explorer of all six games';

  @override
  String get badgeTenCompleted => '10 games completed';

  @override
  String get badgeMemoryHard => 'Memory champion';

  @override
  String get badgePerfectLogic => 'Perfect logic';

  @override
  String get badgeTactician => 'Tactician';

  @override
  String get badgeQuickReflexes => 'Lightning reflexes';

  @override
  String get badgeSequenceSeven => 'Sequence of seven';

  @override
  String get badgeMazeHard => 'Maze master';

  @override
  String get coachChallengesTitle => 'Brain Academy challenges';

  @override
  String get challengeAssign => 'Assign challenge';

  @override
  String get challengeGame => 'Game';

  @override
  String get challengeDifficulty => 'Difficulty';

  @override
  String get challengeDueDate => 'Due date (optional)';

  @override
  String get challengeNoDue => 'No due date';

  @override
  String get challengeAssigned => 'Challenge assigned';

  @override
  String get challengeRemove => 'Remove';

  @override
  String challengeCompletion(int done, int total) {
    return 'Completed: $done/$total';
  }

  @override
  String get challengeEmpty => 'No challenges yet';

  @override
  String get challengeOpenAction => 'Play';

  @override
  String get validationDueInPast => 'The due date cannot be in the past.';

  @override
  String get brainParentNote => 'Points show practice, not intelligence.';

  @override
  String get brainSettingsTitle => 'Game settings';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get fbWrongTitle => 'Not this one';

  @override
  String get hudScore => 'Score';

  @override
  String get hudTime => 'Time';

  @override
  String hudStreak(int n) {
    return 'Streak ×$n';
  }

  @override
  String hudProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get resultLevelComplete => 'Level complete!';

  @override
  String get resultNewHighScore => 'New high score!';

  @override
  String resultNextUnlocked(int level) {
    return 'Level $level unlocked';
  }

  @override
  String get resultChallengeDone => 'Coach challenge complete!';

  @override
  String get resultBackToAcademy => 'Back to Brain Academy';

  @override
  String get resultTryEasier => 'Try an easier level';

  @override
  String get resultFailTitle => 'Almost there!';

  @override
  String get resultFailEncourage =>
      'Every try makes your brain stronger. Want another go?';

  @override
  String resultStars(int n) {
    return '$n of 3 stars';
  }

  @override
  String get resultRetry => 'Try again';

  @override
  String get failOutOfLives => 'You ran out of lives.';

  @override
  String get failLowAccuracy => 'Fewer than half of the answers were right.';

  @override
  String get failTooSlow => 'Time ran out in several rounds.';

  @override
  String get objMemory => 'Goal: find all the pairs.';

  @override
  String get objLogic => 'Goal: solve 8 puzzles.';

  @override
  String get objSmart => 'Goal: pick the right move in match situations.';

  @override
  String get objQuick => 'Goal: find the target quickly in 12 rounds.';

  @override
  String get objSequence => 'Goal: repeat 5 sequences.';

  @override
  String get objPath => 'Goal: bring the ball to the goal.';

  @override
  String get diffEasyHint => 'Relaxed pace';

  @override
  String get diffMediumHint => 'A bit harder';

  @override
  String get diffHardHint => 'For champions';

  @override
  String levelsUnlocked(int level) {
    return 'Unlocked up to level $level';
  }

  @override
  String logicWhyRepeat(int n) {
    return 'The row repeats every $n shapes.';
  }

  @override
  String get logicWhyGrow => 'Each step adds more of the same shape.';

  @override
  String get logicWhyMissing =>
      'Look at the shapes before and after the “?” — the row repeats.';

  @override
  String get logicCorrectWas => 'The right answer is marked in green.';

  @override
  String get gameNext => 'Next';

  @override
  String get spCoachSays => 'Coach says';

  @override
  String get spYourChoice => 'Your choice';

  @override
  String get spBestChoice => 'Best choice';

  @override
  String get quickTooSlow => 'Too slow!';

  @override
  String get quickHurry => 'Hurry!';

  @override
  String quickReaction(String time) {
    return 'Reaction: $time s';
  }

  @override
  String get seqRepeatHint => 'Now tap them in the same order';

  @override
  String get seqRoundDone => 'Sequence complete!';

  @override
  String get seqMistake => 'Oops! Watch again.';

  @override
  String get mazeBlocked => 'Blocked!';

  @override
  String get mazeStart => 'Start';

  @override
  String get memoryPair => 'Match!';

  @override
  String get memoryNoPair => 'Not a pair';

  @override
  String comboLabel(int n) {
    return 'Combo ×$n!';
  }

  @override
  String get rsvpTitleMatch => 'Coming to the match?';

  @override
  String get scheduleChangedTitle => 'The schedule has changed';

  @override
  String scheduleChangedBody(String when) {
    return 'New time: $when. Please confirm attendance again.';
  }

  @override
  String get ackIsNotRsvp =>
      '\"Got it\" only confirms you have read the change — it does not answer whether your child will attend.';

  @override
  String get ackButton => 'Got it';

  @override
  String get ackDone => 'Marked as read';

  @override
  String get rsvpNeedsReconfirm => 'Needs reconfirmation';

  @override
  String rsvpPreviousAnswer(String answer) {
    return 'Your answer for the previous schedule: $answer';
  }

  @override
  String get rsvpGuardiansDisagree =>
      'Guardians gave different answers — the latest answer counts.';

  @override
  String get guardianLabel => 'Guardian';

  @override
  String get rsvpOldSchedule => 'old schedule';

  @override
  String get rsvpStateConfirmed => 'Confirmed';

  @override
  String get rsvpStateDeclined => 'Declined';

  @override
  String get rsvpStateUncertain => 'Not sure';

  @override
  String get rsvpStateNotResponded => 'No response';

  @override
  String get contactCoach => 'Contact coach';

  @override
  String contactCoachTitle(String coach) {
    return 'Contact $coach';
  }

  @override
  String get contactCoachExplain =>
      'Your parent will get your request and can write to or call the coach. You do not chat with the coach directly.';

  @override
  String get contactCoachSent =>
      'Your parent has been asked to contact the coach';

  @override
  String get contactCoachPending => 'Request sent to your parent';

  @override
  String get contactTopicQuestion => 'I have a question';

  @override
  String get contactTopicAbsence => 'I can\'t come';

  @override
  String get contactTopicTraining => 'About training';

  @override
  String get contactTopicOther => 'Something else';

  @override
  String get eventRescheduled => 'Rescheduled';

  @override
  String get eventLocationChanged => 'Location changed';

  @override
  String get eventShowMap => 'Map';

  @override
  String get studentUpcomingEvents => 'Upcoming trainings and matches';

  @override
  String leaderboardTitle(String org) {
    return 'Leaderboard · $org';
  }

  @override
  String get leaderboardAllGames => 'All games';

  @override
  String get leaderboardWeek => 'This week';

  @override
  String get leaderboardMonth => 'This month';

  @override
  String get leaderboardAllTime => 'All time';

  @override
  String leaderboardAgeBand(String band) {
    return 'Age group $band';
  }

  @override
  String get leaderboardYou => 'you';

  @override
  String leaderboardBadges(int count) {
    return '$count badges';
  }

  @override
  String get leaderboardDisabled =>
      'The leaderboard is not available right now. Your own progress is shown above.';

  @override
  String get leaderboardNoConsent =>
      'You appear on the leaderboard only if your parent allows it. Your private progress is shown above.';

  @override
  String get leaderboardTooFew =>
      'Not enough players in your age group yet. Your private progress is shown above.';

  @override
  String get leaderboardPrivacyNote =>
      'Only nicknames or first names with an initial are shown. Points are for fun and practice — they do not measure intelligence.';

  @override
  String get pointsTotal => 'Points';

  @override
  String get pointsGamesCompleted => 'Games completed';

  @override
  String get pointsThisWeek => 'This week';

  @override
  String get pointsWeekly => 'Points in the last 7 days';

  @override
  String get pointsByGame => 'Points by game';

  @override
  String get pointsRecent => 'Recent games';

  @override
  String pointsValue(int points) {
    return '$points pts';
  }

  @override
  String pointsAccuracy(int percent) {
    return 'Accuracy $percent%';
  }

  @override
  String pointsBest(int score) {
    return 'best $score';
  }

  @override
  String get contactDone => 'Done';

  @override
  String get contactOpenChat => 'Open chat with the coach';

  @override
  String contactRequestFromChild(String child, String coach) {
    return '$child asks you to contact coach $coach';
  }

  @override
  String get leaderboardConsentTitle => 'Brain Academy leaderboard';

  @override
  String get leaderboardConsentExplain =>
      'Off by default. If you allow it, your child appears only on this academy\'s private leaderboard, with a nickname or first name and initial — never a full name, phone, birth date or health data. You can withdraw consent at any time.';

  @override
  String get leaderboardConsentOn => 'Leaderboard consent saved';

  @override
  String get leaderboardConsentOff =>
      'Consent withdrawn — your child is no longer shown';

  @override
  String get leaderboardConsentOffHint => 'Not shown on the leaderboard';

  @override
  String get leaderboardModePseudonym => 'Nickname';

  @override
  String get leaderboardModeInitial => 'First name + initial';

  @override
  String get orgSwitchTitle => 'Choose academy';

  @override
  String get adminColSport => 'Sport';

  @override
  String get adminNavOrganizations => 'Organizations';

  @override
  String get adminNavOrgSettings => 'Academy settings';

  @override
  String get adminNavPrograms => 'Programs';

  @override
  String get adminNavReports => 'Reports';

  @override
  String get adminNavRooms => 'Rooms and halls';

  @override
  String get adminNavSchedule => 'Room schedule';

  @override
  String get adminNavSectionPlatform => 'Platform';

  @override
  String get adminNavSectionTenant => 'Academy';

  @override
  String get bookingAllowGroupOverlap =>
      'The group really has two sessions at once — book anyway';

  @override
  String bookingAlternatives(String times) {
    return 'Free times the same day: $times';
  }

  @override
  String get bookingCancel => 'Cancel booking';

  @override
  String get bookingCancelFuture => 'Cancel this and all later';

  @override
  String get bookingCancelOccurrence => 'Cancel only this one';

  @override
  String get bookingCancelled => 'Booking cancelled';

  @override
  String get bookingCoach => 'Coach';

  @override
  String get bookingConflictsFound => 'Check before saving';

  @override
  String get bookingEdit => 'Edit booking';

  @override
  String bookingFreeRooms(String rooms) {
    return 'Free rooms at this time: $rooms';
  }

  @override
  String get bookingGroup => 'Group';

  @override
  String get bookingKind => 'Type';

  @override
  String get bookingKindEvent => 'Special event';

  @override
  String get bookingKindMaintenance => 'Maintenance';

  @override
  String get bookingKindMatch => 'Match';

  @override
  String get bookingKindTraining => 'Training';

  @override
  String get bookingMoved => 'Booking moved';

  @override
  String get bookingNew => 'New booking';

  @override
  String get bookingRecurring => 'Repeat weekly';

  @override
  String get bookingRejected => 'The room cannot be booked';

  @override
  String get bookingSaveFuture => 'Save this and later';

  @override
  String get bookingSaveOccurrence => 'Save only this one';

  @override
  String get bookingSaved => 'Booking saved';

  @override
  String bookingSeriesNote(int weeks) {
    return 'Every occurrence (up to $weeks weeks ahead) is checked before anything is saved.';
  }

  @override
  String get bookingTitle => 'Title';

  @override
  String get bookingTryInstead => 'Try one of these instead:';

  @override
  String bookingUntil(String date) {
    return 'Until $date';
  }

  @override
  String get conflictCoachOverlap => 'The coach is already booked at this time';

  @override
  String get conflictGroupOverlap =>
      'The group already has a session at this time';

  @override
  String get conflictInvalidRange => 'The end must be after the start';

  @override
  String get conflictMaintenance => 'The room is blocked for maintenance';

  @override
  String get conflictOutsideHours => 'Outside the room\'s opening hours';

  @override
  String get conflictOverCapacity => 'More people than the room holds';

  @override
  String get conflictRoomNotBookable => 'The room is unavailable or archived';

  @override
  String get conflictRoomOverlap => 'The room is already booked at this time';

  @override
  String get conflictTooLong => 'A booking can last at most 12 hours';

  @override
  String get conflictWrongTenant => 'The room belongs to another organization';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get moduleAttendance => 'Attendance';

  @override
  String get moduleBrainAcademy => 'Brain Academy';

  @override
  String get moduleCommunication => 'Chat';

  @override
  String get moduleDisabledRooms =>
      'Room scheduling is not enabled for this organization. The platform administrator can allow it, then you can switch it on in the academy settings.';

  @override
  String get moduleDisabledTitle => 'Module switched off';

  @override
  String get moduleLeaderboards => 'Leaderboards';

  @override
  String get moduleMatches => 'Matches';

  @override
  String get moduleMedia => 'Media gallery';

  @override
  String get moduleMedical => 'Medical certificates';

  @override
  String get moduleNotifications => 'Notifications';

  @override
  String get modulePayments => 'Payments';

  @override
  String get moduleRoomScheduling => 'Room scheduling';

  @override
  String get moduleStudentAccounts => 'Student accounts';

  @override
  String get moduleTrainingPlans => 'Training plans';

  @override
  String get moduleTrainings => 'Trainings';

  @override
  String get none => 'None';

  @override
  String get orgAddCoach => 'Add coach';

  @override
  String get orgAdminAssigned => 'Administrator assigned';

  @override
  String get orgAdminHelp =>
      'The person can then sign in to the Admin Web and manage only this organization.';

  @override
  String get orgAdmins => 'Admins';

  @override
  String get orgAllowedModules => 'Modules allowed by the platform';

  @override
  String get orgAssignAdmin => 'Assign administrator';

  @override
  String get orgBookingBuffer => 'Gap between bookings';

  @override
  String get orgBookingsWeek => 'Room bookings in the next 7 days';

  @override
  String get orgBrainPlays => 'Brain Academy games (7 days)';

  @override
  String get orgBrandColor => 'Brand colour';

  @override
  String get orgBranding => 'Branding and contacts';

  @override
  String get orgCoaches => 'Coaches';

  @override
  String get orgContactEmail => 'Contact email';

  @override
  String get orgContactPhone => 'Contact phone';

  @override
  String get orgCreated => 'Organization created';

  @override
  String get orgDefaultLanguage => 'Default language';

  @override
  String get orgDescription => 'Description';

  @override
  String get orgHealth => 'Tenant health';

  @override
  String orgInactiveBanner(String status) {
    return 'This organization is $status. Settings are read-only and nothing new can be created.';
  }

  @override
  String get orgLabel => 'Organization';

  @override
  String get orgLeaderboardByAge => 'Rank only within the same age group';

  @override
  String get orgLeaderboardEnable => 'Enable the Brain Academy leaderboard';

  @override
  String get orgLeaderboardMin => 'Minimum opted-in students per board';

  @override
  String get orgLeaderboardNotAllowed =>
      'Leaderboards are not allowed for this organization by the platform.';

  @override
  String get orgLeaderboardPrivacy =>
      'Only students whose guardian consented appear, with a nickname or first name + initial.';

  @override
  String get orgLeaderboardSettings => 'Leaderboard';

  @override
  String get orgLimitCoaches => 'Coaches';

  @override
  String get orgLimitGroups => 'Groups';

  @override
  String get orgLimitRooms => 'Rooms';

  @override
  String get orgLimitStudents => 'Students';

  @override
  String get orgLimits => 'Limits';

  @override
  String get orgLogoUrl => 'Logo URL';

  @override
  String get orgManage => 'Plan, status and modules';

  @override
  String get orgModules => 'Enabled modules';

  @override
  String get orgModulesHelp =>
      'Locked modules must first be allowed by the platform administrator.';

  @override
  String get orgModulesOn => 'Modules on';

  @override
  String get orgNameEn => 'Name (English)';

  @override
  String get orgNameKa => 'Name (Georgian)';

  @override
  String get orgNameRu => 'Name (Russian)';

  @override
  String get orgNew => 'New organization';

  @override
  String get orgNoneSelected => 'No organization to manage';

  @override
  String get orgOverLimit => 'One or more plan limits are exceeded.';

  @override
  String get orgPickUser => 'Choose a user';

  @override
  String get orgPlan => 'Plan';

  @override
  String get orgPlatformSubtitle =>
      'Every sports school runs as its own tenant with private data.';

  @override
  String get orgRemoveAdmin => 'Remove administrator';

  @override
  String get orgRemoveCoach => 'Remove';

  @override
  String get orgSaved => 'Saved';

  @override
  String get orgStatusActive => 'Active';

  @override
  String get orgStatusDeactivated => 'Deactivated';

  @override
  String get orgStatusHelp =>
      'Suspended or deactivated: data is kept and readable, but every module is off and nothing new can be created.';

  @override
  String get orgStatusSuspended => 'Suspended';

  @override
  String get orgTimezone => 'Time zone';

  @override
  String get orgUpcomingEvents => 'Upcoming trainings and matches';

  @override
  String get orgUserId => '…or user ID';

  @override
  String get planFree => 'Free';

  @override
  String get planPremium => 'Premium';

  @override
  String get planStandard => 'Standard';

  @override
  String get programAges => 'Ages';

  @override
  String get programCapacity => 'Capacity';

  @override
  String get programNew => 'New program';

  @override
  String get programPaused => 'Paused';

  @override
  String get programScheduleNote => 'Schedule note';

  @override
  String get reportAllGroups => 'All groups';

  @override
  String get reportAttendance => 'Attendance';

  @override
  String get reportBrain => 'Brain Academy';

  @override
  String reportDays(int days) {
    return '$days days';
  }

  @override
  String get reportLastPlayed => 'Last played';

  @override
  String get reportRsvp => 'Parent responses';

  @override
  String get reportWhen => 'When';

  @override
  String get roomAnySport => 'Any sport';

  @override
  String get roomCapacity => 'Capacity';

  @override
  String get roomHours => 'Opening hours';

  @override
  String get roomLabel => 'Room';

  @override
  String get roomMaintenance => 'Add maintenance block';

  @override
  String get roomNew => 'New room';

  @override
  String get roomNone => 'Add a room first';

  @override
  String get roomNote => 'Note';

  @override
  String get roomSports => 'Supported sports (empty = any)';

  @override
  String get roomStatusActive => 'Available';

  @override
  String get roomStatusUnavailable => 'Temporarily unavailable';

  @override
  String get scheduleAllCoaches => 'All coaches';

  @override
  String get scheduleAllRooms => 'All rooms';

  @override
  String get scheduleAllSports => 'All sports';

  @override
  String scheduleBusy(int hours, int minutes) {
    return '$hours h $minutes min booked';
  }

  @override
  String get scheduleDay => 'Day';

  @override
  String get scheduleFree => 'Free';

  @override
  String scheduleSubtitle(String tz) {
    return 'Times shown in $tz. Tap a free slot to book, drag a booking to move it.';
  }

  @override
  String get scheduleWeek => 'Week';

  @override
  String sysEventRescheduled(String when) {
    return 'Schedule changed: $when. Please confirm attendance again.';
  }

  @override
  String get sysEventRescheduledNoTime =>
      'The schedule changed. Please confirm attendance again.';

  @override
  String get moduleParentRsvp => 'Parent RSVP';

  @override
  String get moduleMessageAcks => 'Message acknowledgments';

  @override
  String get moduleCoachChallenges => 'Coach challenges';

  @override
  String get modulePaymentReceipts => 'Payment receipts';

  @override
  String get modulePaymentVerification => 'Payment verification';

  @override
  String get modulePaymentReminders => 'Payment reminders';

  @override
  String get moduleFacilities => 'Facilities';

  @override
  String get moduleReports => 'Reports';

  @override
  String get moduleDataExports => 'Data exports';

  @override
  String get orgAllAcademies => 'All academies';

  @override
  String get orgRoleAdmin => 'Administrator';

  @override
  String get orgRoleStudent => 'Student';

  @override
  String get accessFull => 'Full access';

  @override
  String get accessGrace => 'Grace period';

  @override
  String get accessLabel => 'Access';

  @override
  String get accessReadOnly => 'Read-only';

  @override
  String get addDependencies => 'Enable required features';

  @override
  String addDependenciesConfirm(String features) {
    return 'These features will also be enabled: $features';
  }

  @override
  String get adminEmailLabel => 'Administrator email';

  @override
  String get adminNavFeatureCatalog => 'Feature catalog';

  @override
  String get adminNavHealth => 'System health';

  @override
  String get adminNavInvitations => 'Invitations';

  @override
  String get adminNavMembers => 'Members';

  @override
  String get adminNavPackages => 'Packages';

  @override
  String get adminNavTemplates => 'Organization templates';

  @override
  String get adminNavOverview => 'Overview';

  @override
  String get adminNavPlatformUsers => 'Platform users';

  @override
  String get adminPhoneLabel => 'Administrator phone';

  @override
  String get alertInvitationExpiring => 'Invitation expiring';

  @override
  String get alertOverLimit => 'Over package limit';

  @override
  String get alertPastDue => 'Payment past due';

  @override
  String get alertProvisioning => 'Provisioning not finished';

  @override
  String get alertReadOnly => 'Organization is read-only';

  @override
  String get alertTrialEnding => 'Trial ending soon';

  @override
  String get applyTemplate => 'Apply template';

  @override
  String get applyTemplateNote =>
      'Applying a template to an existing organization shows a preview first. Historical data is never deleted.';

  @override
  String get archive => 'Archive';

  @override
  String get back => 'Back';

  @override
  String get brandingManagedByOrg =>
      'Branding is edited by the organization administrator in Organization settings.';

  @override
  String get bulkPresets => 'Presets';

  @override
  String get changePreview => 'Changes';

  @override
  String get changeReasonHint => 'Why is this changing? (required)';

  @override
  String get changeReasonTitle => 'Reason for the change';

  @override
  String configConflict(int version) {
    return 'Someone else saved a newer version ($version). Reload and apply your changes again.';
  }

  @override
  String get configConflictTitle => 'Configuration changed';

  @override
  String get configHistory => 'Configuration history';

  @override
  String contrastRatio(String ratio) {
    return 'Contrast with white text: $ratio:1 (minimum 4.5:1)';
  }

  @override
  String get copyLink => 'Copy link';

  @override
  String get customLabel => 'Custom';

  @override
  String get customPackageNote =>
      'Every feature is available; entitlements are set per organization.';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get durationDays => 'Duration (days)';

  @override
  String get effDependencyMissing => 'Dependency off';

  @override
  String get effDisabledByOrg => 'Off by organization';

  @override
  String get effNotEntitled => 'Not entitled';

  @override
  String get effNotInPackage => 'Not in package';

  @override
  String get effOn => 'Active';

  @override
  String get effOrgInactive => 'Organization inactive';

  @override
  String get effProvisioning => 'Provisioning';

  @override
  String get effReadOnly => 'Read-only subscription';

  @override
  String get effRolloutOff => 'Rollout inactive';

  @override
  String get errBrandContrast =>
      'This color is not readable with white text. Choose a darker color.';

  @override
  String get errChangeReason => 'Enter a reason for the change.';

  @override
  String get errFeatureDependencies =>
      'Some features need other features that are off.';

  @override
  String get errInvitationClosed => 'This invitation is no longer valid.';

  @override
  String get errInvitationExpired =>
      'This invitation has expired. Ask for a new one.';

  @override
  String get errLimitReached => 'The package limit has been reached.';

  @override
  String get errNotInPackage =>
      'A selected feature is not included in the package.';

  @override
  String get errOrgAddress => 'Enter the address and city.';

  @override
  String get errOrgAdmin => 'Enter the initial administrator phone or email.';

  @override
  String get errOrgEmail => 'Enter a valid contact email.';

  @override
  String get errOrgName => 'Enter the organization name and legal name.';

  @override
  String get errOrgPhone => 'Enter a valid contact phone.';

  @override
  String get errOrgSports => 'Select at least one sport.';

  @override
  String get errRolloutDate =>
      'Choose a date for the trial or scheduled rollout.';

  @override
  String get featCatAdministration => 'Administration';

  @override
  String get featCatCommunication => 'Communication';

  @override
  String get featCatCore => 'Core';

  @override
  String get featCatFacilities => 'Facilities';

  @override
  String get featCatFinance => 'Finance';

  @override
  String get featCatLearning => 'Learning';

  @override
  String get featCategory => 'Category';

  @override
  String get featureAdoption => 'Feature adoption';

  @override
  String get featureCatalogSubtitle =>
      'Every module with its stable id, dependencies and adoption.';

  @override
  String get fundGovernment => 'Government';

  @override
  String get fundMixed => 'Mixed';

  @override
  String get fundNonprofit => 'Nonprofit';

  @override
  String get fundOther => 'Other';

  @override
  String get fundPrivate => 'Private';

  @override
  String get fundingNote =>
      'Funding type does not switch payments on or off by itself; features are set explicitly.';

  @override
  String get graceDays => 'Grace period (days)';

  @override
  String get haveInvitation => 'Have an administrator invitation?';

  @override
  String get healthDaily => 'daily';

  @override
  String get healthJobGated => 'skips organizations where the feature is off';

  @override
  String get healthJobs => 'Scheduled jobs';

  @override
  String get inPackage => 'In package';

  @override
  String get initialFeatures => 'Initial features';

  @override
  String get invAccepted => 'Accepted';

  @override
  String get invExpired => 'Expired';

  @override
  String get invPending => 'Pending';

  @override
  String get invRejected => 'Rejected';

  @override
  String get invRevoked => 'Revoked';

  @override
  String get invitationAcceptButton => 'Accept';

  @override
  String get invitationAcceptedSnack =>
      'Invitation accepted. You are now an administrator.';

  @override
  String get invitationCreated => 'Invitation created';

  @override
  String get invitationLinkNote =>
      'Send this link to the administrator. It is shown only once and is valid for 7 days.';

  @override
  String get invitationNote =>
      'The administrator receives an invitation that expires in 7 days. They sign in with this phone or email and accept it.';

  @override
  String get invitationRejectButton => 'Decline';

  @override
  String get invitationRejectedSnack => 'Invitation declined.';

  @override
  String get invitationTokenLabel => 'Invitation code';

  @override
  String get inviteAdmin => 'Invite administrator';

  @override
  String get inviteExpires => 'Expires';

  @override
  String get inviteRecipient => 'Recipient';

  @override
  String get inviteResend => 'Resend';

  @override
  String get lastChange => 'Last change';

  @override
  String get limitNotifications => 'Notifications this month';

  @override
  String get limitSms => 'SMS this month';

  @override
  String get limitStorage => 'Storage (MB)';

  @override
  String get membersPrivacyNote =>
      'Only counts and group names are shown here; personal details stay in the organization.';

  @override
  String missingDependencies(String features) {
    return 'Missing required features for: $features';
  }

  @override
  String get noAlerts => 'No alerts';

  @override
  String get noChanges => 'No changes';

  @override
  String get operationalAlerts => 'Operational alerts';

  @override
  String get orgCity => 'City';

  @override
  String get orgCreateButton => 'Create organization';

  @override
  String get orgFunding => 'Funding';

  @override
  String get orgLegalName => 'Legal name';

  @override
  String get orgProvisioned => 'Organization created';

  @override
  String get orgRegistrationId => 'Registration number';

  @override
  String get orgTypeAcademy => 'Children\'s academy';

  @override
  String get orgTypeClub => 'Sports club';

  @override
  String get orgTypeIndependent => 'Independent coach';

  @override
  String get orgTypeLabel => 'Organization type';

  @override
  String get orgTypeOther => 'Other';

  @override
  String get orgTypeSchool => 'Sports school';

  @override
  String get packageLabel => 'Package';

  @override
  String get packageNew => 'New package';

  @override
  String get packagesSubtitle =>
      'Feature sets, limits and indicative pricing. No billing provider is connected.';

  @override
  String get platformOverview => 'Platform overview';

  @override
  String get platformOverviewSubtitle =>
      'All organizations, subscriptions and feature adoption.';

  @override
  String get priceLabel => 'Price';

  @override
  String get recentAdminActions => 'Recent administrator actions';

  @override
  String refreshDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count organizations updated',
      one: '1 organization updated',
      zero: 'No organization changed',
    );
    return '$_temp0';
  }

  @override
  String get requiresLabel => 'Requires';

  @override
  String get restore => 'Restore';

  @override
  String get restrictedLabel => 'Restricted';

  @override
  String get rolloutDisabled => 'Disabled';

  @override
  String get rolloutEnabled => 'Enabled';

  @override
  String get rolloutFrom => 'from';

  @override
  String get rolloutScheduled => 'Scheduled';

  @override
  String get rolloutTrial => 'Trial';

  @override
  String get rolloutUntil => 'until';

  @override
  String get runEntitlementRefresh => 'Run entitlement refresh';

  @override
  String get statOrganizations => 'Organizations';

  @override
  String get statParents => 'Parents';

  @override
  String get statStudents => 'Students';

  @override
  String get statUsers => 'Users';

  @override
  String get subActive => 'Active';

  @override
  String get subCancelled => 'Cancelled';

  @override
  String get subExpired => 'Expired';

  @override
  String get subPastDue => 'Past due';

  @override
  String get subSuspended => 'Suspended';

  @override
  String get subTrial => 'Trial';

  @override
  String get subscriptionEnds => 'Ends';

  @override
  String get subscriptionLabel => 'Subscription';

  @override
  String get subscriptionPolicyNote =>
      'Read-only keeps every record; nothing is deleted. Managed manually — no charges are made.';

  @override
  String get subscriptionsSubtitle =>
      'Status, end date and access for every organization.';

  @override
  String get subscriptionsTitle => 'Subscriptions';

  @override
  String get syntheticData => 'Demo data';

  @override
  String get tabAdmins => 'Admins & members';

  @override
  String get tabAudit => 'Audit history';

  @override
  String get tabBranding => 'Branding';

  @override
  String get tabFeatures => 'Features';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabSubscription => 'Subscription';

  @override
  String get tabUsage => 'Limits & usage';

  @override
  String get templateLabel => 'Template';

  @override
  String get templateNew => 'New template';

  @override
  String get unsavedChanges => 'You have unsaved changes';

  @override
  String get usageSyntheticNote =>
      'Storage and message counts in Demo Mode are estimates.';

  @override
  String get adminNavActivity => 'Activity';

  @override
  String get pickerSearchHint => 'Search…';

  @override
  String get pickerClearSearch => 'Clear search';

  @override
  String pickerSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'Nothing selected',
    );
    return '$_temp0';
  }

  @override
  String get pickerSelectAll => 'Select all';

  @override
  String get pickerClearAll => 'Clear all';

  @override
  String get pickerRemove => 'Remove';

  @override
  String get pickerNoOptions => 'Nothing to choose from yet.';

  @override
  String pickerNoResults(String query) {
    return 'No results for “$query”. Try another spelling.';
  }

  @override
  String pickerDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done ($count)',
      zero: 'Done',
    );
    return '$_temp0';
  }

  @override
  String get pickerChoose => 'Choose…';

  @override
  String get pickerGroupFree => 'Free at this time';

  @override
  String get pickerGroupBusy => 'Busy at this time';

  @override
  String wizardStepOf(int step, int total, String name) {
    return 'Step $step of $total: $name';
  }

  @override
  String get adminNavSecCatalog => 'Catalog & content';

  @override
  String get adminNavSecPeople => 'People';

  @override
  String get adminNavSecPrograms => 'Sports & programs';

  @override
  String get adminNavSecCalendar => 'Calendar & facilities';

  @override
  String get adminNavSecCommunication => 'Communication';

  @override
  String get adminNavSecFinanceReports => 'Payments & reports';

  @override
  String get adminNavSecOrganization => 'Organization';

  @override
  String get adminOrgContext => 'Pages below work on this organization';

  @override
  String get adminSwitchOrg => 'Switch organization';

  @override
  String featureOffTitle(String feature) {
    return '$feature is off for this organization';
  }

  @override
  String get featureOffBodyOrg =>
      'Nothing is lost — existing records are kept. Switch the feature on in Organization settings if your package includes it; otherwise ask the platform administrator.';

  @override
  String get featureOffBodyPlatform =>
      'Existing records are kept. You can allow the feature in this organization\'s Features tab.';

  @override
  String get featureOffOpenSettings => 'Open organization settings';

  @override
  String get featureOffOpenOrg => 'Open the organization\'s features';

  @override
  String get errRequiredField => 'Required';

  @override
  String get errCapacity => 'Enter a number from 1 to 2000';

  @override
  String get roomOpensAt => 'Opens at';

  @override
  String get roomClosesAt => 'Closes at';

  @override
  String get roomClosed => 'Closed';

  @override
  String get roomSameHours => 'Same hours every day';

  @override
  String get roomCapacityHint => 'How many people the room safely holds';

  @override
  String get roomSportsHint => 'Bookings for other sports show a warning';

  @override
  String get roomCreated => 'Room added';

  @override
  String get roomCreate => 'Add room';

  @override
  String get roomEdit => 'Edit room';

  @override
  String get formBasics => 'Basics';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get confirmRemoveAdminBody =>
      'They will lose access to this organization\'s administration immediately. Their other roles stay.';

  @override
  String get adminRemovedSnack => 'Administrator removed';

  @override
  String confirmOrgStatusTitle(String status) {
    return 'Change status to “$status”?';
  }

  @override
  String get confirmOrgSuspendBody =>
      'Everyone in this organization immediately loses the ability to create or change anything. Data is kept and can be reactivated later.';

  @override
  String get confirmOrgActivateBody =>
      'Members regain access to the organization\'s enabled features.';

  @override
  String get navChildren => 'Children';

  @override
  String get navMessages => 'Messages';

  @override
  String get navMore => 'More';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navGroups => 'Groups';

  @override
  String get navMySchedule => 'My schedule';

  @override
  String get navFindClubs => 'Find clubs on the map';

  @override
  String get hubNoChildrenBody =>
      'Add your child to join a group, confirm trainings and follow progress.';

  @override
  String get hubChildProfile => 'Profile';

  @override
  String get hubChildProgress => 'Progress';

  @override
  String get hubChildDocuments => 'Health documents';

  @override
  String get hubNoGroupsTitle => 'No groups yet';

  @override
  String get hubNoGroupsBody =>
      'Create a group for your sport, then invite families with its code.';

  @override
  String get hubNextSession => 'Next session';

  @override
  String get hubTakeAttendance => 'Take attendance';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'You will need a new SMS code to sign in again.';

  @override
  String rsvpSavedInline(String answer) {
    return 'Saved: $answer. The coach sees it.';
  }

  @override
  String get rsvpReasonSaved => 'Reason saved';

  @override
  String get rsvpSaveReason => 'Save reason';

  @override
  String get rsvpReasonLabel => 'Reason (optional)';

  @override
  String attendanceSkippedDeclined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count children whose parents said “won\'t attend” were left for you to mark.',
      one:
          '1 child whose parent said “won\'t attend” was left for you to mark.',
    );
    return '$_temp0';
  }

  @override
  String attendanceRemainingAs(String status) {
    return 'Remaining: $status';
  }

  @override
  String get bookingPickTime => 'Free times nearby — tap one to move there';

  @override
  String get bookingPickRoom => 'Rooms free at this time — tap one to use it';

  @override
  String get bookingKeepAsIs => 'Keep as it was';

  @override
  String roomBusyWith(String title, String time) {
    return 'Busy: «$title» $time';
  }

  @override
  String confirmRemoveCoachBody(String name) {
    return '$name will no longer be a coach of this organization. Their groups and history stay.';
  }

  @override
  String get coachRemovedSnack => 'Coach removed from the organization';

  @override
  String get coachAddedSnack => 'Coach added to the organization';

  @override
  String get wizBasics => 'Basics';

  @override
  String get wizPackage => 'Package';

  @override
  String get wizFeatures => 'Features';

  @override
  String get wizAdmin => 'Administrator';

  @override
  String get wizReview => 'Review';

  @override
  String get wizFixErrors => 'Please fix the highlighted fields to continue.';

  @override
  String get venueGroupClub => 'Your club\'s venues';

  @override
  String get venueGroupOther => 'Other venues for this sport';

  @override
  String get adminNoMatches => 'Nothing matches your search or filter.';

  @override
  String get adminClearFilters => 'Clear search and filters';

  @override
  String get adminPrevPage => 'Previous page';

  @override
  String get adminNextPage => 'Next page';

  @override
  String get confirmRevokeBody =>
      'The invitation link stops working immediately. You can send a new invitation later.';

  @override
  String get invitationRevokedSnack => 'Invitation revoked';

  @override
  String get confirmArchiveTemplateBody =>
      'Archived templates can\'t be used for new organizations. Organizations already created from it are not changed.';

  @override
  String get templateArchivedSnack => 'Template archived';

  @override
  String get templateRestoredSnack => 'Template restored';

  @override
  String get confirmCancelBookingBody =>
      'The room becomes free for others at this time. Linked trainings are cancelled and families are notified.';

  @override
  String confirmArchiveGroupBody(String name) {
    return '“$name” will stop appearing in schedules and lists. Its history is kept and it can be restored.';
  }

  @override
  String get groupArchivedSnack => 'Group archived';

  @override
  String get groupRestoredSnack => 'Group restored';

  @override
  String get itemGoneTitle => 'This item no longer exists';

  @override
  String get itemGoneBody =>
      'It may have been deleted or cancelled. Go back to see the current list.';

  @override
  String get featOrgOn => 'Org: on';

  @override
  String get featOrgOff => 'Org: off';

  @override
  String get featLegend =>
      'Package = what the package includes · Org = the organization\'s own switch · Active/blocked = what users get right now · Rollout = timing · The switch on the right = allowed by the platform (what you change here).';

  @override
  String get m191UnsavedTitle => 'You have unsaved changes';

  @override
  String get m191UnsavedBody => 'If you leave now, they will be lost.';

  @override
  String get m191Stay => 'Stay';

  @override
  String get m191Discard => 'Discard';

  @override
  String get m191FieldGenericError =>
      'Something is not right with this field — please check it.';

  @override
  String get m191PhoneHint => '5XX XX XX XX';

  @override
  String get m191DiscardMessage => 'Discard message';

  @override
  String get m191ClearSearch => 'Clear search';

  @override
  String get m191ClearEndDate => 'Clear end date';

  @override
  String get m191RemoveAttachment => 'Remove attachment';

  @override
  String m191RatingStars(String category, int stars) {
    return '$category: $stars of 5';
  }

  @override
  String get m191LevelDown => 'Lower level';

  @override
  String get m191LevelUp => 'Higher level';

  @override
  String get m191PhotoLibrary => 'Photo library';

  @override
  String get m191PdfFile => 'PDF file';

  @override
  String m191FileGuidance(int mb) {
    return 'Photo (JPG, PNG) or PDF · up to $mb MB';
  }

  @override
  String m191FileSize(int kb) {
    return '$kb KB';
  }

  @override
  String get m191ReplaceFile => 'Replace';

  @override
  String get m191RemoveFile => 'Remove file';

  @override
  String get m191Uploading => 'Uploading…';

  @override
  String get m191UploadFailedTitle => 'Not uploaded';

  @override
  String m191InputsKept(String reason) {
    return '$reason Your file and details are kept — you can try again.';
  }

  @override
  String m191CertExistingValid(String status, String date) {
    return 'Current certificate: $status · until $date';
  }

  @override
  String get m191CertReplacesExisting =>
      'The new certificate replaces this one.';

  @override
  String get m191CertAddsToExisting =>
      'The new certificate is added; the one valid the longest applies.';

  @override
  String get m191ReceiptNotSentTitle => 'Not sent';

  @override
  String get s191CalendarWhose => 'Whose schedule';

  @override
  String get s191CalendarLegendTraining => 'Training';

  @override
  String get s191CalendarLegendMatch => 'Match';

  @override
  String get s191CalendarMatchesError => 'Matches could not be loaded.';

  @override
  String get s191GroupClubHelper => 'Only clubs where you coach';

  @override
  String get s191GroupSportHelper => 'Only sports offered by the chosen club';

  @override
  String get s191GroupNameHint => 'For example: U10 beginners';

  @override
  String get s191RosterEmptyTitle => 'No children in this group yet';

  @override
  String get s191RosterEmptyBody =>
      'Share the group code with parents or add a child by name.';

  @override
  String get s191RosterSearchHint => 'Search by child\'s name';

  @override
  String s191RosterNoMatches(String query) {
    return 'No child named “$query” in this group.';
  }

  @override
  String s191RosterMoreActions(String name) {
    return 'More actions for $name';
  }

  @override
  String s191ChildDetails(String name) {
    return '$name\'s details';
  }

  @override
  String get s191ChildChipHint => 'Tap to choose, long-press for details';

  @override
  String get s191RsvpAllTitle => 'Same answer for all children';

  @override
  String get s191RsvpAllSaved => 'Answer saved for all children';

  @override
  String get s191JoinAlreadyMember => 'Already in this group';

  @override
  String s191JoinAgeOutside(int age, int min, int max) {
    return 'Age $age; the group is for ages $min–$max';
  }

  @override
  String get a191ErrCoachNotInOrg =>
      'Choose coaches who belong to this organization.';

  @override
  String get a191ErrGroupFull =>
      'This group is full. Increase its capacity or choose another group.';

  @override
  String get a191ErrGroupCapacity => 'Capacity must be a number from 1 to 500.';

  @override
  String get a191ErrCapacityBelowMembers =>
      'The group already has more children than this capacity.';

  @override
  String get a191ErrDuplicateName => 'Something with this name already exists.';

  @override
  String get a191ChooseSport => 'Choose a sport or program';

  @override
  String get a191ChooseCoach => 'Choose at least one coach';

  @override
  String a191GroupCreated(String name) {
    return 'Group “$name” created. Next: invite guardians from Members.';
  }

  @override
  String get a191StepSport => 'Sport';

  @override
  String get a191StepName => 'Name & ages';

  @override
  String get a191StepCoach => 'Coach';

  @override
  String get a191StepCapacity => 'Places';

  @override
  String get a191FromProgram => 'Program (optional)';

  @override
  String get a191FromProgramHint =>
      'Fills sport, ages, coaches and places from the program';

  @override
  String get a191GroupName => 'Group name';

  @override
  String get a191GroupNameHint => 'e.g. Volleyball U-12';

  @override
  String a191Ages(int from, int to) {
    return 'Ages $from–$to';
  }

  @override
  String get a191NoCoachesYet =>
      'This organization has no coaches yet. Add a coach in Organization settings first.';

  @override
  String get a191Coaches => 'Coaches';

  @override
  String get a191Capacity => 'Places (optional)';

  @override
  String get a191CapacityHint =>
      'Maximum number of children. Leave empty for no limit.';

  @override
  String get a191ScheduleNote => 'Schedule note (optional)';

  @override
  String get a191ScheduleNoteHint => 'e.g. Mon, Wed 16:00 · Hall A';

  @override
  String get a191RoomLater =>
      'Rooms and recurring sessions are booked in Room schedule after the group exists.';

  @override
  String get a191NoLimit => 'No limit';

  @override
  String get a191AfterCreate =>
      'After creating: invite guardians from Members and book sessions in Room schedule.';

  @override
  String get a191CreateGroup => 'Create group';

  @override
  String get a191GroupSaved => 'Group saved';

  @override
  String get a191EditGroup => 'Edit group';

  @override
  String get a191InviteFieldsRequired =>
      'Enter the child\'s first name, birth date and the guardian\'s phone.';

  @override
  String get a191InviteSent =>
      'Invitation sent. The child joins when the guardian accepts.';

  @override
  String a191MembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
      zero: 'No children yet',
    );
    return '$_temp0';
  }

  @override
  String a191MembersOfCapacity(int count, int capacity) {
    return '$count of $capacity places taken';
  }

  @override
  String get a191RosterPrivacy =>
      'Only first name, last-name initial and birth year are shown to administrators.';

  @override
  String get a191NoMembersYet =>
      'No children in this group yet. Invite guardians below.';

  @override
  String get a191RemoveFromGroup => 'Remove from group';

  @override
  String a191RemoveFromGroupBody(String child, String group) {
    return '$child will no longer be in “$group”. Attendance history is kept; the guardian keeps the child profile.';
  }

  @override
  String get a191RemovedSnack => 'Removed from the group';

  @override
  String get a191InviteGuardian => 'Enroll through the guardian';

  @override
  String get a191InviteGuardianHint =>
      'The guardian receives an invitation and decides. If they already registered this child, they link the existing profile — no duplicate is created.';

  @override
  String get a191GuardianPhone => 'Guardian\'s phone';

  @override
  String get a191SendInvite => 'Send invitation';

  @override
  String get a191Invitations => 'Invitations';

  @override
  String get a191InviteWaiting => 'Waiting for guardian';

  @override
  String get a191InviteAccepted => 'Joined';

  @override
  String get a191InviteDeclined => 'Declined';

  @override
  String get a191InviteRevoked => 'Withdrawn';

  @override
  String get birthDate => 'Birth date';

  @override
  String get a191Members => 'Members';

  @override
  String a191SetupTitle(String org) {
    return 'Set up $org';
  }

  @override
  String a191SetupProgress(int done, int total) {
    return '$done of $total steps done — based on what is saved';
  }

  @override
  String get a191SetupSports => 'Choose the sports you offer';

  @override
  String get a191SetupCoaches => 'Add coaches';

  @override
  String get a191SetupRooms => 'Add rooms and halls';

  @override
  String get a191SetupPrograms => 'Create programs';

  @override
  String get a191SetupGroups => 'Create groups';

  @override
  String get a191SetupSessions => 'Schedule sessions';

  @override
  String get a191SetupStudents => 'Invite guardians to enroll children';

  @override
  String get a191SetupDone => 'Done';

  @override
  String get a191SetupTodo => 'To do';

  @override
  String get a191SetupStart => 'Start';

  @override
  String get a191SetupOpen => 'Open';

  @override
  String get a191ErrNameRequired => 'Enter a name (at least 2 characters).';

  @override
  String get a191ErrSportId =>
      'Enter a short identifier in Latin letters, e.g. volleyball.';

  @override
  String get a191ErrNumbers => 'Limits and price must be numbers.';

  @override
  String get a191CreateProgram => 'Create program';

  @override
  String get a191ProgramCreated => 'Program created';

  @override
  String get a191CreateSport => 'Add sport';

  @override
  String get featDesc_trainings =>
      'Training sessions: schedule, changes and cancellations for groups.';

  @override
  String get featDesc_matches => 'Matches and competitions with results.';

  @override
  String get featDesc_attendance =>
      'Coaches record who was present, absent or excused.';

  @override
  String get featDesc_communication =>
      'Group chat between coaches and families.';

  @override
  String get featDesc_studentAccounts =>
      'Children get their own limited student login.';

  @override
  String get featDesc_brainAcademy =>
      'Brain Academy thinking games for children.';

  @override
  String get featDesc_trainingPlans =>
      'Weekly plans and homework from coaches.';

  @override
  String get featDesc_payments =>
      'Tuition fees parents pay to the school (not the platform subscription).';

  @override
  String get featDesc_medicalCertificates =>
      'Parents upload health certificates; coaches see validity only.';

  @override
  String get featDesc_media =>
      'Coaches share training photos and videos with consenting families.';

  @override
  String get featDesc_leaderboards =>
      'Opt-in rankings with nicknames, only with guardian consent.';

  @override
  String get featDesc_roomScheduling =>
      'Book halls and rooms without double bookings.';

  @override
  String get featDesc_notifications => 'Push and in-app notifications.';

  @override
  String get featDesc_parentRsvp =>
      'Parents answer whether their child will attend.';

  @override
  String get featDesc_messageAcks =>
      'Coaches can ask families to confirm they read a message.';

  @override
  String get featDesc_coachChallenges =>
      'Coaches assign Brain Academy challenges.';

  @override
  String get featDesc_paymentReceipts =>
      'Parents upload a bank receipt for a payment.';

  @override
  String get featDesc_paymentVerification =>
      'Staff check uploaded receipts and confirm payments.';

  @override
  String get featDesc_paymentReminders =>
      'Automatic reminders before payments are due (SMS only if enabled).';

  @override
  String get featDesc_facilities =>
      'Rooms and halls of the organization with capacity and hours.';

  @override
  String get featDesc_reports =>
      'Attendance and activity reports for administrators.';

  @override
  String get featDesc_dataExports =>
      'Coaches and admins export rosters and attendance.';

  @override
  String get a191FeatureWhat => 'What it does';

  @override
  String get a191PrevWeek => 'Previous week';

  @override
  String get a191NextWeek => 'Next week';

  @override
  String get a191PrevDay => 'Previous day';

  @override
  String get a191NextDay => 'Next day';

  @override
  String get a191PickDate => 'Go to date';
}
