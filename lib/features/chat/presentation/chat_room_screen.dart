import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../media/presentation/media_providers.dart';
import '../domain/chat_message.dart';
import '../domain/receipts.dart';
import '../../moderation/domain/report.dart';
import '../../moderation/presentation/report_dialog.dart';
import 'chat_providers.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.groupId, this.embedded = false});

  final String groupId;

  /// Rendered as the detail pane of the tablet master-detail chat layout
  /// (no route, no back button).
  final bool embedded;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _text = TextEditingController();
  bool _sending = false;
  bool _announcement = false;
  bool _requiresAck = false;

  /// Messages that failed to send — kept with a retry action (never shown
  /// as sent when the backend rejected them).
  final _failed = <({String text, bool announcement, bool requiresAck})>[];
  int _lastSeenCount = -1;

  // v1.4 read marks: messages actually shown on screen are queued and sent
  // in one debounced batch; failures are retried on the next sighting.
  final _seenQueue = <String>{};
  final _seenSent = <String>{};
  Timer? _seenTimer;
  final _scrollTick = ValueNotifier<int>(0);
  static const seenDebounce = Duration(milliseconds: 600);

  void _onSeen(String messageId) {
    if (_seenSent.contains(messageId) || !_seenQueue.add(messageId)) return;
    _seenTimer?.cancel();
    _seenTimer = Timer(seenDebounce, _flushSeen);
  }

  void _flushSeen() {
    if (_seenQueue.isEmpty) return;
    final ids = _seenQueue.toList();
    _seenQueue.clear();
    _seenSent.addAll(ids);
    ref.read(chatRepositoryProvider).markSeen(widget.groupId, ids).catchError((Object _) {
      _seenSent.removeAll(ids); // e.g. offline — retried when seen again
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _seenTimer?.cancel();
    _scrollTick.dispose();
    _text.dispose();
    super.dispose();
  }

  void _markRead() {
    if (!mounted) return;
    ref.read(chatRepositoryProvider).markRead(widget.groupId).catchError((_) {});
  }

  Future<void> _send({String? retryText, bool? retryAnnouncement, bool? retryAck}) async {
    final text = retryText ?? _text.text;
    final announcement = retryAnnouncement ?? _announcement;
    final requiresAck = retryAck ?? _requiresAck;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .send(widget.groupId, text, announcement: announcement, requiresAck: requiresAck);
      if (!mounted) return;
      if (retryText == null) {
        _text.clear();
        _announcement = false;
        _requiresAck = false;
      }
    } catch (e) {
      if (!mounted) return;
      if (retryText == null) {
        _failed.add((text: text, announcement: announcement, requiresAck: requiresAck));
        _text.clear();
      }
      showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _retry(int i) async {
    final f = _failed[i];
    setState(() => _failed.removeAt(i));
    try {
      await ref
          .read(chatRepositoryProvider)
          .send(widget.groupId, f.text, announcement: f.announcement, requiresAck: f.requiresAck);
    } catch (e) {
      if (!mounted) return;
      setState(() => _failed.insert(i, f));
      showAppSnack(context, errorText(context, e), error: true);
    }
  }

  Future<void> _messageActions(ChatMessage m, {required bool isCoach, required bool mine}) async {
    final l = context.l10n;
    if (m.isSystem || m.hidden) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCoach)
              ListTile(
                key: const Key('msg-pin'),
                leading: Icon(m.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
                title: Text(m.pinned ? l.chatUnpin : l.chatPin),
                onTap: () => Navigator.pop(context, 'pin'),
              ),
            if (!mine)
              ListTile(
                key: const Key('msg-report'),
                leading: const Icon(Icons.flag_rounded),
                title: Text(l.report),
                onTap: () => Navigator.pop(context, 'report'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'pin') {
      await runGuarded(context, () => ref.read(chatRepositoryProvider).setPinned(widget.groupId, m.id, !m.pinned));
    } else if (action == 'report') {
      await showReportDialog(
        context,
        ref,
        targetType: ReportTarget.chatMessage,
        targetPath: 'chats/${widget.groupId}/messages/${m.id}',
        groupId: widget.groupId,
      );
    }
  }

  Future<void> _sendPhoto() async {
    final photo = await MediaPicker.pickOnePhoto();
    if (photo == null || !mounted) return;
    await runGuarded(context, () => ref.read(chatRepositoryProvider).send(widget.groupId, '', attachments: [photo]));
  }

  /// Explicit acknowledgment — only from the button, never on open/read.
  Future<void> _acknowledge(ChatMessage m) async {
    final l = context.l10n;
    await runGuarded(
      context,
      () => ref.read(chatRepositoryProvider).acknowledge(widget.groupId, m.id),
      success: l.chatAckSent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final group = ref.watch(groupsByIdProvider)[widget.groupId];
    final messages = ref.watch(chatMessagesProvider(widget.groupId));
    final me = ref.watch(currentUserProvider);
    final isCoach = group != null && me != null && group.hasCoach(me.id) && me.isApprovedCoach;
    final receipts = isCoach
        ? (ref.watch(sentReceiptsProvider(widget.groupId)).value ?? const <String, MessageReceipt>{})
        : const <String, MessageReceipt>{};
    final isParentMember = me != null && me.isParent && group != null && group.hasParent(me.id);
    final marks = isParentMember ? ref.watch(myMarksProvider(widget.groupId)).value : null;
    final limit = ref.watch(chatLimitProvider(widget.groupId));
    // Mark as read whenever new messages arrive while the room is open.
    final count = messages.value?.length ?? -1;
    if (count != _lastSeenCount) {
      _lastSeenCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
    }
    final pinned = (messages.value ?? const <ChatMessage>[]).where((m) => m.pinned && !m.hidden).lastOrNull;
    final title = Row(
      children: [
        if (group != null) SportBadge(sportKey: group.sportId, size: 36),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(group?.name ?? l.navChat, overflow: TextOverflow.ellipsis)),
      ],
    );
    final body = Column(
      children: [
        if (pinned != null) _PinnedBanner(message: pinned),
        Expanded(
          child: AsyncView<List<ChatMessage>>(
            value: messages,
            onRetry: () => ref.invalidate(chatMessagesProvider(widget.groupId)),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(icon: Icons.waving_hand_rounded, title: l.chatEmpty, body: l.chatPrivacyNote);
              }
              final reversed = list.reversed.toList();
              final canLoadMore = list.length >= limit;
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification || n is ScrollUpdateNotification) _scrollTick.value++;
                  return false;
                },
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  itemCount: reversed.length + _failed.length + (canLoadMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _failed.length) {
                      final fi = _failed.length - 1 - index;
                      return _FailedBubble(
                        text: _failed[fi].text,
                        onRetry: () => _retry(fi),
                        onDiscard: () => setState(() => _failed.removeAt(fi)),
                      );
                    }
                    final i = index - _failed.length;
                    if (i == reversed.length) {
                      return Center(
                        child: TextButton.icon(
                          key: const Key('chat-load-earlier'),
                          onPressed: () => ref.read(chatLimitProvider(widget.groupId).notifier).state = limit + 50,
                          icon: const Icon(Icons.history_rounded),
                          label: Text(l.loadEarlier),
                        ),
                      );
                    }
                    final m = reversed[i];
                    final older = i + 1 < reversed.length ? reversed[i + 1] : null;
                    final showDay = older == null || !isSameDay(older.createdAt, m.createdAt);
                    final showName = older == null || older.senderId != m.senderId || showDay;
                    final mine = m.senderId == me?.id;
                    Widget bubble = _Bubble(
                      message: m,
                      mine: mine,
                      showName: showName,
                      sportKey: group?.sportId ?? '',
                      receipt: mine && isCoach ? receipts[m.id] : null,
                      onOpenReceipt: () => context.push('/chat/${widget.groupId}/receipts/${m.id}'),
                      ackState: marks == null || !m.requiresAck || !marks.ackRequested.contains(m.id)
                          ? null
                          : (marks.acked.containsKey(m.id) ? true : false),
                      onAcknowledge: () => _acknowledge(m),
                    );
                    // Parents: a coach message becomes "seen" only once it is
                    // actually visible in this open conversation.
                    if (marks != null &&
                        !mine &&
                        !m.hidden &&
                        !m.isSystem &&
                        m.senderRole == UserRole.coach &&
                        !marks.read.contains(m.id)) {
                      bubble = SeenReporter(
                        key: ValueKey('seen-${m.id}'),
                        tick: _scrollTick,
                        onSeen: () => _onSeen(m.id),
                        child: bubble,
                      );
                    }
                    return Column(
                      children: [
                        if (showDay) _DayDivider(date: m.createdAt),
                        if (m.isSystem)
                          _SystemLine(message: m)
                        else
                          GestureDetector(
                            onLongPress: () => _messageActions(m, isCoach: isCoach, mine: mine),
                            child: bubble,
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCoach)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      children: [
                        FilterChip(
                          key: const Key('chat-announcement-toggle'),
                          avatar: const Icon(Icons.campaign_rounded, size: 18),
                          label: Text(l.chatAnnouncementToggle),
                          selected: _announcement,
                          onSelected: (v) => setState(() => _announcement = v),
                        ),
                        FilterChip(
                          key: const Key('chat-ack-toggle'),
                          avatar: const Icon(Icons.task_alt_rounded, size: 18),
                          label: Text(l.chatAckToggle),
                          selected: _requiresAck,
                          onSelected: (v) => setState(() => _requiresAck = v),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: l.photoAttachment,
                      onPressed: _sendPhoto,
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('chat-input'),
                        controller: _text,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l.typeMessage,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton.filled(
                      key: const Key('chat-send'),
                      tooltip: l.send,
                      onPressed: _sending ? null : () => _send(),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (widget.embedded) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          left: false,
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
                ),
                child: DefaultTextStyle.merge(style: Theme.of(context).textTheme.titleMedium, child: title),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: title,
        actions: [
          IconButton(
            key: const Key('chat-contacts'),
            tooltip: l.contactsTitle,
            onPressed: () => context.push('/group/${widget.groupId}/contacts'),
            icon: const Icon(Icons.contact_phone_rounded),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(Fmt.of(context).weekdayDayMonth(date), style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showName,
    required this.sportKey,
    this.receipt,
    this.onOpenReceipt,
    this.ackState,
    this.onAcknowledge,
  });

  final ChatMessage message;
  final bool mine;
  final bool showName;
  final String sportKey;

  /// v1.4 receipt summary (the coach's own messages only).
  final MessageReceipt? receipt;
  final VoidCallback? onOpenReceipt;

  /// Parent recipient of an acknowledgment request: false = pending,
  /// true = acknowledged, null = not asked.
  final bool? ackState;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isCoach = message.senderRole == UserRole.coach;
    final announcement = message.isAnnouncement;
    final bg = message.hidden
        ? scheme.surfaceContainerHigh
        : announcement
        ? AppColors.volt.withValues(alpha: 0.22)
        : (mine ? scheme.primary : scheme.surface);
    final fg = message.hidden ? scheme.onSurfaceVariant : (mine && !announcement ? Colors.white : scheme.onSurface);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Padding(
          padding: EdgeInsets.only(top: showName ? AppSpacing.sm : 2),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showName && !mine)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (isCoach) ...[
                        const SizedBox(width: 6),
                        StatusPill(label: context.l10n.roleCoach, color: AppColors.blue, dense: true),
                      ],
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                decoration: BoxDecoration(
                  color: bg,
                  border: mine
                      ? null
                      : Border.all(color: isCoach ? AppColors.blue.withValues(alpha: 0.4) : scheme.outline),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (announcement)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_rounded, size: 16, color: fg),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.chatAnnouncement,
                              style: t.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    if (message.requiresAck && !message.hidden)
                      Padding(
                        key: Key('ack-required-${message.id}'),
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.task_alt_rounded, size: 16, color: fg),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                context.l10n.chatAckRequired,
                                style: t.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (message.hidden)
                      Text(
                        context.l10n.messageHidden,
                        style: t.bodySmall?.copyWith(color: fg, fontStyle: FontStyle.italic),
                      )
                    else ...[
                      for (final a in message.attachments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: MediaPhoto(refPath: a, sportKey: sportKey, size: 200),
                        ),
                      if (message.text.isNotEmpty) Text(message.text, style: t.bodyMedium?.copyWith(color: fg)),
                    ],
                    if (ackState == false && !message.hidden)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: FilledButton.icon(
                          key: Key('ack-${message.id}'),
                          onPressed: onAcknowledge,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(context.l10n.chatAckButton),
                        ),
                      ),
                    if (ackState == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          key: Key('acked-${message.id}'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                context.l10n.chatAckDone,
                                style: t.labelMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.of(context).time(message.createdAt),
                      style: t.labelSmall?.copyWith(
                        color: mine && !announcement ? Colors.white70 : scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    if (receipt != null)
                      InkWell(
                        key: Key('receipt-${message.id}'),
                        onTap: onOpenReceipt,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              context.l10n.receiptSeenBy(receipt!.readCount, receipt!.recipientCount),
                              if (receipt!.requiresAck)
                                context.l10n.receiptAckShort(receipt!.ackCount, receipt!.recipientCount),
                            ].join(' · '),
                            textAlign: TextAlign.end,
                            style: t.labelSmall?.copyWith(
                              color: mine && !announcement ? Colors.white : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: mine && !announcement ? Colors.white70 : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedBanner extends StatelessWidget {
  const _PinnedBanner({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      key: const Key('chat-pinned-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.volt.withValues(alpha: 0.18),
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin_rounded, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(message.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              systemMessageText(context, message),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedBubble extends StatelessWidget {
  const _FailedBubble({required this.text, required this.onRetry, required this.onDiscard});

  final String text;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        key: const Key('chat-failed'),
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.danger),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(l.chatSendFailed, style: Theme.of(context).textTheme.labelSmall),
                TextButton(key: const Key('chat-retry'), onPressed: onRetry, child: Text(l.chatRetry)),
                IconButton(
                  key: const Key('chat-discard'),
                  tooltip: l.m191DiscardMessage,
                  onPressed: onDiscard,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reports once when its child is at least 60 % visible in the enclosing
/// scrollable, the route is current and the app is in the foreground.
/// Re-checked after layout and whenever [tick] changes (scrolling).
class SeenReporter extends StatefulWidget {
  const SeenReporter({super.key, required this.tick, required this.onSeen, required this.child});

  final ValueListenable<int> tick;
  final VoidCallback onSeen;
  final Widget child;

  static const minVisibleFraction = 0.6;

  @override
  State<SeenReporter> createState() => _SeenReporterState();
}

class _SeenReporterState extends State<SeenReporter> {
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    widget.tick.addListener(_schedule);
  }

  @override
  void didUpdateWidget(SeenReporter old) {
    super.didUpdateWidget(old);
    if (old.tick != widget.tick) {
      old.tick.removeListener(_schedule);
      widget.tick.addListener(_schedule);
    }
  }

  @override
  void dispose() {
    widget.tick.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    if (_reported) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_reported || !mounted) return;
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final box = context.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    final viewport = scrollable?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.attached || !viewport.attached || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final view = viewport.localToGlobal(Offset.zero) & viewport.size;
    final visible = rect.intersect(view);
    if (visible.isEmpty || visible.height <= 0 || visible.width <= 0) return;
    final needed = (rect.height < view.height ? rect.height : view.height) * SeenReporter.minVisibleFraction;
    if (visible.height >= needed) {
      _reported = true;
      widget.onSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return widget.child;
  }
}
