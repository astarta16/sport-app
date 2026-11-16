import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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

  /// v1.6 student area (demo mode only).
  static const studentHome = '/kid/home';
  static String brainGame(String game) => '/kid/brain/$game';
  static const explore = '/explore';

  static const parentHome = '/parent/home';
  static const parentCalendar = '/parent/calendar';

  /// Legacy v1.0 tab paths; redirect to [chats] (chat moved to the top bar in v1.1).
  static const parentChat = '/parent/chat';
  static const parentMap = '/parent/map';
  static const parentProfile = '/parent/profile';

  static const coachHome = '/coach/home';
  static const coachCalendar = '/coach/calendar';
  static const coachChat = '/coach/chat';
  static const coachMap = '/coach/map';
  static const coachProfile = '/coach/profile';

  static const chats = '/chats';
  static const calendar = '/calendar';
  static const adminOnly = '/admin-only';
  static const invites = '/invites';
  static const account = '/account';
  static const privacy = '/account/privacy';
  static const newGroup = '/group/new';
  static const newMedia = '/media/new';
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
  static String match(String id) => '/match/$id';
  static String newMatch(String groupId) => '/match/new?groupId=$groupId';
  static String editMatch(String id) => '/match/$id/edit';
  static String newSeries(String groupId) => '/series/new?groupId=$groupId';
  static String editSeries(String id, String from) => '/series/$id/edit?from=$from';
  static String attendance(String trainingId) => '/training/$trainingId/attendance';
  static String progress(String childId) => '/children/$childId/progress';
  static String media(String id) => '/media/$id';
  static String newMediaFor(String groupId) => '/media/new?groupId=$groupId';
  static String inviteChild(String groupId) => '/group/$groupId/invite';
  static const plans = '/plans';
  static const paymentReview = '/payments/review';
  static String students([String? groupId]) => groupId == null ? '/students' : '/students?groupId=$groupId';
  static String plan(String id) => '/plans/$id';
  static String editPlan(String id) => '/plans/$id/edit';
  static String newPlan([String? groupId]) => groupId == null ? '/plans/new' : '/plans/new?groupId=$groupId';
  static String paymentProof(String paymentId) => '/payments/$paymentId/proof';
}

/// Pops when there is a page to return to; otherwise (opened by a deep link
/// or notification) goes to the user's home instead of crashing.
extension SafePop on BuildContext {
  void popOrHome() {
    if (canPop()) {
      pop();
    } else {
      go(Routes.splash);
    }
  }
}
