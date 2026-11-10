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
import 'chat_providers.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    final ok = await runGuarded(context, () => ref.read(chatRepositoryProvider).send(widget.groupId, text));
    if (!mounted) return;
    if (ok) _text.clear();
    setState(() => _sending = false);
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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (group != null) SportBadge(sportKey: group.sportId, size: 36),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(group?.name ?? l.navChat, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<List<ChatMessage>>(
              value: messages,
              onRetry: () => ref.invalidate(chatMessagesProvider(widget.groupId)),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(icon: Icons.waving_hand_rounded, title: l.chatEmpty, body: l.chatPrivacyNote);
                }
                final reversed = list.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  itemCount: reversed.length,
                  itemBuilder: (context, i) {
                    final m = reversed[i];
                    final older = i + 1 < reversed.length ? reversed[i + 1] : null;
                    final showDay = older == null || !isSameDay(older.createdAt, m.createdAt);
                    final showName = older == null || older.senderId != m.senderId || showDay;
                    return Column(
                      children: [
                        if (showDay) _DayDivider(date: m.createdAt),
                        _Bubble(
                          message: m,
                          mine: m.senderId == me?.id,
                          showName: showName,
                          sportKey: group?.sportId ?? '',
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
              child: Row(
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
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  const _Bubble({required this.message, required this.mine, required this.showName, required this.sportKey});

  final ChatMessage message;
  final bool mine;
  final bool showName;
  final String sportKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isCoach = message.senderRole == UserRole.coach;
    final bg = mine ? scheme.primary : scheme.surface;
    final fg = mine ? Colors.white : scheme.onSurface;
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
                    for (final a in message.attachments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: MediaPhoto(refPath: a, sportKey: sportKey, size: 200),
                      ),
                    if (message.text.isNotEmpty) Text(message.text, style: t.bodyMedium?.copyWith(color: fg)),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.of(context).time(message.createdAt),
                      style: t.labelSmall?.copyWith(
                        color: mine ? Colors.white70 : scheme.onSurfaceVariant,
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
