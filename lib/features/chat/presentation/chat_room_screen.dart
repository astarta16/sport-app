import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../media/presentation/media_providers.dart';
import '../domain/chat_message.dart';
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

  /// Messages that failed to send — kept with a retry action (never shown
  /// as sent when the backend rejected them).
  final _failed = <({String text, bool announcement})>[];
  int _lastSeenCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _markRead() {
    if (!mounted) return;
    ref.read(chatRepositoryProvider).markRead(widget.groupId).catchError((_) {});
  }

  Future<void> _send({String? retryText, bool? retryAnnouncement}) async {
    final text = retryText ?? _text.text;
    final announcement = retryAnnouncement ?? _announcement;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).send(widget.groupId, text, announcement: announcement);
      if (!mounted) return;
      if (retryText == null) {
        _text.clear();
        _announcement = false;
      }
    } catch (e) {
      if (!mounted) return;
      if (retryText == null) {
        _failed.add((text: text, announcement: announcement));
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
      await ref.read(chatRepositoryProvider).send(widget.groupId, f.text, announcement: f.announcement);
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final group = ref.watch(groupsByIdProvider)[widget.groupId];
    final messages = ref.watch(chatMessagesProvider(widget.groupId));
    final me = ref.watch(currentUserProvider);
    final isCoach = group != null && me != null && group.hasCoach(me.id) && me.isApprovedCoach;
    final receipts = isCoach
        ? (ref.watch(readReceiptsProvider(widget.groupId)).value ?? const {})
        : const <String, DateTime>{};
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
              return ListView.builder(
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
                  return Column(
                    children: [
                      if (showDay) _DayDivider(date: m.createdAt),
                      if (m.isSystem)
                        _SystemLine(message: m)
                      else
                        GestureDetector(
                          onLongPress: () => _messageActions(m, isCoach: isCoach, mine: m.senderId == me?.id),
                          child: _Bubble(
                            message: m,
                            mine: m.senderId == me?.id,
                            showName: showName,
                            sportKey: group?.sportId ?? '',
                            readBy: m.senderId == me?.id && isCoach
                                ? receipts.entries.where((e) => e.key != me.id && !e.value.isBefore(m.createdAt)).length
                                : null,
                          ),
                        ),
                    ],
                  );
                },
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
                    child: FilterChip(
                      key: const Key('chat-announcement-toggle'),
                      avatar: const Icon(Icons.campaign_rounded, size: 18),
                      label: Text(l.chatAnnouncementToggle),
                      selected: _announcement,
                      onSelected: (v) => setState(() => _announcement = v),
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
      appBar: AppBar(titleSpacing: 0, title: title),
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
    this.readBy,
  });

  final ChatMessage message;
  final bool mine;
  final bool showName;
  final String sportKey;

  /// Read receipts (coach's own messages only).
  final int? readBy;

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
                    const SizedBox(height: 2),
                    Text(
                      readBy == null
                          ? Fmt.of(context).time(message.createdAt)
                          : '${Fmt.of(context).time(message.createdAt)} · ${context.l10n.chatReadBy(readBy!)}',
                      style: t.labelSmall?.copyWith(
                        color: mine && !announcement ? Colors.white70 : scheme.onSurfaceVariant,
                        fontSize: 10,
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
              message.text,
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
                IconButton(onPressed: onDiscard, icon: const Icon(Icons.close_rounded, size: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
