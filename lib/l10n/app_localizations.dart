import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ka'),
  ];

  /// No description provided for @appName.
  ///
  /// In ka, this message translates to:
  /// **'გუნდი'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის სპორტი — ერთ სივრცეში'**
  String get appTagline;

  /// No description provided for @continueLabel.
  ///
  /// In ka, this message translates to:
  /// **'გაგრძელება'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმება'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ka, this message translates to:
  /// **'შენახვა'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ka, this message translates to:
  /// **'წაშლა'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურება'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In ka, this message translates to:
  /// **'დახურვა'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In ka, this message translates to:
  /// **'ხელახლა ცდა'**
  String get retry;

  /// No description provided for @next.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგი'**
  String get next;

  /// No description provided for @done.
  ///
  /// In ka, this message translates to:
  /// **'მზადაა'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In ka, this message translates to:
  /// **'რედაქტირება'**
  String get edit;

  /// No description provided for @seeAll.
  ///
  /// In ka, this message translates to:
  /// **'ყველა'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In ka, this message translates to:
  /// **'დღეს'**
  String get today;

  /// No description provided for @optional.
  ///
  /// In ka, this message translates to:
  /// **'არასავალდებულო'**
  String get optional;

  /// No description provided for @demoBadge.
  ///
  /// In ka, this message translates to:
  /// **'დემო'**
  String get demoBadge;

  /// No description provided for @errorGeneric.
  ///
  /// In ka, this message translates to:
  /// **'რაღაც შეცდომა მოხდა. სცადეთ ხელახლა.'**
  String get errorGeneric;

  /// No description provided for @errorPermission.
  ///
  /// In ka, this message translates to:
  /// **'ამ მოქმედებაზე წვდომა არ გაქვთ.'**
  String get errorPermission;

  /// No description provided for @errorNetwork.
  ///
  /// In ka, this message translates to:
  /// **'კავშირი ვერ დამყარდა. შეამოწმეთ ინტერნეტი.'**
  String get errorNetwork;

  /// No description provided for @errorNotFound.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერი ვერ მოიძებნა.'**
  String get errorNotFound;

  /// No description provided for @errorInvalidCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდი არასწორია.'**
  String get errorInvalidCode;

  /// No description provided for @errorNotSignedIn.
  ///
  /// In ka, this message translates to:
  /// **'გთხოვთ, შეხვიდეთ ანგარიშზე.'**
  String get errorNotSignedIn;

  /// No description provided for @errorTitle.
  ///
  /// In ka, this message translates to:
  /// **'ვერ ჩაიტვირთა'**
  String get errorTitle;

  /// No description provided for @validationRequired.
  ///
  /// In ka, this message translates to:
  /// **'სავალდებულო ველი'**
  String get validationRequired;

  /// No description provided for @validationInvalidPhone.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ სწორი მობილურის ნომერი (5XX XXX XXX)'**
  String get validationInvalidPhone;

  /// No description provided for @validationInvalidOtp.
  ///
  /// In ka, this message translates to:
  /// **'კოდი უნდა იყოს 6 ციფრი'**
  String get validationInvalidOtp;

  /// No description provided for @validationTooShort.
  ///
  /// In ka, this message translates to:
  /// **'ძალიან მოკლეა'**
  String get validationTooShort;

  /// No description provided for @validationTooLong.
  ///
  /// In ka, this message translates to:
  /// **'ძალიან გრძელია'**
  String get validationTooLong;

  /// No description provided for @validationInvalidName.
  ///
  /// In ka, this message translates to:
  /// **'გამოიყენეთ მხოლოდ ასოები'**
  String get validationInvalidName;

  /// No description provided for @validationDateInFuture.
  ///
  /// In ka, this message translates to:
  /// **'თარიღი მომავალშია'**
  String get validationDateInFuture;

  /// No description provided for @validationTooOldForChild.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის ასაკი უნდა იყოს 18 წლამდე'**
  String get validationTooOldForChild;

  /// No description provided for @validationTooYoung.
  ///
  /// In ka, this message translates to:
  /// **'მინიმალური ასაკი 3 წელია'**
  String get validationTooYoung;

  /// No description provided for @validationSportRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ მინიმუმ ერთი სპორტი'**
  String get validationSportRequired;

  /// No description provided for @validationClubRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ კლუბი'**
  String get validationClubRequired;

  /// No description provided for @validationConsentRequired.
  ///
  /// In ka, this message translates to:
  /// **'გასაგრძელებლად საჭიროა თანხმობა'**
  String get validationConsentRequired;

  /// No description provided for @validationVenueRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ ადგილი'**
  String get validationVenueRequired;

  /// No description provided for @validationDurationRange.
  ///
  /// In ka, this message translates to:
  /// **'ხანგრძლივობა 15–300 წუთი'**
  String get validationDurationRange;

  /// No description provided for @validationFocusRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ მინიმუმ ერთი თემა'**
  String get validationFocusRequired;

  /// No description provided for @validationDescriptionTooLong.
  ///
  /// In ka, this message translates to:
  /// **'აღწერა ძალიან გრძელია'**
  String get validationDescriptionTooLong;

  /// No description provided for @validationStartInPast.
  ///
  /// In ka, this message translates to:
  /// **'დრო უკვე გასულია'**
  String get validationStartInPast;

  /// No description provided for @validationPhotoConsentRequired.
  ///
  /// In ka, this message translates to:
  /// **'დაადასტურეთ ფოტოებზე თანხმობის პირობა'**
  String get validationPhotoConsentRequired;

  /// No description provided for @validationFileType.
  ///
  /// In ka, this message translates to:
  /// **'დასაშვებია მხოლოდ JPG, PNG ან PDF'**
  String get validationFileType;

  /// No description provided for @validationFileTooLarge.
  ///
  /// In ka, this message translates to:
  /// **'ფაილი 10 MB-ზე დიდია'**
  String get validationFileTooLarge;

  /// No description provided for @validationFileEmpty.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ ფაილი'**
  String get validationFileEmpty;

  /// No description provided for @validationDatesOrder.
  ///
  /// In ka, this message translates to:
  /// **'ვადა გაცემის თარიღის შემდეგ უნდა იყოს'**
  String get validationDatesOrder;

  /// No description provided for @validationIssuedInFuture.
  ///
  /// In ka, this message translates to:
  /// **'გაცემის თარიღი მომავალშია'**
  String get validationIssuedInFuture;

  /// No description provided for @validationEmptyMessage.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინება ცარიელია'**
  String get validationEmptyMessage;

  /// No description provided for @validationMessageTooLong.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინება ძალიან გრძელია'**
  String get validationMessageTooLong;

  /// No description provided for @validationAmountPositive.
  ///
  /// In ka, this message translates to:
  /// **'თანხა უნდა იყოს 0-ზე მეტი'**
  String get validationAmountPositive;

  /// No description provided for @validationDayOfMonth.
  ///
  /// In ka, this message translates to:
  /// **'რიცხვი 1-დან 28-მდე'**
  String get validationDayOfMonth;

  /// No description provided for @validationAlreadyMember.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი უკვე ამ ჯგუფშია'**
  String get validationAlreadyMember;

  /// No description provided for @validationRequestExists.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნა უკვე გაგზავნილია'**
  String get validationRequestExists;

  /// No description provided for @onboardingTitle1.
  ///
  /// In ka, this message translates to:
  /// **'ყველა ვარჯიში ერთ კალენდარში'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In ka, this message translates to:
  /// **'დრო, ადგილი და მწვრთნელი — ყოველთვის ხელთ. ცვლილებებს მაშინვე გაიგებთ.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In ka, this message translates to:
  /// **'პირდაპირი კავშირი მწვრთნელთან'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის ჩატი მშობლებისა და მწვრთნელებისთვის, ფოტოები ვარჯიშებიდან.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In ka, this message translates to:
  /// **'ცნობები და გადახდები უსაფრთხოდ'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In ka, this message translates to:
  /// **'ჯანმრთელობის ცნობები დაცულ საცავში, შეხსენებები ვადებზე და გადასახადებზე.'**
  String get onboardingBody3;

  /// No description provided for @onboardingStart.
  ///
  /// In ka, this message translates to:
  /// **'დავიწყოთ'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In ka, this message translates to:
  /// **'გამოტოვება'**
  String get onboardingSkip;

  /// No description provided for @phoneTitle.
  ///
  /// In ka, this message translates to:
  /// **'შესვლა ტელეფონით'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In ka, this message translates to:
  /// **'გამოგიგზავნით ერთჯერად SMS კოდს. პაროლი არ გჭირდებათ.'**
  String get phoneSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In ka, this message translates to:
  /// **'მობილურის ნომერი'**
  String get phoneLabel;

  /// No description provided for @sendCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდის მიღება'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ კოდი'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In ka, this message translates to:
  /// **'6-ნიშნა კოდი გაიგზავნა ნომერზე {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @verify.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურება'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდის ხელახლა გაგზავნა'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In ka, this message translates to:
  /// **'ხელახლა გაგზავნა {seconds} წამში'**
  String resendIn(int seconds);

  /// No description provided for @demoOtpHint.
  ///
  /// In ka, this message translates to:
  /// **'დემო რეჟიმი: შეიყვანეთ 123456'**
  String get demoOtpHint;

  /// No description provided for @demoAccountsTitle.
  ///
  /// In ka, this message translates to:
  /// **'სწრაფი შესვლა დემო ანგარიშით'**
  String get demoAccountsTitle;

  /// No description provided for @demoAccountsSubtitle.
  ///
  /// In ka, this message translates to:
  /// **'გამოგონილი მონაცემები — რეალური SMS, გადახდა ან სამედიცინო ინფორმაცია არ გამოიყენება.'**
  String get demoAccountsSubtitle;

  /// No description provided for @demoPendingCoach.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელი (დასადასტურებელი)'**
  String get demoPendingCoach;

  /// No description provided for @guestBrowse.
  ///
  /// In ka, this message translates to:
  /// **'კლუბების ნახვა შესვლის გარეშე'**
  String get guestBrowse;

  /// No description provided for @termsNote.
  ///
  /// In ka, this message translates to:
  /// **'გაგრძელებით ეთანხმებით მომსახურების პირობებს და კონფიდენციალურობის პოლიტიკას.'**
  String get termsNote;

  /// No description provided for @registerTitle.
  ///
  /// In ka, this message translates to:
  /// **'პროფილის შექმნა'**
  String get registerTitle;

  /// No description provided for @chooseRole.
  ///
  /// In ka, this message translates to:
  /// **'ვინ ხართ?'**
  String get chooseRole;

  /// No description provided for @roleParent.
  ///
  /// In ka, this message translates to:
  /// **'მშობელი'**
  String get roleParent;

  /// No description provided for @roleParentDesc.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვების ვარჯიშები, ჩატი მწვრთნელთან, ცნობები და გადახდები'**
  String get roleParentDesc;

  /// No description provided for @roleCoach.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელი'**
  String get roleCoach;

  /// No description provided for @roleCoachDesc.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფების მართვა, ვარჯიშების დაგეგმვა. საჭიროებს კლუბის დადასტურებას.'**
  String get roleCoachDesc;

  /// No description provided for @roleChild.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი'**
  String get roleChild;

  /// No description provided for @roleChildDesc.
  ///
  /// In ka, this message translates to:
  /// **'14 წლამდე ბავშვის პროფილს მშობელი ქმნის. 14–17 წლის ანგარიშები მალე დაემატება.'**
  String get roleChildDesc;

  /// No description provided for @soon.
  ///
  /// In ka, this message translates to:
  /// **'მალე'**
  String get soon;

  /// No description provided for @firstName.
  ///
  /// In ka, this message translates to:
  /// **'სახელი'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ka, this message translates to:
  /// **'გვარი'**
  String get lastName;

  /// No description provided for @sportsLabel.
  ///
  /// In ka, this message translates to:
  /// **'სპორტის სახეობები'**
  String get sportsLabel;

  /// No description provided for @clubsLabel.
  ///
  /// In ka, this message translates to:
  /// **'კლუბი'**
  String get clubsLabel;

  /// No description provided for @consentData.
  ///
  /// In ka, this message translates to:
  /// **'ვეთანხმები პერსონალური მონაცემების დამუშავებას'**
  String get consentData;

  /// No description provided for @consentDataDetails.
  ///
  /// In ka, this message translates to:
  /// **'ვამუშავებთ სახელს, ტელეფონს და ბავშვის სავარჯიშო მონაცემებს მხოლოდ სერვისის მიწოდებისთვის. ნებისმიერ დროს შეგიძლიათ ანგარიშის წაშლა.'**
  String get consentDataDetails;

  /// No description provided for @consentSms.
  ///
  /// In ka, this message translates to:
  /// **'ვეთანხმები SMS შეხსენებების მიღებას გადასახადებზე'**
  String get consentSms;

  /// No description provided for @finishRegistration.
  ///
  /// In ka, this message translates to:
  /// **'დასრულება'**
  String get finishRegistration;

  /// No description provided for @stepOf.
  ///
  /// In ka, this message translates to:
  /// **'ნაბიჯი {current} / {total}'**
  String stepOf(int current, int total);

  /// No description provided for @coachPendingTitle.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში მოწმდება'**
  String get coachPendingTitle;

  /// No description provided for @coachPendingBody.
  ///
  /// In ka, this message translates to:
  /// **'კლუბის ადმინისტრატორი ადასტურებს მწვრთნელის როლს. დადასტურებამდე ბავშვების მონაცემები არ ჩანს — ეს იცავს ბავშვებს.'**
  String get coachPendingBody;

  /// No description provided for @coachPendingDemoApprove.
  ///
  /// In ka, this message translates to:
  /// **'დემო: დადასტურება ადმინისტრატორის სახელით'**
  String get coachPendingDemoApprove;

  /// No description provided for @coachRejectedTitle.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნა უარყოფილია'**
  String get coachRejectedTitle;

  /// No description provided for @coachRejectedBody.
  ///
  /// In ka, this message translates to:
  /// **'დაუკავშირდით კლუბის ადმინისტრაციას.'**
  String get coachRejectedBody;

  /// No description provided for @childAccountUnsupported.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის დამოუკიდებელი ანგარიში ჯერ არ არის ხელმისაწვდომი. ვარჯიშებს მშობლის ანგარიშიდან ნახავთ.'**
  String get childAccountUnsupported;

  /// No description provided for @signOut.
  ///
  /// In ka, this message translates to:
  /// **'გასვლა'**
  String get signOut;

  /// No description provided for @navHome.
  ///
  /// In ka, this message translates to:
  /// **'მთავარი'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In ka, this message translates to:
  /// **'კალენდარი'**
  String get navCalendar;

  /// No description provided for @navChat.
  ///
  /// In ka, this message translates to:
  /// **'ჩატი'**
  String get navChat;

  /// No description provided for @navMap.
  ///
  /// In ka, this message translates to:
  /// **'რუკა'**
  String get navMap;

  /// No description provided for @navProfile.
  ///
  /// In ka, this message translates to:
  /// **'პროფილი'**
  String get navProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In ka, this message translates to:
  /// **'დილა მშვიდობისა, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingDay.
  ///
  /// In ka, this message translates to:
  /// **'გამარჯობა, {name}'**
  String greetingDay(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In ka, this message translates to:
  /// **'საღამო მშვიდობისა, {name}'**
  String greetingEvening(String name);

  /// No description provided for @nextTraining.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგი ვარჯიში'**
  String get nextTraining;

  /// No description provided for @noUpcomingTrainings.
  ///
  /// In ka, this message translates to:
  /// **'უახლოესი ვარჯიში ჯერ არ არის დაგეგმილი'**
  String get noUpcomingTrainings;

  /// No description provided for @directions.
  ///
  /// In ka, this message translates to:
  /// **'მარშრუტი'**
  String get directions;

  /// No description provided for @details.
  ///
  /// In ka, this message translates to:
  /// **'დეტალები'**
  String get details;

  /// No description provided for @coachLabel.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელი'**
  String get coachLabel;

  /// No description provided for @venueLabel.
  ///
  /// In ka, this message translates to:
  /// **'ადგილი'**
  String get venueLabel;

  /// No description provided for @medicalStatus.
  ///
  /// In ka, this message translates to:
  /// **'ჯანმრთელობის ცნობა'**
  String get medicalStatus;

  /// No description provided for @coachMessages.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის შეტყობინებები'**
  String get coachMessages;

  /// No description provided for @recentPhotos.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოები ვარჯიშებიდან'**
  String get recentPhotos;

  /// No description provided for @paymentSummary.
  ///
  /// In ka, this message translates to:
  /// **'გადასახადი'**
  String get paymentSummary;

  /// No description provided for @noChildrenTitle.
  ///
  /// In ka, this message translates to:
  /// **'დაამატეთ პირველი ბავშვი'**
  String get noChildrenTitle;

  /// No description provided for @noChildrenBody.
  ///
  /// In ka, this message translates to:
  /// **'შექმენით ბავშვის პროფილი და აირჩიეთ სპორტი — დანარჩენს ჩვენ მივხედავთ.'**
  String get noChildrenBody;

  /// No description provided for @addChild.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის დამატება'**
  String get addChild;

  /// No description provided for @noGroupTitle.
  ///
  /// In ka, this message translates to:
  /// **'{name} ჯერ არ არის ჯგუფში'**
  String noGroupTitle(String name);

  /// No description provided for @noGroupBody.
  ///
  /// In ka, this message translates to:
  /// **'იპოვეთ კლუბი რუკაზე და გაგზავნეთ გაწევრიანების მოთხოვნა.'**
  String get noGroupBody;

  /// No description provided for @findClub.
  ///
  /// In ka, this message translates to:
  /// **'კლუბის პოვნა'**
  String get findClub;

  /// No description provided for @inDays.
  ///
  /// In ka, this message translates to:
  /// **'{count, plural, =0{დღეს} =1{ხვალ} other{{count} დღეში}}'**
  String inDays(int count);

  /// No description provided for @startsInHours.
  ///
  /// In ka, this message translates to:
  /// **'{count, plural, =0{იწყება მალე} other{{count} საათში}}'**
  String startsInHours(int count);

  /// No description provided for @noMessages.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინებები ჯერ არ არის'**
  String get noMessages;

  /// No description provided for @noPhotos.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოები გამოჩნდება ვარჯიშების შემდეგ'**
  String get noPhotos;

  /// No description provided for @allPaid.
  ///
  /// In ka, this message translates to:
  /// **'ყველა გადასახადი დაფარულია'**
  String get allPaid;

  /// No description provided for @yearsOld.
  ///
  /// In ka, this message translates to:
  /// **'{count} წლის'**
  String yearsOld(int count);

  /// No description provided for @openChat.
  ///
  /// In ka, this message translates to:
  /// **'ჩატის გახსნა'**
  String get openChat;

  /// No description provided for @statusScheduled.
  ///
  /// In ka, this message translates to:
  /// **'დაგეგმილი'**
  String get statusScheduled;

  /// No description provided for @statusCancelled.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმებული'**
  String get statusCancelled;

  /// No description provided for @statusMoved.
  ///
  /// In ka, this message translates to:
  /// **'გადატანილი'**
  String get statusMoved;

  /// No description provided for @statusDone.
  ///
  /// In ka, this message translates to:
  /// **'ჩატარებული'**
  String get statusDone;

  /// No description provided for @focusTechnique.
  ///
  /// In ka, this message translates to:
  /// **'ტექნიკა'**
  String get focusTechnique;

  /// No description provided for @focusSpeed.
  ///
  /// In ka, this message translates to:
  /// **'სისწრაფე'**
  String get focusSpeed;

  /// No description provided for @focusPhysical.
  ///
  /// In ka, this message translates to:
  /// **'ფიზიკური მომზადება'**
  String get focusPhysical;

  /// No description provided for @focusBall.
  ///
  /// In ka, this message translates to:
  /// **'ბურთთან მუშაობა'**
  String get focusBall;

  /// No description provided for @durationMinutes.
  ///
  /// In ka, this message translates to:
  /// **'{count} წთ'**
  String durationMinutes(int count);

  /// No description provided for @trainingTitle.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში'**
  String get trainingTitle;

  /// No description provided for @trainingDescription.
  ///
  /// In ka, this message translates to:
  /// **'აღწერა'**
  String get trainingDescription;

  /// No description provided for @trainingFocus.
  ///
  /// In ka, this message translates to:
  /// **'თემა'**
  String get trainingFocus;

  /// No description provided for @trainingPhotos.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოები'**
  String get trainingPhotos;

  /// No description provided for @movedFrom.
  ///
  /// In ka, this message translates to:
  /// **'გადატანილია {date}-დან'**
  String movedFrom(String date);

  /// No description provided for @cancelledBanner.
  ///
  /// In ka, this message translates to:
  /// **'ეს ვარჯიში გაუქმდა'**
  String get cancelledBanner;

  /// No description provided for @newTraining.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ვარჯიში'**
  String get newTraining;

  /// No description provided for @editTraining.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშის რედაქტირება'**
  String get editTraining;

  /// No description provided for @cancelTraining.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმება'**
  String get cancelTraining;

  /// No description provided for @cancelTrainingConfirm.
  ///
  /// In ka, this message translates to:
  /// **'გავაუქმოთ ვარჯიში? ჯგუფის მშობლები მიიღებენ შეტყობინებას.'**
  String get cancelTrainingConfirm;

  /// No description provided for @keepTraining.
  ///
  /// In ka, this message translates to:
  /// **'არა, დავტოვოთ'**
  String get keepTraining;

  /// No description provided for @rescheduleTraining.
  ///
  /// In ka, this message translates to:
  /// **'გადატანა'**
  String get rescheduleTraining;

  /// No description provided for @markDone.
  ///
  /// In ka, this message translates to:
  /// **'ჩატარებულია'**
  String get markDone;

  /// No description provided for @addPhotos.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოების დამატება'**
  String get addPhotos;

  /// No description provided for @dateLabel.
  ///
  /// In ka, this message translates to:
  /// **'თარიღი'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In ka, this message translates to:
  /// **'დაწყების დრო'**
  String get timeLabel;

  /// No description provided for @durationLabel.
  ///
  /// In ka, this message translates to:
  /// **'ხანგრძლივობა'**
  String get durationLabel;

  /// No description provided for @trainingSaved.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში შენახულია და მშობლებს ეცნობათ'**
  String get trainingSaved;

  /// No description provided for @trainingCancelled.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში გაუქმდა'**
  String get trainingCancelled;

  /// No description provided for @trainingRescheduled.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში გადატანილია'**
  String get trainingRescheduled;

  /// No description provided for @trainingMarkedDone.
  ///
  /// In ka, this message translates to:
  /// **'მონიშნულია ჩატარებულად'**
  String get trainingMarkedDone;

  /// No description provided for @photoConsentTitle.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოებზე თანხმობა'**
  String get photoConsentTitle;

  /// No description provided for @photoConsentMissing.
  ///
  /// In ka, this message translates to:
  /// **'თანხმობა არ აქვს: {names}. ეს ბავშვები ფოტოზე არ უნდა ჩანდნენ.'**
  String photoConsentMissing(String names);

  /// No description provided for @photoConsentAllGiven.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის ყველა ბავშვს აქვს მშობლის თანხმობა ფოტოებზე.'**
  String get photoConsentAllGiven;

  /// No description provided for @photoConsentConfirm.
  ///
  /// In ka, this message translates to:
  /// **'ვადასტურებ, რომ ფოტოებზე არ ჩანან ბავშვები თანხმობის გარეშე'**
  String get photoConsentConfirm;

  /// No description provided for @selectVenue.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ ადგილი'**
  String get selectVenue;

  /// No description provided for @descriptionHint.
  ///
  /// In ka, this message translates to:
  /// **'რას ვივარჯიშებთ? მაგ.: პასები, დარტყმა კარში…'**
  String get descriptionHint;

  /// No description provided for @groupLabel.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფი'**
  String get groupLabel;

  /// No description provided for @photosAdded.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოები დაემატა'**
  String get photosAdded;

  /// No description provided for @customDuration.
  ///
  /// In ka, this message translates to:
  /// **'სხვა'**
  String get customDuration;

  /// No description provided for @saveTraining.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშის შენახვა'**
  String get saveTraining;

  /// No description provided for @trainingFromTo.
  ///
  /// In ka, this message translates to:
  /// **'{start} – {end}'**
  String trainingFromTo(String start, String end);

  /// No description provided for @trainingHistory.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშების ისტორია'**
  String get trainingHistory;

  /// No description provided for @upcoming.
  ///
  /// In ka, this message translates to:
  /// **'მომავალი ვარჯიშები'**
  String get upcoming;

  /// No description provided for @noTrainingsDay.
  ///
  /// In ka, this message translates to:
  /// **'ამ დღეს ვარჯიში არ არის'**
  String get noTrainingsDay;

  /// No description provided for @allChildren.
  ///
  /// In ka, this message translates to:
  /// **'ყველა ბავშვი'**
  String get allChildren;

  /// No description provided for @coachHomeSubtitle.
  ///
  /// In ka, this message translates to:
  /// **'დღევანდელი სურათი თქვენს ჯგუფებში'**
  String get coachHomeSubtitle;

  /// No description provided for @groupMembers.
  ///
  /// In ka, this message translates to:
  /// **'{count} ბავშვი'**
  String groupMembers(int count);

  /// No description provided for @roster.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის წევრები'**
  String get roster;

  /// No description provided for @noGroupsCoach.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფები ჯერ არ გაქვთ მინიჭებული. მიმართეთ კლუბის ადმინისტრატორს.'**
  String get noGroupsCoach;

  /// No description provided for @membershipRequests.
  ///
  /// In ka, this message translates to:
  /// **'გაწევრიანების მოთხოვნები'**
  String get membershipRequests;

  /// No description provided for @approve.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურება'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფა'**
  String get reject;

  /// No description provided for @requestApproved.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი დაემატა ჯგუფს'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნა უარყოფილია'**
  String get requestRejected;

  /// No description provided for @removeFromGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფიდან ამოშლა'**
  String get removeFromGroup;

  /// No description provided for @removeFromGroupConfirm.
  ///
  /// In ka, this message translates to:
  /// **'ამოვშალოთ {name} ჯგუფიდან? თქვენი წვდომა ბავშვის მონაცემებსა და ცნობებზე ავტომატურად შეწყდება.'**
  String removeFromGroupConfirm(String name);

  /// No description provided for @parentsLabel.
  ///
  /// In ka, this message translates to:
  /// **'მშობლები'**
  String get parentsLabel;

  /// No description provided for @call.
  ///
  /// In ka, this message translates to:
  /// **'დარეკვა'**
  String get call;

  /// No description provided for @viewCertificate.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის გახსნა'**
  String get viewCertificate;

  /// No description provided for @ageRange.
  ///
  /// In ka, this message translates to:
  /// **'{min}–{max} წელი'**
  String ageRange(int min, int max);

  /// No description provided for @statMembers.
  ///
  /// In ka, this message translates to:
  /// **'წევრი'**
  String get statMembers;

  /// No description provided for @statThisWeek.
  ///
  /// In ka, this message translates to:
  /// **'ამ კვირაში'**
  String get statThisWeek;

  /// No description provided for @statCertAlerts.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის პრობლემა'**
  String get statCertAlerts;

  /// No description provided for @wantsToJoin.
  ///
  /// In ka, this message translates to:
  /// **'{child} სურს გაწევრიანება ჯგუფში {group}'**
  String wantsToJoin(String child, String group);

  /// No description provided for @todayTrainings.
  ///
  /// In ka, this message translates to:
  /// **'დღევანდელი და მომავალი ვარჯიშები'**
  String get todayTrainings;

  /// No description provided for @selectGroupTitle.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ ჯგუფი'**
  String get selectGroupTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In ka, this message translates to:
  /// **'დაიწყეთ საუბარი ჯგუფთან'**
  String get chatEmpty;

  /// No description provided for @typeMessage.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინება…'**
  String get typeMessage;

  /// No description provided for @chatGroups.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის ჩატები'**
  String get chatGroups;

  /// No description provided for @chatNotAllowed.
  ///
  /// In ka, this message translates to:
  /// **'ჩატი ხელმისაწვდომია მხოლოდ მშობლებისა და მწვრთნელებისთვის.'**
  String get chatNotAllowed;

  /// No description provided for @chatPrivacyNote.
  ///
  /// In ka, this message translates to:
  /// **'ჩატში მხოლოდ ჯგუფის მწვრთნელები და მშობლები არიან. ტელეფონის ნომრები სხვა მშობლებს არ უჩანთ.'**
  String get chatPrivacyNote;

  /// No description provided for @noChats.
  ///
  /// In ka, this message translates to:
  /// **'ჩატები გამოჩნდება, როცა ბავშვი ჯგუფში გაწევრიანდება'**
  String get noChats;

  /// No description provided for @photoAttachment.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო'**
  String get photoAttachment;

  /// No description provided for @searchPlaces.
  ///
  /// In ka, this message translates to:
  /// **'ძიება სახელით ან მისამართით'**
  String get searchPlaces;

  /// No description provided for @allSports.
  ///
  /// In ka, this message translates to:
  /// **'ყველა'**
  String get allSports;

  /// No description provided for @venueStadium.
  ///
  /// In ka, this message translates to:
  /// **'სტადიონი'**
  String get venueStadium;

  /// No description provided for @venueHall.
  ///
  /// In ka, this message translates to:
  /// **'დარბაზი'**
  String get venueHall;

  /// No description provided for @venueField.
  ///
  /// In ka, this message translates to:
  /// **'მოედანი'**
  String get venueField;

  /// No description provided for @venuePool.
  ///
  /// In ka, this message translates to:
  /// **'აუზი'**
  String get venuePool;

  /// No description provided for @clubLabel.
  ///
  /// In ka, this message translates to:
  /// **'კლუბი'**
  String get clubLabel;

  /// No description provided for @groupsLabel.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფები'**
  String get groupsLabel;

  /// No description provided for @requestMembership.
  ///
  /// In ka, this message translates to:
  /// **'გაწევრიანების მოთხოვნა'**
  String get requestMembership;

  /// No description provided for @requestSent.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნა გაიგზავნა მწვრთნელთან'**
  String get requestSent;

  /// No description provided for @selectChild.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ ბავშვი'**
  String get selectChild;

  /// No description provided for @openInMaps.
  ///
  /// In ka, this message translates to:
  /// **'გახსნა რუკის აპლიკაციაში'**
  String get openInMaps;

  /// No description provided for @mapNoResults.
  ///
  /// In ka, this message translates to:
  /// **'ამ ფილტრით ლოკაცია ვერ მოიძებნა'**
  String get mapNoResults;

  /// No description provided for @distanceKm.
  ///
  /// In ka, this message translates to:
  /// **'{km} კმ'**
  String distanceKm(String km);

  /// No description provided for @clubDetails.
  ///
  /// In ka, this message translates to:
  /// **'კლუბის გვერდი'**
  String get clubDetails;

  /// No description provided for @noGroupsInClub.
  ///
  /// In ka, this message translates to:
  /// **'ამ კლუბში ჯგუფები ჯერ არ არის'**
  String get noGroupsInClub;

  /// No description provided for @signInToJoin.
  ///
  /// In ka, this message translates to:
  /// **'გაწევრიანებისთვის შედით ანგარიშზე'**
  String get signInToJoin;

  /// No description provided for @mapAttribution.
  ///
  /// In ka, this message translates to:
  /// **'© OpenStreetMap'**
  String get mapAttribution;

  /// No description provided for @placesCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} ლოკაცია'**
  String placesCount(int count);

  /// No description provided for @certificatesTitle.
  ///
  /// In ka, this message translates to:
  /// **'ჯანმრთელობის ცნობები'**
  String get certificatesTitle;

  /// No description provided for @certValid.
  ///
  /// In ka, this message translates to:
  /// **'მოქმედებს'**
  String get certValid;

  /// No description provided for @certExpiring.
  ///
  /// In ka, this message translates to:
  /// **'იწურება'**
  String get certExpiring;

  /// No description provided for @certExpired.
  ///
  /// In ka, this message translates to:
  /// **'ვადაგასული'**
  String get certExpired;

  /// No description provided for @certMissing.
  ///
  /// In ka, this message translates to:
  /// **'არ არის'**
  String get certMissing;

  /// No description provided for @validUntil.
  ///
  /// In ka, this message translates to:
  /// **'მოქმედებს {date}-მდე'**
  String validUntil(String date);

  /// No description provided for @issuedOn.
  ///
  /// In ka, this message translates to:
  /// **'გაცემულია {date}'**
  String issuedOn(String date);

  /// No description provided for @uploadCertificate.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის ატვირთვა'**
  String get uploadCertificate;

  /// No description provided for @certConsentTitle.
  ///
  /// In ka, this message translates to:
  /// **'სანამ ატვირთავთ'**
  String get certConsentTitle;

  /// No description provided for @certConsentWhat.
  ///
  /// In ka, this message translates to:
  /// **'რა მონაცემი მუშავდება'**
  String get certConsentWhat;

  /// No description provided for @certConsentWhatBody.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის ფაილი, გაცემის თარიღი და მოქმედების ვადა. ჯანმრთელობის მონაცემი განსაკუთრებული კატეგორიაა და დაცულია კანონით.'**
  String get certConsentWhatBody;

  /// No description provided for @certConsentWho.
  ///
  /// In ka, this message translates to:
  /// **'ვის ექნება წვდომა'**
  String get certConsentWho;

  /// No description provided for @certConsentWhoBody.
  ///
  /// In ka, this message translates to:
  /// **'თქვენ და იმ ჯგუფის მწვრთნელებს, სადაც ბავშვი ამჟამად ვარჯიშობს. მწვრთნელი ხედავს სტატუსს, ფაილის გახსნა ცალკე ქმედებაა და აღირიცხება ჟურნალში.'**
  String get certConsentWhoBody;

  /// No description provided for @certConsentDelete.
  ///
  /// In ka, this message translates to:
  /// **'როგორ წაიშლება'**
  String get certConsentDelete;

  /// No description provided for @certConsentDeleteBody.
  ///
  /// In ka, this message translates to:
  /// **'ნებისმიერ დროს შეგიძლიათ წაშლა. ანგარიშის წაშლისას ყველა ცნობა სრულად იშლება. ჯგუფიდან გასვლისას მწვრთნელის წვდომა წყდება.'**
  String get certConsentDeleteBody;

  /// No description provided for @certConsentAgree.
  ///
  /// In ka, this message translates to:
  /// **'ვეთანხმები ჯანმრთელობის ცნობის დამუშავებას ზემოთ აღწერილი პირობებით'**
  String get certConsentAgree;

  /// No description provided for @takePhoto.
  ///
  /// In ka, this message translates to:
  /// **'კამერა'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In ka, this message translates to:
  /// **'გალერეა'**
  String get fromGallery;

  /// No description provided for @pickDocument.
  ///
  /// In ka, this message translates to:
  /// **'ფაილი (PDF)'**
  String get pickDocument;

  /// No description provided for @issueDate.
  ///
  /// In ka, this message translates to:
  /// **'გაცემის თარიღი'**
  String get issueDate;

  /// No description provided for @expiryDate.
  ///
  /// In ka, this message translates to:
  /// **'მოქმედების ვადა'**
  String get expiryDate;

  /// No description provided for @fileRequirements.
  ///
  /// In ka, this message translates to:
  /// **'JPG, PNG ან PDF · მაქსიმუმ 10 MB'**
  String get fileRequirements;

  /// No description provided for @certUploaded.
  ///
  /// In ka, this message translates to:
  /// **'ცნობა ატვირთულია'**
  String get certUploaded;

  /// No description provided for @deleteCertificate.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის წაშლა'**
  String get deleteCertificate;

  /// No description provided for @deleteCertificateConfirm.
  ///
  /// In ka, this message translates to:
  /// **'წავშალოთ ცნობა? ფაილი საცავიდან სრულად წაიშლება.'**
  String get deleteCertificateConfirm;

  /// No description provided for @certDeleted.
  ///
  /// In ka, this message translates to:
  /// **'ცნობა წაიშალა'**
  String get certDeleted;

  /// No description provided for @openFile.
  ///
  /// In ka, this message translates to:
  /// **'ფაილის გახსნა'**
  String get openFile;

  /// No description provided for @accessExpiresIn.
  ///
  /// In ka, this message translates to:
  /// **'დროებითი წვდომა · იწურება {minutes} წუთში'**
  String accessExpiresIn(int minutes);

  /// No description provided for @accessExpired.
  ///
  /// In ka, this message translates to:
  /// **'წვდომის ვადა ამოიწურა. გახსენით ხელახლა.'**
  String get accessExpired;

  /// No description provided for @demoDocument.
  ///
  /// In ka, this message translates to:
  /// **'დემო დოკუმენტი'**
  String get demoDocument;

  /// No description provided for @demoDocumentBody.
  ///
  /// In ka, this message translates to:
  /// **'დემო რეჟიმში რეალური სამედიცინო ფაილები არ ინახება. პროდაქშენში ფაილი იხსნება 5-წუთიანი ხელმოწერილი ბმულით.'**
  String get demoDocumentBody;

  /// No description provided for @accessLog.
  ///
  /// In ka, this message translates to:
  /// **'წვდომის ჟურნალი'**
  String get accessLog;

  /// No description provided for @accessLogOpen.
  ///
  /// In ka, this message translates to:
  /// **'{name} — გახსნა'**
  String accessLogOpen(String name);

  /// No description provided for @accessLogDenied.
  ///
  /// In ka, this message translates to:
  /// **'{name} — უარი'**
  String accessLogDenied(String name);

  /// No description provided for @accessLogDelete.
  ///
  /// In ka, this message translates to:
  /// **'{name} — წაშლა'**
  String accessLogDelete(String name);

  /// No description provided for @noCertificates.
  ///
  /// In ka, this message translates to:
  /// **'ცნობა ჯერ არ არის ატვირთული'**
  String get noCertificates;

  /// No description provided for @certExpiresIn.
  ///
  /// In ka, this message translates to:
  /// **'{count, plural, =0{ვადა იწურება დღეს} =1{ვადა იწურება ხვალ} other{ვადა იწურება {count} დღეში}}'**
  String certExpiresIn(int count);

  /// No description provided for @certExpiredAgo.
  ///
  /// In ka, this message translates to:
  /// **'ვადა გავიდა {count} დღის წინ'**
  String certExpiredAgo(int count);

  /// No description provided for @certRemindersNote.
  ///
  /// In ka, this message translates to:
  /// **'შეხსენებას მიიღებთ ვადის გასვლამდე 14 და 3 დღით ადრე და ვადის დღეს.'**
  String get certRemindersNote;

  /// No description provided for @fileSelected.
  ///
  /// In ka, this message translates to:
  /// **'არჩეულია: {name}'**
  String fileSelected(String name);

  /// No description provided for @notificationsTitle.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინებები'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ka, this message translates to:
  /// **'ახალი შეტყობინება არ გაქვთ'**
  String get notificationsEmpty;

  /// No description provided for @markAllRead.
  ///
  /// In ka, this message translates to:
  /// **'ყველას წაკითხვა'**
  String get markAllRead;

  /// No description provided for @notifNewTraining.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ვარჯიში'**
  String get notifNewTraining;

  /// No description provided for @notifTrainingChanged.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში შეიცვალა'**
  String get notifTrainingChanged;

  /// No description provided for @notifTrainingReminder.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში 2 საათში'**
  String get notifTrainingReminder;

  /// No description provided for @notifChatMessage.
  ///
  /// In ka, this message translates to:
  /// **'ახალი შეტყობინება'**
  String get notifChatMessage;

  /// No description provided for @notifCertificateExpiry.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის ვადა იწურება'**
  String get notifCertificateExpiry;

  /// No description provided for @notifNewPhotos.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ფოტოები'**
  String get notifNewPhotos;

  /// No description provided for @notifPaymentReminder.
  ///
  /// In ka, this message translates to:
  /// **'გადასახადის შეხსენება'**
  String get notifPaymentReminder;

  /// No description provided for @notifPaymentSms.
  ///
  /// In ka, this message translates to:
  /// **'SMS შეხსენება გადასახადზე'**
  String get notifPaymentSms;

  /// No description provided for @notifBodyGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფი: {group}'**
  String notifBodyGroup(String group);

  /// No description provided for @notifBodyChat.
  ///
  /// In ka, this message translates to:
  /// **'{sender} · {group}'**
  String notifBodyChat(String sender, String group);

  /// No description provided for @notifBodyCert.
  ///
  /// In ka, this message translates to:
  /// **'{child} — {days} დღე დარჩა'**
  String notifBodyCert(String child, String days);

  /// No description provided for @notifBodyPayment.
  ///
  /// In ka, this message translates to:
  /// **'{child} — {amount} ₾'**
  String notifBodyPayment(String child, String amount);

  /// No description provided for @notificationSettings.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინებების პარამეტრები'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsHint.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ, რა ტიპის შეტყობინებები მიიღოთ.'**
  String get notificationSettingsHint;

  /// No description provided for @pushDemoNote.
  ///
  /// In ka, this message translates to:
  /// **'დემო რეჟიმში push შეტყობინებები არ იგზავნება — ისინი ჩნდება აპის შიგნით.'**
  String get pushDemoNote;

  /// No description provided for @paymentsTitle.
  ///
  /// In ka, this message translates to:
  /// **'გადახდები'**
  String get paymentsTitle;

  /// No description provided for @paymentPending.
  ///
  /// In ka, this message translates to:
  /// **'გადასახდელი'**
  String get paymentPending;

  /// No description provided for @paymentPaid.
  ///
  /// In ka, this message translates to:
  /// **'გადახდილი'**
  String get paymentPaid;

  /// No description provided for @paymentCancelled.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმებული'**
  String get paymentCancelled;

  /// No description provided for @paymentOverdue.
  ///
  /// In ka, this message translates to:
  /// **'ვადაგადაცილებული'**
  String get paymentOverdue;

  /// No description provided for @totalDue.
  ///
  /// In ka, this message translates to:
  /// **'სულ გადასახდელი'**
  String get totalDue;

  /// No description provided for @dueOn.
  ///
  /// In ka, this message translates to:
  /// **'ვადა: {date}'**
  String dueOn(String date);

  /// No description provided for @paidOn.
  ///
  /// In ka, this message translates to:
  /// **'გადახდილია {date}'**
  String paidOn(String date);

  /// No description provided for @markPaid.
  ///
  /// In ka, this message translates to:
  /// **'გადახდილია'**
  String get markPaid;

  /// No description provided for @markPending.
  ///
  /// In ka, this message translates to:
  /// **'დაბრუნება მოლოდინში'**
  String get markPending;

  /// No description provided for @cancelPayment.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმება'**
  String get cancelPayment;

  /// No description provided for @chargeGroup.
  ///
  /// In ka, this message translates to:
  /// **'ერთჯერადი გადასახადი'**
  String get chargeGroup;

  /// No description provided for @chargeGroupHint.
  ///
  /// In ka, this message translates to:
  /// **'გადასახადი შეიქმნება ჯგუფის ყველა ბავშვისთვის.'**
  String get chargeGroupHint;

  /// No description provided for @recurringPlans.
  ///
  /// In ka, this message translates to:
  /// **'ყოველთვიური გადასახადი'**
  String get recurringPlans;

  /// No description provided for @createPlan.
  ///
  /// In ka, this message translates to:
  /// **'გეგმის შექმნა'**
  String get createPlan;

  /// No description provided for @amountLabel.
  ///
  /// In ka, this message translates to:
  /// **'თანხა (₾)'**
  String get amountLabel;

  /// No description provided for @dayOfMonthLabel.
  ///
  /// In ka, this message translates to:
  /// **'თვის რიცხვი'**
  String get dayOfMonthLabel;

  /// No description provided for @everyMonthOn.
  ///
  /// In ka, this message translates to:
  /// **'{amount} ₾ · ყოველი თვის {day} რიცხვში'**
  String everyMonthOn(String amount, int day);

  /// No description provided for @generateThisMonth.
  ///
  /// In ka, this message translates to:
  /// **'ამ თვის გადასახადების შექმნა'**
  String get generateThisMonth;

  /// No description provided for @generated.
  ///
  /// In ka, this message translates to:
  /// **'შეიქმნა {count} გადასახადი'**
  String generated(int count);

  /// No description provided for @runReminders.
  ///
  /// In ka, this message translates to:
  /// **'SMS შეხსენებების გაშვება'**
  String get runReminders;

  /// No description provided for @remindersReport.
  ///
  /// In ka, this message translates to:
  /// **'გაიგზავნა {sent} · გამოტოვდა {skipped} · ხელახლა გაშვება დუბლიკატს არ ქმნის'**
  String remindersReport(int sent, int skipped);

  /// No description provided for @smsLog.
  ///
  /// In ka, this message translates to:
  /// **'SMS ჟურნალი'**
  String get smsLog;

  /// No description provided for @smsMockNote.
  ///
  /// In ka, this message translates to:
  /// **'დემო: გამოიყენება იმიტირებული SMS პროვაიდერი. რეალური SMS არ იგზავნება.'**
  String get smsMockNote;

  /// No description provided for @noPayments.
  ///
  /// In ka, this message translates to:
  /// **'გადასახადები ჯერ არ არის'**
  String get noPayments;

  /// No description provided for @paymentHistory.
  ///
  /// In ka, this message translates to:
  /// **'ისტორია'**
  String get paymentHistory;

  /// No description provided for @nextDue.
  ///
  /// In ka, this message translates to:
  /// **'უახლოესი ვადა {date}'**
  String nextDue(String date);

  /// No description provided for @paymentUpdated.
  ///
  /// In ka, this message translates to:
  /// **'სტატუსი განახლდა'**
  String get paymentUpdated;

  /// No description provided for @chargeCreated.
  ///
  /// In ka, this message translates to:
  /// **'შეიქმნა {count} გადასახადი'**
  String chargeCreated(int count);

  /// No description provided for @reminderSchedule.
  ///
  /// In ka, this message translates to:
  /// **'SMS: 5 დღით ადრე და წინა დღეს, 10:00 (თბილისი)'**
  String get reminderSchedule;

  /// No description provided for @myChildren.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი ბავშვები'**
  String get myChildren;

  /// No description provided for @editProfile.
  ///
  /// In ka, this message translates to:
  /// **'პროფილის რედაქტირება'**
  String get editProfile;

  /// No description provided for @settingsTitle.
  ///
  /// In ka, this message translates to:
  /// **'პარამეტრები'**
  String get settingsTitle;

  /// No description provided for @themeLabel.
  ///
  /// In ka, this message translates to:
  /// **'თემა'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In ka, this message translates to:
  /// **'სისტემური'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ka, this message translates to:
  /// **'ღია'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ka, this message translates to:
  /// **'მუქი'**
  String get themeDark;

  /// No description provided for @languageLabel.
  ///
  /// In ka, this message translates to:
  /// **'ენა'**
  String get languageLabel;

  /// No description provided for @switchDemoAccount.
  ///
  /// In ka, this message translates to:
  /// **'დემო ანგარიშის შეცვლა'**
  String get switchDemoAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიშის წაშლა'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში და ყველა ცნობა სამუდამოდ წაიშლება. ამის გაუქმება შეუძლებელია.'**
  String get deleteAccountConfirm;

  /// No description provided for @privacyTitle.
  ///
  /// In ka, this message translates to:
  /// **'კონფიდენციალურობა'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვების მონაცემები ხელმისაწვდომია მხოლოდ მშობლებისა და ჯგუფის დადასტურებული მწვრთნელებისთვის.'**
  String get privacyBody;

  /// No description provided for @childProfile.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის პროფილი'**
  String get childProfile;

  /// No description provided for @birthDateLabel.
  ///
  /// In ka, this message translates to:
  /// **'დაბადების თარიღი'**
  String get birthDateLabel;

  /// No description provided for @ownAccountTitle.
  ///
  /// In ka, this message translates to:
  /// **'საკუთარი ანგარიში (14+)'**
  String get ownAccountTitle;

  /// No description provided for @ownAccountDisabled.
  ///
  /// In ka, this message translates to:
  /// **'ჩაირთვება ასაკისა და თანხმობის პოლიტიკის იურიდიული დადასტურების შემდეგ.'**
  String get ownAccountDisabled;

  /// No description provided for @photoConsentLabel.
  ///
  /// In ka, this message translates to:
  /// **'თანხმობა ვარჯიშის ფოტოებზე'**
  String get photoConsentLabel;

  /// No description provided for @photoConsentHelp.
  ///
  /// In ka, this message translates to:
  /// **'თანხმობის გარეშე ბავშვი მწვრთნელის ფოტოებზე არ უნდა ჩანდეს.'**
  String get photoConsentHelp;

  /// No description provided for @removeChild.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის წაშლა'**
  String get removeChild;

  /// No description provided for @removeChildConfirm.
  ///
  /// In ka, this message translates to:
  /// **'წავშალოთ {name}-ს პროფილი? წაიშლება ცნობებიც.'**
  String removeChildConfirm(String name);

  /// No description provided for @childSaved.
  ///
  /// In ka, this message translates to:
  /// **'პროფილი შენახულია'**
  String get childSaved;

  /// No description provided for @requestPending.
  ///
  /// In ka, this message translates to:
  /// **'მოლოდინში'**
  String get requestPending;

  /// No description provided for @pendingRequests.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნილი მოთხოვნები'**
  String get pendingRequests;

  /// No description provided for @roleLabel.
  ///
  /// In ka, this message translates to:
  /// **'როლი'**
  String get roleLabel;

  /// No description provided for @approvedCoach.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურებული მწვრთნელი'**
  String get approvedCoach;

  /// No description provided for @appVersion.
  ///
  /// In ka, this message translates to:
  /// **'ვერსია {version}'**
  String appVersion(String version);

  /// No description provided for @modeDemo.
  ///
  /// In ka, this message translates to:
  /// **'დემო რეჟიმი'**
  String get modeDemo;

  /// No description provided for @modeFirebase.
  ///
  /// In ka, this message translates to:
  /// **'Firebase'**
  String get modeFirebase;

  /// No description provided for @groupsCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} ჯგუფი'**
  String groupsCount(int count);

  /// No description provided for @notInGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის გარეშე'**
  String get notInGroup;

  /// No description provided for @firebaseNotConfiguredTitle.
  ///
  /// In ka, this message translates to:
  /// **'Firebase არ არის კონფიგურირებული'**
  String get firebaseNotConfiguredTitle;

  /// No description provided for @firebaseNotConfiguredBody.
  ///
  /// In ka, this message translates to:
  /// **'გაუშვით `flutterfire configure` ან აპი დემო რეჟიმში: --dart-define=APP_MODE=demo'**
  String get firebaseNotConfiguredBody;

  /// No description provided for @chatTooltip.
  ///
  /// In ka, this message translates to:
  /// **'ჩატები'**
  String get chatTooltip;

  /// No description provided for @chatsTitle.
  ///
  /// In ka, this message translates to:
  /// **'ჩატები'**
  String get chatsTitle;

  /// No description provided for @quickActions.
  ///
  /// In ka, this message translates to:
  /// **'სწრაფი მოქმედებები'**
  String get quickActions;

  /// No description provided for @actionAdd.
  ///
  /// In ka, this message translates to:
  /// **'დამატება'**
  String get actionAdd;

  /// No description provided for @reasonLabel.
  ///
  /// In ka, this message translates to:
  /// **'მიზეზი'**
  String get reasonLabel;

  /// No description provided for @reasonHint.
  ///
  /// In ka, this message translates to:
  /// **'მოკლედ აღწერეთ მიზეზი'**
  String get reasonHint;

  /// No description provided for @loadMore.
  ///
  /// In ka, this message translates to:
  /// **'მეტის ჩატვირთვა'**
  String get loadMore;

  /// No description provided for @loadEarlier.
  ///
  /// In ka, this message translates to:
  /// **'ადრინდელი შეტყობინებები'**
  String get loadEarlier;

  /// No description provided for @all.
  ///
  /// In ka, this message translates to:
  /// **'ყველა'**
  String get all;

  /// No description provided for @share.
  ///
  /// In ka, this message translates to:
  /// **'გაზიარება'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In ka, this message translates to:
  /// **'კოპირება'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In ka, this message translates to:
  /// **'დაკოპირდა'**
  String get copied;

  /// No description provided for @accept.
  ///
  /// In ka, this message translates to:
  /// **'მიღება'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფა'**
  String get decline;

  /// No description provided for @report.
  ///
  /// In ka, this message translates to:
  /// **'გასაჩივრება'**
  String get report;

  /// No description provided for @send.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნა'**
  String get send;

  /// No description provided for @search.
  ///
  /// In ka, this message translates to:
  /// **'ძიება'**
  String get search;

  /// No description provided for @create.
  ///
  /// In ka, this message translates to:
  /// **'შექმნა'**
  String get create;

  /// No description provided for @remove.
  ///
  /// In ka, this message translates to:
  /// **'წაშლა'**
  String get remove;

  /// No description provided for @statusLabel.
  ///
  /// In ka, this message translates to:
  /// **'სტატუსი'**
  String get statusLabel;

  /// No description provided for @offlineBanner.
  ///
  /// In ka, this message translates to:
  /// **'კავშირი არ არის — ნაჩვენებია შენახული მონაცემები. ცვლილებები ვერ შეინახება.'**
  String get offlineBanner;

  /// No description provided for @backOnline.
  ///
  /// In ka, this message translates to:
  /// **'კავშირი აღდგა'**
  String get backOnline;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In ka, this message translates to:
  /// **'წვდომა შეზღუდულია'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In ka, this message translates to:
  /// **'ამ გვერდის ნახვის უფლება არ გაქვთ.'**
  String get permissionDeniedBody;

  /// No description provided for @validationCancelReasonRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ გაუქმების მიზეზი'**
  String get validationCancelReasonRequired;

  /// No description provided for @validationCancelReasonTooShort.
  ///
  /// In ka, this message translates to:
  /// **'მიზეზი უნდა იყოს მინიმუმ 5 სიმბოლო'**
  String get validationCancelReasonTooShort;

  /// No description provided for @validationWeekdaysRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ მინიმუმ ერთი დღე'**
  String get validationWeekdaysRequired;

  /// No description provided for @validationEndBeforeStart.
  ///
  /// In ka, this message translates to:
  /// **'დასრულება დაწყებამდეა'**
  String get validationEndBeforeStart;

  /// No description provided for @validationSeriesTooLong.
  ///
  /// In ka, this message translates to:
  /// **'განრიგი მაქსიმუმ 1 წლით'**
  String get validationSeriesTooLong;

  /// No description provided for @validationSeriesOverlap.
  ///
  /// In ka, this message translates to:
  /// **'ამ ჯგუფს ამ დღეებსა და დროს უკვე აქვს განრიგი'**
  String get validationSeriesOverlap;

  /// No description provided for @validationOpponentRequired.
  ///
  /// In ka, this message translates to:
  /// **'მიუთითეთ მეტოქე გუნდი'**
  String get validationOpponentRequired;

  /// No description provided for @validationGroupNameRequired.
  ///
  /// In ka, this message translates to:
  /// **'მიუთითეთ ჯგუფის სახელი'**
  String get validationGroupNameRequired;

  /// No description provided for @validationGroupAgeRange.
  ///
  /// In ka, this message translates to:
  /// **'ასაკი 3–18, მინიმუმი ≤ მაქსიმუმი'**
  String get validationGroupAgeRange;

  /// No description provided for @validationInvalidGroupCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდი არასწორია ან ჯგუფი არ არის აქტიური'**
  String get validationInvalidGroupCode;

  /// No description provided for @validationInviteExists.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევა უკვე გაგზავნილია'**
  String get validationInviteExists;

  /// No description provided for @validationInviteClosed.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევა უკვე დახურულია'**
  String get validationInviteClosed;

  /// No description provided for @validationLinkChildRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ ბავშვი'**
  String get validationLinkChildRequired;

  /// No description provided for @validationNotMember.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი ამ ჯგუფში არ არის'**
  String get validationNotMember;

  /// No description provided for @validationRsvpClosed.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში უკვე დაიწყო — პასუხის შეცვლა აღარ შეიძლება'**
  String get validationRsvpClosed;

  /// No description provided for @validationTrainingCancelled.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში გაუქმებულია'**
  String get validationTrainingCancelled;

  /// No description provided for @validationAttendanceTooEarly.
  ///
  /// In ka, this message translates to:
  /// **'დასწრებას ვარჯიშამდე ერთი საათით ადრე მონიშნავთ'**
  String get validationAttendanceTooEarly;

  /// No description provided for @validationFeedbackEmpty.
  ///
  /// In ka, this message translates to:
  /// **'შეაფასეთ მინიმუმ ერთი კატეგორია ან დაწერეთ კომენტარი'**
  String get validationFeedbackEmpty;

  /// No description provided for @validationFeedbackRating.
  ///
  /// In ka, this message translates to:
  /// **'შეფასება 1–5'**
  String get validationFeedbackRating;

  /// No description provided for @validationMediaGroupsRequired.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ მინიმუმ ერთი ჯგუფი'**
  String get validationMediaGroupsRequired;

  /// No description provided for @validationVideoTooLarge.
  ///
  /// In ka, this message translates to:
  /// **'ვიდეო 100 MB-ზე დიდია'**
  String get validationVideoTooLarge;

  /// No description provided for @validationVideoTooLong.
  ///
  /// In ka, this message translates to:
  /// **'ვიდეო 60 წამზე გრძელია'**
  String get validationVideoTooLong;

  /// No description provided for @validationAvatarTooLarge.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო 1 MB-ზე დიდია'**
  String get validationAvatarTooLarge;

  /// No description provided for @validationRateLimited.
  ///
  /// In ka, this message translates to:
  /// **'ძალიან ბევრი მცდელობა. სცადეთ მოგვიანებით.'**
  String get validationRateLimited;

  /// No description provided for @validationAlreadyReported.
  ///
  /// In ka, this message translates to:
  /// **'უკვე გაასაჩივრეთ'**
  String get validationAlreadyReported;

  /// No description provided for @validationReasonRequired.
  ///
  /// In ka, this message translates to:
  /// **'მიუთითეთ მიზეზი (მინიმუმ 5 სიმბოლო)'**
  String get validationReasonRequired;

  /// No description provided for @validationLocationOutsideGeorgia.
  ///
  /// In ka, this message translates to:
  /// **'ლოკაცია საქართველოს ფარგლებს გარეთაა'**
  String get validationLocationOutsideGeorgia;

  /// No description provided for @validationClubArchived.
  ///
  /// In ka, this message translates to:
  /// **'კლუბი დაარქივებულია'**
  String get validationClubArchived;

  /// No description provided for @validationMatchCancelled.
  ///
  /// In ka, this message translates to:
  /// **'თამაში გაუქმებულია'**
  String get validationMatchCancelled;

  /// No description provided for @validationCannotPin.
  ///
  /// In ka, this message translates to:
  /// **'სისტემური შეტყობინება ვერ დაიპინება'**
  String get validationCannotPin;

  /// No description provided for @validationAgeRange.
  ///
  /// In ka, this message translates to:
  /// **'ასაკი 3–18'**
  String get validationAgeRange;

  /// No description provided for @validationReportClosed.
  ///
  /// In ka, this message translates to:
  /// **'საჩივარი უკვე განხილულია'**
  String get validationReportClosed;

  /// No description provided for @validationCannotChangeOwnRole.
  ///
  /// In ka, this message translates to:
  /// **'საკუთარ როლს ვერ შეცვლით'**
  String get validationCannotChangeOwnRole;

  /// No description provided for @validationChildNotFound.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი ვერ მოიძებნა'**
  String get validationChildNotFound;

  /// No description provided for @cancelReasonTitle.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმების მიზეზი'**
  String get cancelReasonTitle;

  /// No description provided for @cancelReasonHint.
  ///
  /// In ka, this message translates to:
  /// **'მიზეზი სავალდებულოა — მშობლები მას ნახავენ კალენდარსა და ჩატში.'**
  String get cancelReasonHint;

  /// No description provided for @cancelReasonIllness.
  ///
  /// In ka, this message translates to:
  /// **'ავადმყოფობა'**
  String get cancelReasonIllness;

  /// No description provided for @cancelReasonWeather.
  ///
  /// In ka, this message translates to:
  /// **'ამინდი'**
  String get cancelReasonWeather;

  /// No description provided for @cancelReasonVenueBusy.
  ///
  /// In ka, this message translates to:
  /// **'სტადიონი დაკავებულია'**
  String get cancelReasonVenueBusy;

  /// No description provided for @cancelReasonOther.
  ///
  /// In ka, this message translates to:
  /// **'სხვა'**
  String get cancelReasonOther;

  /// No description provided for @cancelReasonTextLabel.
  ///
  /// In ka, this message translates to:
  /// **'დეტალები (5–300 სიმბოლო)'**
  String get cancelReasonTextLabel;

  /// No description provided for @cancelAction.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმება'**
  String get cancelAction;

  /// No description provided for @cancelledWithReason.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმდა: {reason}'**
  String cancelledWithReason(String reason);

  /// No description provided for @trainingCancelledSnack.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში გაუქმდა, მშობლებს ეცნობათ'**
  String get trainingCancelledSnack;

  /// No description provided for @matchTitle.
  ///
  /// In ka, this message translates to:
  /// **'თამაში'**
  String get matchTitle;

  /// No description provided for @matchesTitle.
  ///
  /// In ka, this message translates to:
  /// **'თამაშები'**
  String get matchesTitle;

  /// No description provided for @nextMatch.
  ///
  /// In ka, this message translates to:
  /// **'უახლოესი თამაში'**
  String get nextMatch;

  /// No description provided for @newMatch.
  ///
  /// In ka, this message translates to:
  /// **'ახალი თამაში'**
  String get newMatch;

  /// No description provided for @editMatch.
  ///
  /// In ka, this message translates to:
  /// **'თამაშის რედაქტირება'**
  String get editMatch;

  /// No description provided for @matchOpponent.
  ///
  /// In ka, this message translates to:
  /// **'მეტოქე გუნდი'**
  String get matchOpponent;

  /// No description provided for @matchVs.
  ///
  /// In ka, this message translates to:
  /// **'vs {opponent}'**
  String matchVs(String opponent);

  /// No description provided for @matchType.
  ///
  /// In ka, this message translates to:
  /// **'ტიპი'**
  String get matchType;

  /// No description provided for @matchTypeFriendly.
  ///
  /// In ka, this message translates to:
  /// **'ამხანაგური'**
  String get matchTypeFriendly;

  /// No description provided for @matchTypeLeague.
  ///
  /// In ka, this message translates to:
  /// **'ლიგა'**
  String get matchTypeLeague;

  /// No description provided for @matchTypeTournament.
  ///
  /// In ka, this message translates to:
  /// **'ტურნირი'**
  String get matchTypeTournament;

  /// No description provided for @matchHomeAway.
  ///
  /// In ka, this message translates to:
  /// **'მოედანი'**
  String get matchHomeAway;

  /// No description provided for @matchHome.
  ///
  /// In ka, this message translates to:
  /// **'საშინაო'**
  String get matchHome;

  /// No description provided for @matchAway.
  ///
  /// In ka, this message translates to:
  /// **'გასვლითი'**
  String get matchAway;

  /// No description provided for @matchNeutral.
  ///
  /// In ka, this message translates to:
  /// **'ნეიტრალური'**
  String get matchNeutral;

  /// No description provided for @matchComment.
  ///
  /// In ka, this message translates to:
  /// **'კომენტარი'**
  String get matchComment;

  /// No description provided for @matchSaved.
  ///
  /// In ka, this message translates to:
  /// **'თამაში შენახულია, მშობლებს ეცნობათ'**
  String get matchSaved;

  /// No description provided for @matchCancelledSnack.
  ///
  /// In ka, this message translates to:
  /// **'თამაში გაუქმდა, მშობლებს ეცნობათ'**
  String get matchCancelledSnack;

  /// No description provided for @matchPlayed.
  ///
  /// In ka, this message translates to:
  /// **'ჩატარდა'**
  String get matchPlayed;

  /// No description provided for @markPlayed.
  ///
  /// In ka, this message translates to:
  /// **'ჩატარებულად მონიშვნა'**
  String get markPlayed;

  /// No description provided for @cancelMatch.
  ///
  /// In ka, this message translates to:
  /// **'თამაშის გაუქმება'**
  String get cancelMatch;

  /// No description provided for @matchBadge.
  ///
  /// In ka, this message translates to:
  /// **'თამაში'**
  String get matchBadge;

  /// No description provided for @noMatches.
  ///
  /// In ka, this message translates to:
  /// **'დაგეგმილი თამაში არ არის'**
  String get noMatches;

  /// No description provided for @seriesTitle.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშების განრიგი'**
  String get seriesTitle;

  /// No description provided for @seriesNew.
  ///
  /// In ka, this message translates to:
  /// **'განმეორებადი განრიგი'**
  String get seriesNew;

  /// No description provided for @seriesEdit.
  ///
  /// In ka, this message translates to:
  /// **'განრიგის შეცვლა'**
  String get seriesEdit;

  /// No description provided for @seriesWeekdays.
  ///
  /// In ka, this message translates to:
  /// **'კვირის დღეები'**
  String get seriesWeekdays;

  /// No description provided for @seriesStartTime.
  ///
  /// In ka, this message translates to:
  /// **'დაწყების დრო'**
  String get seriesStartTime;

  /// No description provided for @seriesStartDate.
  ///
  /// In ka, this message translates to:
  /// **'დაწყების თარიღი'**
  String get seriesStartDate;

  /// No description provided for @seriesEndDate.
  ///
  /// In ka, this message translates to:
  /// **'დასრულების თარიღი'**
  String get seriesEndDate;

  /// No description provided for @seriesNoEnd.
  ///
  /// In ka, this message translates to:
  /// **'დასრულების გარეშე'**
  String get seriesNoEnd;

  /// No description provided for @seriesSummary.
  ///
  /// In ka, this message translates to:
  /// **'{days} · {time}'**
  String seriesSummary(String days, String time);

  /// No description provided for @seriesSaved.
  ///
  /// In ka, this message translates to:
  /// **'განრიგი შენახულია — ვარჯიშები კალენდარშია'**
  String get seriesSaved;

  /// No description provided for @seriesEnded.
  ///
  /// In ka, this message translates to:
  /// **'განრიგი დასრულდა'**
  String get seriesEnded;

  /// No description provided for @seriesEndAction.
  ///
  /// In ka, this message translates to:
  /// **'განრიგის დასრულება'**
  String get seriesEndAction;

  /// No description provided for @seriesEndConfirm.
  ///
  /// In ka, this message translates to:
  /// **'შემდგომი ვარჯიშები წაიშლება. ვარჯიშები, რომლებზეც მშობლებმა უკვე უპასუხეს, გაუქმდება მიზეზით.'**
  String get seriesEndConfirm;

  /// No description provided for @seriesNone.
  ///
  /// In ka, this message translates to:
  /// **'განმეორებადი განრიგი ჯერ არ არის'**
  String get seriesNone;

  /// No description provided for @seriesRecurringBadge.
  ///
  /// In ka, this message translates to:
  /// **'განრიგიდან'**
  String get seriesRecurringBadge;

  /// No description provided for @editScopeTitle.
  ///
  /// In ka, this message translates to:
  /// **'რომელი ვარჯიში შევცვალოთ?'**
  String get editScopeTitle;

  /// No description provided for @editScopeThis.
  ///
  /// In ka, this message translates to:
  /// **'მხოლოდ ეს ვარჯიში'**
  String get editScopeThis;

  /// No description provided for @editScopeFuture.
  ///
  /// In ka, this message translates to:
  /// **'ეს და შემდეგი ვარჯიშები'**
  String get editScopeFuture;

  /// No description provided for @seriesHorizonNote.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშები იქმნება 8 კვირით წინ და ავტომატურად გრძელდება.'**
  String get seriesHorizonNote;

  /// No description provided for @seriesConflicts.
  ///
  /// In ka, this message translates to:
  /// **'{count} თარიღი გამოტოვდა — იმ დროს უკვე არის ვარჯიში'**
  String seriesConflicts(int count);

  /// No description provided for @rsvpTitle.
  ///
  /// In ka, this message translates to:
  /// **'მოვა ვარჯიშზე?'**
  String get rsvpTitle;

  /// No description provided for @rsvpYes.
  ///
  /// In ka, this message translates to:
  /// **'მოვა'**
  String get rsvpYes;

  /// No description provided for @rsvpNo.
  ///
  /// In ka, this message translates to:
  /// **'ვერ მოვა'**
  String get rsvpNo;

  /// No description provided for @rsvpMaybe.
  ///
  /// In ka, this message translates to:
  /// **'ჯერ არ ვიცი'**
  String get rsvpMaybe;

  /// No description provided for @rsvpReasonHint.
  ///
  /// In ka, this message translates to:
  /// **'მიზეზი (არასავალდებულო)'**
  String get rsvpReasonHint;

  /// No description provided for @rsvpSaved.
  ///
  /// In ka, this message translates to:
  /// **'პასუხი გაეგზავნა მწვრთნელს'**
  String get rsvpSaved;

  /// No description provided for @rsvpClosedNote.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში დაიწყო — პასუხი აღარ იცვლება.'**
  String get rsvpClosedNote;

  /// No description provided for @rsvpNotice.
  ///
  /// In ka, this message translates to:
  /// **'პასუხი დასწრებად არ ითვლება — დასწრებას მწვრთნელი აღნიშნავს.'**
  String get rsvpNotice;

  /// No description provided for @attendanceTitle.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get attendanceTitle;

  /// No description provided for @attendancePresent.
  ///
  /// In ka, this message translates to:
  /// **'მოვიდა'**
  String get attendancePresent;

  /// No description provided for @attendanceAbsent.
  ///
  /// In ka, this message translates to:
  /// **'არ მოსულა'**
  String get attendanceAbsent;

  /// No description provided for @attendanceExcused.
  ///
  /// In ka, this message translates to:
  /// **'საპატიო'**
  String get attendanceExcused;

  /// No description provided for @attendanceNotMarked.
  ///
  /// In ka, this message translates to:
  /// **'არ არის მონიშნული'**
  String get attendanceNotMarked;

  /// No description provided for @attendanceMarkAllPresent.
  ///
  /// In ka, this message translates to:
  /// **'დანარჩენები — მოვიდა'**
  String get attendanceMarkAllPresent;

  /// No description provided for @attendanceSummary.
  ///
  /// In ka, this message translates to:
  /// **'{present} მოვიდა · {absent} არა · {excused} საპატიო · {unmarked} მოუნიშნავი'**
  String attendanceSummary(int present, int absent, int excused, int unmarked);

  /// No description provided for @attendanceRecorded.
  ///
  /// In ka, this message translates to:
  /// **'აღრიცხული დასწრება'**
  String get attendanceRecorded;

  /// No description provided for @attendanceOpen.
  ///
  /// In ka, this message translates to:
  /// **'დასწრების აღრიცხვა'**
  String get attendanceOpen;

  /// No description provided for @attendanceRsvpLabel.
  ///
  /// In ka, this message translates to:
  /// **'მშობლის პასუხი: {answer}'**
  String attendanceRsvpLabel(String answer);

  /// No description provided for @attendanceGroupStats.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის დასწრება'**
  String get attendanceGroupStats;

  /// No description provided for @attendanceThisMonth.
  ///
  /// In ka, this message translates to:
  /// **'ამ თვეში'**
  String get attendanceThisMonth;

  /// No description provided for @attendanceRate.
  ///
  /// In ka, this message translates to:
  /// **'{percent}%'**
  String attendanceRate(int percent);

  /// No description provided for @attendanceNoData.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება ჯერ არ არის აღრიცხული'**
  String get attendanceNoData;

  /// No description provided for @attendanceHistory.
  ///
  /// In ka, this message translates to:
  /// **'დასწრების ისტორია'**
  String get attendanceHistory;

  /// No description provided for @attendanceMonthly.
  ///
  /// In ka, this message translates to:
  /// **'თვიური დასწრება'**
  String get attendanceMonthly;

  /// No description provided for @attendanceUpcomingResponses.
  ///
  /// In ka, this message translates to:
  /// **'მომავალი ვარჯიშები'**
  String get attendanceUpcomingResponses;

  /// No description provided for @responsesTitle.
  ///
  /// In ka, this message translates to:
  /// **'მშობლების პასუხები'**
  String get responsesTitle;

  /// No description provided for @responsesCount.
  ///
  /// In ka, this message translates to:
  /// **'{yes} მოვა · {no} ვერ · {maybe} არ იცის'**
  String responsesCount(int yes, int no, int maybe);

  /// No description provided for @progressTitle.
  ///
  /// In ka, this message translates to:
  /// **'პროგრესი'**
  String get progressTitle;

  /// No description provided for @progressTrainings.
  ///
  /// In ka, this message translates to:
  /// **'ჩატარებული ვარჯიში'**
  String get progressTrainings;

  /// No description provided for @progressRate.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get progressRate;

  /// No description provided for @progressTrend.
  ///
  /// In ka, this message translates to:
  /// **'დასწრების ტენდენცია'**
  String get progressTrend;

  /// No description provided for @progressFeedback.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის შეფასება'**
  String get progressFeedback;

  /// No description provided for @progressNoFeedback.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელს ჯერ არ დაუწერია შეფასება'**
  String get progressNoFeedback;

  /// No description provided for @progressAchievements.
  ///
  /// In ka, this message translates to:
  /// **'მიღწევები'**
  String get progressAchievements;

  /// No description provided for @progressPrivacyNote.
  ///
  /// In ka, this message translates to:
  /// **'პროგრესს ხედავთ მხოლოდ თქვენ და ბავშვის მწვრთნელები. რეიტინგები არ ქვეყნდება.'**
  String get progressPrivacyNote;

  /// No description provided for @feedbackTechnique.
  ///
  /// In ka, this message translates to:
  /// **'ტექნიკა'**
  String get feedbackTechnique;

  /// No description provided for @feedbackDiscipline.
  ///
  /// In ka, this message translates to:
  /// **'დისციპლინა'**
  String get feedbackDiscipline;

  /// No description provided for @feedbackTeamwork.
  ///
  /// In ka, this message translates to:
  /// **'გუნდური თამაში'**
  String get feedbackTeamwork;

  /// No description provided for @feedbackEffort.
  ///
  /// In ka, this message translates to:
  /// **'მონდომება'**
  String get feedbackEffort;

  /// No description provided for @feedbackImprovement.
  ///
  /// In ka, this message translates to:
  /// **'პროგრესი'**
  String get feedbackImprovement;

  /// No description provided for @feedbackAdd.
  ///
  /// In ka, this message translates to:
  /// **'შეფასების დამატება'**
  String get feedbackAdd;

  /// No description provided for @feedbackComment.
  ///
  /// In ka, this message translates to:
  /// **'კომენტარი მშობლისთვის'**
  String get feedbackComment;

  /// No description provided for @feedbackCommentHint.
  ///
  /// In ka, this message translates to:
  /// **'დაწერეთ კონსტრუქციულად და ბავშვის ასაკის შესაბამისად'**
  String get feedbackCommentHint;

  /// No description provided for @feedbackSaved.
  ///
  /// In ka, this message translates to:
  /// **'შეფასება გაეგზავნა მშობელს'**
  String get feedbackSaved;

  /// No description provided for @achFirstTraining.
  ///
  /// In ka, this message translates to:
  /// **'პირველი ვარჯიში'**
  String get achFirstTraining;

  /// No description provided for @achAttended.
  ///
  /// In ka, this message translates to:
  /// **'{count} ვარჯიში'**
  String achAttended(int count);

  /// No description provided for @achPerfectMonth.
  ///
  /// In ka, this message translates to:
  /// **'სრულყოფილი თვე'**
  String get achPerfectMonth;

  /// No description provided for @achStreak.
  ///
  /// In ka, this message translates to:
  /// **'3 თვე ზედიზედ'**
  String get achStreak;

  /// No description provided for @achLocked.
  ///
  /// In ka, this message translates to:
  /// **'ჯერ არ არის'**
  String get achLocked;

  /// No description provided for @invitesTitle.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევები'**
  String get invitesTitle;

  /// No description provided for @invitesEmpty.
  ///
  /// In ka, this message translates to:
  /// **'ახალი მოწვევა არ გაქვთ'**
  String get invitesEmpty;

  /// No description provided for @inviteFrom.
  ///
  /// In ka, this message translates to:
  /// **'{child} მოწვეულია ჯგუფში {group}'**
  String inviteFrom(String child, String group);

  /// No description provided for @inviteLinkTitle.
  ///
  /// In ka, this message translates to:
  /// **'რომელ ბავშვს ეხება მოწვევა?'**
  String get inviteLinkTitle;

  /// No description provided for @inviteLinkHint.
  ///
  /// In ka, this message translates to:
  /// **'თუ ბავშვი უკვე დარეგისტრირებულია, აირჩიეთ ის — ასე დუბლიკატი არ შეიქმნება.'**
  String get inviteLinkHint;

  /// No description provided for @inviteAsNew.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ბავშვის სახით დამატება ({name})'**
  String inviteAsNew(String name);

  /// No description provided for @inviteMediaConsent.
  ///
  /// In ka, this message translates to:
  /// **'ვეთანხმები, რომ ბავშვი გამოჩნდეს გუნდის ფოტოებსა და ვიდეოებში'**
  String get inviteMediaConsent;

  /// No description provided for @inviteAccepted.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი დაემატა ჯგუფს'**
  String get inviteAccepted;

  /// No description provided for @inviteDeclined.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევა უარყოფილია'**
  String get inviteDeclined;

  /// No description provided for @inviteBanner.
  ///
  /// In ka, this message translates to:
  /// **'{count} ახალი მოწვევა ჯგუფში'**
  String inviteBanner(int count);

  /// No description provided for @inviteStatusSent.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნილი'**
  String get inviteStatusSent;

  /// No description provided for @inviteStatusAccepted.
  ///
  /// In ka, this message translates to:
  /// **'მიღებული'**
  String get inviteStatusAccepted;

  /// No description provided for @inviteStatusDeclined.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფილი'**
  String get inviteStatusDeclined;

  /// No description provided for @inviteStatusRevoked.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმებული'**
  String get inviteStatusRevoked;

  /// No description provided for @inviteRevoke.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევის გაუქმება'**
  String get inviteRevoke;

  /// No description provided for @groupCode.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის კოდი'**
  String get groupCode;

  /// No description provided for @groupCodeHint.
  ///
  /// In ka, this message translates to:
  /// **'მშობელი კოდს შეიყვანს ბავშვის პროფილში — თქვენ დაადასტურებთ.'**
  String get groupCodeHint;

  /// No description provided for @groupCodeShareText.
  ///
  /// In ka, this message translates to:
  /// **'შემოუერთდით ჯგუფს „{group}“ აპლიკაციაში გუნდი. კოდი: {code}'**
  String groupCodeShareText(String group, String code);

  /// No description provided for @joinGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფში გაწევრება კოდით'**
  String get joinGroup;

  /// No description provided for @joinGroupCodeLabel.
  ///
  /// In ka, this message translates to:
  /// **'6-სიმბოლოიანი კოდი'**
  String get joinGroupCodeLabel;

  /// No description provided for @joinGroupSent.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნა გაეგზავნა ჯგუფს „{group}“'**
  String joinGroupSent(String group);

  /// No description provided for @leaveGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფიდან გასვლა'**
  String get leaveGroup;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In ka, this message translates to:
  /// **'{child} დატოვებს ჯგუფს „{group}“. მწვრთნელი მის მონაცემებს და ცნობას ვეღარ ნახავს.'**
  String leaveGroupConfirm(String child, String group);

  /// No description provided for @leftGroup.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი გავიდა ჯგუფიდან'**
  String get leftGroup;

  /// No description provided for @membershipTitle.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფები და მოთხოვნები'**
  String get membershipTitle;

  /// No description provided for @newGroup.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ჯგუფი'**
  String get newGroup;

  /// No description provided for @groupName.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის სახელი'**
  String get groupName;

  /// No description provided for @groupAgeFrom.
  ///
  /// In ka, this message translates to:
  /// **'ასაკი — დან'**
  String get groupAgeFrom;

  /// No description provided for @groupAgeTo.
  ///
  /// In ka, this message translates to:
  /// **'ასაკი — მდე'**
  String get groupAgeTo;

  /// No description provided for @groupClub.
  ///
  /// In ka, this message translates to:
  /// **'კლუბი'**
  String get groupClub;

  /// No description provided for @groupSport.
  ///
  /// In ka, this message translates to:
  /// **'სპორტი'**
  String get groupSport;

  /// No description provided for @groupCreated.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფი შეიქმნა. კოდი: {code}'**
  String groupCreated(String code);

  /// No description provided for @addChildTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის დამატება'**
  String get addChildTitle;

  /// No description provided for @addChildByCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდით'**
  String get addChildByCode;

  /// No description provided for @addChildBySearch.
  ///
  /// In ka, this message translates to:
  /// **'ძიებით'**
  String get addChildBySearch;

  /// No description provided for @addChildManual.
  ///
  /// In ka, this message translates to:
  /// **'ხელით'**
  String get addChildManual;

  /// No description provided for @addChildSearchHint.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის სახელი ან გვარი'**
  String get addChildSearchHint;

  /// No description provided for @addChildSearchNote.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევა მიდის მშობელთან. ბავშვი ჯგუფში მხოლოდ მშობლის დადასტურების შემდეგ ჩანს.'**
  String get addChildSearchNote;

  /// No description provided for @addChildManualNote.
  ///
  /// In ka, this message translates to:
  /// **'მშობელი მიიღებს მოწვევას. დადასტურებამდე ხედავთ მხოლოდ სახელს და გვარს.'**
  String get addChildManualNote;

  /// No description provided for @parentPhone.
  ///
  /// In ka, this message translates to:
  /// **'მშობლის ტელეფონი'**
  String get parentPhone;

  /// No description provided for @inviteSent.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევა გაეგზავნა მშობელს'**
  String get inviteSent;

  /// No description provided for @invitesSent.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნილი მოწვევები'**
  String get invitesSent;

  /// No description provided for @birthYearShort.
  ///
  /// In ka, this message translates to:
  /// **'{year} წ.'**
  String birthYearShort(int year);

  /// No description provided for @pendingParentBadge.
  ///
  /// In ka, this message translates to:
  /// **'ელოდება მშობელს'**
  String get pendingParentBadge;

  /// No description provided for @noSearchResults.
  ///
  /// In ka, this message translates to:
  /// **'ვერაფერი მოიძებნა'**
  String get noSearchResults;

  /// No description provided for @requestViaCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდით'**
  String get requestViaCode;

  /// No description provided for @mediaTitle.
  ///
  /// In ka, this message translates to:
  /// **'მედია'**
  String get mediaTitle;

  /// No description provided for @mediaRecent.
  ///
  /// In ka, this message translates to:
  /// **'ბოლო ფოტოები და ვიდეოები'**
  String get mediaRecent;

  /// No description provided for @mediaTakePhoto.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოს გადაღება'**
  String get mediaTakePhoto;

  /// No description provided for @mediaRecordVideo.
  ///
  /// In ka, this message translates to:
  /// **'ვიდეოს გადაღება'**
  String get mediaRecordVideo;

  /// No description provided for @mediaFromGallery.
  ///
  /// In ka, this message translates to:
  /// **'გალერეიდან'**
  String get mediaFromGallery;

  /// No description provided for @mediaCaption.
  ///
  /// In ka, this message translates to:
  /// **'წარწერა'**
  String get mediaCaption;

  /// No description provided for @mediaGroups.
  ///
  /// In ka, this message translates to:
  /// **'ვის გამოუჩნდეს'**
  String get mediaGroups;

  /// No description provided for @mediaConsentConfirm.
  ///
  /// In ka, this message translates to:
  /// **'ვადასტურებ: ბავშვები, რომელთა მშობლებს თანხმობა არ აქვთ, მედიაში არ ჩანან'**
  String get mediaConsentConfirm;

  /// No description provided for @mediaPublish.
  ///
  /// In ka, this message translates to:
  /// **'გამოქვეყნება'**
  String get mediaPublish;

  /// No description provided for @mediaPublished.
  ///
  /// In ka, this message translates to:
  /// **'გამოქვეყნდა — ჯგუფის მშობლებს ეცნობათ'**
  String get mediaPublished;

  /// No description provided for @mediaEmpty.
  ///
  /// In ka, this message translates to:
  /// **'მედია ჯერ არ არის'**
  String get mediaEmpty;

  /// No description provided for @mediaVideo.
  ///
  /// In ka, this message translates to:
  /// **'ვიდეო · {seconds} წმ'**
  String mediaVideo(int seconds);

  /// No description provided for @mediaNoDownload.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა გამორთულია ბავშვების კონფიდენციალურობისთვის.'**
  String get mediaNoDownload;

  /// No description provided for @mediaDelete.
  ///
  /// In ka, this message translates to:
  /// **'მედიის წაშლა'**
  String get mediaDelete;

  /// No description provided for @mediaHidden.
  ///
  /// In ka, this message translates to:
  /// **'კონტენტი დამალულია მოდერაციით'**
  String get mediaHidden;

  /// No description provided for @mediaLimits.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო ≤ 10 MB · ვიდეო ≤ 60 წმ და 100 MB'**
  String get mediaLimits;

  /// No description provided for @mediaConsentMissing.
  ///
  /// In ka, this message translates to:
  /// **'{count} ბავშვს მედიაზე თანხმობა არ აქვს: {names}'**
  String mediaConsentMissing(int count, String names);

  /// No description provided for @reportTitle.
  ///
  /// In ka, this message translates to:
  /// **'გასაჩივრება'**
  String get reportTitle;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In ka, this message translates to:
  /// **'შეუფერებელი კონტენტი'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonPrivacy.
  ///
  /// In ka, this message translates to:
  /// **'კონფიდენციალურობა'**
  String get reportReasonPrivacy;

  /// No description provided for @reportReasonSpam.
  ///
  /// In ka, this message translates to:
  /// **'სპამი'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonOther.
  ///
  /// In ka, this message translates to:
  /// **'სხვა'**
  String get reportReasonOther;

  /// No description provided for @reportNote.
  ///
  /// In ka, this message translates to:
  /// **'კომენტარი (არასავალდებულო)'**
  String get reportNote;

  /// No description provided for @reportSent.
  ///
  /// In ka, this message translates to:
  /// **'საჩივარი გაეგზავნა ადმინისტრატორს'**
  String get reportSent;

  /// No description provided for @messageHidden.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინება დამალულია მოდერაციით'**
  String get messageHidden;

  /// No description provided for @chatsEmpty.
  ///
  /// In ka, this message translates to:
  /// **'ჩატები გამოჩნდება, როცა ბავშვი ჯგუფში გაწევრდება'**
  String get chatsEmpty;

  /// No description provided for @chatAnnouncement.
  ///
  /// In ka, this message translates to:
  /// **'განცხადება'**
  String get chatAnnouncement;

  /// No description provided for @chatAnnouncementToggle.
  ///
  /// In ka, this message translates to:
  /// **'განცხადებად გაგზავნა (დაპინული)'**
  String get chatAnnouncementToggle;

  /// No description provided for @chatPin.
  ///
  /// In ka, this message translates to:
  /// **'დაპინვა'**
  String get chatPin;

  /// No description provided for @chatUnpin.
  ///
  /// In ka, this message translates to:
  /// **'მოხსნა'**
  String get chatUnpin;

  /// No description provided for @chatPinned.
  ///
  /// In ka, this message translates to:
  /// **'დაპინული'**
  String get chatPinned;

  /// No description provided for @chatReadBy.
  ///
  /// In ka, this message translates to:
  /// **'წაიკითხა {count}'**
  String chatReadBy(int count);

  /// No description provided for @chatSendFailed.
  ///
  /// In ka, this message translates to:
  /// **'ვერ გაიგზავნა'**
  String get chatSendFailed;

  /// No description provided for @chatRetry.
  ///
  /// In ka, this message translates to:
  /// **'ხელახლა'**
  String get chatRetry;

  /// No description provided for @chatSending.
  ///
  /// In ka, this message translates to:
  /// **'იგზავნება…'**
  String get chatSending;

  /// No description provided for @chatNoMessages.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინებები ჯერ არ არის'**
  String get chatNoMessages;

  /// No description provided for @chatSystem.
  ///
  /// In ka, this message translates to:
  /// **'სისტემა'**
  String get chatSystem;

  /// No description provided for @unreadCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} წაუკითხავი'**
  String unreadCount(int count);

  /// No description provided for @notifNewMatch.
  ///
  /// In ka, this message translates to:
  /// **'ახალი თამაში'**
  String get notifNewMatch;

  /// No description provided for @notifMatchChanged.
  ///
  /// In ka, this message translates to:
  /// **'თამაში შეიცვალა'**
  String get notifMatchChanged;

  /// No description provided for @notifMatchReminder.
  ///
  /// In ka, this message translates to:
  /// **'თამაშის შეხსენება'**
  String get notifMatchReminder;

  /// No description provided for @notifGroupInvite.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევა ჯგუფში'**
  String get notifGroupInvite;

  /// No description provided for @notifInviteAnswered.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევაზე პასუხი'**
  String get notifInviteAnswered;

  /// No description provided for @notifAttendanceRecorded.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება აღირიცხა'**
  String get notifAttendanceRecorded;

  /// No description provided for @notifFeedbackAdded.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის შეფასება'**
  String get notifFeedbackAdded;

  /// No description provided for @notifAnnouncement.
  ///
  /// In ka, this message translates to:
  /// **'განცხადება'**
  String get notifAnnouncement;

  /// No description provided for @notifNewMedia.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ფოტო/ვიდეო'**
  String get notifNewMedia;

  /// No description provided for @notifScheduleChanged.
  ///
  /// In ka, this message translates to:
  /// **'განრიგი შეიცვალა'**
  String get notifScheduleChanged;

  /// No description provided for @notifBodyMatch.
  ///
  /// In ka, this message translates to:
  /// **'{opponent} · {group}'**
  String notifBodyMatch(String opponent, String group);

  /// No description provided for @notifBodyInvite.
  ///
  /// In ka, this message translates to:
  /// **'{child} → {group}'**
  String notifBodyInvite(String child, String group);

  /// No description provided for @notifBodyChild.
  ///
  /// In ka, this message translates to:
  /// **'{child}'**
  String notifBodyChild(String child);

  /// No description provided for @notifBodyCancelled.
  ///
  /// In ka, this message translates to:
  /// **'{group} · {reason}'**
  String notifBodyCancelled(String group, String reason);

  /// No description provided for @catTrainings.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშები'**
  String get catTrainings;

  /// No description provided for @catMatches.
  ///
  /// In ka, this message translates to:
  /// **'თამაშები'**
  String get catMatches;

  /// No description provided for @catInvitations.
  ///
  /// In ka, this message translates to:
  /// **'მოწვევები'**
  String get catInvitations;

  /// No description provided for @catAttendance.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get catAttendance;

  /// No description provided for @catPayments.
  ///
  /// In ka, this message translates to:
  /// **'გადახდები'**
  String get catPayments;

  /// No description provided for @catChat.
  ///
  /// In ka, this message translates to:
  /// **'ჩატი'**
  String get catChat;

  /// No description provided for @catCertificates.
  ///
  /// In ka, this message translates to:
  /// **'ცნობები'**
  String get catCertificates;

  /// No description provided for @catAnnouncements.
  ///
  /// In ka, this message translates to:
  /// **'განცხადებები'**
  String get catAnnouncements;

  /// No description provided for @notificationsEmptyCategory.
  ///
  /// In ka, this message translates to:
  /// **'ამ კატეგორიაში შეტყობინება არ არის'**
  String get notificationsEmptyCategory;

  /// No description provided for @paymentsOutstanding.
  ///
  /// In ka, this message translates to:
  /// **'გადასახდელი'**
  String get paymentsOutstanding;

  /// No description provided for @paymentsPaidTotal.
  ///
  /// In ka, this message translates to:
  /// **'გადახდილი'**
  String get paymentsPaidTotal;

  /// No description provided for @paymentsOverdueTotal.
  ///
  /// In ka, this message translates to:
  /// **'ვადაგადაცილებული'**
  String get paymentsOverdueTotal;

  /// No description provided for @paymentsFilterChild.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვი'**
  String get paymentsFilterChild;

  /// No description provided for @paymentsFilterSport.
  ///
  /// In ka, this message translates to:
  /// **'სპორტი'**
  String get paymentsFilterSport;

  /// No description provided for @paymentsReminderPrefs.
  ///
  /// In ka, this message translates to:
  /// **'შეხსენების პარამეტრები'**
  String get paymentsReminderPrefs;

  /// No description provided for @paymentsNoOnline.
  ///
  /// In ka, this message translates to:
  /// **'ონლაინ გადახდა ჯერ არ არის — გადაიხადეთ კლუბის მითითებით.'**
  String get paymentsNoOnline;

  /// No description provided for @paymentCancelReason.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმების მიზეზი'**
  String get paymentCancelReason;

  /// No description provided for @paymentAudit.
  ///
  /// In ka, this message translates to:
  /// **'ცვლილებების ისტორია'**
  String get paymentAudit;

  /// No description provided for @paymentAuditLine.
  ///
  /// In ka, this message translates to:
  /// **'{actor}: {from} → {to}'**
  String paymentAuditLine(String actor, String from, String to);

  /// No description provided for @paymentSummaryMonth.
  ///
  /// In ka, this message translates to:
  /// **'{month} — შეჯამება'**
  String paymentSummaryMonth(String month);

  /// No description provided for @paymentTitleLabel.
  ///
  /// In ka, this message translates to:
  /// **'დასახელება (არასავალდებულო)'**
  String get paymentTitleLabel;

  /// No description provided for @paymentChildren.
  ///
  /// In ka, this message translates to:
  /// **'{count} ბავშვი'**
  String paymentChildren(int count);

  /// No description provided for @accountTitle.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში'**
  String get accountTitle;

  /// No description provided for @profilePhoto.
  ///
  /// In ka, this message translates to:
  /// **'პროფილის ფოტო'**
  String get profilePhoto;

  /// No description provided for @profilePhotoChange.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოს შეცვლა'**
  String get profilePhotoChange;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოს წაშლა'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო განახლდა'**
  String get profilePhotoUpdated;

  /// No description provided for @privacySettingsTitle.
  ///
  /// In ka, this message translates to:
  /// **'კონფიდენციალურობა'**
  String get privacySettingsTitle;

  /// No description provided for @privacyPhotoVisible.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი ფოტო ჩანდეს ჯგუფის მწვრთნელებისთვის/მშობლებისთვის'**
  String get privacyPhotoVisible;

  /// No description provided for @privacyAnalytics.
  ///
  /// In ka, this message translates to:
  /// **'ანონიმური დიაგნოსტიკა (შეცდომების ანგარიშები)'**
  String get privacyAnalytics;

  /// No description provided for @consentsTitle.
  ///
  /// In ka, this message translates to:
  /// **'თანხმობები'**
  String get consentsTitle;

  /// No description provided for @consentDataGiven.
  ///
  /// In ka, this message translates to:
  /// **'მონაცემების დამუშავება — {date}'**
  String consentDataGiven(String date);

  /// No description provided for @consentSmsToggle.
  ///
  /// In ka, this message translates to:
  /// **'SMS შეხსენებები გადასახადებზე'**
  String get consentSmsToggle;

  /// No description provided for @consentMedia.
  ///
  /// In ka, this message translates to:
  /// **'მედია: {child}'**
  String consentMedia(String child);

  /// No description provided for @dataExport.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი მონაცემების ექსპორტი'**
  String get dataExport;

  /// No description provided for @dataExportHint.
  ///
  /// In ka, this message translates to:
  /// **'მიიღებთ JSON ფაილს თქვენი და ბავშვების მონაცემებით (სამედიცინო ფაილების შიგთავსის გარეშე).'**
  String get dataExportHint;

  /// No description provided for @dataExportReady.
  ///
  /// In ka, this message translates to:
  /// **'ექსპორტი მზადაა'**
  String get dataExportReady;

  /// No description provided for @dataExportRequested.
  ///
  /// In ka, this message translates to:
  /// **'ექსპორტის მოთხოვნა მიღებულია'**
  String get dataExportRequested;

  /// No description provided for @accountRequests.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნები'**
  String get accountRequests;

  /// No description provided for @requestStatusPending.
  ///
  /// In ka, this message translates to:
  /// **'მოლოდინში'**
  String get requestStatusPending;

  /// No description provided for @requestStatusProcessing.
  ///
  /// In ka, this message translates to:
  /// **'მუშავდება'**
  String get requestStatusProcessing;

  /// No description provided for @requestStatusDone.
  ///
  /// In ka, this message translates to:
  /// **'დასრულდა'**
  String get requestStatusDone;

  /// No description provided for @requestStatusRejected.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფილი'**
  String get requestStatusRejected;

  /// No description provided for @deleteImpactTitle.
  ///
  /// In ka, this message translates to:
  /// **'რა მოხდება წაშლისას'**
  String get deleteImpactTitle;

  /// No description provided for @deleteImpactDeleted.
  ///
  /// In ka, this message translates to:
  /// **'წაიშლება (მხოლოდ თქვენ ხართ მეურვე): {names}'**
  String deleteImpactDeleted(String names);

  /// No description provided for @deleteImpactUnlinked.
  ///
  /// In ka, this message translates to:
  /// **'დარჩება სხვა მეურვესთან: {names}'**
  String deleteImpactUnlinked(String names);

  /// No description provided for @deleteImpactPayments.
  ///
  /// In ka, this message translates to:
  /// **'გადახდების ისტორია ანონიმურად შეინახება კლუბის აღრიცხვისთვის.'**
  String get deleteImpactPayments;

  /// No description provided for @retentionTitle.
  ///
  /// In ka, this message translates to:
  /// **'შენახვა და წაშლა'**
  String get retentionTitle;

  /// No description provided for @retentionBody.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიშის წაშლისას იშლება პროფილი, ფოტოები, ცნობები (ფაილებიც), დასწრება და შეფასებები იმ ბავშვებისა, რომელთა ერთადერთი მეურვე ხართ. სხვა მეურვის ბავშვი არ იშლება.'**
  String get retentionBody;

  /// No description provided for @weekSchedule.
  ///
  /// In ka, this message translates to:
  /// **'ამ კვირის განრიგი'**
  String get weekSchedule;

  /// No description provided for @weekEmpty.
  ///
  /// In ka, this message translates to:
  /// **'ამ კვირაში ვარჯიში არ არის'**
  String get weekEmpty;

  /// No description provided for @attendanceTile.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get attendanceTile;

  /// No description provided for @attendanceTileValue.
  ///
  /// In ka, this message translates to:
  /// **'{percent}% ამ თვეში'**
  String attendanceTileValue(int percent);

  /// No description provided for @progressShort.
  ///
  /// In ka, this message translates to:
  /// **'პროგრესი'**
  String get progressShort;

  /// No description provided for @importantTitle.
  ///
  /// In ka, this message translates to:
  /// **'მნიშვნელოვანი'**
  String get importantTitle;

  /// No description provided for @coachFab.
  ///
  /// In ka, this message translates to:
  /// **'დამატება'**
  String get coachFab;

  /// No description provided for @addTrainingOne.
  ///
  /// In ka, this message translates to:
  /// **'ერთჯერადი ვარჯიში'**
  String get addTrainingOne;

  /// No description provided for @addSeries.
  ///
  /// In ka, this message translates to:
  /// **'განმეორებადი განრიგი'**
  String get addSeries;

  /// No description provided for @addMatch.
  ///
  /// In ka, this message translates to:
  /// **'თამაში'**
  String get addMatch;

  /// No description provided for @addMedia.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო / ვიდეო'**
  String get addMedia;

  /// No description provided for @addChildToGroup.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვის მოწვევა'**
  String get addChildToGroup;

  /// No description provided for @newVenue.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ლოკაცია რუკაზე'**
  String get newVenue;

  /// No description provided for @venuePickHint.
  ///
  /// In ka, this message translates to:
  /// **'შეეხეთ რუკას ადგილის მოსანიშნად'**
  String get venuePickHint;

  /// No description provided for @venueNearby.
  ///
  /// In ka, this message translates to:
  /// **'ახლოს უკვე არის ლოკაციები (200 მ):'**
  String get venueNearby;

  /// No description provided for @venueUseExisting.
  ///
  /// In ka, this message translates to:
  /// **'არსებულის გამოყენება'**
  String get venueUseExisting;

  /// No description provided for @venueName.
  ///
  /// In ka, this message translates to:
  /// **'ლოკაციის სახელი'**
  String get venueName;

  /// No description provided for @venueAddress.
  ///
  /// In ka, this message translates to:
  /// **'მისამართი'**
  String get venueAddress;

  /// No description provided for @venueUnverified.
  ///
  /// In ka, this message translates to:
  /// **'დაუდასტურებელი'**
  String get venueUnverified;

  /// No description provided for @venueSaved.
  ///
  /// In ka, this message translates to:
  /// **'ლოკაცია შენახულია'**
  String get venueSaved;

  /// No description provided for @mapLayerVenues.
  ///
  /// In ka, this message translates to:
  /// **'ადგილები'**
  String get mapLayerVenues;

  /// No description provided for @mapLayerTrainings.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშები'**
  String get mapLayerTrainings;

  /// No description provided for @mapLayerMatches.
  ///
  /// In ka, this message translates to:
  /// **'თამაშები'**
  String get mapLayerMatches;

  /// No description provided for @mapToday.
  ///
  /// In ka, this message translates to:
  /// **'დღეს'**
  String get mapToday;

  /// No description provided for @mapThisWeek.
  ///
  /// In ka, this message translates to:
  /// **'ამ კვირაში'**
  String get mapThisWeek;

  /// No description provided for @sportCategoryTeam.
  ///
  /// In ka, this message translates to:
  /// **'გუნდური'**
  String get sportCategoryTeam;

  /// No description provided for @sportCategoryCombat.
  ///
  /// In ka, this message translates to:
  /// **'ორთაბრძოლა'**
  String get sportCategoryCombat;

  /// No description provided for @sportCategoryOther.
  ///
  /// In ka, this message translates to:
  /// **'სხვა'**
  String get sportCategoryOther;

  /// No description provided for @sportAgeMin.
  ///
  /// In ka, this message translates to:
  /// **'მინ. ასაკი: {age}'**
  String sportAgeMin(int age);

  /// No description provided for @sportRequiresCert.
  ///
  /// In ka, this message translates to:
  /// **'საჭიროა სამედიცინო ცნობა'**
  String get sportRequiresCert;

  /// No description provided for @demoOffline.
  ///
  /// In ka, this message translates to:
  /// **'ოფლაინ რეჟიმის სიმულაცია'**
  String get demoOffline;

  /// No description provided for @demoOfflineHint.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები ვერ შეინახება — აპი სწორ შეცდომას აჩვენებს.'**
  String get demoOfflineHint;

  /// No description provided for @aboutVersion.
  ///
  /// In ka, this message translates to:
  /// **'ვერსია {version} · {env}'**
  String aboutVersion(String version, String env);

  /// No description provided for @adminUseWeb.
  ///
  /// In ka, this message translates to:
  /// **'ადმინისტრატორის პანელი ხელმისაწვდომია ვებ-ვერსიაში.'**
  String get adminUseWeb;

  /// No description provided for @adminTitle.
  ///
  /// In ka, this message translates to:
  /// **'გუნდი · ადმინისტრირება'**
  String get adminTitle;

  /// No description provided for @adminSignInTitle.
  ///
  /// In ka, this message translates to:
  /// **'ადმინისტრატორის პანელი'**
  String get adminSignInTitle;

  /// No description provided for @adminSignInBody.
  ///
  /// In ka, this message translates to:
  /// **'შესვლა მხოლოდ ადმინისტრატორებისთვის. უფლებები მოწმდება სერვერზე.'**
  String get adminSignInBody;

  /// No description provided for @adminDemoAccounts.
  ///
  /// In ka, this message translates to:
  /// **'დემო ანგარიშები'**
  String get adminDemoAccounts;

  /// No description provided for @adminDemoTryParent.
  ///
  /// In ka, this message translates to:
  /// **'შემოწმება: მშობლის ანგარიში (წვდომა აკრძალულია)'**
  String get adminDemoTryParent;

  /// No description provided for @adminPhoneSignIn.
  ///
  /// In ka, this message translates to:
  /// **'შესვლა ტელეფონით'**
  String get adminPhoneSignIn;

  /// No description provided for @adminFirebaseLoginNote.
  ///
  /// In ka, this message translates to:
  /// **'ვებ-ზე ტელეფონით შესვლას სჭირდება Firebase-ის reCAPTCHA კონფიგურაცია (იხ. docs/firebase-setup.md).'**
  String get adminFirebaseLoginNote;

  /// No description provided for @adminRolePlatform.
  ///
  /// In ka, this message translates to:
  /// **'პლატფორმის ადმინი'**
  String get adminRolePlatform;

  /// No description provided for @adminRoleClub.
  ///
  /// In ka, this message translates to:
  /// **'კლუბის ადმინი'**
  String get adminRoleClub;

  /// No description provided for @adminScopeClubs.
  ///
  /// In ka, this message translates to:
  /// **'კლუბები: {clubs}'**
  String adminScopeClubs(String clubs);

  /// No description provided for @adminNavDashboard.
  ///
  /// In ka, this message translates to:
  /// **'მიმოხილვა'**
  String get adminNavDashboard;

  /// No description provided for @adminNavCoaches.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელები'**
  String get adminNavCoaches;

  /// No description provided for @adminNavClubs.
  ///
  /// In ka, this message translates to:
  /// **'კლუბები'**
  String get adminNavClubs;

  /// No description provided for @adminNavSports.
  ///
  /// In ka, this message translates to:
  /// **'სპორტები'**
  String get adminNavSports;

  /// No description provided for @adminNavGroups.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფები'**
  String get adminNavGroups;

  /// No description provided for @adminNavModeration.
  ///
  /// In ka, this message translates to:
  /// **'მოდერაცია'**
  String get adminNavModeration;

  /// No description provided for @adminNavAudit.
  ///
  /// In ka, this message translates to:
  /// **'აუდიტი'**
  String get adminNavAudit;

  /// No description provided for @adminNavAdmins.
  ///
  /// In ka, this message translates to:
  /// **'ადმინისტრატორები'**
  String get adminNavAdmins;

  /// No description provided for @adminStatParents.
  ///
  /// In ka, this message translates to:
  /// **'მშობლები'**
  String get adminStatParents;

  /// No description provided for @adminStatChildren.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვები'**
  String get adminStatChildren;

  /// No description provided for @adminStatCoaches.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელები'**
  String get adminStatCoaches;

  /// No description provided for @adminStatClubs.
  ///
  /// In ka, this message translates to:
  /// **'კლუბები'**
  String get adminStatClubs;

  /// No description provided for @adminStatGroups.
  ///
  /// In ka, this message translates to:
  /// **'აქტიური ჯგუფები'**
  String get adminStatGroups;

  /// No description provided for @adminStatTrainings.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშები (7 დღე)'**
  String get adminStatTrainings;

  /// No description provided for @adminStatMatches.
  ///
  /// In ka, this message translates to:
  /// **'მომავალი თამაშები'**
  String get adminStatMatches;

  /// No description provided for @adminStatPendingCoaches.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის განაცხადები'**
  String get adminStatPendingCoaches;

  /// No description provided for @adminStatPendingRequests.
  ///
  /// In ka, this message translates to:
  /// **'გაწევრების მოთხოვნები'**
  String get adminStatPendingRequests;

  /// No description provided for @adminStatReports.
  ///
  /// In ka, this message translates to:
  /// **'საჩივრები'**
  String get adminStatReports;

  /// No description provided for @adminNeedsAttention.
  ///
  /// In ka, this message translates to:
  /// **'ყურადღებას საჭიროებს'**
  String get adminNeedsAttention;

  /// No description provided for @adminSearch.
  ///
  /// In ka, this message translates to:
  /// **'ძიება…'**
  String get adminSearch;

  /// No description provided for @adminFilterAll.
  ///
  /// In ka, this message translates to:
  /// **'ყველა'**
  String get adminFilterAll;

  /// No description provided for @adminColName.
  ///
  /// In ka, this message translates to:
  /// **'სახელი'**
  String get adminColName;

  /// No description provided for @adminColStatus.
  ///
  /// In ka, this message translates to:
  /// **'სტატუსი'**
  String get adminColStatus;

  /// No description provided for @adminColClubs.
  ///
  /// In ka, this message translates to:
  /// **'კლუბები'**
  String get adminColClubs;

  /// No description provided for @adminColSports.
  ///
  /// In ka, this message translates to:
  /// **'სპორტი'**
  String get adminColSports;

  /// No description provided for @adminColGroups.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფები'**
  String get adminColGroups;

  /// No description provided for @adminColApplied.
  ///
  /// In ka, this message translates to:
  /// **'განაცხადი'**
  String get adminColApplied;

  /// No description provided for @adminColActions.
  ///
  /// In ka, this message translates to:
  /// **'მოქმედებები'**
  String get adminColActions;

  /// No description provided for @adminColAddress.
  ///
  /// In ka, this message translates to:
  /// **'მისამართი'**
  String get adminColAddress;

  /// No description provided for @adminColMembers.
  ///
  /// In ka, this message translates to:
  /// **'წევრები'**
  String get adminColMembers;

  /// No description provided for @adminColCoach.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელი'**
  String get adminColCoach;

  /// No description provided for @adminColSchedule.
  ///
  /// In ka, this message translates to:
  /// **'განრიგი'**
  String get adminColSchedule;

  /// No description provided for @adminColRequests.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნები'**
  String get adminColRequests;

  /// No description provided for @adminColUpcoming.
  ///
  /// In ka, this message translates to:
  /// **'მომავალი ვარჯიშები'**
  String get adminColUpcoming;

  /// No description provided for @adminColCategory.
  ///
  /// In ka, this message translates to:
  /// **'კატეგორია'**
  String get adminColCategory;

  /// No description provided for @adminColAgeMin.
  ///
  /// In ka, this message translates to:
  /// **'მინ. ასაკი'**
  String get adminColAgeMin;

  /// No description provided for @adminColCert.
  ///
  /// In ka, this message translates to:
  /// **'ცნობა'**
  String get adminColCert;

  /// No description provided for @adminColActive.
  ///
  /// In ka, this message translates to:
  /// **'აქტიური'**
  String get adminColActive;

  /// No description provided for @adminColWhen.
  ///
  /// In ka, this message translates to:
  /// **'დრო'**
  String get adminColWhen;

  /// No description provided for @adminColActor.
  ///
  /// In ka, this message translates to:
  /// **'ვინ'**
  String get adminColActor;

  /// No description provided for @adminColAction.
  ///
  /// In ka, this message translates to:
  /// **'მოქმედება'**
  String get adminColAction;

  /// No description provided for @adminColTarget.
  ///
  /// In ka, this message translates to:
  /// **'ობიექტი'**
  String get adminColTarget;

  /// No description provided for @adminColDetails.
  ///
  /// In ka, this message translates to:
  /// **'დეტალები'**
  String get adminColDetails;

  /// No description provided for @adminColReason.
  ///
  /// In ka, this message translates to:
  /// **'მიზეზი'**
  String get adminColReason;

  /// No description provided for @adminColContent.
  ///
  /// In ka, this message translates to:
  /// **'კონტენტი'**
  String get adminColContent;

  /// No description provided for @adminPageOf.
  ///
  /// In ka, this message translates to:
  /// **'{pageStart}–{pageEnd} / {total}'**
  String adminPageOf(int pageStart, int pageEnd, int total);

  /// No description provided for @adminApprove.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურება'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფა'**
  String get adminReject;

  /// No description provided for @adminSuspend.
  ///
  /// In ka, this message translates to:
  /// **'შეჩერება'**
  String get adminSuspend;

  /// No description provided for @adminRevoke.
  ///
  /// In ka, this message translates to:
  /// **'წვდომის გაუქმება'**
  String get adminRevoke;

  /// No description provided for @adminReinstate.
  ///
  /// In ka, this message translates to:
  /// **'აღდგენა'**
  String get adminReinstate;

  /// No description provided for @adminReasonTitle.
  ///
  /// In ka, this message translates to:
  /// **'მიზეზი (სავალდებულო)'**
  String get adminReasonTitle;

  /// No description provided for @adminCoachStatusPending.
  ///
  /// In ka, this message translates to:
  /// **'მოლოდინში'**
  String get adminCoachStatusPending;

  /// No description provided for @adminCoachStatusApproved.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურებული'**
  String get adminCoachStatusApproved;

  /// No description provided for @adminCoachStatusRejected.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფილი'**
  String get adminCoachStatusRejected;

  /// No description provided for @adminCoachStatusSuspended.
  ///
  /// In ka, this message translates to:
  /// **'შეჩერებული'**
  String get adminCoachStatusSuspended;

  /// No description provided for @adminCoachStatusRevoked.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმებული'**
  String get adminCoachStatusRevoked;

  /// No description provided for @adminCoachUpdated.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის სტატუსი განახლდა'**
  String get adminCoachUpdated;

  /// No description provided for @adminAssignClub.
  ///
  /// In ka, this message translates to:
  /// **'კლუბზე მიმაგრება'**
  String get adminAssignClub;

  /// No description provided for @adminUnassignClub.
  ///
  /// In ka, this message translates to:
  /// **'კლუბიდან მოხსნა'**
  String get adminUnassignClub;

  /// No description provided for @adminNewClub.
  ///
  /// In ka, this message translates to:
  /// **'ახალი კლუბი'**
  String get adminNewClub;

  /// No description provided for @adminEditClub.
  ///
  /// In ka, this message translates to:
  /// **'კლუბის რედაქტირება'**
  String get adminEditClub;

  /// No description provided for @adminArchive.
  ///
  /// In ka, this message translates to:
  /// **'დაარქივება'**
  String get adminArchive;

  /// No description provided for @adminRestore.
  ///
  /// In ka, this message translates to:
  /// **'აღდგენა'**
  String get adminRestore;

  /// No description provided for @adminArchived.
  ///
  /// In ka, this message translates to:
  /// **'დაარქივებული'**
  String get adminArchived;

  /// No description provided for @adminLat.
  ///
  /// In ka, this message translates to:
  /// **'განედი'**
  String get adminLat;

  /// No description provided for @adminLng.
  ///
  /// In ka, this message translates to:
  /// **'გრძედი'**
  String get adminLng;

  /// No description provided for @adminPhone.
  ///
  /// In ka, this message translates to:
  /// **'ტელეფონი'**
  String get adminPhone;

  /// No description provided for @adminDescription.
  ///
  /// In ka, this message translates to:
  /// **'აღწერა'**
  String get adminDescription;

  /// No description provided for @adminSaved.
  ///
  /// In ka, this message translates to:
  /// **'შენახულია'**
  String get adminSaved;

  /// No description provided for @adminNewSport.
  ///
  /// In ka, this message translates to:
  /// **'ახალი სპორტი'**
  String get adminNewSport;

  /// No description provided for @adminEditSport.
  ///
  /// In ka, this message translates to:
  /// **'სპორტის რედაქტირება'**
  String get adminEditSport;

  /// No description provided for @adminSportId.
  ///
  /// In ka, this message translates to:
  /// **'იდენტიფიკატორი (ლათინური)'**
  String get adminSportId;

  /// No description provided for @adminSportOrder.
  ///
  /// In ka, this message translates to:
  /// **'რიგი'**
  String get adminSportOrder;

  /// No description provided for @adminReadOnly.
  ///
  /// In ka, this message translates to:
  /// **'მხოლოდ ნახვა — რედაქტირება პლატფორმის ადმინისტრატორს შეუძლია.'**
  String get adminReadOnly;

  /// No description provided for @adminHide.
  ///
  /// In ka, this message translates to:
  /// **'დამალვა'**
  String get adminHide;

  /// No description provided for @adminKeep.
  ///
  /// In ka, this message translates to:
  /// **'დატოვება'**
  String get adminKeep;

  /// No description provided for @adminReportOpen.
  ///
  /// In ka, this message translates to:
  /// **'ღია'**
  String get adminReportOpen;

  /// No description provided for @adminReportResolved.
  ///
  /// In ka, this message translates to:
  /// **'დამალულია'**
  String get adminReportResolved;

  /// No description provided for @adminReportDismissed.
  ///
  /// In ka, this message translates to:
  /// **'დატოვებულია'**
  String get adminReportDismissed;

  /// No description provided for @adminModerationEmpty.
  ///
  /// In ka, this message translates to:
  /// **'საჩივრები არ არის'**
  String get adminModerationEmpty;

  /// No description provided for @adminModerationNote.
  ///
  /// In ka, this message translates to:
  /// **'მედიის ნახვა ხდება მხოლოდ დროებითი ხელმოწერილი ბმულით. ბავშვების პერსონალური მონაცემები აქ არ ჩანს.'**
  String get adminModerationNote;

  /// No description provided for @adminMakeClubAdmin.
  ///
  /// In ka, this message translates to:
  /// **'კლუბის ადმინად დანიშვნა'**
  String get adminMakeClubAdmin;

  /// No description provided for @adminRemoveAdmin.
  ///
  /// In ka, this message translates to:
  /// **'ადმინის უფლების მოხსნა'**
  String get adminRemoveAdmin;

  /// No description provided for @adminRoleUpdated.
  ///
  /// In ka, this message translates to:
  /// **'როლი განახლდა'**
  String get adminRoleUpdated;

  /// No description provided for @adminGrantHint.
  ///
  /// In ka, this message translates to:
  /// **'პირველი პლატფორმის ადმინი ინიშნება მხოლოდ სერვერის სკრიპტით (functions/scripts/grant-platform-admin.mjs).'**
  String get adminGrantHint;

  /// No description provided for @adminNotAdminTitle.
  ///
  /// In ka, this message translates to:
  /// **'ადმინისტრატორის უფლება არ გაქვთ'**
  String get adminNotAdminTitle;

  /// No description provided for @adminNotAdminBody.
  ///
  /// In ka, this message translates to:
  /// **'ეს ანგარიში ვერ გამოიყენებს ადმინისტრატორის პანელს. გამოიყენეთ მობილური აპი.'**
  String get adminNotAdminBody;

  /// No description provided for @adminChildDataNote.
  ///
  /// In ka, this message translates to:
  /// **'ბავშვების სახელები და სამედიცინო მონაცემები ადმინისტრატორებს არ უჩანთ — მხოლოდ რაოდენობები.'**
  String get adminChildDataNote;

  /// No description provided for @adminEmpty.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები არ არის'**
  String get adminEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ka'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ka':
      return AppLocalizationsKa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
