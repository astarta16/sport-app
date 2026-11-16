import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/presentation/children_providers.dart';
import '../domain/child_thread.dart';

final childThreadMessagesProvider = StreamProvider.autoDispose.family<List<ChildThreadMessage>, (String, String)>((
  ref,
  key,
) {
  ref.watch(currentUidProvider);
  return ref.watch(childThreadsRepositoryProvider).watchMessages(key.$1, key.$2);
});

final myChildThreadsProvider = StreamProvider.autoDispose<List<ChildThread>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(childThreadsRepositoryProvider).watchMyThreads();
});

/// `/student/:childId/coach/:coachId` — private conversation about ONE child
/// between the child's guardians and one of the child's coaches.
class ChildThreadScreen extends ConsumerStatefulWidget {
  const ChildThreadScreen({super.key, required this.childId, required this.coachId});

  final String childId;
  final String coachId;

  @override
  ConsumerState<ChildThreadScreen> createState() => _ChildThreadScreenState();
}

class _ChildThreadScreenState extends ConsumerState<ChildThreadScreen> {
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
    final ok = await runGuarded(
      context,
      () => ref.read(childThreadsRepositoryProvider).send(widget.childId, widget.coachId, text),
    );
    if (!mounted) return;
    if (ok) _text.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final me = ref.watch(currentUserProvider);
    final child = ref.watch(childProvider(widget.childId)).value;
    final coach = ref.watch(publicProfileProvider(widget.coachId)).value;
    final messages = ref.watch(childThreadMessagesProvider((widget.childId, widget.coachId)));
    final iAmCoach = me?.id == widget.coachId;
    final childName = child?.firstName ?? '…';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          iAmCoach ? childName : (coach?.fullName ?? l.roleCoach),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!iAmCoach && coach?.phone != null)
            IconButton(
              key: const Key('thread-call'),
              tooltip: l.contactCallName(coach!.fullName),
              onPressed: () => callPhone(coach.phone!),
              icon: const Icon(Icons.call_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            key: const Key('thread-child-banner'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            color: AppColors.volt.withValues(alpha: 0.18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.threadAbout(child?.fullName ?? childName), style: t.titleSmall),
                Text(l.threadPrivacy(childName), style: t.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<ChildThreadMessage>>(
              value: messages,
              onRetry: () => ref.invalidate(childThreadMessagesProvider((widget.childId, widget.coachId))),
              data: (list) {
                if (list.isEmpty) return EmptyState(icon: Icons.forum_outlined, title: l.threadEmpty);
                final reversed = list.reversed.toList();
                return ListView.builder(
                  key: const Key('thread-list'),
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: reversed.length,
                  itemBuilder: (context, i) {
                    final m = reversed[i];
                    final mine = m.senderId == me?.id;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                        child: Container(
                          key: Key('thread-msg-${m.id}'),
                          margin: const EdgeInsets.only(top: AppSpacing.xs),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                          decoration: BoxDecoration(
                            color: mine ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                            border: mine ? null : Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!mine)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    m.senderRole == UserRole.coach ? '${m.senderName} · ${l.roleCoach}' : m.senderName,
                                    style: t.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              Text(m.text, style: t.bodyMedium?.copyWith(color: mine ? Colors.white : null)),
                              Text(
                                Fmt.of(context).time(m.createdAt),
                                style: t.labelSmall?.copyWith(color: mine ? Colors.white70 : null, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('thread-input'),
                      controller: _text,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: ChildThreadMessage.maxLength,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: l.typeMessage),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    key: const Key('thread-send'),
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

/// Chat list section: conversations about specific children.
class ChildThreadsSection extends ConsumerWidget {
  const ChildThreadsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(myChildThreadsProvider).value ?? const <ChildThread>[];
    if (threads.isEmpty) return const SizedBox.shrink();
    final me = ref.watch(currentUserProvider);
    return Column(
      key: const Key('child-threads'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(context.l10n.threadsTitle),
        for (final th in threads)
          Consumer(
            builder: (context, ref, _) {
              final child = ref.watch(childProvider(th.childId)).value;
              final coach = ref.watch(publicProfileProvider(th.coachId)).value;
              final title = me?.id == th.coachId
                  ? (child?.fullName ?? '…')
                  : '${child?.firstName ?? '…'} · ${coach?.fullName ?? ''}';
              return AppCard(
                key: Key('thread-${th.id}'),
                onTap: () => context.push('/student/${th.childId}/coach/${th.coachId}'),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    InitialsAvatar(name: child?.fullName ?? '?', size: 40),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (th.lastMessageAt != null)
                      Text(
                        Fmt.of(context).dayMonthShort(th.lastMessageAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
