/// Route paths in one place.
class Routes {
  Routes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const register = '/auth/register';
  static const coachPending = '/auth/pending';
  static const childUnsupported = '/auth/child';
  static const explore = '/explore';

  static const parentHome = '/parent/home';
  static const parentCalendar = '/parent/calendar';
  static const parentChat = '/parent/chat';
  static const parentMap = '/parent/map';
  static const parentProfile = '/parent/profile';

  static const coachHome = '/coach/home';
  static const coachCalendar = '/coach/calendar';
  static const coachChat = '/coach/chat';
  static const coachMap = '/coach/map';
  static const coachProfile = '/coach/profile';

  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const settings = '/settings';
  static const payments = '/payments';
  static const newChild = '/children/new';

  static String training(String id) => '/training/$id';
  static String editTraining(String id) => '/training/$id/edit';
  static String newTraining(String groupId) => '/training/new?groupId=$groupId';
  static String chat(String groupId) => '/chat/$groupId';
  static String child(String id) => '/children/$id';
  static String certificates(String childId) => '/certificates/$childId';
  static String uploadCertificate(String childId) => '/certificates/$childId/upload';
  static String roster(String groupId) => '/group/$groupId';
  static String groupPayments(String groupId) => '/group/$groupId/payments';
  static String club(String id) => '/club/$id';
}
