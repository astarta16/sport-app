import 'dart:async';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/domain/app_user.dart';
import '../../chat/domain/chat_message.dart';
import '../../children/domain/child.dart';
import '../../clubs/domain/club.dart';
import '../../groups/domain/group.dart';
import '../../medical_certificates/domain/medical_certificate.dart';
import '../../notifications/domain/notification_models.dart';
import '../../payments/domain/payment.dart';
import '../../sports/domain/sport.dart';
import '../../trainings/domain/training.dart';

/// In-memory stand-in for Firestore + Storage + Cloud Functions used by
/// DEMO MODE. Every demo repository goes through it and it enforces the
/// same [AccessPolicy] as the production rules, so demo behaviour matches
/// production authorization. It holds only fictional data and is never
/// constructed when the app runs in Firebase mode (see `bootstrap.dart`).
class DemoBackend {
  DemoBackend({DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final DateTime Function() clock;

  final users = <String, AppUser>{};
  final children = <String, Child>{};
  final sports = <String, Sport>{};
  final clubs = <String, Club>{};
  final venues = <String, Venue>{};
  final groups = <String, Group>{};
  final trainings = <String, Training>{};
  final certificates = <String, MedicalCertificate>{};
  final certificateFiles = <String, Uint8List>{};
  final accessLog = <CertificateAccessEntry>[];
  final messages = <String, List<ChatMessage>>{};
  final notifications = <AppNotification>[];
  final requests = <String, MembershipRequest>{};
  final payments = <String, Payment>{};
  final plans = <String, PaymentPlan>{};
  final smsLog = <SmsLogEntry>[];

  /// Uploaded photo bytes keyed by `demo-mem://<id>`.
  final photos = <String, Uint8List>{};

  /// Signed-in identity (uid + phone); the profile lives in [users].
  ({String uid, String phone})? session;

  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  String newId(String prefix) => '$prefix-${++_seq}';

  /// Call after every mutation so watchers re-emit.
  void commit() => _changes.add(null);

  /// Re-evaluates [read] on every commit. Errors (e.g. permission denied)
  /// are delivered as stream errors.
  Stream<T> watch<T>(T Function() read) {
    late StreamController<T> controller;
    StreamSubscription<void>? sub;
    void emit() {
      try {
        controller.add(read());
      } catch (e, st) {
        controller.addError(e, st);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        emit();
        sub = _changes.stream.listen((_) => emit());
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  AppUser? get currentUser => session == null ? null : users[session!.uid];

  AppUser get me {
    final u = currentUser;
    if (u == null) throw const AuthException('not-signed-in');
    return u;
  }

  Iterable<Group> groupsOfChild(String childId) => groups.values.where((g) => g.hasChild(childId));

  Child requireChild(String id) => children[id] ?? (throw NotFoundException('child $id'));
  Group requireGroup(String id) => groups[id] ?? (throw NotFoundException('group $id'));

  /// Server-side trigger equivalent: keeps `group.parentIds` and
  /// `child.groupIds` consistent with `memberChildIds`.
  void recomputeMemberships() {
    for (final g in groups.values.toList()) {
      final parents = <String>{for (final cid in g.memberChildIds) ...?children[cid]?.parentIds}.toList();
      groups[g.id] = g.copyWith(parentIds: parents);
    }
    for (final c in children.values.toList()) {
      final ids = groups.values.where((g) => g.hasChild(c.id)).map((g) => g.id).toList();
      children[c.id] = c.copyWith(groupIds: ids);
    }
  }

  /// Cloud-Function equivalent of a push fan-out with role-based recipient
  /// selection and per-user preferences.
  void dispatch(
    NotificationType type,
    Group group, {
    String? route,
    Map<String, String> args = const {},
    String? excludeUserId,
    Set<String>? onlyParentIds,
  }) {
    final recipients = AccessPolicy.notificationRecipients(
      type: type,
      group: group,
      users: users.values,
      excludeUserId: excludeUserId,
      onlyParentIds: onlyParentIds,
    );
    for (final u in recipients) {
      notifications.add(
        AppNotification(
          id: newId('ntf'),
          userId: u.id,
          type: type,
          title: '',
          body: '',
          createdAt: clock(),
          route: route,
          args: {'group': group.name, ...args},
        ),
      );
    }
  }
}
