import '../../authentication/domain/app_user.dart';
import '../../chat/data/demo_chat_repository.dart';
import '../../chat/domain/chat_message.dart';
import 'demo_backend.dart';
import 'demo_seed.dart';

/// v1.4 demo data (all fictional, 555-range phone numbers):
/// - a second guardian (father) for Luka, with recorded relations;
/// - coach messages with read receipts, one requiring acknowledgment
///   (Eka has acknowledged, Ana's parent has only seen it, Nino and Davit
///   have not responded yet);
/// - the basketball group has parent downloads turned off (media policy);
/// - one logged media download for the admin audit page.
class DemoSeedV14 {
  DemoSeedV14._();

  static const secondGuardian = 'parent-5';
  static const ackMessage = 'msg-ack-1';
  static const infoMessage = 'msg-info-1';

  static void seed(DemoBackend db) {
    final now = db.clock();

    // ── Multiple guardians ──────────────────────────────────────────────
    db.users[secondGuardian] = AppUser(
      id: secondGuardian,
      role: UserRole.parent,
      firstName: 'დავით',
      lastName: 'ბერიძე',
      phone: '+995555000105',
      createdAt: now.subtract(const Duration(days: 120)),
      dataConsentAt: now.subtract(const Duration(days: 120)),
      smsConsentAt: now.subtract(const Duration(days: 120)),
    );
    final luka = db.children['child-1'];
    if (luka != null) {
      db.children['child-1'] = luka.copyWith(parentIds: [...luka.parentIds, secondGuardian]);
    }
    db.guardianRelations['child-1'] = {DemoIds.parent: 'mother', secondGuardian: 'father'};
    db.guardianRelations['child-4'] = {'parent-2': 'mother'};
    db.guardianRelations['child-7'] = {'parent-3': 'grandparent'};
    // group.parentIds is derived from the members' parents (server trigger).
    for (final g in db.groups.values.toList()) {
      final parents = <String>{for (final c in g.memberChildIds) ...?db.children[c]?.parentIds}.toList();
      db.groups[g.id] = g.copyWith(parentIds: parents);
    }

    // ── Media policy: downloads off for the basketball group ────────────
    final basket = db.groups['g-basket-u13'];
    if (basket != null) db.groups[basket.id] = basket.copyWith(mediaDownloadsEnabled: false);

    // ── Read receipts / acknowledgment ──────────────────────────────────
    final u10 = db.groups['g-football-u10'];
    final coach = db.users[DemoIds.coach];
    if (u10 != null && coach != null) {
      final msgs = db.messages[u10.id] ??= [];
      final info = ChatMessage(
        id: infoMessage,
        groupId: u10.id,
        senderId: coach.id,
        senderName: coach.fullName,
        senderRole: UserRole.coach,
        text: 'შაბათს ფორმა — ლურჯი მაისური. გთხოვთ, წყალი არ დაგავიწყდეთ 💧',
        createdAt: now.subtract(const Duration(hours: 20)),
      );
      final ack = ChatMessage(
        id: ackMessage,
        groupId: u10.id,
        senderId: coach.id,
        senderName: coach.fullName,
        senderRole: UserRole.coach,
        text: 'ყურადღება: შაბათის ამხანაგური გადაიტანეს 10:00 საათზე, დახურულ დარბაზში. გთხოვთ, დაადასტუროთ.',
        createdAt: now.subtract(const Duration(hours: 3)),
        type: ChatMessageType.announcement,
        pinned: true,
        requiresAck: true,
      );
      msgs
        ..addAll([info, ack])
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      // Snapshot every coach message (as the server does on creation).
      for (final g in db.groups.values) {
        for (final m in db.messages[g.id] ?? const <ChatMessage>[]) {
          if (m.senderRole == UserRole.coach && !m.isSystem && !db.msgRecipients.containsKey(m.id)) {
            DemoChatRepository.snapshotRecipients(db, g, m);
          }
        }
      }
      DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
      db.msgReads[infoMessage] = {'parent-2': ago(1100), 'parent-3': ago(900), DemoIds.parent: ago(800)};
      db.msgReads[ackMessage] = {'parent-2': ago(150), 'parent-3': ago(120)};
      db.msgAcks[ackMessage] = {'parent-2': ago(148)};
    }

    // ── One logged download (admin audit page) ──────────────────────────
    db.mediaDownloads.add(
      MediaDownloadEvent(
        postId: 'post-1',
        userId: 'parent-2',
        role: 'parent',
        groupId: 'g-football-u10',
        clubId: 'club-1',
        mediaType: 'photo',
        at: now.subtract(const Duration(days: 1)),
      ),
    );
  }
}
