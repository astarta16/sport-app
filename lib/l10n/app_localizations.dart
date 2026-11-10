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
