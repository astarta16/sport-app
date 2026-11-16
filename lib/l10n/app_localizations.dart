import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';
import 'app_localizations_ru.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ka'), Locale('ru')];

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

  /// No description provided for @languageRussian.
  ///
  /// In ka, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageGeorgian.
  ///
  /// In ka, this message translates to:
  /// **'ქართული'**
  String get languageGeorgian;

  /// No description provided for @languageEnglish.
  ///
  /// In ka, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChanged.
  ///
  /// In ka, this message translates to:
  /// **'ენა შეიცვალა'**
  String get languageChanged;

  /// No description provided for @languageHint.
  ///
  /// In ka, this message translates to:
  /// **'ენა არ არის დამოკიდებული ტელეფონის ენაზე. ტრენერის მიერ დაწერილი ტექსტი არ ითარგმნება.'**
  String get languageHint;

  /// No description provided for @certCurrent.
  ///
  /// In ka, this message translates to:
  /// **'მოქმედი ცნობა'**
  String get certCurrent;

  /// No description provided for @certReplace.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის შეცვლა'**
  String get certReplace;

  /// No description provided for @certReplaced.
  ///
  /// In ka, this message translates to:
  /// **'შეცვლილია ახლით'**
  String get certReplaced;

  /// No description provided for @certPreview.
  ///
  /// In ka, this message translates to:
  /// **'ნახვა'**
  String get certPreview;

  /// No description provided for @certDownload.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა'**
  String get certDownload;

  /// No description provided for @certExpiresOn.
  ///
  /// In ka, this message translates to:
  /// **'ვადა: {date}'**
  String certExpiresOn(String date);

  /// No description provided for @certAppliesTo.
  ///
  /// In ka, this message translates to:
  /// **'ეხება: {sport}'**
  String certAppliesTo(String sport);

  /// No description provided for @certAllSports.
  ///
  /// In ka, this message translates to:
  /// **'ყველა სპორტი'**
  String get certAllSports;

  /// No description provided for @certSportLabel.
  ///
  /// In ka, this message translates to:
  /// **'რომელ სპორტს ეხება'**
  String get certSportLabel;

  /// No description provided for @certTakePhoto.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოს გადაღება'**
  String get certTakePhoto;

  /// No description provided for @certChooseFile.
  ///
  /// In ka, this message translates to:
  /// **'ფაილის არჩევა'**
  String get certChooseFile;

  /// No description provided for @certSensitiveWarning.
  ///
  /// In ka, this message translates to:
  /// **'სამედიცინო დოკუმენტი მგრძნობიარე ინფორმაციაა. ნუ გაუზიარებთ მას სხვებს და წაშალეთ, როცა აღარ დაგჭირდებათ.'**
  String get certSensitiveWarning;

  /// No description provided for @certDownloadConfirm.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა'**
  String get certDownloadConfirm;

  /// No description provided for @certAccessLogged.
  ///
  /// In ka, this message translates to:
  /// **'ნახვა აღრიცხულია უსაფრთხოების ჟურნალში'**
  String get certAccessLogged;

  /// No description provided for @certAccessHistory.
  ///
  /// In ka, this message translates to:
  /// **'წვდომის ისტორია'**
  String get certAccessHistory;

  /// No description provided for @certAccessView.
  ///
  /// In ka, this message translates to:
  /// **'{who} — ნახვა, {when}'**
  String certAccessView(String who, String when);

  /// No description provided for @certAccessDownload.
  ///
  /// In ka, this message translates to:
  /// **'{who} — ჩამოტვირთვა, {when}'**
  String certAccessDownload(String who, String when);

  /// No description provided for @certPdfPreview.
  ///
  /// In ka, this message translates to:
  /// **'PDF დოკუმენტი'**
  String get certPdfPreview;

  /// No description provided for @certSavedTemp.
  ///
  /// In ka, this message translates to:
  /// **'ფაილი დროებით შენახულია. გაზიარების შემდეგ ის აპიდან წაიშლება.'**
  String get certSavedTemp;

  /// No description provided for @certNoAdminAccess.
  ///
  /// In ka, this message translates to:
  /// **'ადმინისტრატორები სამედიცინო დოკუმენტებს ვერ ხედავენ — მხოლოდ სტატუსებს.'**
  String get certNoAdminAccess;

  /// No description provided for @rosterTitle.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლეები'**
  String get rosterTitle;

  /// No description provided for @rosterSearch.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლის ძიება'**
  String get rosterSearch;

  /// No description provided for @rosterSortName.
  ///
  /// In ka, this message translates to:
  /// **'სახელით'**
  String get rosterSortName;

  /// No description provided for @rosterSortAge.
  ///
  /// In ka, this message translates to:
  /// **'ასაკით'**
  String get rosterSortAge;

  /// No description provided for @rosterSortAttendance.
  ///
  /// In ka, this message translates to:
  /// **'დასწრებით'**
  String get rosterSortAttendance;

  /// No description provided for @rosterSortCert.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის სტატუსით'**
  String get rosterSortCert;

  /// No description provided for @rosterFilterAll.
  ///
  /// In ka, this message translates to:
  /// **'ყველა'**
  String get rosterFilterAll;

  /// No description provided for @rosterFilterCertIssues.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის პრობლემა'**
  String get rosterFilterCertIssues;

  /// No description provided for @rosterFilterLowAttendance.
  ///
  /// In ka, this message translates to:
  /// **'დაბალი დასწრება'**
  String get rosterFilterLowAttendance;

  /// No description provided for @rosterEmptyFilter.
  ///
  /// In ka, this message translates to:
  /// **'ამ ფილტრით მოსწავლე არ მოიძებნა'**
  String get rosterEmptyFilter;

  /// No description provided for @rosterStudentDetail.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლე'**
  String get rosterStudentDetail;

  /// No description provided for @rosterAttendanceRate.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება {percent}%'**
  String rosterAttendanceRate(int percent);

  /// No description provided for @rosterNoAttendance.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება ჯერ არ არის'**
  String get rosterNoAttendance;

  /// No description provided for @rosterCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} მოსწავლე'**
  String rosterCount(int count);

  /// No description provided for @attendanceSave.
  ///
  /// In ka, this message translates to:
  /// **'შენახვა'**
  String get attendanceSave;

  /// No description provided for @attendanceSaved.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება შენახულია'**
  String get attendanceSaved;

  /// No description provided for @attendanceUnsaved.
  ///
  /// In ka, this message translates to:
  /// **'{count} შეუნახავი ცვლილება'**
  String attendanceUnsaved(int count);

  /// No description provided for @attendanceDiscard.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმება'**
  String get attendanceDiscard;

  /// No description provided for @attendanceEditNote.
  ///
  /// In ka, this message translates to:
  /// **'უკვე აღრიცხული დასწრება შეგიძლიათ შეცვალოთ — ყოველი ცვლილება ინახება.'**
  String get attendanceEditNote;

  /// No description provided for @attendanceByStudent.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლეების მიხედვით'**
  String get attendanceByStudent;

  /// No description provided for @attendanceByGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის მიხედვით'**
  String get attendanceByGroup;

  /// No description provided for @attendanceReportTitle.
  ///
  /// In ka, this message translates to:
  /// **'დასწრების ანგარიში'**
  String get attendanceReportTitle;

  /// No description provided for @attendanceSessions.
  ///
  /// In ka, this message translates to:
  /// **'{count} ვარჯიში'**
  String attendanceSessions(int count);

  /// No description provided for @attendanceMarkAll.
  ///
  /// In ka, this message translates to:
  /// **'ყველა'**
  String get attendanceMarkAll;

  /// No description provided for @exportTitle.
  ///
  /// In ka, this message translates to:
  /// **'ექსპორტი'**
  String get exportTitle;

  /// No description provided for @exportRoster.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლეთა სია'**
  String get exportRoster;

  /// No description provided for @exportTrainingSheet.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშის დასწრების ფურცელი'**
  String get exportTrainingSheet;

  /// No description provided for @exportMonthly.
  ///
  /// In ka, this message translates to:
  /// **'თვიური დასწრების ანგარიში'**
  String get exportMonthly;

  /// No description provided for @exportFormat.
  ///
  /// In ka, this message translates to:
  /// **'ფორმატი'**
  String get exportFormat;

  /// No description provided for @exportIncludeCompliance.
  ///
  /// In ka, this message translates to:
  /// **'ცნობის სტატუსის ჩართვა (მხოლოდ საჭიროების შემთხვევაში)'**
  String get exportIncludeCompliance;

  /// No description provided for @exportWarning.
  ///
  /// In ka, this message translates to:
  /// **'ფაილი შეიცავს ბავშვების პერსონალურ მონაცემებს. გაუზიარეთ მხოლოდ იმას, ვისაც ნამდვილად სჭირდება, და წაშალეთ გამოყენების შემდეგ.'**
  String get exportWarning;

  /// No description provided for @exportConfirm.
  ///
  /// In ka, this message translates to:
  /// **'გასაგებია, ექსპორტი'**
  String get exportConfirm;

  /// No description provided for @exportReady.
  ///
  /// In ka, this message translates to:
  /// **'ფაილი მზადაა: {name}'**
  String exportReady(String name);

  /// No description provided for @exportChooseTraining.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ ვარჯიში'**
  String get exportChooseTraining;

  /// No description provided for @exportChooseMonth.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ თვე'**
  String get exportChooseMonth;

  /// No description provided for @exportColStudent.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლე'**
  String get exportColStudent;

  /// No description provided for @exportColGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფი'**
  String get exportColGroup;

  /// No description provided for @exportColDate.
  ///
  /// In ka, this message translates to:
  /// **'თარიღი'**
  String get exportColDate;

  /// No description provided for @exportColStatus.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get exportColStatus;

  /// No description provided for @exportColAge.
  ///
  /// In ka, this message translates to:
  /// **'ასაკი'**
  String get exportColAge;

  /// No description provided for @exportColCert.
  ///
  /// In ka, this message translates to:
  /// **'ცნობა'**
  String get exportColCert;

  /// No description provided for @exportColRate.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება %'**
  String get exportColRate;

  /// No description provided for @exportGenerated.
  ///
  /// In ka, this message translates to:
  /// **'შექმნილია: {date}'**
  String exportGenerated(String date);

  /// No description provided for @exportConfidential.
  ///
  /// In ka, this message translates to:
  /// **'კონფიდენციალური — მხოლოდ შიდა გამოყენებისთვის'**
  String get exportConfidential;

  /// No description provided for @exportPage.
  ///
  /// In ka, this message translates to:
  /// **'გვ. {n}'**
  String exportPage(int n);

  /// No description provided for @plansTitle.
  ///
  /// In ka, this message translates to:
  /// **'სავარჯიშო გეგმები'**
  String get plansTitle;

  /// No description provided for @plansEmpty.
  ///
  /// In ka, this message translates to:
  /// **'გეგმები ჯერ არ არის'**
  String get plansEmpty;

  /// No description provided for @planNew.
  ///
  /// In ka, this message translates to:
  /// **'ახალი გეგმა'**
  String get planNew;

  /// No description provided for @planEdit.
  ///
  /// In ka, this message translates to:
  /// **'გეგმის რედაქტირება'**
  String get planEdit;

  /// No description provided for @planTitleLabel.
  ///
  /// In ka, this message translates to:
  /// **'სათაური'**
  String get planTitleLabel;

  /// No description provided for @planDescription.
  ///
  /// In ka, this message translates to:
  /// **'აღწერა'**
  String get planDescription;

  /// No description provided for @planType.
  ///
  /// In ka, this message translates to:
  /// **'გეგმის ტიპი'**
  String get planType;

  /// No description provided for @planTypeSeasonal.
  ///
  /// In ka, this message translates to:
  /// **'სეზონური'**
  String get planTypeSeasonal;

  /// No description provided for @planTypeMonthly.
  ///
  /// In ka, this message translates to:
  /// **'თვიური'**
  String get planTypeMonthly;

  /// No description provided for @planTypeWeekly.
  ///
  /// In ka, this message translates to:
  /// **'კვირის'**
  String get planTypeWeekly;

  /// No description provided for @planTypeExercise.
  ///
  /// In ka, this message translates to:
  /// **'ინდივიდუალური სავარჯიშო'**
  String get planTypeExercise;

  /// No description provided for @planTypeHomework.
  ///
  /// In ka, this message translates to:
  /// **'საშინაო დავალება'**
  String get planTypeHomework;

  /// No description provided for @planGroups.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფები'**
  String get planGroups;

  /// No description provided for @planStart.
  ///
  /// In ka, this message translates to:
  /// **'დაწყება'**
  String get planStart;

  /// No description provided for @planEnd.
  ///
  /// In ka, this message translates to:
  /// **'დასრულება'**
  String get planEnd;

  /// No description provided for @planStatusDraft.
  ///
  /// In ka, this message translates to:
  /// **'მონახაზი'**
  String get planStatusDraft;

  /// No description provided for @planStatusPublished.
  ///
  /// In ka, this message translates to:
  /// **'გამოქვეყნებული'**
  String get planStatusPublished;

  /// No description provided for @planStatusArchived.
  ///
  /// In ka, this message translates to:
  /// **'დაარქივებული'**
  String get planStatusArchived;

  /// No description provided for @planSaveDraft.
  ///
  /// In ka, this message translates to:
  /// **'მონახაზის შენახვა'**
  String get planSaveDraft;

  /// No description provided for @planPublish.
  ///
  /// In ka, this message translates to:
  /// **'გამოქვეყნება'**
  String get planPublish;

  /// No description provided for @planArchive.
  ///
  /// In ka, this message translates to:
  /// **'დაარქივება'**
  String get planArchive;

  /// No description provided for @planUnpublish.
  ///
  /// In ka, this message translates to:
  /// **'მონახაზად დაბრუნება'**
  String get planUnpublish;

  /// No description provided for @planPublished.
  ///
  /// In ka, this message translates to:
  /// **'გეგმა გამოქვეყნდა — მშობლებს ეცნობათ'**
  String get planPublished;

  /// No description provided for @planSaved.
  ///
  /// In ka, this message translates to:
  /// **'გეგმა შენახულია'**
  String get planSaved;

  /// No description provided for @planArchived.
  ///
  /// In ka, this message translates to:
  /// **'გეგმა დაარქივდა'**
  String get planArchived;

  /// No description provided for @planExercises.
  ///
  /// In ka, this message translates to:
  /// **'სავარჯიშოები'**
  String get planExercises;

  /// No description provided for @planAddExercise.
  ///
  /// In ka, this message translates to:
  /// **'სავარჯიშოს დამატება'**
  String get planAddExercise;

  /// No description provided for @planNoExercises.
  ///
  /// In ka, this message translates to:
  /// **'დაამატეთ მინიმუმ ერთი სავარჯიშო'**
  String get planNoExercises;

  /// No description provided for @planViews.
  ///
  /// In ka, this message translates to:
  /// **'ნახა {count} მშობელმა'**
  String planViews(int count);

  /// No description provided for @planCompletion.
  ///
  /// In ka, this message translates to:
  /// **'შესრულებული: {done} / {total}'**
  String planCompletion(String done, int total);

  /// No description provided for @planSelfReported.
  ///
  /// In ka, this message translates to:
  /// **'შესრულებას მშობელი აღნიშნავს — მწვრთნელი არ ამოწმებს.'**
  String get planSelfReported;

  /// No description provided for @planPeriod.
  ///
  /// In ka, this message translates to:
  /// **'{start} – {end}'**
  String planPeriod(String start, String end);

  /// No description provided for @planOpenEnded.
  ///
  /// In ka, this message translates to:
  /// **'{start}-დან'**
  String planOpenEnded(String start);

  /// No description provided for @planHomeworkDue.
  ///
  /// In ka, this message translates to:
  /// **'დავალება შემდეგ ვარჯიშამდე'**
  String get planHomeworkDue;

  /// No description provided for @planActive.
  ///
  /// In ka, this message translates to:
  /// **'აქტიური გეგმები'**
  String get planActive;

  /// No description provided for @planDraftsOnlyCoach.
  ///
  /// In ka, this message translates to:
  /// **'მონახაზები მშობლებს არ უჩანთ'**
  String get planDraftsOnlyCoach;

  /// No description provided for @exerciseName.
  ///
  /// In ka, this message translates to:
  /// **'სავარჯიშოს სახელი'**
  String get exerciseName;

  /// No description provided for @exerciseDescription.
  ///
  /// In ka, this message translates to:
  /// **'აღწერა'**
  String get exerciseDescription;

  /// No description provided for @exerciseInstructions.
  ///
  /// In ka, this message translates to:
  /// **'ინსტრუქცია'**
  String get exerciseInstructions;

  /// No description provided for @exerciseDuration.
  ///
  /// In ka, this message translates to:
  /// **'ხანგრძლივობა (წთ)'**
  String get exerciseDuration;

  /// No description provided for @exerciseReps.
  ///
  /// In ka, this message translates to:
  /// **'გამეორებები'**
  String get exerciseReps;

  /// No description provided for @exerciseSets.
  ///
  /// In ka, this message translates to:
  /// **'სეტები'**
  String get exerciseSets;

  /// No description provided for @exerciseRest.
  ///
  /// In ka, this message translates to:
  /// **'დასვენება (წმ)'**
  String get exerciseRest;

  /// No description provided for @exerciseMedia.
  ///
  /// In ka, this message translates to:
  /// **'მასალები'**
  String get exerciseMedia;

  /// No description provided for @exerciseAddLink.
  ///
  /// In ka, this message translates to:
  /// **'ბმულის დამატება'**
  String get exerciseAddLink;

  /// No description provided for @exerciseLinkHint.
  ///
  /// In ka, this message translates to:
  /// **'https://…'**
  String get exerciseLinkHint;

  /// No description provided for @exerciseLinkInvalid.
  ///
  /// In ka, this message translates to:
  /// **'ბმული უნდა იწყებოდეს https://-ით'**
  String get exerciseLinkInvalid;

  /// No description provided for @exerciseOpenLink.
  ///
  /// In ka, this message translates to:
  /// **'ბმულის გახსნა'**
  String get exerciseOpenLink;

  /// No description provided for @exerciseExternalWarning.
  ///
  /// In ka, this message translates to:
  /// **'ბმული გაიხსნება ბრაუზერში. აპი მას თქვენს მონაცემებს არ უზიარებს.'**
  String get exerciseExternalWarning;

  /// No description provided for @exerciseMoveUp.
  ///
  /// In ka, this message translates to:
  /// **'ზემოთ'**
  String get exerciseMoveUp;

  /// No description provided for @exerciseMoveDown.
  ///
  /// In ka, this message translates to:
  /// **'ქვემოთ'**
  String get exerciseMoveDown;

  /// No description provided for @exerciseRemove.
  ///
  /// In ka, this message translates to:
  /// **'წაშლა'**
  String get exerciseRemove;

  /// No description provided for @exerciseSummary.
  ///
  /// In ka, this message translates to:
  /// **'{sets} × {reps}'**
  String exerciseSummary(String sets, String reps);

  /// No description provided for @exerciseMinutes.
  ///
  /// In ka, this message translates to:
  /// **'{n} წთ'**
  String exerciseMinutes(int n);

  /// No description provided for @exerciseRestSec.
  ///
  /// In ka, this message translates to:
  /// **'დასვენება {n} წმ'**
  String exerciseRestSec(int n);

  /// No description provided for @progressNotStarted.
  ///
  /// In ka, this message translates to:
  /// **'არ დაწყებულა'**
  String get progressNotStarted;

  /// No description provided for @progressInProgress.
  ///
  /// In ka, this message translates to:
  /// **'მიმდინარე'**
  String get progressInProgress;

  /// No description provided for @progressCompleted.
  ///
  /// In ka, this message translates to:
  /// **'შესრულებულია'**
  String get progressCompleted;

  /// No description provided for @progressFor.
  ///
  /// In ka, this message translates to:
  /// **'{child}-ის პროგრესი'**
  String progressFor(String child);

  /// No description provided for @validationPlanTitle.
  ///
  /// In ka, this message translates to:
  /// **'მიუთითეთ სათაური'**
  String get validationPlanTitle;

  /// No description provided for @validationPlanGroups.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ მინიმუმ ერთი ჯგუფი'**
  String get validationPlanGroups;

  /// No description provided for @validationPlanExercises.
  ///
  /// In ka, this message translates to:
  /// **'დაამატეთ მინიმუმ ერთი სავარჯიშო'**
  String get validationPlanExercises;

  /// No description provided for @validationPlanDates.
  ///
  /// In ka, this message translates to:
  /// **'დასრულება დაწყებამდეა'**
  String get validationPlanDates;

  /// No description provided for @validationExerciseName.
  ///
  /// In ka, this message translates to:
  /// **'მიუთითეთ სავარჯიშოს სახელი'**
  String get validationExerciseName;

  /// No description provided for @validationLink.
  ///
  /// In ka, this message translates to:
  /// **'ბმული არასწორია (მხოლოდ https://)'**
  String get validationLink;

  /// No description provided for @validationTooManyExercises.
  ///
  /// In ka, this message translates to:
  /// **'მაქსიმუმ 50 სავარჯიშო'**
  String get validationTooManyExercises;

  /// No description provided for @validationTooManyMedia.
  ///
  /// In ka, this message translates to:
  /// **'მაქსიმუმ 10 მასალა სავარჯიშოზე'**
  String get validationTooManyMedia;

  /// No description provided for @validationPlanNotDraft.
  ///
  /// In ka, this message translates to:
  /// **'მხოლოდ მონახაზის რედაქტირებაა შესაძლებელი გამოქვეყნებამდე'**
  String get validationPlanNotDraft;

  /// No description provided for @payProofAction.
  ///
  /// In ka, this message translates to:
  /// **'გადახდის დადასტურება'**
  String get payProofAction;

  /// No description provided for @payProofTitle.
  ///
  /// In ka, this message translates to:
  /// **'გადახდის დადასტურება'**
  String get payProofTitle;

  /// No description provided for @payProofDate.
  ///
  /// In ka, this message translates to:
  /// **'გადახდის თარიღი'**
  String get payProofDate;

  /// No description provided for @payProofReference.
  ///
  /// In ka, this message translates to:
  /// **'ტრანზაქციის / საიდენტიფიკაციო ნომერი'**
  String get payProofReference;

  /// No description provided for @payProofNote.
  ///
  /// In ka, this message translates to:
  /// **'შენიშვნა'**
  String get payProofNote;

  /// No description provided for @payProofReceipt.
  ///
  /// In ka, this message translates to:
  /// **'ქვითარი (JPG, PNG ან PDF, მაქს. 10 MB)'**
  String get payProofReceipt;

  /// No description provided for @payProofSubmit.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნა შესამოწმებლად'**
  String get payProofSubmit;

  /// No description provided for @payProofSubmitted.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნილია — მწვრთნელი შეამოწმებს'**
  String get payProofSubmitted;

  /// No description provided for @payProofUploading.
  ///
  /// In ka, this message translates to:
  /// **'იტვირთება… {percent}%'**
  String payProofUploading(int percent);

  /// No description provided for @payProofHint.
  ///
  /// In ka, this message translates to:
  /// **'თქვენი დადასტურება გადახდას ავტომატურად გადახდილად არ აქცევს — მას ამოწმებს უფლებამოსილი მწვრთნელი ან კლუბის ადმინი.'**
  String get payProofHint;

  /// No description provided for @payStateAwaiting.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურების მოლოდინში'**
  String get payStateAwaiting;

  /// No description provided for @payStateUnderReview.
  ///
  /// In ka, this message translates to:
  /// **'მოწმდება'**
  String get payStateUnderReview;

  /// No description provided for @payStateRejected.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფილია'**
  String get payStateRejected;

  /// No description provided for @payStatePaid.
  ///
  /// In ka, this message translates to:
  /// **'გადახდილია'**
  String get payStatePaid;

  /// No description provided for @payRejectedReason.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფის მიზეზი: {reason}'**
  String payRejectedReason(String reason);

  /// No description provided for @payResubmit.
  ///
  /// In ka, this message translates to:
  /// **'ხელახლა გაგზავნა'**
  String get payResubmit;

  /// No description provided for @paySubmittedOn.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნილია {date}'**
  String paySubmittedOn(String date);

  /// No description provided for @payViewReceipt.
  ///
  /// In ka, this message translates to:
  /// **'ქვითრის ნახვა'**
  String get payViewReceipt;

  /// No description provided for @payVerifiedBy.
  ///
  /// In ka, this message translates to:
  /// **'დაადასტურა {name}, {date}'**
  String payVerifiedBy(String name, String date);

  /// No description provided for @payReviewQueue.
  ///
  /// In ka, this message translates to:
  /// **'გადახდების დადასტურება'**
  String get payReviewQueue;

  /// No description provided for @payReviewEmpty.
  ///
  /// In ka, this message translates to:
  /// **'დასადასტურებელი გადახდა არ არის'**
  String get payReviewEmpty;

  /// No description provided for @payApprove.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურება'**
  String get payApprove;

  /// No description provided for @payReject.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფა'**
  String get payReject;

  /// No description provided for @payApproved.
  ///
  /// In ka, this message translates to:
  /// **'გადახდა დადასტურდა — მშობელს ეცნობა'**
  String get payApproved;

  /// No description provided for @payRejectedSnack.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფილია — მშობელს ეცნობა მიზეზი'**
  String get payRejectedSnack;

  /// No description provided for @payRejectReasonTitle.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფის მიზეზი'**
  String get payRejectReasonTitle;

  /// No description provided for @payNotReviewer.
  ///
  /// In ka, this message translates to:
  /// **'გადახდების დადასტურების უფლება მხოლოდ დანიშნულ მწვრთნელებსა და კლუბის ადმინისტრატორებს აქვთ.'**
  String get payNotReviewer;

  /// No description provided for @payHistory.
  ///
  /// In ka, this message translates to:
  /// **'ისტორია'**
  String get payHistory;

  /// No description provided for @payEventSubmitted.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნა'**
  String get payEventSubmitted;

  /// No description provided for @payEventResubmitted.
  ///
  /// In ka, this message translates to:
  /// **'ხელახლა გაგზავნა'**
  String get payEventResubmitted;

  /// No description provided for @payEventReviewStarted.
  ///
  /// In ka, this message translates to:
  /// **'შემოწმება დაიწყო'**
  String get payEventReviewStarted;

  /// No description provided for @payEventApproved.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურდა'**
  String get payEventApproved;

  /// No description provided for @payEventRejected.
  ///
  /// In ka, this message translates to:
  /// **'უარყოფილია'**
  String get payEventRejected;

  /// No description provided for @payEventViewed.
  ///
  /// In ka, this message translates to:
  /// **'ქვითარი ნახეს'**
  String get payEventViewed;

  /// No description provided for @payPaymentManagers.
  ///
  /// In ka, this message translates to:
  /// **'გადახდების დამდასტურებლები'**
  String get payPaymentManagers;

  /// No description provided for @payProofFor.
  ///
  /// In ka, this message translates to:
  /// **'{child} · {amount} · {due}'**
  String payProofFor(String child, String amount, String due);

  /// No description provided for @validationProofExists.
  ///
  /// In ka, this message translates to:
  /// **'ამ გადახდაზე დადასტურება უკვე მოწმდება'**
  String get validationProofExists;

  /// No description provided for @validationProofClosed.
  ///
  /// In ka, this message translates to:
  /// **'ეს დადასტურება უკვე განხილულია'**
  String get validationProofClosed;

  /// No description provided for @validationPaymentClosed.
  ///
  /// In ka, this message translates to:
  /// **'გადახდა უკვე დახურულია'**
  String get validationPaymentClosed;

  /// No description provided for @validationReceiptRequired.
  ///
  /// In ka, this message translates to:
  /// **'დაურთეთ ქვითარი'**
  String get validationReceiptRequired;

  /// No description provided for @validationDateFuture.
  ///
  /// In ka, this message translates to:
  /// **'თარიღი მომავალშია'**
  String get validationDateFuture;

  /// No description provided for @notifPaymentProofSubmitted.
  ///
  /// In ka, this message translates to:
  /// **'გადახდის დადასტურება შემოწმებისთვის'**
  String get notifPaymentProofSubmitted;

  /// No description provided for @notifPaymentProofApproved.
  ///
  /// In ka, this message translates to:
  /// **'გადახდა დადასტურდა'**
  String get notifPaymentProofApproved;

  /// No description provided for @notifPaymentProofRejected.
  ///
  /// In ka, this message translates to:
  /// **'გადახდის დადასტურება უარყოფილია'**
  String get notifPaymentProofRejected;

  /// No description provided for @notifTrainingPlanPublished.
  ///
  /// In ka, this message translates to:
  /// **'ახალი სავარჯიშო გეგმა'**
  String get notifTrainingPlanPublished;

  /// No description provided for @notifBodyPlan.
  ///
  /// In ka, this message translates to:
  /// **'{title} · {group}'**
  String notifBodyPlan(String title, String group);

  /// No description provided for @notifBodyProof.
  ///
  /// In ka, this message translates to:
  /// **'{child} · {amount}'**
  String notifBodyProof(String child, String amount);

  /// No description provided for @notifBodyProofRejected.
  ///
  /// In ka, this message translates to:
  /// **'{child} · {reason}'**
  String notifBodyProofRejected(String child, String reason);

  /// No description provided for @notifBodyCertDays.
  ///
  /// In ka, this message translates to:
  /// **'{child} — {days} დღე დარჩა'**
  String notifBodyCertDays(String child, String days);

  /// No description provided for @notifBodyCertExpired.
  ///
  /// In ka, this message translates to:
  /// **'{child} — ცნობას ვადა გაუვიდა'**
  String notifBodyCertExpired(String child);

  /// No description provided for @sysTrainingCancelled.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში გაუქმდა ({when}). მიზეზი: {reason}'**
  String sysTrainingCancelled(String when, String reason);

  /// No description provided for @sysTrainingMoved.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიში გადაიდო: {from} → {to}'**
  String sysTrainingMoved(String from, String to);

  /// No description provided for @sysMatchCreated.
  ///
  /// In ka, this message translates to:
  /// **'დაემატა თამაში: {opponent}, {when}'**
  String sysMatchCreated(String opponent, String when);

  /// No description provided for @sysMatchMoved.
  ///
  /// In ka, this message translates to:
  /// **'თამაში გადაიდო: {from} → {to}'**
  String sysMatchMoved(String from, String to);

  /// No description provided for @sysMatchCancelled.
  ///
  /// In ka, this message translates to:
  /// **'თამაში ({opponent}) გაუქმდა. მიზეზი: {reason}'**
  String sysMatchCancelled(String opponent, String reason);

  /// No description provided for @sysScheduleCreated.
  ///
  /// In ka, this message translates to:
  /// **'დაემატა ვარჯიშების განრიგი'**
  String get sysScheduleCreated;

  /// No description provided for @sysScheduleChanged.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშების განრიგი შეიცვალა {from}-დან'**
  String sysScheduleChanged(String from);

  /// No description provided for @sysPlanPublished.
  ///
  /// In ka, this message translates to:
  /// **'გამოქვეყნდა სავარჯიშო გეგმა: {title}'**
  String sysPlanPublished(String title);

  /// No description provided for @sysScheduleReason.
  ///
  /// In ka, this message translates to:
  /// **'განრიგი შეიცვალა'**
  String get sysScheduleReason;

  /// No description provided for @adminNavCompliance.
  ///
  /// In ka, this message translates to:
  /// **'ცნობები'**
  String get adminNavCompliance;

  /// No description provided for @adminNavAttendance.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get adminNavAttendance;

  /// No description provided for @adminNavPlans.
  ///
  /// In ka, this message translates to:
  /// **'სავარჯიშო გეგმები'**
  String get adminNavPlans;

  /// No description provided for @adminNavPayments.
  ///
  /// In ka, this message translates to:
  /// **'გადახდები'**
  String get adminNavPayments;

  /// No description provided for @adminNavSettings.
  ///
  /// In ka, this message translates to:
  /// **'პარამეტრები'**
  String get adminNavSettings;

  /// No description provided for @adminComplianceNote.
  ///
  /// In ka, this message translates to:
  /// **'მხოლოდ სტატუსების რაოდენობა — დოკუმენტები და ბავშვების სახელები არ ჩანს.'**
  String get adminComplianceNote;

  /// No description provided for @adminColValid.
  ///
  /// In ka, this message translates to:
  /// **'მოქმედი'**
  String get adminColValid;

  /// No description provided for @adminColExpiring.
  ///
  /// In ka, this message translates to:
  /// **'იწურება'**
  String get adminColExpiring;

  /// No description provided for @adminColExpired.
  ///
  /// In ka, this message translates to:
  /// **'ვადაგასული'**
  String get adminColExpired;

  /// No description provided for @adminColMissing.
  ///
  /// In ka, this message translates to:
  /// **'არ არის'**
  String get adminColMissing;

  /// No description provided for @adminColRate.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get adminColRate;

  /// No description provided for @adminColSessions.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშები'**
  String get adminColSessions;

  /// No description provided for @adminColPlans.
  ///
  /// In ka, this message translates to:
  /// **'გეგმები'**
  String get adminColPlans;

  /// No description provided for @adminColPlanType.
  ///
  /// In ka, this message translates to:
  /// **'ტიპი'**
  String get adminColPlanType;

  /// No description provided for @adminColAmount.
  ///
  /// In ka, this message translates to:
  /// **'თანხა'**
  String get adminColAmount;

  /// No description provided for @adminColSubmitted.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნილია'**
  String get adminColSubmitted;

  /// No description provided for @adminColReviewers.
  ///
  /// In ka, this message translates to:
  /// **'დამდასტურებლები'**
  String get adminColReviewers;

  /// No description provided for @adminPaymentQueueNote.
  ///
  /// In ka, this message translates to:
  /// **'ქვითარი იხსნება დროებითი ბმულით და მისი ნახვა აღირიცხება.'**
  String get adminPaymentQueueNote;

  /// No description provided for @adminSetReviewers.
  ///
  /// In ka, this message translates to:
  /// **'დამდასტურებლების მინიჭება'**
  String get adminSetReviewers;

  /// No description provided for @adminLanguage.
  ///
  /// In ka, this message translates to:
  /// **'ინტერფეისის ენა'**
  String get adminLanguage;

  /// No description provided for @adminRosterNote.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლეთა რაოდენობა ჯგუფების მიხედვით — სახელების გარეშე.'**
  String get adminRosterNote;

  /// No description provided for @adminMonth.
  ///
  /// In ka, this message translates to:
  /// **'თვე'**
  String get adminMonth;

  /// No description provided for @addToCalendar.
  ///
  /// In ka, this message translates to:
  /// **'კალენდარში დამატება'**
  String get addToCalendar;

  /// No description provided for @exportSchedule.
  ///
  /// In ka, this message translates to:
  /// **'განრიგის კალენდარში გატანა'**
  String get exportSchedule;

  /// No description provided for @calendarNothingToExport.
  ///
  /// In ka, this message translates to:
  /// **'გასატანი ვარჯიშები არ არის'**
  String get calendarNothingToExport;

  /// No description provided for @contactsTitle.
  ///
  /// In ka, this message translates to:
  /// **'კონტაქტები'**
  String get contactsTitle;

  /// No description provided for @contactsCoachTitle.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის კონტაქტი'**
  String get contactsCoachTitle;

  /// No description provided for @contactsParentsTitle.
  ///
  /// In ka, this message translates to:
  /// **'მშობლები და მეურვეები'**
  String get contactsParentsTitle;

  /// No description provided for @contactCallName.
  ///
  /// In ka, this message translates to:
  /// **'დარეკვა: {name}'**
  String contactCallName(String name);

  /// No description provided for @contactNoPhone.
  ///
  /// In ka, this message translates to:
  /// **'ტელეფონის ნომერი არ არის'**
  String get contactNoPhone;

  /// No description provided for @contactCoachAction.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელთან დაკავშირება'**
  String get contactCoachAction;

  /// No description provided for @contactParentsAction.
  ///
  /// In ka, this message translates to:
  /// **'მშობლების კონტაქტები'**
  String get contactParentsAction;

  /// No description provided for @contactPrivacyCoach.
  ///
  /// In ka, this message translates to:
  /// **'ამ ნომრებს მხოლოდ ამ ჯგუფის მწვრთნელები ხედავენ. გამოიყენეთ ისინი მხოლოდ გუნდის საკითხებისთვის.'**
  String get contactPrivacyCoach;

  /// No description provided for @contactPrivacyParent.
  ///
  /// In ka, this message translates to:
  /// **'თქვენი შვილის ჯგუფის მწვრთნელის კონტაქტი. სხვა მშობლების ნომრები არ ჩანს.'**
  String get contactPrivacyParent;

  /// No description provided for @contactParentOf.
  ///
  /// In ka, this message translates to:
  /// **'მშობელი: {names}'**
  String contactParentOf(String names);

  /// No description provided for @contactsEmpty.
  ///
  /// In ka, this message translates to:
  /// **'კონტაქტები არ არის'**
  String get contactsEmpty;

  /// No description provided for @relationMother.
  ///
  /// In ka, this message translates to:
  /// **'დედა'**
  String get relationMother;

  /// No description provided for @relationFather.
  ///
  /// In ka, this message translates to:
  /// **'მამა'**
  String get relationFather;

  /// No description provided for @relationGuardian.
  ///
  /// In ka, this message translates to:
  /// **'მეურვე'**
  String get relationGuardian;

  /// No description provided for @relationGrandparent.
  ///
  /// In ka, this message translates to:
  /// **'ბებია ან ბაბუა'**
  String get relationGrandparent;

  /// No description provided for @relationOther.
  ///
  /// In ka, this message translates to:
  /// **'სხვა ნათესავი'**
  String get relationOther;

  /// No description provided for @receiptSeenBy.
  ///
  /// In ka, this message translates to:
  /// **'ნახა {read}/{total} მშობელმა'**
  String receiptSeenBy(int read, int total);

  /// No description provided for @receiptSeenShort.
  ///
  /// In ka, this message translates to:
  /// **'ნანახია: {read}/{total}'**
  String receiptSeenShort(int read, int total);

  /// No description provided for @receiptAckShort.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურებულია: {acked}/{total}'**
  String receiptAckShort(int acked, int total);

  /// No description provided for @receiptsTitle.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინების სტატუსი'**
  String get receiptsTitle;

  /// No description provided for @receiptNotSeen.
  ///
  /// In ka, this message translates to:
  /// **'არ უნახავს'**
  String get receiptNotSeen;

  /// No description provided for @receiptSeen.
  ///
  /// In ka, this message translates to:
  /// **'ნანახია'**
  String get receiptSeen;

  /// No description provided for @receiptAcknowledged.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურებულია'**
  String get receiptAcknowledged;

  /// No description provided for @receiptSeenAt.
  ///
  /// In ka, this message translates to:
  /// **'ნანახია {time}'**
  String receiptSeenAt(String time);

  /// No description provided for @receiptAckAt.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურდა {time}'**
  String receiptAckAt(String time);

  /// No description provided for @receiptPrivacy.
  ///
  /// In ka, this message translates to:
  /// **'ვინ ნახა ეს შეტყობინება, მხოლოდ თქვენ ხედავთ. მოგვიანებით დამატებული მშობლები არ ითვლება.'**
  String get receiptPrivacy;

  /// No description provided for @chatAckToggle.
  ///
  /// In ka, this message translates to:
  /// **'გაცნობის დადასტურების მოთხოვნა'**
  String get chatAckToggle;

  /// No description provided for @chatAckRequired.
  ///
  /// In ka, this message translates to:
  /// **'საჭიროა გაცნობის დადასტურება'**
  String get chatAckRequired;

  /// No description provided for @chatAckButton.
  ///
  /// In ka, this message translates to:
  /// **'გავეცანი'**
  String get chatAckButton;

  /// No description provided for @chatAckDone.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურებულია'**
  String get chatAckDone;

  /// No description provided for @chatAckSent.
  ///
  /// In ka, this message translates to:
  /// **'დადასტურება გაიგზავნა'**
  String get chatAckSent;

  /// No description provided for @dashboardAcksTitle.
  ///
  /// In ka, this message translates to:
  /// **'თქვენს დადასტურებას ელოდება'**
  String get dashboardAcksTitle;

  /// No description provided for @dashboardAcksBody.
  ///
  /// In ka, this message translates to:
  /// **'{count} შეტყობინება · {groups}'**
  String dashboardAcksBody(int count, String groups);

  /// No description provided for @notifAckRequested.
  ///
  /// In ka, this message translates to:
  /// **'გთხოვთ, დაადასტუროთ გაცნობა'**
  String get notifAckRequested;

  /// No description provided for @videoPlay.
  ///
  /// In ka, this message translates to:
  /// **'დაკვრა'**
  String get videoPlay;

  /// No description provided for @videoPause.
  ///
  /// In ka, this message translates to:
  /// **'პაუზა'**
  String get videoPause;

  /// No description provided for @videoBack10.
  ///
  /// In ka, this message translates to:
  /// **'10 წამით უკან'**
  String get videoBack10;

  /// No description provided for @videoForward10.
  ///
  /// In ka, this message translates to:
  /// **'10 წამით წინ'**
  String get videoForward10;

  /// No description provided for @videoFullscreen.
  ///
  /// In ka, this message translates to:
  /// **'სრულ ეკრანზე'**
  String get videoFullscreen;

  /// No description provided for @videoExitFullscreen.
  ///
  /// In ka, this message translates to:
  /// **'სრული ეკრანიდან გასვლა'**
  String get videoExitFullscreen;

  /// No description provided for @videoLoading.
  ///
  /// In ka, this message translates to:
  /// **'ვიდეო იტვირთება…'**
  String get videoLoading;

  /// No description provided for @videoBuffering.
  ///
  /// In ka, this message translates to:
  /// **'ბუფერიზაცია…'**
  String get videoBuffering;

  /// No description provided for @videoError.
  ///
  /// In ka, this message translates to:
  /// **'ვიდეოს დაკვრა ვერ მოხერხდა.'**
  String get videoError;

  /// No description provided for @videoPosition.
  ///
  /// In ka, this message translates to:
  /// **'ვიდეოს პოზიცია'**
  String get videoPosition;

  /// No description provided for @downloadAction.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა'**
  String get downloadAction;

  /// No description provided for @downloadTitle.
  ///
  /// In ka, this message translates to:
  /// **'მედიის ჩამოტვირთვა'**
  String get downloadTitle;

  /// No description provided for @downloadNotice.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვისას ფაილის ასლი შეინახება თქვენს მოწყობილობაზე. მისი დისტანციურად წაშლა შეუძლებელია, ამიტომ გაუზიარეთ პასუხისმგებლობით.'**
  String get downloadNotice;

  /// No description provided for @downloadProgress.
  ///
  /// In ka, this message translates to:
  /// **'იტვირთება… {percent}%'**
  String downloadProgress(int percent);

  /// No description provided for @downloadCancelled.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა გაუქმდა'**
  String get downloadCancelled;

  /// No description provided for @downloadFailed.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა ვერ მოხერხდა. შეამოწმეთ კავშირი და სცადეთ ხელახლა.'**
  String get downloadFailed;

  /// No description provided for @downloadDone.
  ///
  /// In ka, this message translates to:
  /// **'მზადაა: {name}. აირჩიეთ, სად შეინახოთ.'**
  String downloadDone(String name);

  /// No description provided for @downloadDenied.
  ///
  /// In ka, this message translates to:
  /// **'ამ ფაილზე წვდომა აღარ გაქვთ.'**
  String get downloadDenied;

  /// No description provided for @downloadStorageError.
  ///
  /// In ka, this message translates to:
  /// **'ფაილის შენახვა ამ მოწყობილობაზე ვერ მოხერხდა.'**
  String get downloadStorageError;

  /// No description provided for @downloadPolicyOff.
  ///
  /// In ka, this message translates to:
  /// **'ამ ჯგუფისთვის ჩამოტვირთვა გამორთულია.'**
  String get downloadPolicyOff;

  /// No description provided for @adminNavMediaDownloads.
  ///
  /// In ka, this message translates to:
  /// **'მედიის ჩამოტვირთვები'**
  String get adminNavMediaDownloads;

  /// No description provided for @adminMediaPolicy.
  ///
  /// In ka, this message translates to:
  /// **'მშობლებს შეუძლიათ ფოტოებისა და ვიდეოების ჩამოტვირთვა'**
  String get adminMediaPolicy;

  /// No description provided for @adminMediaDownloadsNote.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელების ფოტოებისა და ვიდეოების ავტორიზებული ჩამოტვირთვები. ჩამოტვირთული ასლის გაუქმება შეუძლებელია.'**
  String get adminMediaDownloadsNote;

  /// No description provided for @adminColPost.
  ///
  /// In ka, this message translates to:
  /// **'პოსტი'**
  String get adminColPost;

  /// No description provided for @adminColUser.
  ///
  /// In ka, this message translates to:
  /// **'მომხმარებელი'**
  String get adminColUser;

  /// No description provided for @adminColDownloads.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა'**
  String get adminColDownloads;

  /// No description provided for @studentProfileTitle.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლის პროფილი'**
  String get studentProfileTitle;

  /// No description provided for @studentProfileOpen.
  ///
  /// In ka, this message translates to:
  /// **'პროფილი'**
  String get studentProfileOpen;

  /// No description provided for @tabOverview.
  ///
  /// In ka, this message translates to:
  /// **'მიმოხილვა'**
  String get tabOverview;

  /// No description provided for @tabTrainings.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშები'**
  String get tabTrainings;

  /// No description provided for @tabPlans.
  ///
  /// In ka, this message translates to:
  /// **'გეგმები'**
  String get tabPlans;

  /// No description provided for @tabMedia.
  ///
  /// In ka, this message translates to:
  /// **'მედია'**
  String get tabMedia;

  /// No description provided for @tabMatches.
  ///
  /// In ka, this message translates to:
  /// **'მატჩები'**
  String get tabMatches;

  /// No description provided for @profileSportsGroups.
  ///
  /// In ka, this message translates to:
  /// **'სპორტი და ჯგუფები'**
  String get profileSportsGroups;

  /// No description provided for @profileCoaches.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელები'**
  String get profileCoaches;

  /// No description provided for @profileUpcomingTrainings.
  ///
  /// In ka, this message translates to:
  /// **'მომავალი ვარჯიშები'**
  String get profileUpcomingTrainings;

  /// No description provided for @profileUpcomingMatches.
  ///
  /// In ka, this message translates to:
  /// **'მომავალი მატჩები'**
  String get profileUpcomingMatches;

  /// No description provided for @profileTrainingHistory.
  ///
  /// In ka, this message translates to:
  /// **'ვარჯიშების ისტორია'**
  String get profileTrainingHistory;

  /// No description provided for @profileAttendance.
  ///
  /// In ka, this message translates to:
  /// **'დასწრება'**
  String get profileAttendance;

  /// No description provided for @profileHomework.
  ///
  /// In ka, this message translates to:
  /// **'საშინაო დავალება'**
  String get profileHomework;

  /// No description provided for @profileMatchResults.
  ///
  /// In ka, this message translates to:
  /// **'მატჩების შედეგები'**
  String get profileMatchResults;

  /// No description provided for @profileCertificate.
  ///
  /// In ka, this message translates to:
  /// **'სამედიცინო ცნობა'**
  String get profileCertificate;

  /// No description provided for @profilePayments.
  ///
  /// In ka, this message translates to:
  /// **'გადახდები'**
  String get profilePayments;

  /// No description provided for @profileEmpty.
  ///
  /// In ka, this message translates to:
  /// **'ჯერ არაფერია'**
  String get profileEmpty;

  /// No description provided for @profileCoachScope.
  ///
  /// In ka, this message translates to:
  /// **'ნაჩვენებია მხოლოდ თქვენი ჯგუფების მონაცემები.'**
  String get profileCoachScope;

  /// No description provided for @contactCoachAbout.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელისთვის მიწერა: {child}'**
  String contactCoachAbout(String child);

  /// No description provided for @threadAbout.
  ///
  /// In ka, this message translates to:
  /// **'თემა: {child}'**
  String threadAbout(String child);

  /// No description provided for @threadPrivacy.
  ///
  /// In ka, this message translates to:
  /// **'ამ მიმოწერას ხედავენ მხოლოდ ბავშვის ({child}) მშობლები და ეს მწვრთნელი.'**
  String threadPrivacy(String child);

  /// No description provided for @threadEmpty.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინებები ჯერ არ არის. დაწერეთ პირველი.'**
  String get threadEmpty;

  /// No description provided for @threadsTitle.
  ///
  /// In ka, this message translates to:
  /// **'მიმოწერა მოსწავლეების შესახებ'**
  String get threadsTitle;

  /// No description provided for @chooseCoach.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ მწვრთნელი'**
  String get chooseCoach;

  /// No description provided for @notifChildMessage.
  ///
  /// In ka, this message translates to:
  /// **'შეტყობინება ბავშვის შესახებ'**
  String get notifChildMessage;

  /// No description provided for @matchResultEnter.
  ///
  /// In ka, this message translates to:
  /// **'შედეგის შეყვანა'**
  String get matchResultEnter;

  /// No description provided for @matchResultCorrect.
  ///
  /// In ka, this message translates to:
  /// **'შედეგის შესწორება'**
  String get matchResultCorrect;

  /// No description provided for @matchResultTitle.
  ///
  /// In ka, this message translates to:
  /// **'საბოლოო ანგარიში'**
  String get matchResultTitle;

  /// No description provided for @matchResultOurTeam.
  ///
  /// In ka, this message translates to:
  /// **'ჩვენი გუნდი'**
  String get matchResultOurTeam;

  /// No description provided for @matchResultOpponent.
  ///
  /// In ka, this message translates to:
  /// **'მეტოქე'**
  String get matchResultOpponent;

  /// No description provided for @matchResultSummary.
  ///
  /// In ka, this message translates to:
  /// **'შეჯამება (არასავალდებულო)'**
  String get matchResultSummary;

  /// No description provided for @matchResultFinishedAt.
  ///
  /// In ka, this message translates to:
  /// **'დასრულდა: {time}'**
  String matchResultFinishedAt(String time);

  /// No description provided for @matchWin.
  ///
  /// In ka, this message translates to:
  /// **'მოგება'**
  String get matchWin;

  /// No description provided for @matchDraw.
  ///
  /// In ka, this message translates to:
  /// **'ფრე'**
  String get matchDraw;

  /// No description provided for @matchLoss.
  ///
  /// In ka, this message translates to:
  /// **'წაგება'**
  String get matchLoss;

  /// No description provided for @matchResultCorrected.
  ///
  /// In ka, this message translates to:
  /// **'შესწორებულია'**
  String get matchResultCorrected;

  /// No description provided for @matchResultSaved.
  ///
  /// In ka, this message translates to:
  /// **'შედეგი შენახულია'**
  String get matchResultSaved;

  /// No description provided for @matchResultHistory.
  ///
  /// In ka, this message translates to:
  /// **'შესწორებების ისტორია'**
  String get matchResultHistory;

  /// No description provided for @matchResultLatest.
  ///
  /// In ka, this message translates to:
  /// **'ბოლო შედეგი'**
  String get matchResultLatest;

  /// No description provided for @matchResultNotice.
  ///
  /// In ka, this message translates to:
  /// **'მშობლები შეტყობინებას პირველი შედეგის შენახვისას მიიღებენ. შესწორებები აღირიცხება.'**
  String get matchResultNotice;

  /// No description provided for @notifMatchResult.
  ///
  /// In ka, this message translates to:
  /// **'მატჩის შედეგი'**
  String get notifMatchResult;

  /// No description provided for @notifBodyMatchResult.
  ///
  /// In ka, this message translates to:
  /// **'{opponent}: {our}–{their}'**
  String notifBodyMatchResult(String opponent, String our, String their);

  /// No description provided for @validationResultScore.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ ანგარიში 0-დან 999-მდე.'**
  String get validationResultScore;

  /// No description provided for @validationResultNotStarted.
  ///
  /// In ka, this message translates to:
  /// **'შედეგის შეყვანა შესაძლებელია მატჩის დაწყების შემდეგ.'**
  String get validationResultNotStarted;

  /// No description provided for @validationResultCancelled.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმებულ მატჩს შედეგი არ აქვს.'**
  String get validationResultCancelled;

  /// No description provided for @validationResultCompletedAt.
  ///
  /// In ka, this message translates to:
  /// **'დასრულების დრო უნდა იყოს მატჩის დაწყებასა და ახლანდელ დროს შორის.'**
  String get validationResultCompletedAt;

  /// No description provided for @payDownloadReceipt.
  ///
  /// In ka, this message translates to:
  /// **'ქვითრის ჩამოტვირთვა'**
  String get payDownloadReceipt;

  /// No description provided for @payProofNotFound.
  ///
  /// In ka, this message translates to:
  /// **'მოთხოვნა ვერ მოიძებნა ან უკვე განხილულია.'**
  String get payProofNotFound;

  /// No description provided for @payEventDownloaded.
  ///
  /// In ka, this message translates to:
  /// **'მიმომხილველმა ქვითარი ჩამოტვირთა'**
  String get payEventDownloaded;

  /// No description provided for @roleStudent.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლე'**
  String get roleStudent;

  /// No description provided for @continueAsStudent.
  ///
  /// In ka, this message translates to:
  /// **'გაგრძელება მოსწავლედ'**
  String get continueAsStudent;

  /// No description provided for @studentDemoNote.
  ///
  /// In ka, this message translates to:
  /// **'მოსწავლის შესვლა მხოლოდ დემო რეჟიმშია ხელმისაწვდომი.'**
  String get studentDemoNote;

  /// No description provided for @studentWelcome.
  ///
  /// In ka, this message translates to:
  /// **'გამარჯობა, {name}! ვიმეცადინოთ?'**
  String studentWelcome(String name);

  /// No description provided for @studentNavHome.
  ///
  /// In ka, this message translates to:
  /// **'მთავარი'**
  String get studentNavHome;

  /// No description provided for @studentNavBrain.
  ///
  /// In ka, this message translates to:
  /// **'ტვინის აკადემია'**
  String get studentNavBrain;

  /// No description provided for @studentNavProgress.
  ///
  /// In ka, this message translates to:
  /// **'პროგრესი'**
  String get studentNavProgress;

  /// No description provided for @studentMySports.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი სპორტი'**
  String get studentMySports;

  /// No description provided for @studentMyCoach.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი მწვრთნელი'**
  String get studentMyCoach;

  /// No description provided for @studentNextTraining.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგი ვარჯიში'**
  String get studentNextTraining;

  /// No description provided for @studentNoTraining.
  ///
  /// In ka, this message translates to:
  /// **'დაგეგმილი ვარჯიში არ არის'**
  String get studentNoTraining;

  /// No description provided for @studentUpcomingMatches.
  ///
  /// In ka, this message translates to:
  /// **'მომავალი მატჩები'**
  String get studentUpcomingMatches;

  /// No description provided for @studentMatchResults.
  ///
  /// In ka, this message translates to:
  /// **'მატჩების შედეგები'**
  String get studentMatchResults;

  /// No description provided for @studentPlans.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი სავარჯიშო გეგმები'**
  String get studentPlans;

  /// No description provided for @studentHomework.
  ///
  /// In ka, this message translates to:
  /// **'საშინაო დავალება'**
  String get studentHomework;

  /// No description provided for @studentAttendance.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი დასწრება'**
  String get studentAttendance;

  /// No description provided for @studentAttendanceRate.
  ///
  /// In ka, this message translates to:
  /// **'{percent}% ვარჯიშზე ვიყავი'**
  String studentAttendanceRate(int percent);

  /// No description provided for @studentAchievements.
  ///
  /// In ka, this message translates to:
  /// **'მიღწევები'**
  String get studentAchievements;

  /// No description provided for @studentNothing.
  ///
  /// In ka, this message translates to:
  /// **'ჯერ არაფერია'**
  String get studentNothing;

  /// No description provided for @studentChallenges.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის გამოწვევები'**
  String get studentChallenges;

  /// No description provided for @challengeDue.
  ///
  /// In ka, this message translates to:
  /// **'ვადა: {date}'**
  String challengeDue(String date);

  /// No description provided for @challengeDone.
  ///
  /// In ka, this message translates to:
  /// **'შესრულებულია'**
  String get challengeDone;

  /// No description provided for @challengeOpen.
  ///
  /// In ka, this message translates to:
  /// **'შესასრულებელია'**
  String get challengeOpen;

  /// No description provided for @challengeOverdue.
  ///
  /// In ka, this message translates to:
  /// **'ვადა გავიდა'**
  String get challengeOverdue;

  /// No description provided for @brainAcademy.
  ///
  /// In ka, this message translates to:
  /// **'ტვინის აკადემია'**
  String get brainAcademy;

  /// No description provided for @brainTagline.
  ///
  /// In ka, this message translates to:
  /// **'ავარჯიშე გონება, როგორც ნამდვილმა სპორტსმენმა'**
  String get brainTagline;

  /// No description provided for @brainNotIq.
  ///
  /// In ka, this message translates to:
  /// **'ქულები სავარჯიშოდ და გასართობადაა — ეს IQ-ის ტესტი არ არის.'**
  String get brainNotIq;

  /// No description provided for @gameMemoryMatch.
  ///
  /// In ka, this message translates to:
  /// **'მეხსიერების წყვილები'**
  String get gameMemoryMatch;

  /// No description provided for @gameLogicQuest.
  ///
  /// In ka, this message translates to:
  /// **'ლოგიკის თავგადასავალი'**
  String get gameLogicQuest;

  /// No description provided for @gameSmartPlay.
  ///
  /// In ka, this message translates to:
  /// **'ჭკვიანი თამაში'**
  String get gameSmartPlay;

  /// No description provided for @gameQuickMind.
  ///
  /// In ka, this message translates to:
  /// **'სწრაფი გონება'**
  String get gameQuickMind;

  /// No description provided for @gameSequenceMaster.
  ///
  /// In ka, this message translates to:
  /// **'თანმიმდევრობის ოსტატი'**
  String get gameSequenceMaster;

  /// No description provided for @gamePathFinder.
  ///
  /// In ka, this message translates to:
  /// **'გზის მაძიებელი'**
  String get gamePathFinder;

  /// No description provided for @gameDescMemory.
  ///
  /// In ka, this message translates to:
  /// **'იპოვე ერთნაირი სპორტული ბარათები'**
  String get gameDescMemory;

  /// No description provided for @gameDescLogic.
  ///
  /// In ka, this message translates to:
  /// **'გამოიცანი ფიგურების წესი'**
  String get gameDescLogic;

  /// No description provided for @gameDescSmart.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიე საუკეთესო სვლა მოედანზე'**
  String get gameDescSmart;

  /// No description provided for @gameDescQuick.
  ///
  /// In ka, this message translates to:
  /// **'სწრაფად იპოვე სწორი სიმბოლო'**
  String get gameDescQuick;

  /// No description provided for @gameDescSequence.
  ///
  /// In ka, this message translates to:
  /// **'დაიმახსოვრე და გაიმეორე'**
  String get gameDescSequence;

  /// No description provided for @gameDescPath.
  ///
  /// In ka, this message translates to:
  /// **'მიიყვანე ბურთი კარამდე'**
  String get gameDescPath;

  /// No description provided for @gameHowToMemory.
  ///
  /// In ka, this message translates to:
  /// **'შეეხე ორ ბარათს. თუ ერთნაირია, დარჩება ღია. იპოვე ყველა წყვილი რაც შეიძლება ნაკლები ცდით.'**
  String get gameHowToMemory;

  /// No description provided for @gameHowToLogic.
  ///
  /// In ka, this message translates to:
  /// **'შეხედე რიგს და აირჩიე ფიგურა, რომელიც „?“-ის ადგილას უნდა იყოს.'**
  String get gameHowToLogic;

  /// No description provided for @gameHowToSmart.
  ///
  /// In ka, this message translates to:
  /// **'ბურთი შენთანაა (ყვითელი რგოლი). აირჩიე საუკეთესო პასი ან მოძრაობა და წაიკითხე ახსნა.'**
  String get gameHowToSmart;

  /// No description provided for @gameHowToQuick.
  ///
  /// In ka, this message translates to:
  /// **'ზემოთ ნაჩვენებია მიზანი. შეეხე იმავე ფიგურას იმავე ფერში, სანამ დრო ამოიწურება.'**
  String get gameHowToQuick;

  /// No description provided for @gameHowToSequence.
  ///
  /// In ka, this message translates to:
  /// **'უყურე, როგორ ინთება ფერები, შემდეგ შეეხე მათ იმავე რიგით. ყოველ რაუნდში რიგი გრძელდება.'**
  String get gameHowToSequence;

  /// No description provided for @gameHowToPath.
  ///
  /// In ka, this message translates to:
  /// **'ისრებით ან გადასმით გადაადგილე ბურთი კარამდე. კედლები და კონუსები გზას კეტავს.'**
  String get gameHowToPath;

  /// No description provided for @diffEasy.
  ///
  /// In ka, this message translates to:
  /// **'მარტივი'**
  String get diffEasy;

  /// No description provided for @diffMedium.
  ///
  /// In ka, this message translates to:
  /// **'საშუალო'**
  String get diffMedium;

  /// No description provided for @diffHard.
  ///
  /// In ka, this message translates to:
  /// **'რთული'**
  String get diffHard;

  /// No description provided for @gameLevel.
  ///
  /// In ka, this message translates to:
  /// **'დონე {level}'**
  String gameLevel(int level);

  /// No description provided for @gameStart.
  ///
  /// In ka, this message translates to:
  /// **'თამაშის დაწყება'**
  String get gameStart;

  /// No description provided for @gamePause.
  ///
  /// In ka, this message translates to:
  /// **'პაუზა'**
  String get gamePause;

  /// No description provided for @gameResume.
  ///
  /// In ka, this message translates to:
  /// **'გაგრძელება'**
  String get gameResume;

  /// No description provided for @gameRestart.
  ///
  /// In ka, this message translates to:
  /// **'თავიდან'**
  String get gameRestart;

  /// No description provided for @gameQuit.
  ///
  /// In ka, this message translates to:
  /// **'გასვლა'**
  String get gameQuit;

  /// No description provided for @gamePaused.
  ///
  /// In ka, this message translates to:
  /// **'თამაში შეჩერებულია'**
  String get gamePaused;

  /// No description provided for @gameScore.
  ///
  /// In ka, this message translates to:
  /// **'ქულა: {score}'**
  String gameScore(int score);

  /// No description provided for @gameTime.
  ///
  /// In ka, this message translates to:
  /// **'დრო: {time}'**
  String gameTime(String time);

  /// No description provided for @gameAttempts.
  ///
  /// In ka, this message translates to:
  /// **'ცდები: {count}'**
  String gameAttempts(int count);

  /// No description provided for @gameAccuracy.
  ///
  /// In ka, this message translates to:
  /// **'სიზუსტე: {percent}%'**
  String gameAccuracy(int percent);

  /// No description provided for @gameComplete.
  ///
  /// In ka, this message translates to:
  /// **'ყოჩაღ!'**
  String get gameComplete;

  /// No description provided for @gameTryAgain.
  ///
  /// In ka, this message translates to:
  /// **'კარგი ცდა იყო! კიდევ ერთხელ?'**
  String get gameTryAgain;

  /// No description provided for @gameNextLevel.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგი დონე'**
  String get gameNextLevel;

  /// No description provided for @gamePlayAgain.
  ///
  /// In ka, this message translates to:
  /// **'კიდევ ერთხელ'**
  String get gamePlayAgain;

  /// No description provided for @gameNewBadge.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ნიშანი!'**
  String get gameNewBadge;

  /// No description provided for @gameBestScore.
  ///
  /// In ka, this message translates to:
  /// **'საუკეთესო: {score}'**
  String gameBestScore(int score);

  /// No description provided for @gameCorrect.
  ///
  /// In ka, this message translates to:
  /// **'სწორია!'**
  String get gameCorrect;

  /// No description provided for @gameWrong.
  ///
  /// In ka, this message translates to:
  /// **'არა უშავს, სცადე ისევ'**
  String get gameWrong;

  /// No description provided for @gameSaveFailed.
  ///
  /// In ka, this message translates to:
  /// **'შედეგის შენახვა ვერ მოხერხდა.'**
  String get gameSaveFailed;

  /// No description provided for @gameRound.
  ///
  /// In ka, this message translates to:
  /// **'რაუნდი {n}/{total}'**
  String gameRound(int n, int total);

  /// No description provided for @gameWatch.
  ///
  /// In ka, this message translates to:
  /// **'კარგად დააკვირდი…'**
  String get gameWatch;

  /// No description provided for @gameYourTurn.
  ///
  /// In ka, this message translates to:
  /// **'შენი ჯერია!'**
  String get gameYourTurn;

  /// No description provided for @gameLives.
  ///
  /// In ka, this message translates to:
  /// **'სიცოცხლე: {n}'**
  String gameLives(int n);

  /// No description provided for @gameMoves.
  ///
  /// In ka, this message translates to:
  /// **'სვლები: {n}'**
  String gameMoves(int n);

  /// No description provided for @gameSound.
  ///
  /// In ka, this message translates to:
  /// **'ხმოვანი ეფექტები'**
  String get gameSound;

  /// No description provided for @gameInstructions.
  ///
  /// In ka, this message translates to:
  /// **'როგორ ვითამაშოთ'**
  String get gameInstructions;

  /// No description provided for @gameChooseDifficulty.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიე სირთულე'**
  String get gameChooseDifficulty;

  /// No description provided for @gameTimeUp.
  ///
  /// In ka, this message translates to:
  /// **'დრო ამოიწურა'**
  String get gameTimeUp;

  /// No description provided for @logicWhatsMissing.
  ///
  /// In ka, this message translates to:
  /// **'რომელი აკლია?'**
  String get logicWhatsMissing;

  /// No description provided for @spQuestion.
  ///
  /// In ka, this message translates to:
  /// **'ბურთი შენთანაა. რომელია საუკეთესო სვლა?'**
  String get spQuestion;

  /// No description provided for @spPassTo.
  ///
  /// In ka, this message translates to:
  /// **'პასი №{n}-ს'**
  String spPassTo(String n);

  /// No description provided for @spPassBack.
  ///
  /// In ka, this message translates to:
  /// **'უკან პასი №{n}-ს'**
  String spPassBack(String n);

  /// No description provided for @spDribble.
  ///
  /// In ka, this message translates to:
  /// **'წინ გავარბენინო'**
  String get spDribble;

  /// No description provided for @spShoot.
  ///
  /// In ka, this message translates to:
  /// **'დარტყმა კარში'**
  String get spShoot;

  /// No description provided for @spHold.
  ///
  /// In ka, this message translates to:
  /// **'ბურთის შეკავება'**
  String get spHold;

  /// No description provided for @spNext.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგი'**
  String get spNext;

  /// No description provided for @spExplain1.
  ///
  /// In ka, this message translates to:
  /// **'№7 თავისუფალია ფლანგზე — მცველი შენ წინაა, ამიტომ გარბენა სარისკოა.'**
  String get spExplain1;

  /// No description provided for @spExplain2.
  ///
  /// In ka, this message translates to:
  /// **'კართან ახლოს ხარ და გზა თავისუფალია — დაარტყი!'**
  String get spExplain2;

  /// No description provided for @spExplain3.
  ///
  /// In ka, this message translates to:
  /// **'ორი მეტოქე გიტევს — უსაფრთხო პასი უკან №4-ს ბურთს შეინარჩუნებს.'**
  String get spExplain3;

  /// No description provided for @spExplain4.
  ///
  /// In ka, this message translates to:
  /// **'№10 მეურვეობის ქვეშაა, №11 კი თავისუფალ სივრცეშია.'**
  String get spExplain4;

  /// No description provided for @spExplain5.
  ///
  /// In ka, this message translates to:
  /// **'№9-მდე პასს მცველი გადაჭრის; №10 თავისუფალია და შეუძლია შემობრუნება.'**
  String get spExplain5;

  /// No description provided for @spExplain6.
  ///
  /// In ka, this message translates to:
  /// **'მარცხნივ მეტოქე №5-ს ფარავს — პასი მარჯვნივ №6-ს უსაფრთხოა.'**
  String get spExplain6;

  /// No description provided for @spExplain7.
  ///
  /// In ka, this message translates to:
  /// **'ცენტრი ჩაკეტილია ორი მცველით; №7 ფლანგზე თავისუფალია.'**
  String get spExplain7;

  /// No description provided for @spExplain8.
  ///
  /// In ka, this message translates to:
  /// **'კუთხე ძალიან ვიწროა დასარტყმელად და №9 დაფარულია; №10 უკეთეს პოზიციაშია.'**
  String get spExplain8;

  /// No description provided for @spExplain9.
  ///
  /// In ka, this message translates to:
  /// **'სამი მეტოქე ცენტრშია — მოედნის გაშლა №2-ზე სივრცეს ქმნის.'**
  String get spExplain9;

  /// No description provided for @mazeGoal.
  ///
  /// In ka, this message translates to:
  /// **'კარი'**
  String get mazeGoal;

  /// No description provided for @mazeUp.
  ///
  /// In ka, this message translates to:
  /// **'ზემოთ'**
  String get mazeUp;

  /// No description provided for @mazeDown.
  ///
  /// In ka, this message translates to:
  /// **'ქვემოთ'**
  String get mazeDown;

  /// No description provided for @mazeLeft.
  ///
  /// In ka, this message translates to:
  /// **'მარცხნივ'**
  String get mazeLeft;

  /// No description provided for @mazeRight.
  ///
  /// In ka, this message translates to:
  /// **'მარჯვნივ'**
  String get mazeRight;

  /// No description provided for @brainProgressTitle.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი პროგრესი'**
  String get brainProgressTitle;

  /// No description provided for @brainPlays.
  ///
  /// In ka, this message translates to:
  /// **'{n} თამაში'**
  String brainPlays(int n);

  /// No description provided for @brainNoPlays.
  ///
  /// In ka, this message translates to:
  /// **'ჯერ არ გითამაშია'**
  String get brainNoPlays;

  /// No description provided for @brainRecentScores.
  ///
  /// In ka, this message translates to:
  /// **'ბოლო ქულები'**
  String get brainRecentScores;

  /// No description provided for @brainBadges.
  ///
  /// In ka, this message translates to:
  /// **'ნიშნები'**
  String get brainBadges;

  /// No description provided for @brainUnlocked.
  ///
  /// In ka, this message translates to:
  /// **'გახსნილი: {level}'**
  String brainUnlocked(String level);

  /// No description provided for @badgeFirstGame.
  ///
  /// In ka, this message translates to:
  /// **'პირველი თამაში'**
  String get badgeFirstGame;

  /// No description provided for @badgeExplorer.
  ///
  /// In ka, this message translates to:
  /// **'ყველა თამაშის მკვლევარი'**
  String get badgeExplorer;

  /// No description provided for @badgeTenCompleted.
  ///
  /// In ka, this message translates to:
  /// **'10 დასრულებული თამაში'**
  String get badgeTenCompleted;

  /// No description provided for @badgeMemoryHard.
  ///
  /// In ka, this message translates to:
  /// **'მეხსიერების ჩემპიონი'**
  String get badgeMemoryHard;

  /// No description provided for @badgePerfectLogic.
  ///
  /// In ka, this message translates to:
  /// **'უშეცდომო ლოგიკა'**
  String get badgePerfectLogic;

  /// No description provided for @badgeTactician.
  ///
  /// In ka, this message translates to:
  /// **'ტაქტიკოსი'**
  String get badgeTactician;

  /// No description provided for @badgeQuickReflexes.
  ///
  /// In ka, this message translates to:
  /// **'ელვისებური რეაქცია'**
  String get badgeQuickReflexes;

  /// No description provided for @badgeSequenceSeven.
  ///
  /// In ka, this message translates to:
  /// **'7-იანი თანმიმდევრობა'**
  String get badgeSequenceSeven;

  /// No description provided for @badgeMazeHard.
  ///
  /// In ka, this message translates to:
  /// **'ლაბირინთის ოსტატი'**
  String get badgeMazeHard;

  /// No description provided for @coachChallengesTitle.
  ///
  /// In ka, this message translates to:
  /// **'ტვინის აკადემიის გამოწვევები'**
  String get coachChallengesTitle;

  /// No description provided for @challengeAssign.
  ///
  /// In ka, this message translates to:
  /// **'გამოწვევის მიცემა'**
  String get challengeAssign;

  /// No description provided for @challengeGame.
  ///
  /// In ka, this message translates to:
  /// **'თამაში'**
  String get challengeGame;

  /// No description provided for @challengeDifficulty.
  ///
  /// In ka, this message translates to:
  /// **'სირთულე'**
  String get challengeDifficulty;

  /// No description provided for @challengeDueDate.
  ///
  /// In ka, this message translates to:
  /// **'ვადა (არასავალდებულო)'**
  String get challengeDueDate;

  /// No description provided for @challengeNoDue.
  ///
  /// In ka, this message translates to:
  /// **'ვადის გარეშე'**
  String get challengeNoDue;

  /// No description provided for @challengeAssigned.
  ///
  /// In ka, this message translates to:
  /// **'გამოწვევა მიცემულია'**
  String get challengeAssigned;

  /// No description provided for @challengeRemove.
  ///
  /// In ka, this message translates to:
  /// **'წაშლა'**
  String get challengeRemove;

  /// No description provided for @challengeCompletion.
  ///
  /// In ka, this message translates to:
  /// **'შეასრულა: {done}/{total}'**
  String challengeCompletion(int done, int total);

  /// No description provided for @challengeEmpty.
  ///
  /// In ka, this message translates to:
  /// **'გამოწვევები ჯერ არ არის'**
  String get challengeEmpty;

  /// No description provided for @challengeOpenAction.
  ///
  /// In ka, this message translates to:
  /// **'თამაში'**
  String get challengeOpenAction;

  /// No description provided for @validationDueInPast.
  ///
  /// In ka, this message translates to:
  /// **'ვადა წარსულში ვერ იქნება.'**
  String get validationDueInPast;

  /// No description provided for @brainParentNote.
  ///
  /// In ka, this message translates to:
  /// **'ქულები სავარჯიშოა და არა ინტელექტის შეფასება.'**
  String get brainParentNote;

  /// No description provided for @brainSettingsTitle.
  ///
  /// In ka, this message translates to:
  /// **'თამაშის პარამეტრები'**
  String get brainSettingsTitle;

  /// No description provided for @settingsHaptics.
  ///
  /// In ka, this message translates to:
  /// **'ვიბრაცია'**
  String get settingsHaptics;

  /// No description provided for @fbWrongTitle.
  ///
  /// In ka, this message translates to:
  /// **'არასწორია'**
  String get fbWrongTitle;

  /// No description provided for @hudScore.
  ///
  /// In ka, this message translates to:
  /// **'ქულა'**
  String get hudScore;

  /// No description provided for @hudTime.
  ///
  /// In ka, this message translates to:
  /// **'დრო'**
  String get hudTime;

  /// No description provided for @hudStreak.
  ///
  /// In ka, this message translates to:
  /// **'სერია ×{n}'**
  String hudStreak(int n);

  /// No description provided for @hudProgress.
  ///
  /// In ka, this message translates to:
  /// **'{done}/{total}'**
  String hudProgress(int done, int total);

  /// No description provided for @resultLevelComplete.
  ///
  /// In ka, this message translates to:
  /// **'დონე გავლილია!'**
  String get resultLevelComplete;

  /// No description provided for @resultNewHighScore.
  ///
  /// In ka, this message translates to:
  /// **'ახალი რეკორდი!'**
  String get resultNewHighScore;

  /// No description provided for @resultNextUnlocked.
  ///
  /// In ka, this message translates to:
  /// **'გაიხსნა დონე {level}'**
  String resultNextUnlocked(int level);

  /// No description provided for @resultChallengeDone.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის გამოწვევა შესრულდა!'**
  String get resultChallengeDone;

  /// No description provided for @resultBackToAcademy.
  ///
  /// In ka, this message translates to:
  /// **'ტვინის აკადემიაში დაბრუნება'**
  String get resultBackToAcademy;

  /// No description provided for @resultTryEasier.
  ///
  /// In ka, this message translates to:
  /// **'სცადე უფრო მარტივი'**
  String get resultTryEasier;

  /// No description provided for @resultFailTitle.
  ///
  /// In ka, this message translates to:
  /// **'ცოტაც და გამოგივა!'**
  String get resultFailTitle;

  /// No description provided for @resultFailEncourage.
  ///
  /// In ka, this message translates to:
  /// **'ყოველი ცდა გონებას აძლიერებს. კიდევ სცადე?'**
  String get resultFailEncourage;

  /// No description provided for @resultStars.
  ///
  /// In ka, this message translates to:
  /// **'{n} ვარსკვლავი 3-დან'**
  String resultStars(int n);

  /// No description provided for @resultRetry.
  ///
  /// In ka, this message translates to:
  /// **'თავიდან ცდა'**
  String get resultRetry;

  /// No description provided for @failOutOfLives.
  ///
  /// In ka, this message translates to:
  /// **'სიცოცხლეები ამოგეწურა.'**
  String get failOutOfLives;

  /// No description provided for @failLowAccuracy.
  ///
  /// In ka, this message translates to:
  /// **'სწორი იყო პასუხების ნახევარზე ნაკლები.'**
  String get failLowAccuracy;

  /// No description provided for @failTooSlow.
  ///
  /// In ka, this message translates to:
  /// **'რამდენიმე რაუნდში დრო ამოიწურა.'**
  String get failTooSlow;

  /// No description provided for @objMemory.
  ///
  /// In ka, this message translates to:
  /// **'მიზანი: იპოვე ყველა წყვილი.'**
  String get objMemory;

  /// No description provided for @objLogic.
  ///
  /// In ka, this message translates to:
  /// **'მიზანი: ამოხსენი 8 თავსატეხი.'**
  String get objLogic;

  /// No description provided for @objSmart.
  ///
  /// In ka, this message translates to:
  /// **'მიზანი: აირჩიე სწორი სვლა მატჩის სიტუაციებში.'**
  String get objSmart;

  /// No description provided for @objQuick.
  ///
  /// In ka, this message translates to:
  /// **'მიზანი: 12 რაუნდში სწრაფად იპოვე სამიზნე.'**
  String get objQuick;

  /// No description provided for @objSequence.
  ///
  /// In ka, this message translates to:
  /// **'მიზანი: გაიმეორე 5 თანმიმდევრობა.'**
  String get objSequence;

  /// No description provided for @objPath.
  ///
  /// In ka, this message translates to:
  /// **'მიზანი: მიიყვანე ბურთი კარამდე.'**
  String get objPath;

  /// No description provided for @diffEasyHint.
  ///
  /// In ka, this message translates to:
  /// **'მშვიდი ტემპი'**
  String get diffEasyHint;

  /// No description provided for @diffMediumHint.
  ///
  /// In ka, this message translates to:
  /// **'ცოტა უფრო რთული'**
  String get diffMediumHint;

  /// No description provided for @diffHardHint.
  ///
  /// In ka, this message translates to:
  /// **'ჩემპიონებისთვის'**
  String get diffHardHint;

  /// No description provided for @levelsUnlocked.
  ///
  /// In ka, this message translates to:
  /// **'გახსნილია {level} დონემდე'**
  String levelsUnlocked(int level);

  /// No description provided for @logicWhyRepeat.
  ///
  /// In ka, this message translates to:
  /// **'რიგი ყოველ {n} ფიგურაში მეორდება.'**
  String logicWhyRepeat(int n);

  /// No description provided for @logicWhyGrow.
  ///
  /// In ka, this message translates to:
  /// **'ყოველ ნაბიჯზე იგივე ფიგურა მატულობს.'**
  String get logicWhyGrow;

  /// No description provided for @logicWhyMissing.
  ///
  /// In ka, this message translates to:
  /// **'შეხედე ფიგურებს „?“-მდე და მის შემდეგ — რიგი მეორდება.'**
  String get logicWhyMissing;

  /// No description provided for @logicCorrectWas.
  ///
  /// In ka, this message translates to:
  /// **'სწორი პასუხი მწვანედაა მონიშნული.'**
  String get logicCorrectWas;

  /// No description provided for @gameNext.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგი'**
  String get gameNext;

  /// No description provided for @spCoachSays.
  ///
  /// In ka, this message translates to:
  /// **'მწვრთნელის რჩევა'**
  String get spCoachSays;

  /// No description provided for @spYourChoice.
  ///
  /// In ka, this message translates to:
  /// **'შენი არჩევანი'**
  String get spYourChoice;

  /// No description provided for @spBestChoice.
  ///
  /// In ka, this message translates to:
  /// **'საუკეთესო არჩევანი'**
  String get spBestChoice;

  /// No description provided for @quickTooSlow.
  ///
  /// In ka, this message translates to:
  /// **'ძალიან ნელა!'**
  String get quickTooSlow;

  /// No description provided for @quickHurry.
  ///
  /// In ka, this message translates to:
  /// **'იჩქარე!'**
  String get quickHurry;

  /// No description provided for @quickReaction.
  ///
  /// In ka, this message translates to:
  /// **'რეაქცია: {time} წმ'**
  String quickReaction(String time);

  /// No description provided for @seqRepeatHint.
  ///
  /// In ka, this message translates to:
  /// **'ახლა შეეხე იმავე რიგით'**
  String get seqRepeatHint;

  /// No description provided for @seqRoundDone.
  ///
  /// In ka, this message translates to:
  /// **'თანმიმდევრობა სწორია!'**
  String get seqRoundDone;

  /// No description provided for @seqMistake.
  ///
  /// In ka, this message translates to:
  /// **'უი! კიდევ ერთხელ დააკვირდი.'**
  String get seqMistake;

  /// No description provided for @mazeBlocked.
  ///
  /// In ka, this message translates to:
  /// **'გზა ჩაკეტილია!'**
  String get mazeBlocked;

  /// No description provided for @mazeStart.
  ///
  /// In ka, this message translates to:
  /// **'სტარტი'**
  String get mazeStart;

  /// No description provided for @memoryPair.
  ///
  /// In ka, this message translates to:
  /// **'წყვილია!'**
  String get memoryPair;

  /// No description provided for @memoryNoPair.
  ///
  /// In ka, this message translates to:
  /// **'წყვილი არ არის'**
  String get memoryNoPair;

  /// No description provided for @comboLabel.
  ///
  /// In ka, this message translates to:
  /// **'კომბო ×{n}!'**
  String comboLabel(int n);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ka', 'ru'].contains(locale.languageCode);

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
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
