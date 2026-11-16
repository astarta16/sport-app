// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Gundi';

  @override
  String get appTagline => 'Спорт вашего ребёнка — в одном месте';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get close => 'Закрыть';

  @override
  String get retry => 'Повторить';

  @override
  String get next => 'Далее';

  @override
  String get done => 'Готово';

  @override
  String get edit => 'Изменить';

  @override
  String get seeAll => 'Все';

  @override
  String get today => 'Сегодня';

  @override
  String get optional => 'Необязательно';

  @override
  String get demoBadge => 'ДЕМО';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get errorPermission => 'У вас нет доступа к этому действию.';

  @override
  String get errorNetwork => 'Нет соединения. Проверьте подключение к интернету.';

  @override
  String get errorNotFound => 'Не найдено.';

  @override
  String get errorInvalidCode => 'Неверный код.';

  @override
  String get errorNotSignedIn => 'Пожалуйста, войдите в аккаунт.';

  @override
  String get errorTitle => 'Не удалось загрузить';

  @override
  String get validationRequired => 'Обязательное поле';

  @override
  String get validationInvalidPhone => 'Введите корректный номер мобильного (5XX XXX XXX)';

  @override
  String get validationInvalidOtp => 'Код должен состоять из 6 цифр';

  @override
  String get validationTooShort => 'Слишком коротко';

  @override
  String get validationTooLong => 'Слишком длинно';

  @override
  String get validationInvalidName => 'Используйте только буквы';

  @override
  String get validationDateInFuture => 'Дата не может быть в будущем';

  @override
  String get validationTooOldForChild => 'Ребёнку должно быть меньше 18 лет';

  @override
  String get validationTooYoung => 'Минимальный возраст — 3 года';

  @override
  String get validationSportRequired => 'Выберите хотя бы один вид спорта';

  @override
  String get validationClubRequired => 'Выберите клуб';

  @override
  String get validationConsentRequired => 'Чтобы продолжить, нужно согласие';

  @override
  String get validationVenueRequired => 'Выберите место';

  @override
  String get validationDurationRange => 'Длительность — от 15 до 300 минут';

  @override
  String get validationFocusRequired => 'Выберите хотя бы одно направление';

  @override
  String get validationDescriptionTooLong => 'Описание слишком длинное';

  @override
  String get validationStartInPast => 'Это время уже прошло';

  @override
  String get validationPhotoConsentRequired => 'Подтвердите условие о согласии на фото';

  @override
  String get validationFileType => 'Допустимы только JPG, PNG или PDF';

  @override
  String get validationFileTooLarge => 'Файл больше 10 МБ';

  @override
  String get validationFileEmpty => 'Выберите файл';

  @override
  String get validationDatesOrder => 'Срок действия должен заканчиваться после даты выдачи';

  @override
  String get validationIssuedInFuture => 'Дата выдачи в будущем';

  @override
  String get validationEmptyMessage => 'Сообщение пустое';

  @override
  String get validationMessageTooLong => 'Сообщение слишком длинное';

  @override
  String get validationAmountPositive => 'Сумма должна быть больше 0';

  @override
  String get validationDayOfMonth => 'День — от 1 до 28';

  @override
  String get validationAlreadyMember => 'Ребёнок уже в этой группе';

  @override
  String get validationRequestExists => 'Заявка уже отправлена и ждёт ответа';

  @override
  String get onboardingTitle1 => 'Все тренировки в одном календаре';

  @override
  String get onboardingBody1 => 'Время, место и тренер — всегда под рукой. Об изменениях вы узнаете сразу.';

  @override
  String get onboardingTitle2 => 'Прямая связь с тренером';

  @override
  String get onboardingBody2 => 'Групповой чат родителей и тренеров, фото с каждой тренировки.';

  @override
  String get onboardingTitle3 => 'Справки и оплата — под защитой';

  @override
  String get onboardingBody3 => 'Медицинские справки в закрытом хранилище, напоминания о сроках действия и оплате.';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get phoneTitle => 'Вход по номеру телефона';

  @override
  String get phoneSubtitle => 'Мы отправим одноразовый код по SMS. Пароль не нужен.';

  @override
  String get phoneLabel => 'Номер мобильного';

  @override
  String get sendCode => 'Получить код';

  @override
  String get otpTitle => 'Введите код';

  @override
  String otpSubtitle(String phone) {
    return 'Мы отправили 6-значный код на номер $phone';
  }

  @override
  String get verify => 'Подтвердить';

  @override
  String get resendCode => 'Отправить код ещё раз';

  @override
  String resendIn(int seconds) {
    return 'Повторно через $seconds с';
  }

  @override
  String get demoOtpHint => 'Демо-режим: введите 123456';

  @override
  String get demoAccountsTitle => 'Быстрый вход в демо';

  @override
  String get demoAccountsSubtitle => 'Вымышленные данные — без реальных SMS, платежей и медицинской информации.';

  @override
  String get demoPendingCoach => 'Тренер (ожидает одобрения)';

  @override
  String get guestBrowse => 'Смотреть клубы без входа';

  @override
  String get termsNote => 'Продолжая, вы принимаете Условия использования и Политику конфиденциальности.';

  @override
  String get registerTitle => 'Создайте профиль';

  @override
  String get chooseRole => 'Кто вы?';

  @override
  String get roleParent => 'Родитель';

  @override
  String get roleParentDesc => 'Тренировки детей, чат с тренером, справки и оплата';

  @override
  String get roleCoach => 'Тренер';

  @override
  String get roleCoachDesc => 'Управление группами и планирование тренировок. Нужно одобрение клуба.';

  @override
  String get roleChild => 'Ребёнок';

  @override
  String get roleChildDesc => 'Профили детей до 14 лет создают родители. Аккаунты для 14–17 лет скоро появятся.';

  @override
  String get soon => 'Скоро';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get sportsLabel => 'Виды спорта';

  @override
  String get clubsLabel => 'Клуб';

  @override
  String get consentData => 'Даю согласие на обработку моих персональных данных';

  @override
  String get consentDataDetails =>
      'Мы обрабатываем ваше имя, телефон и данные о тренировках ребёнка только для работы сервиса. Вы можете удалить аккаунт в любой момент.';

  @override
  String get consentSms => 'Даю согласие на SMS-напоминания об оплате';

  @override
  String get finishRegistration => 'Завершить';

  @override
  String stepOf(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get coachPendingTitle => 'Ваш аккаунт на проверке';

  @override
  String get coachPendingBody =>
      'Администратор клуба проверяет каждого тренера. До этого данные детей скрыты — так мы их защищаем.';

  @override
  String get coachPendingDemoApprove => 'Демо: одобрить как администратор';

  @override
  String get coachRejectedTitle => 'Заявка отклонена';

  @override
  String get coachRejectedBody => 'Пожалуйста, свяжитесь с администрацией клуба.';

  @override
  String get childAccountUnsupported => 'Собственные аккаунты для детей пока недоступны. Используйте аккаунт родителя.';

  @override
  String get signOut => 'Выйти';

  @override
  String get navHome => 'Главная';

  @override
  String get navCalendar => 'Календарь';

  @override
  String get navChat => 'Чат';

  @override
  String get navMap => 'Карта';

  @override
  String get navProfile => 'Профиль';

  @override
  String greetingMorning(String name) {
    return 'Доброе утро, $name';
  }

  @override
  String greetingDay(String name) {
    return 'Здравствуйте, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Добрый вечер, $name';
  }

  @override
  String get nextTraining => 'Следующая тренировка';

  @override
  String get noUpcomingTrainings => 'Предстоящих тренировок пока нет';

  @override
  String get directions => 'Маршрут';

  @override
  String get details => 'Подробнее';

  @override
  String get coachLabel => 'Тренер';

  @override
  String get venueLabel => 'Место';

  @override
  String get medicalStatus => 'Медицинская справка';

  @override
  String get coachMessages => 'Сообщения от тренера';

  @override
  String get recentPhotos => 'Фото с тренировок';

  @override
  String get paymentSummary => 'Оплата';

  @override
  String get noChildrenTitle => 'Добавьте первого ребёнка';

  @override
  String get noChildrenBody => 'Создайте профиль и выберите вид спорта — остальное мы возьмём на себя.';

  @override
  String get addChild => 'Добавить ребёнка';

  @override
  String noGroupTitle(String name) {
    return '$name пока не в группе';
  }

  @override
  String get noGroupBody => 'Найдите клуб на карте и отправьте заявку на вступление.';

  @override
  String get findClub => 'Найти клуб';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Через $count дня',
      many: 'Через $count дней',
      few: 'Через $count дня',
      one: 'Через $count день',
      zero: 'Сегодня',
    );
    return '$_temp0';
  }

  @override
  String startsInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Через $count часа',
      many: 'Через $count часов',
      few: 'Через $count часа',
      one: 'Через $count час',
      zero: 'Скоро начнётся',
    );
    return '$_temp0';
  }

  @override
  String get noMessages => 'Сообщений пока нет';

  @override
  String get noPhotos => 'Фото появятся после тренировок';

  @override
  String get allPaid => 'Всё оплачено';

  @override
  String yearsOld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count года',
      many: '$count лет',
      few: '$count года',
      one: '$count год',
    );
    return '$_temp0';
  }

  @override
  String get openChat => 'Открыть чат';

  @override
  String get statusScheduled => 'Запланирована';

  @override
  String get statusCancelled => 'Отменена';

  @override
  String get statusMoved => 'Перенесена';

  @override
  String get statusDone => 'Проведена';

  @override
  String get focusTechnique => 'Техника';

  @override
  String get focusSpeed => 'Скорость';

  @override
  String get focusPhysical => 'Физподготовка';

  @override
  String get focusBall => 'Работа с мячом';

  @override
  String durationMinutes(int count) {
    return '$count мин';
  }

  @override
  String get trainingTitle => 'Тренировка';

  @override
  String get trainingDescription => 'Описание';

  @override
  String get trainingFocus => 'Направление';

  @override
  String get trainingPhotos => 'Фото';

  @override
  String movedFrom(String date) {
    return 'Перенесена с $date';
  }

  @override
  String get cancelledBanner => 'Эта тренировка отменена';

  @override
  String get newTraining => 'Новая тренировка';

  @override
  String get editTraining => 'Изменить тренировку';

  @override
  String get cancelTraining => 'Отменить тренировку';

  @override
  String get cancelTrainingConfirm => 'Отменить эту тренировку? Родители группы получат уведомление.';

  @override
  String get keepTraining => 'Нет, оставить';

  @override
  String get rescheduleTraining => 'Перенести';

  @override
  String get markDone => 'Отметить проведённой';

  @override
  String get addPhotos => 'Добавить фото';

  @override
  String get dateLabel => 'Дата';

  @override
  String get timeLabel => 'Время начала';

  @override
  String get durationLabel => 'Длительность';

  @override
  String get trainingSaved => 'Тренировка сохранена, родители уведомлены';

  @override
  String get trainingCancelled => 'Тренировка отменена';

  @override
  String get trainingRescheduled => 'Тренировка перенесена';

  @override
  String get trainingMarkedDone => 'Отмечена как проведённая';

  @override
  String get photoConsentTitle => 'Согласие на фото';

  @override
  String photoConsentMissing(String names) {
    return 'Нет согласия: $names. Эти дети не должны попадать на фото.';
  }

  @override
  String get photoConsentAllGiven => 'У всех детей группы есть согласие родителей на фото.';

  @override
  String get photoConsentConfirm => 'Подтверждаю, что на фото нет детей без согласия';

  @override
  String get selectVenue => 'Выберите место';

  @override
  String get descriptionHint => 'Что будете отрабатывать? Например, передачи, удары…';

  @override
  String get groupLabel => 'Группа';

  @override
  String get photosAdded => 'Фото добавлены';

  @override
  String get customDuration => 'Другое';

  @override
  String get saveTraining => 'Сохранить тренировку';

  @override
  String trainingFromTo(String start, String end) {
    return '$start – $end';
  }

  @override
  String get trainingHistory => 'История тренировок';

  @override
  String get upcoming => 'Предстоящие тренировки';

  @override
  String get noTrainingsDay => 'В этот день тренировок нет';

  @override
  String get allChildren => 'Все дети';

  @override
  String get coachHomeSubtitle => 'Сегодня в ваших группах';

  @override
  String groupMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ребёнка',
      many: '$count детей',
      few: '$count ребёнка',
      one: '$count ребёнок',
    );
    return '$_temp0';
  }

  @override
  String get roster => 'Состав группы';

  @override
  String get noGroupsCoach => 'Вам пока не назначены группы. Обратитесь к администратору клуба.';

  @override
  String get membershipRequests => 'Заявки на вступление';

  @override
  String get approve => 'Одобрить';

  @override
  String get reject => 'Отклонить';

  @override
  String get requestApproved => 'Ребёнок добавлен в группу';

  @override
  String get requestRejected => 'Заявка отклонена';

  @override
  String get removeFromGroup => 'Исключить из группы';

  @override
  String removeFromGroupConfirm(String name) {
    return 'Исключить $name из группы? Ваш доступ к данным и справкам ребёнка автоматически прекратится.';
  }

  @override
  String get parentsLabel => 'Родители';

  @override
  String get call => 'Позвонить';

  @override
  String get viewCertificate => 'Открыть справку';

  @override
  String ageRange(int min, int max) {
    return '$min–$max лет';
  }

  @override
  String get statMembers => 'Участники';

  @override
  String get statThisWeek => 'На этой неделе';

  @override
  String get statCertAlerts => 'Справки: внимание';

  @override
  String wantsToJoin(String child, String group) {
    return '$child хочет вступить в группу $group';
  }

  @override
  String get todayTrainings => 'Сегодня и далее';

  @override
  String get selectGroupTitle => 'Выберите группу';

  @override
  String get chatEmpty => 'Начните общение с группой';

  @override
  String get typeMessage => 'Сообщение…';

  @override
  String get chatGroups => 'Чаты групп';

  @override
  String get chatNotAllowed => 'Чат доступен только родителям и тренерам.';

  @override
  String get chatPrivacyNote => 'Здесь только тренеры и родители группы. Номера телефонов скрыты от других родителей.';

  @override
  String get noChats => 'Чаты появятся, когда ребёнок вступит в группу';

  @override
  String get photoAttachment => 'Фото';

  @override
  String get searchPlaces => 'Поиск по названию или адресу';

  @override
  String get allSports => 'Все';

  @override
  String get venueStadium => 'Стадион';

  @override
  String get venueHall => 'Спортзал';

  @override
  String get venueField => 'Поле';

  @override
  String get venuePool => 'Бассейн';

  @override
  String get clubLabel => 'Клуб';

  @override
  String get groupsLabel => 'Группы';

  @override
  String get requestMembership => 'Подать заявку';

  @override
  String get requestSent => 'Заявка отправлена тренеру';

  @override
  String get selectChild => 'Выберите ребёнка';

  @override
  String get openInMaps => 'Открыть в картах';

  @override
  String get mapNoResults => 'По этому фильтру мест нет';

  @override
  String distanceKm(String km) {
    return '$km км';
  }

  @override
  String get clubDetails => 'Страница клуба';

  @override
  String get noGroupsInClub => 'В этом клубе пока нет групп';

  @override
  String get signInToJoin => 'Войдите, чтобы подать заявку';

  @override
  String get mapAttribution => '© OpenStreetMap';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count места',
      many: '$count мест',
      few: '$count места',
      one: '$count место',
    );
    return '$_temp0';
  }

  @override
  String get certificatesTitle => 'Медицинские справки';

  @override
  String get certValid => 'Действует';

  @override
  String get certExpiring => 'Истекает';

  @override
  String get certExpired => 'Истекла';

  @override
  String get certMissing => 'Нет справки';

  @override
  String validUntil(String date) {
    return 'Действует до $date';
  }

  @override
  String issuedOn(String date) {
    return 'Выдана $date';
  }

  @override
  String get uploadCertificate => 'Загрузить справку';

  @override
  String get certConsentTitle => 'Перед загрузкой';

  @override
  String get certConsentWhat => 'Что обрабатывается';

  @override
  String get certConsentWhatBody =>
      'Файл справки, дата выдачи и срок действия. Данные о здоровье относятся к особой категории и защищены законом.';

  @override
  String get certConsentWho => 'У кого есть доступ';

  @override
  String get certConsentWhoBody =>
      'У вас и у тренеров групп, в которых сейчас занимается ребёнок. Тренеры видят статус; открытие файла — отдельное действие, которое фиксируется в журнале.';

  @override
  String get certConsentDelete => 'Как удалить';

  @override
  String get certConsentDeleteBody =>
      'Справку можно удалить в любой момент. При удалении аккаунта удаляются все справки. После выхода из группы тренер теряет доступ.';

  @override
  String get certConsentAgree => 'Даю согласие на обработку справки, как описано выше';

  @override
  String get takePhoto => 'Камера';

  @override
  String get fromGallery => 'Галерея';

  @override
  String get pickDocument => 'Файл (PDF)';

  @override
  String get issueDate => 'Дата выдачи';

  @override
  String get expiryDate => 'Действует до';

  @override
  String get fileRequirements => 'JPG, PNG или PDF · до 10 МБ';

  @override
  String get certUploaded => 'Справка загружена';

  @override
  String get deleteCertificate => 'Удалить справку';

  @override
  String get deleteCertificateConfirm => 'Удалить эту справку? Файл будет безвозвратно удалён из хранилища.';

  @override
  String get certDeleted => 'Справка удалена';

  @override
  String get openFile => 'Открыть файл';

  @override
  String accessExpiresIn(int minutes) {
    return 'Временный доступ · истекает через $minutes мин';
  }

  @override
  String get accessExpired => 'Доступ истёк. Откройте файл снова.';

  @override
  String get demoDocument => 'Демо-документ';

  @override
  String get demoDocumentBody =>
      'В демо-режиме реальные медицинские файлы не хранятся. В рабочей версии файл открывается по подписанной ссылке, действующей 5 минут.';

  @override
  String get accessLog => 'Журнал доступа';

  @override
  String accessLogOpen(String name) {
    return '$name — открытие';
  }

  @override
  String accessLogDenied(String name) {
    return '$name — отказ в доступе';
  }

  @override
  String accessLogDelete(String name) {
    return '$name — удаление';
  }

  @override
  String get noCertificates => 'Справка ещё не загружена';

  @override
  String certExpiresIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Истекает через $count дня',
      many: 'Истекает через $count дней',
      few: 'Истекает через $count дня',
      one: 'Истекает через $count день',
      zero: 'Истекает сегодня',
    );
    return '$_temp0';
  }

  @override
  String certExpiredAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Истекла $count дня назад',
      many: 'Истекла $count дней назад',
      few: 'Истекла $count дня назад',
      one: 'Истекла $count день назад',
    );
    return '$_temp0';
  }

  @override
  String get certRemindersNote => 'Мы напомним за 14 и за 3 дня до окончания срока, а также в последний день.';

  @override
  String fileSelected(String name) {
    return 'Выбрано: $name';
  }

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsEmpty => 'Новых уведомлений нет';

  @override
  String get markAllRead => 'Прочитать все';

  @override
  String get notifNewTraining => 'Новая тренировка';

  @override
  String get notifTrainingChanged => 'Тренировка изменена';

  @override
  String get notifTrainingReminder => 'Тренировка через 2 часа';

  @override
  String get notifChatMessage => 'Новое сообщение';

  @override
  String get notifCertificateExpiry => 'Справка истекает';

  @override
  String get notifNewPhotos => 'Новые фото';

  @override
  String get notifPaymentReminder => 'Напоминание об оплате';

  @override
  String get notifPaymentSms => 'SMS-напоминания об оплате';

  @override
  String notifBodyGroup(String group) {
    return 'Группа: $group';
  }

  @override
  String notifBodyChat(String sender, String group) {
    return '$sender · $group';
  }

  @override
  String notifBodyCert(String child, String days) {
    return '$child — осталось дней: $days';
  }

  @override
  String notifBodyPayment(String child, String amount) {
    return '$child — $amount ₾';
  }

  @override
  String get notificationSettings => 'Настройки уведомлений';

  @override
  String get notificationSettingsHint => 'Выберите, какие уведомления получать.';

  @override
  String get pushDemoNote => 'В демо-режиме push-уведомления не отправляются — они показываются в приложении.';

  @override
  String get paymentsTitle => 'Платежи';

  @override
  String get paymentPending => 'Ожидает оплаты';

  @override
  String get paymentPaid => 'Оплачен';

  @override
  String get paymentCancelled => 'Отменён';

  @override
  String get paymentOverdue => 'Просрочен';

  @override
  String get totalDue => 'Итого к оплате';

  @override
  String dueOn(String date) {
    return 'Оплатить до $date';
  }

  @override
  String paidOn(String date) {
    return 'Оплачен $date';
  }

  @override
  String get markPaid => 'Отметить оплату';

  @override
  String get markPending => 'Снять отметку';

  @override
  String get cancelPayment => 'Отменить';

  @override
  String get chargeGroup => 'Разовый платёж';

  @override
  String get chargeGroupHint => 'Платёж будет создан для каждого ребёнка в группе.';

  @override
  String get recurringPlans => 'Ежемесячная оплата';

  @override
  String get createPlan => 'Создать план';

  @override
  String get amountLabel => 'Сумма (₾)';

  @override
  String get dayOfMonthLabel => 'День месяца';

  @override
  String everyMonthOn(String amount, int day) {
    return '$amount ₾ · ежемесячно, $day-го числа';
  }

  @override
  String get generateThisMonth => 'Создать за этот месяц';

  @override
  String generated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создано $count платежа',
      many: 'Создано $count платежей',
      few: 'Создано $count платежа',
      one: 'Создан $count платёж',
    );
    return '$_temp0';
  }

  @override
  String get runReminders => 'Отправить SMS-напоминания';

  @override
  String remindersReport(int sent, int skipped) {
    return 'Отправлено: $sent · пропущено: $skipped · повторный запуск не создаёт дублей';
  }

  @override
  String get smsLog => 'Журнал SMS';

  @override
  String get smsMockNote => 'Демо: используется тестовый SMS-провайдер. Реальные SMS не отправляются.';

  @override
  String get noPayments => 'Платежей пока нет';

  @override
  String get paymentHistory => 'История';

  @override
  String nextDue(String date) {
    return 'Следующий платёж: $date';
  }

  @override
  String get paymentUpdated => 'Статус обновлён';

  @override
  String chargeCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Создано $count платежа',
      many: 'Создано $count платежей',
      few: 'Создано $count платежа',
      one: 'Создан $count платёж',
    );
    return '$_temp0';
  }

  @override
  String get reminderSchedule => 'SMS: за 5 дней и за день до срока, в 10:00 (по Тбилиси)';

  @override
  String get myChildren => 'Мои дети';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get themeLabel => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get languageLabel => 'Язык';

  @override
  String get switchDemoAccount => 'Сменить демо-аккаунт';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirm => 'Ваш аккаунт и все справки будут удалены навсегда. Это действие нельзя отменить.';

  @override
  String get privacyTitle => 'Конфиденциальность';

  @override
  String get privacyBody => 'Данные детей видят только родители и одобренные тренеры их группы.';

  @override
  String get childProfile => 'Профиль ребёнка';

  @override
  String get birthDateLabel => 'Дата рождения';

  @override
  String get ownAccountTitle => 'Собственный аккаунт (14+)';

  @override
  String get ownAccountDisabled => 'Станет доступен после юридического утверждения правил о возрасте и согласии.';

  @override
  String get photoConsentLabel => 'Согласие на фото с тренировок';

  @override
  String get photoConsentHelp => 'Без согласия ребёнок не должен появляться на фото тренера.';

  @override
  String get removeChild => 'Удалить ребёнка';

  @override
  String removeChildConfirm(String name) {
    return 'Удалить профиль ребёнка $name? Справки тоже будут удалены.';
  }

  @override
  String get childSaved => 'Профиль сохранён';

  @override
  String get requestPending => 'Ожидает';

  @override
  String get pendingRequests => 'Отправленные заявки';

  @override
  String get roleLabel => 'Роль';

  @override
  String get approvedCoach => 'Проверенный тренер';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get modeDemo => 'Демо-режим';

  @override
  String get modeFirebase => 'Firebase';

  @override
  String groupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count группы',
      many: '$count групп',
      few: '$count группы',
      one: '$count группа',
    );
    return '$_temp0';
  }

  @override
  String get notInGroup => 'Без группы';

  @override
  String get firebaseNotConfiguredTitle => 'Firebase не настроен';

  @override
  String get firebaseNotConfiguredBody =>
      'Выполните `flutterfire configure` или запустите в демо-режиме с --dart-define=APP_MODE=demo';

  @override
  String get chatTooltip => 'Чаты';

  @override
  String get chatsTitle => 'Чаты';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get actionAdd => 'Добавить';

  @override
  String get reasonLabel => 'Причина';

  @override
  String get reasonHint => 'Кратко опишите причину';

  @override
  String get loadMore => 'Загрузить ещё';

  @override
  String get loadEarlier => 'Предыдущие сообщения';

  @override
  String get all => 'Все';

  @override
  String get share => 'Поделиться';

  @override
  String get copy => 'Копировать';

  @override
  String get copied => 'Скопировано';

  @override
  String get accept => 'Принять';

  @override
  String get decline => 'Отклонить';

  @override
  String get report => 'Пожаловаться';

  @override
  String get send => 'Отправить';

  @override
  String get search => 'Поиск';

  @override
  String get create => 'Создать';

  @override
  String get remove => 'Убрать';

  @override
  String get statusLabel => 'Статус';

  @override
  String get offlineBanner => 'Нет сети — показаны сохранённые данные. Изменения сохранить нельзя.';

  @override
  String get backOnline => 'Снова онлайн';

  @override
  String get permissionDeniedTitle => 'Доступ ограничен';

  @override
  String get permissionDeniedBody => 'У вас нет прав для просмотра этой страницы.';

  @override
  String get validationCancelReasonRequired => 'Выберите причину отмены';

  @override
  String get validationCancelReasonTooShort => 'Причина должна содержать не менее 5 символов';

  @override
  String get validationWeekdaysRequired => 'Выберите хотя бы один день недели';

  @override
  String get validationEndBeforeStart => 'Дата окончания раньше даты начала';

  @override
  String get validationSeriesTooLong => 'Расписание может действовать не более 1 года';

  @override
  String get validationSeriesOverlap => 'У этой группы уже есть расписание в эти дни и в это время';

  @override
  String get validationOpponentRequired => 'Укажите команду соперника';

  @override
  String get validationGroupNameRequired => 'Введите название группы';

  @override
  String get validationGroupAgeRange => 'Возраст 3–18, минимум ≤ максимума';

  @override
  String get validationInvalidGroupCode => 'Неверный код или группа неактивна';

  @override
  String get validationInviteExists => 'Приглашение уже отправлено и ждёт ответа';

  @override
  String get validationInviteClosed => 'Это приглашение уже закрыто';

  @override
  String get validationLinkChildRequired => 'Выберите ребёнка';

  @override
  String get validationNotMember => 'Ребёнок не состоит в этой группе';

  @override
  String get validationRsvpClosed => 'Тренировка уже началась — ответ изменить нельзя';

  @override
  String get validationTrainingCancelled => 'Тренировка отменена';

  @override
  String get validationAttendanceTooEarly => 'Посещаемость можно отмечать за час до начала';

  @override
  String get validationFeedbackEmpty => 'Оцените хотя бы одну категорию или напишите комментарий';

  @override
  String get validationFeedbackRating => 'Оценка должна быть от 1 до 5';

  @override
  String get validationMediaGroupsRequired => 'Выберите хотя бы одну группу';

  @override
  String get validationVideoTooLarge => 'Видео больше 100 МБ';

  @override
  String get validationVideoTooLong => 'Видео длиннее 60 секунд';

  @override
  String get validationAvatarTooLarge => 'Фото больше 1 МБ';

  @override
  String get validationRateLimited => 'Слишком много попыток. Попробуйте позже.';

  @override
  String get validationAlreadyReported => 'Вы уже отправили жалобу';

  @override
  String get validationReasonRequired => 'Укажите причину (не менее 5 символов)';

  @override
  String get validationLocationOutsideGeorgia => 'Это место за пределами Грузии';

  @override
  String get validationClubArchived => 'Клуб в архиве';

  @override
  String get validationMatchCancelled => 'Матч отменён';

  @override
  String get validationCannotPin => 'Системные сообщения нельзя закрепить';

  @override
  String get validationAgeRange => 'Возраст должен быть от 3 до 18 лет';

  @override
  String get validationReportClosed => 'Эта жалоба уже рассмотрена';

  @override
  String get validationCannotChangeOwnRole => 'Нельзя изменить собственную роль';

  @override
  String get validationChildNotFound => 'Ребёнок не найден';

  @override
  String get cancelReasonTitle => 'Причина отмены';

  @override
  String get cancelReasonHint => 'Причина обязательна — родители увидят её в календаре и чате.';

  @override
  String get cancelReasonIllness => 'Болезнь';

  @override
  String get cancelReasonWeather => 'Погода';

  @override
  String get cancelReasonVenueBusy => 'Место занято';

  @override
  String get cancelReasonOther => 'Другое';

  @override
  String get cancelReasonTextLabel => 'Подробности (5–300 символов)';

  @override
  String get cancelAction => 'Отменить';

  @override
  String cancelledWithReason(String reason) {
    return 'Отменена: $reason';
  }

  @override
  String get trainingCancelledSnack => 'Тренировка отменена, родители уведомлены';

  @override
  String get matchTitle => 'Матч';

  @override
  String get matchesTitle => 'Матчи';

  @override
  String get nextMatch => 'Следующий матч';

  @override
  String get newMatch => 'Новый матч';

  @override
  String get editMatch => 'Изменить матч';

  @override
  String get matchOpponent => 'Соперник';

  @override
  String matchVs(String opponent) {
    return 'против $opponent';
  }

  @override
  String get matchType => 'Тип';

  @override
  String get matchTypeFriendly => 'Товарищеский';

  @override
  String get matchTypeLeague => 'Лига';

  @override
  String get matchTypeTournament => 'Турнир';

  @override
  String get matchHomeAway => 'Дома / в гостях';

  @override
  String get matchHome => 'Дома';

  @override
  String get matchAway => 'В гостях';

  @override
  String get matchNeutral => 'Нейтральное';

  @override
  String get matchComment => 'Комментарий';

  @override
  String get matchSaved => 'Матч сохранён, родители уведомлены';

  @override
  String get matchCancelledSnack => 'Матч отменён, родители уведомлены';

  @override
  String get matchPlayed => 'Сыгран';

  @override
  String get markPlayed => 'Отметить сыгранным';

  @override
  String get cancelMatch => 'Отменить матч';

  @override
  String get matchBadge => 'Матч';

  @override
  String get noMatches => 'Матчей не запланировано';

  @override
  String get seriesTitle => 'Расписание тренировок';

  @override
  String get seriesNew => 'Регулярное расписание';

  @override
  String get seriesEdit => 'Изменить расписание';

  @override
  String get seriesWeekdays => 'Дни недели';

  @override
  String get seriesStartTime => 'Время начала';

  @override
  String get seriesStartDate => 'Дата начала';

  @override
  String get seriesEndDate => 'Дата окончания';

  @override
  String get seriesNoEnd => 'Без даты окончания';

  @override
  String seriesSummary(String days, String time) {
    return '$days · $time';
  }

  @override
  String get seriesSaved => 'Расписание сохранено — тренировки добавлены в календарь';

  @override
  String get seriesEnded => 'Расписание завершено';

  @override
  String get seriesEndAction => 'Завершить расписание';

  @override
  String get seriesEndConfirm =>
      'Последующие тренировки будут удалены. Тренировки, на которые родители уже ответили, будут отменены с указанием причины.';

  @override
  String get seriesNone => 'Регулярного расписания пока нет';

  @override
  String get seriesRecurringBadge => 'По расписанию';

  @override
  String get editScopeTitle => 'Какие тренировки изменить?';

  @override
  String get editScopeThis => 'Только эту тренировку';

  @override
  String get editScopeFuture => 'Эту и последующие';

  @override
  String get seriesHorizonNote => 'Тренировки создаются на 8 недель вперёд и продлеваются автоматически.';

  @override
  String seriesConflicts(int count) {
    return 'Пропущено дат: $count — в это время уже есть тренировка';
  }

  @override
  String get rsvpTitle => 'Придёте на тренировку?';

  @override
  String get rsvpYes => 'Приду';

  @override
  String get rsvpNo => 'Не смогу';

  @override
  String get rsvpMaybe => 'Пока не знаю';

  @override
  String get rsvpReasonHint => 'Причина (необязательно)';

  @override
  String get rsvpSaved => 'Ответ отправлен тренеру';

  @override
  String get rsvpClosedNote => 'Тренировка уже началась — ответ окончательный.';

  @override
  String get rsvpNotice => 'Ответ — это не посещаемость: фактическое присутствие отмечает тренер.';

  @override
  String get attendanceTitle => 'Посещаемость';

  @override
  String get attendancePresent => 'Был(а)';

  @override
  String get attendanceAbsent => 'Не был(а)';

  @override
  String get attendanceExcused => 'Уважительная';

  @override
  String get attendanceNotMarked => 'Не отмечен';

  @override
  String get attendanceMarkAllPresent => 'Остальные — были';

  @override
  String attendanceSummary(int present, int absent, int excused, int unmarked) {
    return 'Были: $present · не были: $absent · по уважительной: $excused · не отмечены: $unmarked';
  }

  @override
  String get attendanceRecorded => 'Посещаемость отмечена';

  @override
  String get attendanceOpen => 'Отметить посещаемость';

  @override
  String attendanceRsvpLabel(String answer) {
    return 'Ответ родителя: $answer';
  }

  @override
  String get attendanceGroupStats => 'Посещаемость группы';

  @override
  String get attendanceThisMonth => 'В этом месяце';

  @override
  String attendanceRate(int percent) {
    return '$percent%';
  }

  @override
  String get attendanceNoData => 'Посещаемость пока не отмечалась';

  @override
  String get attendanceHistory => 'История посещаемости';

  @override
  String get attendanceMonthly => 'Посещаемость по месяцам';

  @override
  String get attendanceUpcomingResponses => 'Предстоящие тренировки';

  @override
  String get responsesTitle => 'Ответы родителей';

  @override
  String responsesCount(int yes, int no, int maybe) {
    return 'Да: $yes · нет: $no · не знают: $maybe';
  }

  @override
  String get progressTitle => 'Прогресс';

  @override
  String get progressTrainings => 'Посещено тренировок';

  @override
  String get progressRate => 'Посещаемость';

  @override
  String get progressTrend => 'Динамика посещаемости';

  @override
  String get progressFeedback => 'Отзывы тренера';

  @override
  String get progressNoFeedback => 'Отзывов от тренера пока нет';

  @override
  String get progressAchievements => 'Достижения';

  @override
  String get progressPrivacyNote => 'Это видите только вы и тренеры ребёнка. Рейтинги не публикуются.';

  @override
  String get feedbackTechnique => 'Техника';

  @override
  String get feedbackDiscipline => 'Дисциплина';

  @override
  String get feedbackTeamwork => 'Командная игра';

  @override
  String get feedbackEffort => 'Старание';

  @override
  String get feedbackImprovement => 'Прогресс';

  @override
  String get feedbackAdd => 'Добавить отзыв';

  @override
  String get feedbackComment => 'Комментарий для родителя';

  @override
  String get feedbackCommentHint => 'Пишите конструктивно и с учётом возраста';

  @override
  String get feedbackSaved => 'Отзыв отправлен родителю';

  @override
  String get achFirstTraining => 'Первая тренировка';

  @override
  String achAttended(int count) {
    return 'Тренировок: $count';
  }

  @override
  String get achPerfectMonth => 'Идеальный месяц';

  @override
  String get achStreak => '3 месяца подряд';

  @override
  String get achLocked => 'Пока не получено';

  @override
  String get invitesTitle => 'Приглашения';

  @override
  String get invitesEmpty => 'Новых приглашений нет';

  @override
  String inviteFrom(String child, String group) {
    return '$child приглашён(а) в группу $group';
  }

  @override
  String get inviteLinkTitle => 'Для какого ребёнка это приглашение?';

  @override
  String get inviteLinkHint => 'Если ребёнок уже зарегистрирован, выберите его — дубликат не будет создан.';

  @override
  String inviteAsNew(String name) {
    return 'Добавить как нового ребёнка ($name)';
  }

  @override
  String get inviteMediaConsent => 'Согласен(на), что мой ребёнок может появляться на фото и видео команды';

  @override
  String get inviteAccepted => 'Ребёнок добавлен в группу';

  @override
  String get inviteDeclined => 'Приглашение отклонено';

  @override
  String inviteBanner(int count) {
    return 'Новые приглашения в группы: $count';
  }

  @override
  String get inviteStatusSent => 'Отправлено';

  @override
  String get inviteStatusAccepted => 'Принято';

  @override
  String get inviteStatusDeclined => 'Отклонено';

  @override
  String get inviteStatusRevoked => 'Отозвано';

  @override
  String get inviteRevoke => 'Отозвать приглашение';

  @override
  String get groupCode => 'Код группы';

  @override
  String get groupCodeHint => 'Родители вводят код в профиле ребёнка — вы одобряете заявку.';

  @override
  String groupCodeShareText(String group, String code) {
    return 'Вступайте в группу «$group» в приложении Gundi. Код: $code';
  }

  @override
  String get joinGroup => 'Вступить в группу по коду';

  @override
  String get joinGroupCodeLabel => 'Код из 6 символов';

  @override
  String joinGroupSent(String group) {
    return 'Заявка отправлена в группу «$group»';
  }

  @override
  String get leaveGroup => 'Покинуть группу';

  @override
  String leaveGroupConfirm(String child, String group) {
    return '$child покинет группу «$group». Тренер больше не увидит данные и справку ребёнка.';
  }

  @override
  String get leftGroup => 'Ребёнок покинул группу';

  @override
  String get membershipTitle => 'Группы и заявки';

  @override
  String get newGroup => 'Новая группа';

  @override
  String get groupName => 'Название группы';

  @override
  String get groupAgeFrom => 'Возраст от';

  @override
  String get groupAgeTo => 'Возраст до';

  @override
  String get groupClub => 'Клуб';

  @override
  String get groupSport => 'Вид спорта';

  @override
  String groupCreated(String code) {
    return 'Группа создана. Код: $code';
  }

  @override
  String get addChildTitle => 'Добавить ребёнка';

  @override
  String get addChildByCode => 'По коду';

  @override
  String get addChildBySearch => 'Поиск';

  @override
  String get addChildManual => 'Вручную';

  @override
  String get addChildSearchHint => 'Имя или фамилия ребёнка';

  @override
  String get addChildSearchNote =>
      'Приглашение получит родитель. Ребёнок вступит в группу только после его подтверждения.';

  @override
  String get addChildManualNote => 'Родитель получит приглашение. До подтверждения вы видите только имя.';

  @override
  String get parentPhone => 'Телефон родителя';

  @override
  String get inviteSent => 'Приглашение отправлено родителю';

  @override
  String get invitesSent => 'Отправленные приглашения';

  @override
  String birthYearShort(int year) {
    return '$year г. р.';
  }

  @override
  String get pendingParentBadge => 'Ждём родителя';

  @override
  String get noSearchResults => 'Ничего не найдено';

  @override
  String get requestViaCode => 'по коду';

  @override
  String get mediaTitle => 'Медиа';

  @override
  String get mediaRecent => 'Последние фото и видео';

  @override
  String get mediaTakePhoto => 'Сделать фото';

  @override
  String get mediaRecordVideo => 'Снять видео';

  @override
  String get mediaFromGallery => 'Из галереи';

  @override
  String get mediaCaption => 'Подпись';

  @override
  String get mediaGroups => 'Кто увидит';

  @override
  String get mediaConsentConfirm => 'Подтверждаю: в этих материалах нет детей без согласия родителей';

  @override
  String get mediaPublish => 'Опубликовать';

  @override
  String get mediaPublished => 'Опубликовано — родители группы уведомлены';

  @override
  String get mediaEmpty => 'Медиа пока нет';

  @override
  String mediaVideo(int seconds) {
    return 'Видео · $seconds с';
  }

  @override
  String get mediaNoDownload => 'Скачивание отключено для защиты конфиденциальности детей.';

  @override
  String get mediaDelete => 'Удалить';

  @override
  String get mediaHidden => 'Скрыто модерацией';

  @override
  String get mediaLimits => 'Фото ≤ 10 МБ · видео ≤ 60 с и 100 МБ';

  @override
  String mediaConsentMissing(int count, String names) {
    return 'Нет согласия на медиа ($count): $names';
  }

  @override
  String get reportTitle => 'Жалоба';

  @override
  String get reportReasonInappropriate => 'Неприемлемый контент';

  @override
  String get reportReasonPrivacy => 'Конфиденциальность';

  @override
  String get reportReasonSpam => 'Спам';

  @override
  String get reportReasonOther => 'Другое';

  @override
  String get reportNote => 'Комментарий (необязательно)';

  @override
  String get reportSent => 'Жалоба отправлена администраторам';

  @override
  String get messageHidden => 'Сообщение скрыто модерацией';

  @override
  String get chatsEmpty => 'Чаты появятся, когда ваш ребёнок вступит в группу';

  @override
  String get chatAnnouncement => 'Объявление';

  @override
  String get chatAnnouncementToggle => 'Отправить как объявление (закрепить)';

  @override
  String get chatPin => 'Закрепить';

  @override
  String get chatUnpin => 'Открепить';

  @override
  String get chatPinned => 'Закреплено';

  @override
  String chatReadBy(int count) {
    return 'Прочитали: $count';
  }

  @override
  String get chatSendFailed => 'Не отправлено';

  @override
  String get chatRetry => 'Повторить';

  @override
  String get chatSending => 'Отправка…';

  @override
  String get chatNoMessages => 'Сообщений пока нет';

  @override
  String get chatSystem => 'Система';

  @override
  String unreadCount(int count) {
    return 'Непрочитанных: $count';
  }

  @override
  String get notifNewMatch => 'Новый матч';

  @override
  String get notifMatchChanged => 'Матч изменён';

  @override
  String get notifMatchReminder => 'Напоминание о матче';

  @override
  String get notifGroupInvite => 'Приглашение в группу';

  @override
  String get notifInviteAnswered => 'Ответ на приглашение';

  @override
  String get notifAttendanceRecorded => 'Посещаемость отмечена';

  @override
  String get notifFeedbackAdded => 'Отзыв тренера';

  @override
  String get notifAnnouncement => 'Объявление';

  @override
  String get notifNewMedia => 'Новое фото/видео';

  @override
  String get notifScheduleChanged => 'Расписание изменено';

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
  String get catTrainings => 'Тренировки';

  @override
  String get catMatches => 'Матчи';

  @override
  String get catInvitations => 'Приглашения';

  @override
  String get catAttendance => 'Посещаемость';

  @override
  String get catPayments => 'Платежи';

  @override
  String get catChat => 'Чат';

  @override
  String get catCertificates => 'Справки';

  @override
  String get catAnnouncements => 'Объявления';

  @override
  String get notificationsEmptyCategory => 'В этой категории пусто';

  @override
  String get paymentsOutstanding => 'К оплате';

  @override
  String get paymentsPaidTotal => 'Оплачено';

  @override
  String get paymentsOverdueTotal => 'Просрочено';

  @override
  String get paymentsFilterChild => 'Ребёнок';

  @override
  String get paymentsFilterSport => 'Вид спорта';

  @override
  String get paymentsReminderPrefs => 'Настройки напоминаний';

  @override
  String get paymentsNoOnline => 'Онлайн-оплата пока недоступна — оплачивайте так, как указывает клуб.';

  @override
  String get paymentCancelReason => 'Причина отмены';

  @override
  String get paymentAudit => 'История изменений';

  @override
  String paymentAuditLine(String actor, String from, String to) {
    return '$actor: $from → $to';
  }

  @override
  String paymentSummaryMonth(String month) {
    return '$month — итоги';
  }

  @override
  String get paymentTitleLabel => 'Название (необязательно)';

  @override
  String paymentChildren(int count) {
    return 'Детей: $count';
  }

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get profilePhoto => 'Фото профиля';

  @override
  String get profilePhotoChange => 'Сменить фото';

  @override
  String get profilePhotoRemove => 'Удалить фото';

  @override
  String get profilePhotoUpdated => 'Фото обновлено';

  @override
  String get privacySettingsTitle => 'Конфиденциальность';

  @override
  String get privacyPhotoVisible => 'Показывать моё фото тренерам и родителям моих групп';

  @override
  String get privacyAnalytics => 'Анонимная диагностика (отчёты о сбоях)';

  @override
  String get consentsTitle => 'Согласия';

  @override
  String consentDataGiven(String date) {
    return 'Обработка данных — $date';
  }

  @override
  String get consentSmsToggle => 'SMS-напоминания об оплате';

  @override
  String consentMedia(String child) {
    return 'Медиа: $child';
  }

  @override
  String get dataExport => 'Экспорт моих данных';

  @override
  String get dataExportHint =>
      'Вы получите JSON-файл с вашими данными и данными детей (без содержимого медицинских файлов).';

  @override
  String get dataExportReady => 'Экспорт готов';

  @override
  String get dataExportRequested => 'Экспорт запрошен';

  @override
  String get accountRequests => 'Запросы';

  @override
  String get requestStatusPending => 'Ожидает';

  @override
  String get requestStatusProcessing => 'В обработке';

  @override
  String get requestStatusDone => 'Выполнен';

  @override
  String get requestStatusRejected => 'Отклонён';

  @override
  String get deleteImpactTitle => 'Что произойдёт при удалении';

  @override
  String deleteImpactDeleted(String names) {
    return 'Будут удалены (вы единственный опекун): $names';
  }

  @override
  String deleteImpactUnlinked(String names) {
    return 'Останутся у другого опекуна: $names';
  }

  @override
  String get deleteImpactPayments => 'История платежей сохранится в обезличенном виде для бухгалтерии клуба.';

  @override
  String get retentionTitle => 'Хранение и удаление';

  @override
  String get retentionBody =>
      'При удалении аккаунта удаляются ваш профиль, фото, а для детей, у которых вы единственный опекун, — справки (вместе с файлами), посещаемость и отзывы. Дети, у которых есть другой опекун, не удаляются.';

  @override
  String get weekSchedule => 'Эта неделя';

  @override
  String get weekEmpty => 'На этой неделе тренировок нет';

  @override
  String get attendanceTile => 'Посещаемость';

  @override
  String attendanceTileValue(int percent) {
    return '$percent% в этом месяце';
  }

  @override
  String get progressShort => 'Прогресс';

  @override
  String get importantTitle => 'Важное';

  @override
  String get coachFab => 'Добавить';

  @override
  String get addTrainingOne => 'Разовая тренировка';

  @override
  String get addSeries => 'Регулярное расписание';

  @override
  String get addMatch => 'Матч';

  @override
  String get addMedia => 'Фото / видео';

  @override
  String get addChildToGroup => 'Пригласить ребёнка';

  @override
  String get newVenue => 'Новое место на карте';

  @override
  String get venuePickHint => 'Нажмите на карту, чтобы поставить метку';

  @override
  String get venueNearby => 'Места поблизости (200 м):';

  @override
  String get venueUseExisting => 'Выбрать существующее';

  @override
  String get venueName => 'Название места';

  @override
  String get venueAddress => 'Адрес';

  @override
  String get venueUnverified => 'Не проверено';

  @override
  String get venueSaved => 'Место сохранено';

  @override
  String get mapLayerVenues => 'Места';

  @override
  String get mapLayerTrainings => 'Тренировки';

  @override
  String get mapLayerMatches => 'Матчи';

  @override
  String get mapToday => 'Сегодня';

  @override
  String get mapThisWeek => 'На этой неделе';

  @override
  String get sportCategoryTeam => 'Командные';

  @override
  String get sportCategoryCombat => 'Единоборства';

  @override
  String get sportCategoryOther => 'Другие';

  @override
  String sportAgeMin(int age) {
    return 'Мин. возраст: $age';
  }

  @override
  String get sportRequiresCert => 'Нужна медицинская справка';

  @override
  String get demoOffline => 'Имитировать офлайн';

  @override
  String get demoOfflineHint => 'Запись не проходит — приложение показывает корректную ошибку.';

  @override
  String aboutVersion(String version, String env) {
    return 'Версия $version · $env';
  }

  @override
  String get adminUseWeb => 'Панель администратора доступна в веб-версии.';

  @override
  String get adminTitle => 'Gundi · Админ';

  @override
  String get adminSignInTitle => 'Панель администратора';

  @override
  String get adminSignInBody => 'Только для администраторов. Права проверяются на сервере.';

  @override
  String get adminDemoAccounts => 'Демо-аккаунты';

  @override
  String get adminDemoTryParent => 'Проверка: аккаунт родителя (доступ запрещён)';

  @override
  String get adminPhoneSignIn => 'Войти по телефону';

  @override
  String get adminFirebaseLoginNote =>
      'Для входа по телефону в веб-версии нужна настройка Firebase reCAPTCHA (см. docs/firebase-setup.md).';

  @override
  String get adminRolePlatform => 'Админ платформы';

  @override
  String get adminRoleClub => 'Админ клуба';

  @override
  String adminScopeClubs(String clubs) {
    return 'Клубы: $clubs';
  }

  @override
  String get adminNavDashboard => 'Обзор';

  @override
  String get adminNavCoaches => 'Тренеры';

  @override
  String get adminNavClubs => 'Клубы';

  @override
  String get adminNavSports => 'Виды спорта';

  @override
  String get adminNavGroups => 'Группы';

  @override
  String get adminNavModeration => 'Модерация';

  @override
  String get adminNavAudit => 'Журнал аудита';

  @override
  String get adminNavAdmins => 'Администраторы';

  @override
  String get adminStatParents => 'Родители';

  @override
  String get adminStatChildren => 'Дети';

  @override
  String get adminStatCoaches => 'Тренеры';

  @override
  String get adminStatClubs => 'Клубы';

  @override
  String get adminStatGroups => 'Активные группы';

  @override
  String get adminStatTrainings => 'Тренировки (7 дней)';

  @override
  String get adminStatMatches => 'Предстоящие матчи';

  @override
  String get adminStatPendingCoaches => 'Заявки тренеров';

  @override
  String get adminStatPendingRequests => 'Заявки на вступление';

  @override
  String get adminStatReports => 'Открытые жалобы';

  @override
  String get adminNeedsAttention => 'Требует внимания';

  @override
  String get adminSearch => 'Поиск…';

  @override
  String get adminFilterAll => 'Все';

  @override
  String get adminColName => 'Имя';

  @override
  String get adminColStatus => 'Статус';

  @override
  String get adminColClubs => 'Клубы';

  @override
  String get adminColSports => 'Виды спорта';

  @override
  String get adminColGroups => 'Группы';

  @override
  String get adminColApplied => 'Дата заявки';

  @override
  String get adminColActions => 'Действия';

  @override
  String get adminColAddress => 'Адрес';

  @override
  String get adminColMembers => 'Участники';

  @override
  String get adminColCoach => 'Тренер';

  @override
  String get adminColSchedule => 'Расписание';

  @override
  String get adminColRequests => 'Заявки';

  @override
  String get adminColUpcoming => 'Предстоящие тренировки';

  @override
  String get adminColCategory => 'Категория';

  @override
  String get adminColAgeMin => 'Мин. возраст';

  @override
  String get adminColCert => 'Справка';

  @override
  String get adminColActive => 'Активен';

  @override
  String get adminColWhen => 'Когда';

  @override
  String get adminColActor => 'Кто';

  @override
  String get adminColAction => 'Действие';

  @override
  String get adminColTarget => 'Объект';

  @override
  String get adminColDetails => 'Подробности';

  @override
  String get adminColReason => 'Причина';

  @override
  String get adminColContent => 'Содержимое';

  @override
  String adminPageOf(int pageStart, int pageEnd, int total) {
    return '$pageStart–$pageEnd из $total';
  }

  @override
  String get adminApprove => 'Одобрить';

  @override
  String get adminReject => 'Отклонить';

  @override
  String get adminSuspend => 'Приостановить';

  @override
  String get adminRevoke => 'Отозвать доступ';

  @override
  String get adminReinstate => 'Восстановить';

  @override
  String get adminReasonTitle => 'Причина (обязательно)';

  @override
  String get adminCoachStatusPending => 'На рассмотрении';

  @override
  String get adminCoachStatusApproved => 'Одобрен';

  @override
  String get adminCoachStatusRejected => 'Отклонён';

  @override
  String get adminCoachStatusSuspended => 'Приостановлен';

  @override
  String get adminCoachStatusRevoked => 'Доступ отозван';

  @override
  String get adminCoachUpdated => 'Статус тренера обновлён';

  @override
  String get adminAssignClub => 'Привязать к клубу';

  @override
  String get adminUnassignClub => 'Отвязать от клуба';

  @override
  String get adminNewClub => 'Новый клуб';

  @override
  String get adminEditClub => 'Изменить клуб';

  @override
  String get adminArchive => 'В архив';

  @override
  String get adminRestore => 'Восстановить';

  @override
  String get adminArchived => 'В архиве';

  @override
  String get adminLat => 'Широта';

  @override
  String get adminLng => 'Долгота';

  @override
  String get adminPhone => 'Телефон';

  @override
  String get adminDescription => 'Описание';

  @override
  String get adminSaved => 'Сохранено';

  @override
  String get adminNewSport => 'Новый вид спорта';

  @override
  String get adminEditSport => 'Изменить вид спорта';

  @override
  String get adminSportId => 'Идентификатор (латиницей)';

  @override
  String get adminSportOrder => 'Порядок';

  @override
  String get adminReadOnly => 'Только просмотр — редактировать могут только администраторы платформы.';

  @override
  String get adminHide => 'Скрыть';

  @override
  String get adminKeep => 'Оставить';

  @override
  String get adminReportOpen => 'Открыта';

  @override
  String get adminReportResolved => 'Скрыто';

  @override
  String get adminReportDismissed => 'Оставлено';

  @override
  String get adminModerationEmpty => 'Жалоб нет';

  @override
  String get adminModerationNote =>
      'Медиа открываются только по краткосрочным подписанным ссылкам. Персональные данные детей здесь не показываются.';

  @override
  String get adminMakeClubAdmin => 'Назначить админом клуба';

  @override
  String get adminRemoveAdmin => 'Снять права админа';

  @override
  String get adminRoleUpdated => 'Роль обновлена';

  @override
  String get adminGrantHint =>
      'Первый администратор платформы назначается только через серверный скрипт (functions/scripts/grant-platform-admin.mjs).';

  @override
  String get adminNotAdminTitle => 'Вы не администратор';

  @override
  String get adminNotAdminBody =>
      'Этот аккаунт не может использовать панель администратора. Пожалуйста, пользуйтесь мобильным приложением.';

  @override
  String get adminChildDataNote => 'Администраторы не видят имена детей и медицинские данные — только количество.';

  @override
  String get adminEmpty => 'Записей нет';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageGeorgian => 'ქართული';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChanged => 'Язык изменён';

  @override
  String get languageHint => 'Язык не зависит от языка телефона. Тексты, написанные тренерами, не переводятся.';

  @override
  String get certCurrent => 'Действующая справка';

  @override
  String get certReplace => 'Заменить справку';

  @override
  String get certReplaced => 'Заменена новой';

  @override
  String get certPreview => 'Просмотр';

  @override
  String get certDownload => 'Скачать';

  @override
  String certExpiresOn(String date) {
    return 'Действует до: $date';
  }

  @override
  String certAppliesTo(String sport) {
    return 'Для: $sport';
  }

  @override
  String get certAllSports => 'Все виды спорта';

  @override
  String get certSportLabel => 'Для какого вида спорта';

  @override
  String get certTakePhoto => 'Сфотографировать';

  @override
  String get certChooseFile => 'Выбрать файл';

  @override
  String get certSensitiveWarning =>
      'Медицинские документы — конфиденциальная информация. Не пересылайте их и удалите файл, когда он больше не нужен.';

  @override
  String get certDownloadConfirm => 'Скачать';

  @override
  String get certAccessLogged => 'Этот доступ записан в журнал безопасности';

  @override
  String get certAccessHistory => 'История доступа';

  @override
  String certAccessView(String who, String when) {
    return '$who — просмотр, $when';
  }

  @override
  String certAccessDownload(String who, String when) {
    return '$who — скачивание, $when';
  }

  @override
  String get certPdfPreview => 'PDF-документ';

  @override
  String get certSavedTemp => 'Файл сохранён временно и будет удалён из приложения после отправки.';

  @override
  String get certNoAdminAccess => 'Администраторы не видят медицинские документы — только статусы.';

  @override
  String get rosterTitle => 'Ученики';

  @override
  String get rosterSearch => 'Поиск ученика';

  @override
  String get rosterSortName => 'По имени';

  @override
  String get rosterSortAge => 'По возрасту';

  @override
  String get rosterSortAttendance => 'По посещаемости';

  @override
  String get rosterSortCert => 'По справке';

  @override
  String get rosterFilterAll => 'Все';

  @override
  String get rosterFilterCertIssues => 'Проблемы со справкой';

  @override
  String get rosterFilterLowAttendance => 'Низкая посещаемость';

  @override
  String get rosterEmptyFilter => 'Нет учеников по этому фильтру';

  @override
  String get rosterStudentDetail => 'Ученик';

  @override
  String rosterAttendanceRate(int percent) {
    return 'Посещаемость $percent%';
  }

  @override
  String get rosterNoAttendance => 'Посещаемость ещё не отмечена';

  @override
  String rosterCount(int count) {
    return 'Учеников: $count';
  }

  @override
  String get attendanceSave => 'Сохранить';

  @override
  String get attendanceSaved => 'Посещаемость сохранена';

  @override
  String attendanceUnsaved(int count) {
    return 'Несохранённых изменений: $count';
  }

  @override
  String get attendanceDiscard => 'Отменить';

  @override
  String get attendanceEditNote => 'Отмеченную посещаемость можно исправить — каждое изменение сохраняется.';

  @override
  String get attendanceByStudent => 'По ученикам';

  @override
  String get attendanceByGroup => 'По группе';

  @override
  String get attendanceReportTitle => 'Отчёт о посещаемости';

  @override
  String attendanceSessions(int count) {
    return 'Тренировок: $count';
  }

  @override
  String get attendanceMarkAll => 'Все';

  @override
  String get exportTitle => 'Экспорт';

  @override
  String get exportRoster => 'Список учеников';

  @override
  String get exportTrainingSheet => 'Лист посещаемости тренировки';

  @override
  String get exportMonthly => 'Ежемесячный отчёт о посещаемости';

  @override
  String get exportFormat => 'Формат';

  @override
  String get exportIncludeCompliance => 'Включить статус справки (только при необходимости)';

  @override
  String get exportWarning =>
      'Файл содержит персональные данные детей. Передавайте его только тем, кому он действительно нужен, и удалите после использования.';

  @override
  String get exportConfirm => 'Понятно, экспортировать';

  @override
  String exportReady(String name) {
    return 'Файл готов: $name';
  }

  @override
  String get exportChooseTraining => 'Выберите тренировку';

  @override
  String get exportChooseMonth => 'Выберите месяц';

  @override
  String get exportColStudent => 'Ученик';

  @override
  String get exportColGroup => 'Группа';

  @override
  String get exportColDate => 'Дата';

  @override
  String get exportColStatus => 'Посещаемость';

  @override
  String get exportColAge => 'Возраст';

  @override
  String get exportColCert => 'Справка';

  @override
  String get exportColRate => 'Посещаемость, %';

  @override
  String exportGenerated(String date) {
    return 'Создано: $date';
  }

  @override
  String get exportConfidential => 'Конфиденциально — только для внутреннего использования';

  @override
  String exportPage(int n) {
    return 'Стр. $n';
  }

  @override
  String get plansTitle => 'Планы тренировок';

  @override
  String get plansEmpty => 'Планов тренировок пока нет';

  @override
  String get planNew => 'Новый план';

  @override
  String get planEdit => 'Редактировать план';

  @override
  String get planTitleLabel => 'Название';

  @override
  String get planDescription => 'Описание';

  @override
  String get planType => 'Тип плана';

  @override
  String get planTypeSeasonal => 'Сезонный';

  @override
  String get planTypeMonthly => 'Месячный';

  @override
  String get planTypeWeekly => 'Недельный';

  @override
  String get planTypeExercise => 'Отдельное упражнение';

  @override
  String get planTypeHomework => 'Домашнее задание';

  @override
  String get planGroups => 'Группы';

  @override
  String get planStart => 'Начало';

  @override
  String get planEnd => 'Окончание';

  @override
  String get planStatusDraft => 'Черновик';

  @override
  String get planStatusPublished => 'Опубликован';

  @override
  String get planStatusArchived => 'В архиве';

  @override
  String get planSaveDraft => 'Сохранить черновик';

  @override
  String get planPublish => 'Опубликовать';

  @override
  String get planArchive => 'В архив';

  @override
  String get planUnpublish => 'Вернуть в черновики';

  @override
  String get planPublished => 'План опубликован — родители получили уведомление';

  @override
  String get planSaved => 'План сохранён';

  @override
  String get planArchived => 'План перенесён в архив';

  @override
  String get planExercises => 'Упражнения';

  @override
  String get planAddExercise => 'Добавить упражнение';

  @override
  String get planNoExercises => 'Добавьте хотя бы одно упражнение';

  @override
  String planViews(int count) {
    return 'Просмотрели родители: $count';
  }

  @override
  String planCompletion(String done, int total) {
    return 'Выполнено: $done из $total';
  }

  @override
  String get planSelfReported => 'Выполнение отмечают родители — тренер его не проверяет.';

  @override
  String planPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String planOpenEnded(String start) {
    return 'С $start';
  }

  @override
  String get planHomeworkDue => 'Задание до следующей тренировки';

  @override
  String get planActive => 'Активные планы';

  @override
  String get planDraftsOnlyCoach => 'Родители не видят черновики';

  @override
  String get exerciseName => 'Название упражнения';

  @override
  String get exerciseDescription => 'Описание';

  @override
  String get exerciseInstructions => 'Инструкция';

  @override
  String get exerciseDuration => 'Длительность (мин)';

  @override
  String get exerciseReps => 'Повторения';

  @override
  String get exerciseSets => 'Подходы';

  @override
  String get exerciseRest => 'Отдых (сек)';

  @override
  String get exerciseMedia => 'Материалы';

  @override
  String get exerciseAddLink => 'Добавить ссылку';

  @override
  String get exerciseLinkHint => 'https://…';

  @override
  String get exerciseLinkInvalid => 'Ссылка должна начинаться с https://';

  @override
  String get exerciseOpenLink => 'Открыть ссылку';

  @override
  String get exerciseExternalWarning => 'Ссылка откроется в браузере. Приложение не передаёт ей ваши данные.';

  @override
  String get exerciseMoveUp => 'Выше';

  @override
  String get exerciseMoveDown => 'Ниже';

  @override
  String get exerciseRemove => 'Удалить';

  @override
  String exerciseSummary(String sets, String reps) {
    return '$sets × $reps';
  }

  @override
  String exerciseMinutes(int n) {
    return '$n мин';
  }

  @override
  String exerciseRestSec(int n) {
    return 'Отдых $n с';
  }

  @override
  String get progressNotStarted => 'Не начато';

  @override
  String get progressInProgress => 'В процессе';

  @override
  String get progressCompleted => 'Выполнено';

  @override
  String progressFor(String child) {
    return 'Прогресс: $child';
  }

  @override
  String get validationPlanTitle => 'Введите название';

  @override
  String get validationPlanGroups => 'Выберите хотя бы одну группу';

  @override
  String get validationPlanExercises => 'Добавьте хотя бы одно упражнение';

  @override
  String get validationPlanDates => 'Окончание раньше начала';

  @override
  String get validationExerciseName => 'Введите название упражнения';

  @override
  String get validationLink => 'Неверная ссылка (только https://)';

  @override
  String get validationTooManyExercises => 'Не более 50 упражнений';

  @override
  String get validationTooManyMedia => 'Не более 10 материалов на упражнение';

  @override
  String get validationPlanNotDraft => 'До публикации можно редактировать только черновик';

  @override
  String get payProofAction => 'Подтвердить оплату';

  @override
  String get payProofTitle => 'Подтверждение оплаты';

  @override
  String get payProofDate => 'Дата оплаты';

  @override
  String get payProofReference => 'Номер транзакции / платежа';

  @override
  String get payProofNote => 'Комментарий';

  @override
  String get payProofReceipt => 'Квитанция (JPG, PNG или PDF, до 10 МБ)';

  @override
  String get payProofSubmit => 'Отправить на проверку';

  @override
  String get payProofSubmitted => 'Отправлено — тренер проверит оплату';

  @override
  String payProofUploading(int percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String get payProofHint =>
      'Ваше подтверждение само по себе не отмечает платёж как оплаченный — его проверяет уполномоченный тренер или администратор клуба.';

  @override
  String get payStateAwaiting => 'Ожидает подтверждения';

  @override
  String get payStateUnderReview => 'На проверке';

  @override
  String get payStateRejected => 'Отклонено';

  @override
  String get payStatePaid => 'Оплачено';

  @override
  String payRejectedReason(String reason) {
    return 'Причина отказа: $reason';
  }

  @override
  String get payResubmit => 'Отправить снова';

  @override
  String paySubmittedOn(String date) {
    return 'Отправлено $date';
  }

  @override
  String get payViewReceipt => 'Посмотреть квитанцию';

  @override
  String payVerifiedBy(String name, String date) {
    return 'Подтвердил(а) $name, $date';
  }

  @override
  String get payReviewQueue => 'Подтверждения оплат';

  @override
  String get payReviewEmpty => 'Нет оплат для проверки';

  @override
  String get payApprove => 'Подтвердить';

  @override
  String get payReject => 'Отклонить';

  @override
  String get payApproved => 'Оплата подтверждена — родитель получил уведомление';

  @override
  String get payRejectedSnack => 'Отклонено — родителю сообщили причину';

  @override
  String get payRejectReasonTitle => 'Причина отказа';

  @override
  String get payNotReviewer => 'Подтверждать оплаты могут только назначенные тренеры и администраторы клуба.';

  @override
  String get payHistory => 'История';

  @override
  String get payEventSubmitted => 'Отправлено';

  @override
  String get payEventResubmitted => 'Отправлено повторно';

  @override
  String get payEventReviewStarted => 'Проверка начата';

  @override
  String get payEventApproved => 'Подтверждено';

  @override
  String get payEventRejected => 'Отклонено';

  @override
  String get payEventViewed => 'Квитанция просмотрена';

  @override
  String get payPaymentManagers => 'Проверяющие оплаты';

  @override
  String payProofFor(String child, String amount, String due) {
    return '$child · $amount · $due';
  }

  @override
  String get validationProofExists => 'Подтверждение по этому платежу уже на проверке';

  @override
  String get validationProofClosed => 'По этому подтверждению уже принято решение';

  @override
  String get validationPaymentClosed => 'Этот платёж уже закрыт';

  @override
  String get validationReceiptRequired => 'Приложите квитанцию';

  @override
  String get validationDateFuture => 'Дата в будущем';

  @override
  String get notifPaymentProofSubmitted => 'Подтверждение оплаты на проверку';

  @override
  String get notifPaymentProofApproved => 'Оплата подтверждена';

  @override
  String get notifPaymentProofRejected => 'Подтверждение оплаты отклонено';

  @override
  String get notifTrainingPlanPublished => 'Новый план тренировок';

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
    return '$child — осталось дней: $days';
  }

  @override
  String notifBodyCertExpired(String child) {
    return '$child — срок справки истёк';
  }

  @override
  String sysTrainingCancelled(String when, String reason) {
    return 'Тренировка отменена ($when). Причина: $reason';
  }

  @override
  String sysTrainingMoved(String from, String to) {
    return 'Тренировка перенесена: $from → $to';
  }

  @override
  String sysMatchCreated(String opponent, String when) {
    return 'Новый матч: $opponent, $when';
  }

  @override
  String sysMatchMoved(String from, String to) {
    return 'Матч перенесён: $from → $to';
  }

  @override
  String sysMatchCancelled(String opponent, String reason) {
    return 'Матч ($opponent) отменён. Причина: $reason';
  }

  @override
  String get sysScheduleCreated => 'Добавлено расписание тренировок';

  @override
  String sysScheduleChanged(String from) {
    return 'Расписание тренировок меняется с $from';
  }

  @override
  String sysPlanPublished(String title) {
    return 'Опубликован план тренировок: $title';
  }

  @override
  String get sysScheduleReason => 'Расписание изменено';

  @override
  String get adminNavCompliance => 'Справки';

  @override
  String get adminNavAttendance => 'Посещаемость';

  @override
  String get adminNavPlans => 'Планы тренировок';

  @override
  String get adminNavPayments => 'Оплаты';

  @override
  String get adminNavSettings => 'Настройки';

  @override
  String get adminComplianceNote => 'Только количество по статусам — без документов и имён детей.';

  @override
  String get adminColValid => 'Действует';

  @override
  String get adminColExpiring => 'Истекает';

  @override
  String get adminColExpired => 'Истекла';

  @override
  String get adminColMissing => 'Нет';

  @override
  String get adminColRate => 'Посещаемость';

  @override
  String get adminColSessions => 'Тренировки';

  @override
  String get adminColPlans => 'Планы';

  @override
  String get adminColPlanType => 'Тип';

  @override
  String get adminColAmount => 'Сумма';

  @override
  String get adminColSubmitted => 'Отправлено';

  @override
  String get adminColReviewers => 'Проверяющие';

  @override
  String get adminPaymentQueueNote => 'Квитанции открываются по временной ссылке, каждый просмотр записывается.';

  @override
  String get adminSetReviewers => 'Назначить проверяющих';

  @override
  String get adminLanguage => 'Язык интерфейса';

  @override
  String get adminRosterNote => 'Количество учеников по группам — без имён.';

  @override
  String get adminMonth => 'Месяц';

  @override
  String get addToCalendar => 'Добавить в календарь';

  @override
  String get exportSchedule => 'Экспорт расписания в календарь';

  @override
  String get calendarNothingToExport => 'Нет предстоящих тренировок для экспорта';

  @override
  String get contactsTitle => 'Контакты';

  @override
  String get contactsCoachTitle => 'Контакт тренера';

  @override
  String get contactsParentsTitle => 'Родители и опекуны';

  @override
  String contactCallName(String name) {
    return 'Позвонить: $name';
  }

  @override
  String get contactNoPhone => 'Номер не указан';

  @override
  String get contactCoachAction => 'Связаться с тренером';

  @override
  String get contactParentsAction => 'Контакты родителей';

  @override
  String get contactPrivacyCoach =>
      'Эти номера видят только тренеры этой группы. Используйте их только по вопросам команды.';

  @override
  String get contactPrivacyParent => 'Тренер группы вашего ребёнка. Номера других родителей не показываются.';

  @override
  String contactParentOf(String names) {
    return 'Родитель: $names';
  }

  @override
  String get contactsEmpty => 'Нет доступных контактов';

  @override
  String get relationMother => 'Мама';

  @override
  String get relationFather => 'Папа';

  @override
  String get relationGuardian => 'Опекун';

  @override
  String get relationGrandparent => 'Бабушка или дедушка';

  @override
  String get relationOther => 'Другой родственник';

  @override
  String receiptSeenBy(int read, int total) {
    return 'Просмотрели $read из $total родителей';
  }

  @override
  String receiptSeenShort(int read, int total) {
    return 'Просмотрено: $read/$total';
  }

  @override
  String receiptAckShort(int acked, int total) {
    return 'Подтвердили: $acked/$total';
  }

  @override
  String get receiptsTitle => 'Статус сообщения';

  @override
  String get receiptNotSeen => 'Не просмотрено';

  @override
  String get receiptSeen => 'Просмотрено';

  @override
  String get receiptAcknowledged => 'Подтверждено';

  @override
  String receiptSeenAt(String time) {
    return 'Просмотрено $time';
  }

  @override
  String receiptAckAt(String time) {
    return 'Подтверждено $time';
  }

  @override
  String get receiptPrivacy =>
      'Кто прочитал сообщение, видите только вы. Родители, присоединившиеся позже, не учитываются.';

  @override
  String get chatAckToggle => 'Запросить подтверждение';

  @override
  String get chatAckRequired => 'Требуется подтверждение';

  @override
  String get chatAckButton => 'Ознакомился(ась)';

  @override
  String get chatAckDone => 'Подтверждено';

  @override
  String get chatAckSent => 'Подтверждение отправлено';

  @override
  String get dashboardAcksTitle => 'Ждут вашего подтверждения';

  @override
  String dashboardAcksBody(int count, String groups) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сообщения',
      many: '$count сообщений',
      few: '$count сообщения',
      one: '$count сообщение',
    );
    return '$_temp0 · $groups';
  }

  @override
  String get notifAckRequested => 'Подтвердите ознакомление';

  @override
  String get videoPlay => 'Воспроизвести';

  @override
  String get videoPause => 'Пауза';

  @override
  String get videoBack10 => 'Назад на 10 секунд';

  @override
  String get videoForward10 => 'Вперёд на 10 секунд';

  @override
  String get videoFullscreen => 'Во весь экран';

  @override
  String get videoExitFullscreen => 'Выйти из полноэкранного режима';

  @override
  String get videoLoading => 'Загрузка видео…';

  @override
  String get videoBuffering => 'Буферизация…';

  @override
  String get videoError => 'Не удалось воспроизвести видео.';

  @override
  String get videoPosition => 'Позиция видео';

  @override
  String get downloadAction => 'Скачать';

  @override
  String get downloadTitle => 'Скачивание медиафайла';

  @override
  String get downloadNotice =>
      'При скачивании копия сохраняется на вашем устройстве. Удалить её удалённо нельзя, поэтому делитесь ею ответственно.';

  @override
  String downloadProgress(int percent) {
    return 'Скачивание… $percent%';
  }

  @override
  String get downloadCancelled => 'Скачивание отменено';

  @override
  String get downloadFailed => 'Не удалось скачать. Проверьте соединение и повторите попытку.';

  @override
  String downloadDone(String name) {
    return 'Готово: $name. Выберите, где сохранить.';
  }

  @override
  String get downloadDenied => 'У вас больше нет доступа к этому файлу.';

  @override
  String get downloadStorageError => 'Не удалось сохранить файл на этом устройстве.';

  @override
  String get downloadPolicyOff => 'Для этой группы скачивание отключено.';

  @override
  String get adminNavMediaDownloads => 'Скачивания медиа';

  @override
  String get adminMediaPolicy => 'Родители могут скачивать фото и видео';

  @override
  String get adminMediaDownloadsNote =>
      'Разрешённые скачивания фото и видео тренеров. Скачанную копию нельзя отозвать.';

  @override
  String get adminColPost => 'Публикация';

  @override
  String get adminColUser => 'Пользователь';

  @override
  String get adminColDownloads => 'Скачивание';

  @override
  String get studentProfileTitle => 'Профиль ученика';

  @override
  String get studentProfileOpen => 'Профиль';

  @override
  String get tabOverview => 'Обзор';

  @override
  String get tabTrainings => 'Тренировки';

  @override
  String get tabPlans => 'Планы';

  @override
  String get tabMedia => 'Медиа';

  @override
  String get tabMatches => 'Матчи';

  @override
  String get profileSportsGroups => 'Виды спорта и группы';

  @override
  String get profileCoaches => 'Тренеры';

  @override
  String get profileUpcomingTrainings => 'Предстоящие тренировки';

  @override
  String get profileUpcomingMatches => 'Предстоящие матчи';

  @override
  String get profileTrainingHistory => 'История тренировок';

  @override
  String get profileAttendance => 'Посещаемость';

  @override
  String get profileHomework => 'Домашние задания';

  @override
  String get profileMatchResults => 'Результаты матчей';

  @override
  String get profileCertificate => 'Медицинская справка';

  @override
  String get profilePayments => 'Платежи';

  @override
  String get profileEmpty => 'Пока пусто';

  @override
  String get profileCoachScope => 'Показаны только данные ваших групп.';

  @override
  String contactCoachAbout(String child) {
    return 'Написать тренеру: $child';
  }

  @override
  String threadAbout(String child) {
    return 'По поводу: $child';
  }

  @override
  String threadPrivacy(String child) {
    return 'Эту переписку видят только родители ($child) и этот тренер.';
  }

  @override
  String get threadEmpty => 'Сообщений пока нет. Напишите первое.';

  @override
  String get threadsTitle => 'Переписка об учениках';

  @override
  String get chooseCoach => 'Выберите тренера';

  @override
  String get notifChildMessage => 'Сообщение о ребёнке';

  @override
  String get matchResultEnter => 'Ввести результат';

  @override
  String get matchResultCorrect => 'Исправить результат';

  @override
  String get matchResultTitle => 'Итоговый счёт';

  @override
  String get matchResultOurTeam => 'Наша команда';

  @override
  String get matchResultOpponent => 'Соперник';

  @override
  String get matchResultSummary => 'Итоги (необязательно)';

  @override
  String matchResultFinishedAt(String time) {
    return 'Завершён: $time';
  }

  @override
  String get matchWin => 'Победа';

  @override
  String get matchDraw => 'Ничья';

  @override
  String get matchLoss => 'Поражение';

  @override
  String get matchResultCorrected => 'Исправлено';

  @override
  String get matchResultSaved => 'Результат сохранён';

  @override
  String get matchResultHistory => 'История исправлений';

  @override
  String get matchResultLatest => 'Последний результат';

  @override
  String get matchResultNotice =>
      'Родители получат уведомление при первом сохранении результата. Исправления фиксируются.';

  @override
  String get notifMatchResult => 'Результат матча';

  @override
  String notifBodyMatchResult(String opponent, String our, String their) {
    return '$opponent: $our–$their';
  }

  @override
  String get validationResultScore => 'Введите счёт от 0 до 999.';

  @override
  String get validationResultNotStarted => 'Результат можно ввести после начала матча.';

  @override
  String get validationResultCancelled => 'У отменённого матча нет результата.';

  @override
  String get validationResultCompletedAt => 'Время окончания должно быть между началом матча и текущим моментом.';

  @override
  String get payDownloadReceipt => 'Скачать квитанцию';

  @override
  String get payProofNotFound => 'Запрос не найден или уже обработан.';

  @override
  String get payEventDownloaded => 'Проверяющий скачал квитанцию';

  @override
  String get roleStudent => 'Ученик';

  @override
  String get continueAsStudent => 'Продолжить как ученик';

  @override
  String get studentDemoNote => 'Вход ученика доступен только в демо-режиме.';

  @override
  String studentWelcome(String name) {
    return 'Привет, $name! Готов играть?';
  }

  @override
  String get studentNavHome => 'Главная';

  @override
  String get studentNavBrain => 'Академия ума';

  @override
  String get studentNavProgress => 'Прогресс';

  @override
  String get studentMySports => 'Мой спорт';

  @override
  String get studentMyCoach => 'Мой тренер';

  @override
  String get studentNextTraining => 'Следующая тренировка';

  @override
  String get studentNoTraining => 'Тренировок не запланировано';

  @override
  String get studentUpcomingMatches => 'Предстоящие матчи';

  @override
  String get studentMatchResults => 'Результаты матчей';

  @override
  String get studentPlans => 'Мои планы тренировок';

  @override
  String get studentHomework => 'Домашние задания';

  @override
  String get studentAttendance => 'Моя посещаемость';

  @override
  String studentAttendanceRate(int percent) {
    return 'Посетил(а) $percent% тренировок';
  }

  @override
  String get studentAchievements => 'Достижения';

  @override
  String get studentNothing => 'Пока ничего';

  @override
  String get studentChallenges => 'Задания тренера';

  @override
  String challengeDue(String date) {
    return 'Срок: $date';
  }

  @override
  String get challengeDone => 'Выполнено';

  @override
  String get challengeOpen => 'Нужно сделать';

  @override
  String get challengeOverdue => 'Просрочено';

  @override
  String get brainAcademy => 'Академия ума';

  @override
  String get brainTagline => 'Тренируй ум, как настоящий спортсмен';

  @override
  String get brainNotIq => 'Очки — для тренировки и удовольствия, это не тест IQ.';

  @override
  String get gameMemoryMatch => 'Найди пару';

  @override
  String get gameLogicQuest => 'Логический квест';

  @override
  String get gameSmartPlay => 'Умная игра';

  @override
  String get gameQuickMind => 'Быстрый ум';

  @override
  String get gameSequenceMaster => 'Мастер последовательностей';

  @override
  String get gamePathFinder => 'Найди путь';

  @override
  String get gameDescMemory => 'Найди одинаковые спортивные карточки';

  @override
  String get gameDescLogic => 'Разгадай закономерность фигур';

  @override
  String get gameDescSmart => 'Выбери лучший ход на поле';

  @override
  String get gameDescQuick => 'Быстро найди нужный символ';

  @override
  String get gameDescSequence => 'Запомни и повтори';

  @override
  String get gameDescPath => 'Доведи мяч до ворот';

  @override
  String get gameHowToMemory =>
      'Открой две карточки. Одинаковые остаются открытыми. Найди все пары за меньшее число попыток.';

  @override
  String get gameHowToLogic => 'Посмотри на ряд и выбери фигуру, которая должна стоять на месте «?».';

  @override
  String get gameHowToSmart => 'Мяч у тебя (жёлтое кольцо). Выбери лучший пас или движение и прочитай объяснение.';

  @override
  String get gameHowToQuick => 'Цель показана сверху. Нажми ту же фигуру того же цвета, пока не вышло время.';

  @override
  String get gameHowToSequence =>
      'Смотри, как загораются цвета, затем нажми их в том же порядке. С каждым раундом ряд длиннее.';

  @override
  String get gameHowToPath => 'Двигай мяч к воротам стрелками или свайпом. Стены и конусы мешают пройти.';

  @override
  String get diffEasy => 'Лёгкий';

  @override
  String get diffMedium => 'Средний';

  @override
  String get diffHard => 'Сложный';

  @override
  String gameLevel(int level) {
    return 'Уровень $level';
  }

  @override
  String get gameStart => 'Начать игру';

  @override
  String get gamePause => 'Пауза';

  @override
  String get gameResume => 'Продолжить';

  @override
  String get gameRestart => 'Заново';

  @override
  String get gameQuit => 'Выйти';

  @override
  String get gamePaused => 'Игра на паузе';

  @override
  String gameScore(int score) {
    return 'Очки: $score';
  }

  @override
  String gameTime(String time) {
    return 'Время: $time';
  }

  @override
  String gameAttempts(int count) {
    return 'Попытки: $count';
  }

  @override
  String gameAccuracy(int percent) {
    return 'Точность: $percent%';
  }

  @override
  String get gameComplete => 'Отлично!';

  @override
  String get gameTryAgain => 'Хорошая попытка! Ещё раз?';

  @override
  String get gameNextLevel => 'Следующий уровень';

  @override
  String get gamePlayAgain => 'Играть ещё';

  @override
  String get gameNewBadge => 'Новый значок!';

  @override
  String gameBestScore(int score) {
    return 'Рекорд: $score';
  }

  @override
  String get gameCorrect => 'Верно!';

  @override
  String get gameWrong => 'Не совсем — продолжай';

  @override
  String get gameSaveFailed => 'Не удалось сохранить результат.';

  @override
  String gameRound(int n, int total) {
    return 'Раунд $n/$total';
  }

  @override
  String get gameWatch => 'Смотри внимательно…';

  @override
  String get gameYourTurn => 'Твоя очередь!';

  @override
  String gameLives(int n) {
    return 'Жизни: $n';
  }

  @override
  String gameMoves(int n) {
    return 'Ходы: $n';
  }

  @override
  String get gameSound => 'Звуковые эффекты';

  @override
  String get gameInstructions => 'Как играть';

  @override
  String get gameChooseDifficulty => 'Выбери сложность';

  @override
  String get gameTimeUp => 'Время вышло';

  @override
  String get logicWhatsMissing => 'Чего не хватает?';

  @override
  String get spQuestion => 'Мяч у тебя. Какой ход лучший?';

  @override
  String spPassTo(String n) {
    return 'Пас №$n';
  }

  @override
  String spPassBack(String n) {
    return 'Пас назад №$n';
  }

  @override
  String get spDribble => 'Обвести и идти вперёд';

  @override
  String get spShoot => 'Удар по воротам';

  @override
  String get spHold => 'Удержать мяч';

  @override
  String get spNext => 'Далее';

  @override
  String get spExplain1 => '№7 свободен на фланге — защитник прямо перед тобой, обводка рискованна.';

  @override
  String get spExplain2 => 'Ты близко к воротам и путь свободен — бей!';

  @override
  String get spExplain3 => 'Тебя прессингуют двое — безопасный пас назад №4 сохранит мяч.';

  @override
  String get spExplain4 => '№10 под опекой, а №11 в свободной зоне.';

  @override
  String get spExplain5 => 'Пас на №9 перехватят; №10 свободен и может развернуться.';

  @override
  String get spExplain6 => 'Слева соперник закрывает №5 — пас направо №6 безопасен.';

  @override
  String get spExplain7 => 'Центр закрыт двумя защитниками; №7 свободен на фланге.';

  @override
  String get spExplain8 => 'Угол слишком острый для удара, №9 закрыт; у №10 позиция лучше.';

  @override
  String get spExplain9 => 'В центре трое соперников — перевод на №2 открывает пространство.';

  @override
  String get mazeGoal => 'Ворота';

  @override
  String get mazeUp => 'Вверх';

  @override
  String get mazeDown => 'Вниз';

  @override
  String get mazeLeft => 'Влево';

  @override
  String get mazeRight => 'Вправо';

  @override
  String get brainProgressTitle => 'Мой прогресс';

  @override
  String brainPlays(int n) {
    return 'Сыграно игр: $n';
  }

  @override
  String get brainNoPlays => 'Ещё не играл(а)';

  @override
  String get brainRecentScores => 'Последние очки';

  @override
  String get brainBadges => 'Значки';

  @override
  String brainUnlocked(String level) {
    return 'Открыто: $level';
  }

  @override
  String get badgeFirstGame => 'Первая игра';

  @override
  String get badgeExplorer => 'Исследователь всех игр';

  @override
  String get badgeTenCompleted => '10 завершённых игр';

  @override
  String get badgeMemoryHard => 'Чемпион памяти';

  @override
  String get badgePerfectLogic => 'Безупречная логика';

  @override
  String get badgeTactician => 'Тактик';

  @override
  String get badgeQuickReflexes => 'Молниеносная реакция';

  @override
  String get badgeSequenceSeven => 'Последовательность из семи';

  @override
  String get badgeMazeHard => 'Мастер лабиринтов';

  @override
  String get coachChallengesTitle => 'Задания Академии ума';

  @override
  String get challengeAssign => 'Дать задание';

  @override
  String get challengeGame => 'Игра';

  @override
  String get challengeDifficulty => 'Сложность';

  @override
  String get challengeDueDate => 'Срок (необязательно)';

  @override
  String get challengeNoDue => 'Без срока';

  @override
  String get challengeAssigned => 'Задание выдано';

  @override
  String get challengeRemove => 'Удалить';

  @override
  String challengeCompletion(int done, int total) {
    return 'Выполнили: $done/$total';
  }

  @override
  String get challengeEmpty => 'Заданий пока нет';

  @override
  String get challengeOpenAction => 'Играть';

  @override
  String get validationDueInPast => 'Срок не может быть в прошлом.';

  @override
  String get brainParentNote => 'Очки отражают практику, а не интеллект.';

  @override
  String get brainSettingsTitle => 'Настройки игры';

  @override
  String get settingsHaptics => 'Вибрация';

  @override
  String get fbWrongTitle => 'Неверно';

  @override
  String get hudScore => 'Очки';

  @override
  String get hudTime => 'Время';

  @override
  String hudStreak(int n) {
    return 'Серия ×$n';
  }

  @override
  String hudProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get resultLevelComplete => 'Уровень пройден!';

  @override
  String get resultNewHighScore => 'Новый рекорд!';

  @override
  String resultNextUnlocked(int level) {
    return 'Открыт уровень $level';
  }

  @override
  String get resultChallengeDone => 'Задание тренера выполнено!';

  @override
  String get resultBackToAcademy => 'Назад в Академию ума';

  @override
  String get resultTryEasier => 'Попробовать полегче';

  @override
  String get resultFailTitle => 'Почти получилось!';

  @override
  String get resultFailEncourage => 'Каждая попытка тренирует ум. Попробуешь ещё раз?';

  @override
  String resultStars(int n) {
    return '$n из 3 звёзд';
  }

  @override
  String get resultRetry => 'Ещё раз';

  @override
  String get failOutOfLives => 'Закончились жизни.';

  @override
  String get failLowAccuracy => 'Верных ответов меньше половины.';

  @override
  String get failTooSlow => 'В нескольких раундах не хватило времени.';

  @override
  String get objMemory => 'Цель: найти все пары.';

  @override
  String get objLogic => 'Цель: решить 8 головоломок.';

  @override
  String get objSmart => 'Цель: выбрать верный ход в игровых ситуациях.';

  @override
  String get objQuick => 'Цель: быстро найти цель в 12 раундах.';

  @override
  String get objSequence => 'Цель: повторить 5 последовательностей.';

  @override
  String get objPath => 'Цель: довести мяч до ворот.';

  @override
  String get diffEasyHint => 'Спокойный темп';

  @override
  String get diffMediumHint => 'Чуть сложнее';

  @override
  String get diffHardHint => 'Для чемпионов';

  @override
  String levelsUnlocked(int level) {
    return 'Открыто до уровня $level';
  }

  @override
  String logicWhyRepeat(int n) {
    return 'Ряд повторяется через каждые $n фигуры.';
  }

  @override
  String get logicWhyGrow => 'С каждым шагом фигур становится больше.';

  @override
  String get logicWhyMissing => 'Посмотри на фигуры до и после «?» — ряд повторяется.';

  @override
  String get logicCorrectWas => 'Правильный ответ отмечен зелёным.';

  @override
  String get gameNext => 'Далее';

  @override
  String get spCoachSays => 'Совет тренера';

  @override
  String get spYourChoice => 'Твой выбор';

  @override
  String get spBestChoice => 'Лучший выбор';

  @override
  String get quickTooSlow => 'Слишком медленно!';

  @override
  String get quickHurry => 'Быстрее!';

  @override
  String quickReaction(String time) {
    return 'Реакция: $time с';
  }

  @override
  String get seqRepeatHint => 'Теперь нажми в том же порядке';

  @override
  String get seqRoundDone => 'Последовательность верна!';

  @override
  String get seqMistake => 'Ой! Посмотри ещё раз.';

  @override
  String get mazeBlocked => 'Путь закрыт!';

  @override
  String get mazeStart => 'Старт';

  @override
  String get memoryPair => 'Пара!';

  @override
  String get memoryNoPair => 'Не пара';

  @override
  String comboLabel(int n) {
    return 'Комбо ×$n!';
  }

  @override
  String get rsvpTitleMatch => 'Придёт на матч?';

  @override
  String get scheduleChangedTitle => 'Расписание изменилось';

  @override
  String scheduleChangedBody(String when) {
    return 'Новое время: $when. Пожалуйста, подтвердите участие ещё раз.';
  }

  @override
  String get ackIsNotRsvp =>
      '«Ознакомлен(а)» лишь подтверждает, что вы прочитали изменение, — это не ответ об участии ребёнка.';

  @override
  String get ackButton => 'Ознакомлен(а)';

  @override
  String get ackDone => 'Отмечено как прочитанное';

  @override
  String get rsvpNeedsReconfirm => 'Нужно подтвердить снова';

  @override
  String rsvpPreviousAnswer(String answer) {
    return 'Ваш ответ на прежнее расписание: $answer';
  }

  @override
  String get rsvpGuardiansDisagree => 'Опекуны ответили по-разному — учитывается последний ответ.';

  @override
  String get guardianLabel => 'Опекун';

  @override
  String get rsvpOldSchedule => 'старое расписание';

  @override
  String get rsvpStateConfirmed => 'Подтвердили';

  @override
  String get rsvpStateDeclined => 'Не придут';

  @override
  String get rsvpStateUncertain => 'Не уверены';

  @override
  String get rsvpStateNotResponded => 'Нет ответа';

  @override
  String get contactCoach => 'Связаться с тренером';

  @override
  String contactCoachTitle(String coach) {
    return 'Связаться: $coach';
  }

  @override
  String get contactCoachExplain =>
      'Твой родитель получит запрос и напишет или позвонит тренеру. Ты не переписываешься с тренером напрямую.';

  @override
  String get contactCoachSent => 'Родителю отправлена просьба связаться с тренером';

  @override
  String get contactCoachPending => 'Запрос отправлен родителю';

  @override
  String get contactTopicQuestion => 'У меня вопрос';

  @override
  String get contactTopicAbsence => 'Я не смогу прийти';

  @override
  String get contactTopicTraining => 'О тренировке';

  @override
  String get contactTopicOther => 'Другое';

  @override
  String get eventRescheduled => 'Перенесено';

  @override
  String get eventLocationChanged => 'Место изменилось';

  @override
  String get eventShowMap => 'Карта';

  @override
  String get studentUpcomingEvents => 'Ближайшие тренировки и матчи';

  @override
  String leaderboardTitle(String org) {
    return 'Рейтинг · $org';
  }

  @override
  String get leaderboardAllGames => 'Все игры';

  @override
  String get leaderboardWeek => 'Эта неделя';

  @override
  String get leaderboardMonth => 'Этот месяц';

  @override
  String get leaderboardAllTime => 'За всё время';

  @override
  String leaderboardAgeBand(String band) {
    return 'Возрастная группа $band';
  }

  @override
  String get leaderboardYou => 'ты';

  @override
  String leaderboardBadges(int count) {
    return 'Значков: $count';
  }

  @override
  String get leaderboardDisabled => 'Рейтинг сейчас недоступен. Твой прогресс показан выше.';

  @override
  String get leaderboardNoConsent =>
      'Ты появишься в рейтинге только с разрешения родителя. Твой личный прогресс показан выше.';

  @override
  String get leaderboardTooFew => 'В твоей возрастной группе пока мало участников. Твой прогресс показан выше.';

  @override
  String get leaderboardPrivacyNote =>
      'Показываются только псевдонимы или имя с инициалом. Очки — для игры и тренировки, они не измеряют интеллект.';

  @override
  String get pointsTotal => 'Очки';

  @override
  String get pointsGamesCompleted => 'Пройдено игр';

  @override
  String get pointsThisWeek => 'За неделю';

  @override
  String get pointsWeekly => 'Очки за последние 7 дней';

  @override
  String get pointsByGame => 'Очки по играм';

  @override
  String get pointsRecent => 'Последние игры';

  @override
  String pointsValue(int points) {
    return '$points оч.';
  }

  @override
  String pointsAccuracy(int percent) {
    return 'Точность $percent%';
  }

  @override
  String pointsBest(int score) {
    return 'лучший $score';
  }

  @override
  String get contactDone => 'Готово';

  @override
  String get contactOpenChat => 'Открыть чат с тренером';

  @override
  String contactRequestFromChild(String child, String coach) {
    return '$child просит связаться с тренером $coach';
  }

  @override
  String get leaderboardConsentTitle => 'Рейтинг Brain Academy';

  @override
  String get leaderboardConsentExplain =>
      'По умолчанию выключено. Если вы разрешите, ребёнок появится только в закрытом рейтинге этой академии — под псевдонимом или с именем и инициалом, без полного имени, телефона, даты рождения и данных о здоровье. Согласие можно отозвать в любой момент.';

  @override
  String get leaderboardConsentOn => 'Согласие сохранено';

  @override
  String get leaderboardConsentOff => 'Согласие отозвано — ребёнок больше не показывается';

  @override
  String get leaderboardConsentOffHint => 'Не показывается в рейтинге';

  @override
  String get leaderboardModePseudonym => 'Псевдоним';

  @override
  String get leaderboardModeInitial => 'Имя + инициал';

  @override
  String get orgSwitchTitle => 'Выберите академию';

  @override
  String get adminColSport => 'Спорт';

  @override
  String get adminNavOrganizations => 'Организации';

  @override
  String get adminNavOrgSettings => 'Настройки академии';

  @override
  String get adminNavPrograms => 'Программы';

  @override
  String get adminNavReports => 'Отчёты';

  @override
  String get adminNavRooms => 'Залы';

  @override
  String get adminNavSchedule => 'Расписание залов';

  @override
  String get adminNavSectionPlatform => 'Платформа';

  @override
  String get adminNavSectionTenant => 'Академия';

  @override
  String get bookingAllowGroupOverlap => 'У группы действительно два занятия одновременно — всё равно забронировать';

  @override
  String bookingAlternatives(String times) {
    return 'Свободное время в этот день: $times';
  }

  @override
  String get bookingCancel => 'Отменить бронь';

  @override
  String get bookingCancelFuture => 'Отменить это и все последующие';

  @override
  String get bookingCancelOccurrence => 'Отменить только это';

  @override
  String get bookingCancelled => 'Бронь отменена';

  @override
  String get bookingCoach => 'Тренер';

  @override
  String get bookingConflictsFound => 'Проверьте перед сохранением';

  @override
  String get bookingEdit => 'Изменить бронь';

  @override
  String bookingFreeRooms(String rooms) {
    return 'Свободные залы в это время: $rooms';
  }

  @override
  String get bookingGroup => 'Группа';

  @override
  String get bookingKind => 'Тип';

  @override
  String get bookingKindEvent => 'Мероприятие';

  @override
  String get bookingKindMaintenance => 'Обслуживание';

  @override
  String get bookingKindMatch => 'Матч';

  @override
  String get bookingKindTraining => 'Тренировка';

  @override
  String get bookingMoved => 'Бронь перенесена';

  @override
  String get bookingNew => 'Новая бронь';

  @override
  String get bookingRecurring => 'Повторять еженедельно';

  @override
  String get bookingRejected => 'Зал нельзя забронировать';

  @override
  String get bookingSaveFuture => 'Сохранить это и последующие';

  @override
  String get bookingSaveOccurrence => 'Сохранить только это';

  @override
  String get bookingSaved => 'Бронь сохранена';

  @override
  String bookingSeriesNote(int weeks) {
    return 'Перед сохранением проверяется каждое повторение (до $weeks недель вперёд).';
  }

  @override
  String get bookingTitle => 'Название';

  @override
  String get bookingTryInstead => 'Попробуйте вместо этого:';

  @override
  String bookingUntil(String date) {
    return 'До $date';
  }

  @override
  String get conflictCoachOverlap => 'Тренер в это время уже занят';

  @override
  String get conflictGroupOverlap => 'У группы в это время уже есть занятие';

  @override
  String get conflictInvalidRange => 'Окончание должно быть позже начала';

  @override
  String get conflictMaintenance => 'Зал закрыт на обслуживание';

  @override
  String get conflictOutsideHours => 'Вне часов работы зала';

  @override
  String get conflictOverCapacity => 'Людей больше, чем вмещает зал';

  @override
  String get conflictRoomNotBookable => 'Зал недоступен или в архиве';

  @override
  String get conflictRoomOverlap => 'Зал в это время уже забронирован';

  @override
  String get conflictTooLong => 'Бронь может длиться не более 12 часов';

  @override
  String get conflictWrongTenant => 'Зал принадлежит другой организации';

  @override
  String minutesShort(int minutes) {
    return '$minutes мин';
  }

  @override
  String get moduleAttendance => 'Посещаемость';

  @override
  String get moduleBrainAcademy => 'Brain Academy';

  @override
  String get moduleCommunication => 'Общение с родителями';

  @override
  String get moduleDisabledRooms =>
      'Расписание залов не включено для этой организации. Администратор платформы может разрешить его, затем включите его в настройках академии.';

  @override
  String get moduleDisabledTitle => 'Модуль выключен';

  @override
  String get moduleLeaderboards => 'Рейтинги';

  @override
  String get moduleMatches => 'Матчи';

  @override
  String get moduleMedia => 'Медиагалерея';

  @override
  String get moduleMedical => 'Медицинские справки';

  @override
  String get moduleNotifications => 'Уведомления';

  @override
  String get modulePayments => 'Платежи';

  @override
  String get moduleRoomScheduling => 'Расписание залов';

  @override
  String get moduleStudentAccounts => 'Аккаунты учеников';

  @override
  String get moduleTrainingPlans => 'Планы тренировок';

  @override
  String get moduleTrainings => 'Тренировки';

  @override
  String get none => 'Нет';

  @override
  String get orgAddCoach => 'Добавить тренера';

  @override
  String get orgAdminAssigned => 'Администратор назначен';

  @override
  String get orgAdminHelp => 'Этот человек сможет войти в админ-панель и управлять только этой организацией.';

  @override
  String get orgAdmins => 'Админы';

  @override
  String get orgAllowedModules => 'Модули, разрешённые платформой';

  @override
  String get orgAssignAdmin => 'Назначить администратора';

  @override
  String get orgBookingBuffer => 'Перерыв между бронями';

  @override
  String get orgBookingsWeek => 'Брони залов на 7 дней';

  @override
  String get orgBrainPlays => 'Игры Brain Academy (7 дней)';

  @override
  String get orgBrandColor => 'Цвет бренда';

  @override
  String get orgBranding => 'Бренд и контакты';

  @override
  String get orgCoaches => 'Тренеры';

  @override
  String get orgContactEmail => 'Контактный email';

  @override
  String get orgContactPhone => 'Контактный телефон';

  @override
  String get orgCreated => 'Организация создана';

  @override
  String get orgDefaultLanguage => 'Язык по умолчанию';

  @override
  String get orgDescription => 'Описание';

  @override
  String get orgHealth => 'Состояние организации';

  @override
  String orgInactiveBanner(String status) {
    return 'Статус организации: $status. Настройки только для чтения, создавать новое нельзя.';
  }

  @override
  String get orgLabel => 'Организация';

  @override
  String get orgLeaderboardByAge => 'Рейтинг только внутри возрастной группы';

  @override
  String get orgLeaderboardEnable => 'Включить рейтинг Brain Academy';

  @override
  String get orgLeaderboardMin => 'Минимум участников в рейтинге';

  @override
  String get orgLeaderboardNotAllowed => 'Платформа не разрешает рейтинги для этой организации.';

  @override
  String get orgLeaderboardPrivacy =>
      'Показываются только ученики с согласием опекуна — под псевдонимом или с именем и инициалом.';

  @override
  String get orgLeaderboardSettings => 'Рейтинг';

  @override
  String get orgLimitCoaches => 'Тренеры';

  @override
  String get orgLimitGroups => 'Группы';

  @override
  String get orgLimitRooms => 'Залы';

  @override
  String get orgLimitStudents => 'Ученики';

  @override
  String get orgLimits => 'Лимиты';

  @override
  String get orgLogoUrl => 'Ссылка на логотип';

  @override
  String get orgManage => 'Тариф, статус и модули';

  @override
  String get orgModules => 'Включённые модули';

  @override
  String get orgModulesHelp => 'Заблокированные модули сначала должен разрешить администратор платформы.';

  @override
  String get orgModulesOn => 'Модулей вкл.';

  @override
  String get orgNameEn => 'Название (англ.)';

  @override
  String get orgNameKa => 'Название (груз.)';

  @override
  String get orgNameRu => 'Название (рус.)';

  @override
  String get orgNew => 'Новая организация';

  @override
  String get orgNoneSelected => 'Нет организации для управления';

  @override
  String get orgOverLimit => 'Превышен один или несколько лимитов тарифа.';

  @override
  String get orgPickUser => 'Выберите пользователя';

  @override
  String get orgPlan => 'Тариф';

  @override
  String get orgPlatformSubtitle => 'Каждая спортшкола работает отдельно, со своими закрытыми данными.';

  @override
  String get orgRemoveAdmin => 'Снять администратора';

  @override
  String get orgRemoveCoach => 'Убрать';

  @override
  String get orgSaved => 'Сохранено';

  @override
  String get orgStatusActive => 'Активна';

  @override
  String get orgStatusDeactivated => 'Отключена';

  @override
  String get orgStatusHelp =>
      'Приостановлена или отключена: данные сохраняются и доступны для чтения, но все модули выключены и создавать новое нельзя.';

  @override
  String get orgStatusSuspended => 'Приостановлена';

  @override
  String get orgTimezone => 'Часовой пояс';

  @override
  String get orgUpcomingEvents => 'Предстоящие тренировки и матчи';

  @override
  String get orgUserId => '…или ID пользователя';

  @override
  String get planFree => 'Бесплатный';

  @override
  String get planPremium => 'Премиум';

  @override
  String get planStandard => 'Стандарт';

  @override
  String get programAges => 'Возраст';

  @override
  String get programCapacity => 'Мест';

  @override
  String get programNew => 'Новая программа';

  @override
  String get programPaused => 'Приостановлена';

  @override
  String get programScheduleNote => 'Заметка о расписании';

  @override
  String get reportAllGroups => 'Все группы';

  @override
  String get reportAttendance => 'Посещаемость';

  @override
  String get reportBrain => 'Brain Academy';

  @override
  String reportDays(int days) {
    return '$days дн.';
  }

  @override
  String get reportLastPlayed => 'Последняя игра';

  @override
  String get reportRsvp => 'Ответы родителей';

  @override
  String get reportWhen => 'Когда';

  @override
  String get roomAnySport => 'Любой спорт';

  @override
  String get roomCapacity => 'Вместимость';

  @override
  String get roomHours => 'Часы работы';

  @override
  String get roomLabel => 'Зал';

  @override
  String get roomMaintenance => 'Добавить обслуживание';

  @override
  String get roomNew => 'Новый зал';

  @override
  String get roomNone => 'Сначала добавьте зал';

  @override
  String get roomNote => 'Заметка';

  @override
  String get roomSports => 'Виды спорта (пусто = любой)';

  @override
  String get roomStatusActive => 'Доступен';

  @override
  String get roomStatusUnavailable => 'Временно недоступен';

  @override
  String get scheduleAllCoaches => 'Все тренеры';

  @override
  String get scheduleAllRooms => 'Все залы';

  @override
  String get scheduleAllSports => 'Все виды спорта';

  @override
  String scheduleBusy(int hours, int minutes) {
    return 'Занято $hours ч $minutes мин';
  }

  @override
  String get scheduleDay => 'День';

  @override
  String get scheduleFree => 'Свободно';

  @override
  String scheduleSubtitle(String tz) {
    return 'Время в поясе $tz. Нажмите на свободный слот, чтобы забронировать; перетащите бронь, чтобы перенести.';
  }

  @override
  String get scheduleWeek => 'Неделя';

  @override
  String sysEventRescheduled(String when) {
    return 'Расписание изменилось: $when. Пожалуйста, подтвердите участие ещё раз.';
  }

  @override
  String get sysEventRescheduledNoTime => 'Расписание изменилось. Пожалуйста, подтвердите участие ещё раз.';

  @override
  String get moduleParentRsvp => 'Ответы родителей';

  @override
  String get moduleMessageAcks => 'Подтверждение прочтения';

  @override
  String get moduleCoachChallenges => 'Задания тренера';

  @override
  String get modulePaymentReceipts => 'Квитанции об оплате';

  @override
  String get modulePaymentVerification => 'Проверка платежей';

  @override
  String get modulePaymentReminders => 'Напоминания об оплате';

  @override
  String get moduleFacilities => 'Объекты и залы';

  @override
  String get moduleReports => 'Отчёты';

  @override
  String get moduleDataExports => 'Экспорт данных';

  @override
  String get orgAllAcademies => 'Все академии';

  @override
  String get orgRoleAdmin => 'Администратор';

  @override
  String get orgRoleStudent => 'Ученик';

  @override
  String get accessFull => 'Полный доступ';

  @override
  String get accessGrace => 'Льготный период';

  @override
  String get accessLabel => 'Доступ';

  @override
  String get accessReadOnly => 'Только чтение';

  @override
  String get addDependencies => 'Включить необходимые функции';

  @override
  String addDependenciesConfirm(String features) {
    return 'Также будут включены: $features';
  }

  @override
  String get adminEmailLabel => 'Email администратора';

  @override
  String get adminNavFeatureCatalog => 'Каталог функций';

  @override
  String get adminNavHealth => 'Состояние системы';

  @override
  String get adminNavInvitations => 'Приглашения';

  @override
  String get adminNavMembers => 'Участники';

  @override
  String get adminNavPackages => 'Пакеты';

  @override
  String get adminNavTemplates => 'Шаблоны организаций';

  @override
  String get adminNavOverview => 'Обзор';

  @override
  String get adminNavPlatformUsers => 'Пользователи платформы';

  @override
  String get adminPhoneLabel => 'Телефон администратора';

  @override
  String get alertInvitationExpiring => 'Срок приглашения истекает';

  @override
  String get alertOverLimit => 'Превышен лимит пакета';

  @override
  String get alertPastDue => 'Оплата просрочена';

  @override
  String get alertProvisioning => 'Создание не завершено';

  @override
  String get alertReadOnly => 'Организация в режиме чтения';

  @override
  String get alertTrialEnding => 'Пробный период скоро закончится';

  @override
  String get applyTemplate => 'Применить шаблон';

  @override
  String get applyTemplateNote =>
      'Перед применением шаблона к существующей организации показывается предпросмотр. Исторические данные не удаляются.';

  @override
  String get archive => 'Архивировать';

  @override
  String get back => 'Назад';

  @override
  String get brandingManagedByOrg => 'Брендинг редактирует администратор организации в настройках организации.';

  @override
  String get bulkPresets => 'Пресеты';

  @override
  String get changePreview => 'Изменения';

  @override
  String get changeReasonHint => 'Причина изменения (обязательно)';

  @override
  String get changeReasonTitle => 'Причина изменения';

  @override
  String configConflict(int version) {
    return 'Кто-то уже сохранил более новую версию ($version). Обновите и внесите изменения снова.';
  }

  @override
  String get configConflictTitle => 'Конфигурация изменилась';

  @override
  String get configHistory => 'История конфигурации';

  @override
  String contrastRatio(String ratio) {
    return 'Контраст с белым текстом: $ratio:1 (минимум 4.5:1)';
  }

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get customLabel => 'Индивидуальный';

  @override
  String get customPackageNote => 'Доступны все функции; права задаются для каждой организации.';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get durationDays => 'Длительность (дней)';

  @override
  String get effDependencyMissing => 'Зависимость выключена';

  @override
  String get effDisabledByOrg => 'Выключено организацией';

  @override
  String get effNotEntitled => 'Не разрешено';

  @override
  String get effNotInPackage => 'Не входит в пакет';

  @override
  String get effOn => 'Активно';

  @override
  String get effOrgInactive => 'Организация неактивна';

  @override
  String get effProvisioning => 'Создаётся';

  @override
  String get effReadOnly => 'Подписка только для чтения';

  @override
  String get effRolloutOff => 'Развёртывание неактивно';

  @override
  String get errBrandContrast => 'Этот цвет плохо читается с белым текстом. Выберите более тёмный.';

  @override
  String get errChangeReason => 'Укажите причину изменения.';

  @override
  String get errFeatureDependencies => 'Некоторым функциям нужны выключенные функции.';

  @override
  String get errInvitationClosed => 'Это приглашение больше не действует.';

  @override
  String get errInvitationExpired => 'Срок приглашения истёк. Запросите новое.';

  @override
  String get errLimitReached => 'Достигнут лимит пакета.';

  @override
  String get errNotInPackage => 'Выбранная функция не входит в пакет.';

  @override
  String get errOrgAddress => 'Укажите адрес и город.';

  @override
  String get errOrgAdmin => 'Укажите телефон или email первого администратора.';

  @override
  String get errOrgEmail => 'Укажите корректный email.';

  @override
  String get errOrgName => 'Укажите название и юридическое название.';

  @override
  String get errOrgPhone => 'Укажите корректный телефон.';

  @override
  String get errOrgSports => 'Выберите хотя бы один вид спорта.';

  @override
  String get errRolloutDate => 'Выберите дату для пробного или запланированного запуска.';

  @override
  String get featCatAdministration => 'Администрирование';

  @override
  String get featCatCommunication => 'Коммуникация';

  @override
  String get featCatCore => 'Основное';

  @override
  String get featCatFacilities => 'Помещения';

  @override
  String get featCatFinance => 'Финансы';

  @override
  String get featCatLearning => 'Обучение';

  @override
  String get featCategory => 'Категория';

  @override
  String get featureAdoption => 'Использование функций';

  @override
  String get featureCatalogSubtitle => 'Все модули с постоянным id, зависимостями и использованием.';

  @override
  String get fundGovernment => 'Государственная';

  @override
  String get fundMixed => 'Смешанная';

  @override
  String get fundNonprofit => 'Некоммерческая';

  @override
  String get fundOther => 'Другое';

  @override
  String get fundPrivate => 'Частная';

  @override
  String get fundingNote => 'Тип финансирования сам по себе не включает платежи; функции задаются явно.';

  @override
  String get graceDays => 'Льготный период (дней)';

  @override
  String get haveInvitation => 'Есть приглашение администратора?';

  @override
  String get healthDaily => 'ежедневно';

  @override
  String get healthJobGated => 'пропускает организации, где функция выключена';

  @override
  String get healthJobs => 'Плановые задачи';

  @override
  String get inPackage => 'В пакете';

  @override
  String get initialFeatures => 'Начальные функции';

  @override
  String get invAccepted => 'Принято';

  @override
  String get invExpired => 'Истекло';

  @override
  String get invPending => 'Ожидает';

  @override
  String get invRejected => 'Отклонено';

  @override
  String get invRevoked => 'Отозвано';

  @override
  String get invitationAcceptButton => 'Принять';

  @override
  String get invitationAcceptedSnack => 'Приглашение принято. Теперь вы администратор.';

  @override
  String get invitationCreated => 'Приглашение создано';

  @override
  String get invitationLinkNote => 'Отправьте эту ссылку администратору. Она показывается один раз и действует 7 дней.';

  @override
  String get invitationNote =>
      'Администратор получит приглашение на 7 дней. Он входит с этим телефоном или email и принимает его.';

  @override
  String get invitationRejectButton => 'Отклонить';

  @override
  String get invitationRejectedSnack => 'Приглашение отклонено.';

  @override
  String get invitationTokenLabel => 'Код приглашения';

  @override
  String get inviteAdmin => 'Пригласить администратора';

  @override
  String get inviteExpires => 'Истекает';

  @override
  String get inviteRecipient => 'Получатель';

  @override
  String get inviteResend => 'Отправить снова';

  @override
  String get lastChange => 'Последнее изменение';

  @override
  String get limitNotifications => 'Уведомления за месяц';

  @override
  String get limitSms => 'SMS за месяц';

  @override
  String get limitStorage => 'Хранилище (МБ)';

  @override
  String get membersPrivacyNote =>
      'Здесь показаны только количества и названия групп; личные данные остаются в организации.';

  @override
  String missingDependencies(String features) {
    return 'Не хватает нужных функций для: $features';
  }

  @override
  String get noAlerts => 'Нет предупреждений';

  @override
  String get noChanges => 'Изменений нет';

  @override
  String get operationalAlerts => 'Оперативные предупреждения';

  @override
  String get orgCity => 'Город';

  @override
  String get orgCreateButton => 'Создать организацию';

  @override
  String get orgFunding => 'Финансирование';

  @override
  String get orgLegalName => 'Юридическое название';

  @override
  String get orgProvisioned => 'Организация создана';

  @override
  String get orgRegistrationId => 'Регистрационный номер';

  @override
  String get orgTypeAcademy => 'Детская академия';

  @override
  String get orgTypeClub => 'Спортивный клуб';

  @override
  String get orgTypeIndependent => 'Независимый тренер';

  @override
  String get orgTypeLabel => 'Тип организации';

  @override
  String get orgTypeOther => 'Другое';

  @override
  String get orgTypeSchool => 'Спортивная школа';

  @override
  String get packageLabel => 'Пакет';

  @override
  String get packageNew => 'Новый пакет';

  @override
  String get packagesSubtitle => 'Наборы функций, лимиты и ориентировочные цены. Платёжная система не подключена.';

  @override
  String get platformOverview => 'Обзор платформы';

  @override
  String get platformOverviewSubtitle => 'Все организации, подписки и использование функций.';

  @override
  String get priceLabel => 'Цена';

  @override
  String get recentAdminActions => 'Последние действия администраторов';

  @override
  String refreshDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Обновлено $count организаций',
      few: 'Обновлены $count организации',
      one: 'Обновлена $count организация',
      zero: 'Ни одна организация не изменилась',
    );
    return '$_temp0';
  }

  @override
  String get requiresLabel => 'Требует';

  @override
  String get restore => 'Восстановить';

  @override
  String get restrictedLabel => 'Ограничено';

  @override
  String get rolloutDisabled => 'Выключено';

  @override
  String get rolloutEnabled => 'Включено';

  @override
  String get rolloutFrom => 'с';

  @override
  String get rolloutScheduled => 'Запланировано';

  @override
  String get rolloutTrial => 'Пробно';

  @override
  String get rolloutUntil => 'до';

  @override
  String get runEntitlementRefresh => 'Обновить права';

  @override
  String get statOrganizations => 'Организации';

  @override
  String get statParents => 'Родители';

  @override
  String get statStudents => 'Ученики';

  @override
  String get statUsers => 'Пользователи';

  @override
  String get subActive => 'Активна';

  @override
  String get subCancelled => 'Отменена';

  @override
  String get subExpired => 'Истекла';

  @override
  String get subPastDue => 'Просрочена';

  @override
  String get subSuspended => 'Приостановлена';

  @override
  String get subTrial => 'Пробная';

  @override
  String get subscriptionEnds => 'Заканчивается';

  @override
  String get subscriptionLabel => 'Подписка';

  @override
  String get subscriptionPolicyNote =>
      'В режиме чтения все записи сохраняются; ничего не удаляется. Управляется вручную — списаний нет.';

  @override
  String get subscriptionsSubtitle => 'Статус, дата окончания и доступ каждой организации.';

  @override
  String get subscriptionsTitle => 'Подписки';

  @override
  String get syntheticData => 'Демо-данные';

  @override
  String get tabAdmins => 'Админы и участники';

  @override
  String get tabAudit => 'История аудита';

  @override
  String get tabBranding => 'Брендинг';

  @override
  String get tabFeatures => 'Функции';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get tabSubscription => 'Подписка';

  @override
  String get tabUsage => 'Лимиты и использование';

  @override
  String get templateLabel => 'Шаблон';

  @override
  String get templateNew => 'Новый шаблон';

  @override
  String get unsavedChanges => 'Есть несохранённые изменения';

  @override
  String get usageSyntheticNote => 'Объём хранилища и число сообщений в демо-режиме приблизительны.';

  @override
  String get adminNavActivity => 'Активность';

  @override
  String get pickerSearchHint => 'Поиск…';

  @override
  String get pickerClearSearch => 'Очистить поиск';

  @override
  String pickerSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано $count',
      few: 'Выбрано $count',
      one: 'Выбран $count',
      zero: 'Ничего не выбрано',
    );
    return '$_temp0';
  }

  @override
  String get pickerSelectAll => 'Выбрать все';

  @override
  String get pickerClearAll => 'Снять все';

  @override
  String get pickerRemove => 'Убрать';

  @override
  String get pickerNoOptions => 'Пока не из чего выбрать.';

  @override
  String pickerNoResults(String query) {
    return 'По запросу «$query» ничего нет. Попробуйте иначе.';
  }

  @override
  String pickerDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Готово ($count)', zero: 'Готово');
    return '$_temp0';
  }

  @override
  String get pickerChoose => 'Выберите…';

  @override
  String get pickerGroupFree => 'Свободны в это время';

  @override
  String get pickerGroupBusy => 'Заняты в это время';

  @override
  String wizardStepOf(int step, int total, String name) {
    return 'Шаг $step из $total: $name';
  }

  @override
  String get adminNavSecCatalog => 'Каталог и контент';

  @override
  String get adminNavSecPeople => 'Люди';

  @override
  String get adminNavSecPrograms => 'Спорт и программы';

  @override
  String get adminNavSecCalendar => 'Календарь и помещения';

  @override
  String get adminNavSecCommunication => 'Коммуникация';

  @override
  String get adminNavSecFinanceReports => 'Платежи и отчёты';

  @override
  String get adminNavSecOrganization => 'Организация';

  @override
  String get adminOrgContext => 'Разделы ниже относятся к этой организации';

  @override
  String get adminSwitchOrg => 'Сменить организацию';

  @override
  String featureOffTitle(String feature) {
    return '$feature: выключено для этой организации';
  }

  @override
  String get featureOffBodyOrg =>
      'Ничего не потеряно — записи сохранены. Включите функцию в настройках организации, если она входит в пакет; иначе обратитесь к администратору платформы.';

  @override
  String get featureOffBodyPlatform =>
      'Записи сохранены. Разрешить функцию можно на вкладке «Функции» этой организации.';

  @override
  String get featureOffOpenSettings => 'Настройки организации';

  @override
  String get featureOffOpenOrg => 'Открыть функции организации';

  @override
  String get errRequiredField => 'Обязательное поле';

  @override
  String get errCapacity => 'Введите число от 1 до 2000';

  @override
  String get roomOpensAt => 'Открывается';

  @override
  String get roomClosesAt => 'Закрывается';

  @override
  String get roomClosed => 'Закрыто';

  @override
  String get roomSameHours => 'Одинаковые часы каждый день';

  @override
  String get roomCapacityHint => 'Сколько человек помещение вмещает безопасно';

  @override
  String get roomSportsHint => 'Для других видов спорта будет предупреждение';

  @override
  String get roomCreated => 'Помещение добавлено';

  @override
  String get roomCreate => 'Добавить помещение';

  @override
  String get roomEdit => 'Изменить помещение';

  @override
  String get formBasics => 'Основное';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get confirmRemoveAdminBody =>
      'Доступ к управлению этой организацией будет сразу закрыт. Другие роли сохранятся.';

  @override
  String get adminRemovedSnack => 'Администратор удалён';

  @override
  String confirmOrgStatusTitle(String status) {
    return 'Изменить статус на «$status»?';
  }

  @override
  String get confirmOrgSuspendBody =>
      'Все участники организации сразу теряют возможность что-либо создавать или менять. Данные сохраняются, организацию можно активировать снова.';

  @override
  String get confirmOrgActivateBody => 'Участники снова получат доступ к включённым функциям.';

  @override
  String get navChildren => 'Дети';

  @override
  String get navMessages => 'Сообщения';

  @override
  String get navMore => 'Ещё';

  @override
  String get navSchedule => 'Расписание';

  @override
  String get navGroups => 'Группы';

  @override
  String get navMySchedule => 'Моё расписание';

  @override
  String get navFindClubs => 'Найти клубы на карте';

  @override
  String get hubNoChildrenBody =>
      'Добавьте ребёнка, чтобы вступить в группу, подтверждать тренировки и следить за прогрессом.';

  @override
  String get hubChildProfile => 'Профиль';

  @override
  String get hubChildProgress => 'Прогресс';

  @override
  String get hubChildDocuments => 'Медицинские справки';

  @override
  String get hubNoGroupsTitle => 'Групп пока нет';

  @override
  String get hubNoGroupsBody => 'Создайте группу по вашему виду спорта и пригласите семьи по коду.';

  @override
  String get hubNextSession => 'Следующее занятие';

  @override
  String get hubTakeAttendance => 'Отметить посещаемость';

  @override
  String get signOutConfirmTitle => 'Выйти?';

  @override
  String get signOutConfirmBody => 'Для повторного входа понадобится новый SMS-код.';
}
