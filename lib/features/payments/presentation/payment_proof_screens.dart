import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/form_fields.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/presentation/children_providers.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../trainings/domain/training.dart';
import '../domain/payment.dart';
import '../domain/payment_proof.dart';
import 'payments_providers.dart';

final proofsForPaymentProvider = StreamProvider.autoDispose.family<List<PaymentProof>, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(paymentProofsRepositoryProvider).watchForPayment(id);
});

final paymentEventsProvider = StreamProvider.autoDispose.family<List<PaymentVerificationEvent>, String>((ref, id) {
  ref.watch(currentUidProvider);
  return ref.watch(paymentProofsRepositoryProvider).watchEvents(id);
});

final reviewQueueProvider = StreamProvider.autoDispose<List<PaymentProof>>((ref) {
  ref.watch(currentUidProvider);
  return ref.watch(paymentProofsRepositoryProvider).watchReviewQueue();
});

String eventLabel(BuildContext context, VerificationAction a) {
  final l = context.l10n;
  return switch (a) {
    VerificationAction.submitted => l.payEventSubmitted,
    VerificationAction.resubmitted => l.payEventResubmitted,
    VerificationAction.reviewStarted => l.payEventReviewStarted,
    VerificationAction.approved => l.payEventApproved,
    VerificationAction.rejected => l.payEventRejected,
    VerificationAction.viewed => l.payEventViewed,
  };
}

/// Opens a receipt through the repository (short-lived URL / private bytes;
/// reviewer views are audited server-side).
Future<void> openReceipt(BuildContext context, WidgetRef ref, PaymentProof proof) async {
  final l = context.l10n;
  try {
    final r = await ref.read(paymentProofsRepositoryProvider).openReceipt(proof.id);
    if (!context.mounted) return;
    if (r.url != null && r.bytes == null) {
      await launchUrl(r.url!, mode: LaunchMode.inAppBrowserView);
      return;
    }
    final bytes = r.bytes;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('receipt-viewer'),
        title: Text(l.payViewReceipt),
        content: SizedBox(
          width: 420,
          height: 260,
          child: bytes != null && r.mimeType.startsWith('image/') && bytes.length > 100
              ? Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppColors.danger),
                    Text(proof.receiptPath.split('/').last),
                    Text('${(proof.receiptSize / 1024).ceil()} KB', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
      ),
    );
  } catch (e) {
    if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
  }
}

/// Parent: submit (or resubmit) payment proof; see status and history.
class PaymentProofScreen extends ConsumerStatefulWidget {
  const PaymentProofScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  ConsumerState<PaymentProofScreen> createState() => _PaymentProofScreenState();
}

class _PaymentProofScreenState extends ConsumerState<PaymentProofScreen> {
  DateTime? _paidOn;
  final _ref = TextEditingController();
  final _note = TextEditingController();
  PhotoUpload? _receipt;
  double? _progress;
  List<String> _errors = const [];

  @override
  void dispose() {
    _ref.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(Future<PhotoUpload?> Function() p) async {
    final f = await p();
    if (f != null && mounted) setState(() => _receipt = f);
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final now = ref.read(clockProvider)();
    final d = PaymentProofDraft(
      paymentId: widget.paymentId,
      paidOn: _paidOn ?? now,
      receipt: _receipt ?? const PhotoUpload(bytes: [], fileName: '', mimeType: ''),
      reference: _ref.text,
      note: _note.text,
    );
    final errors = PaymentProofDraft.validate(d, now: now);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _progress = 0);
    try {
      await ref
          .read(paymentProofsRepositoryProvider)
          .submit(
            d,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (!mounted) return;
      showAppSnack(context, l.payProofSubmitted);
      setState(() {
        _receipt = null;
        _ref.clear();
        _note.clear();
      });
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
    if (mounted) setState(() => _progress = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final payment = (ref.watch(myPaymentsProvider).value ?? const <Payment>[])
        .where((p) => p.id == widget.paymentId)
        .firstOrNull;
    final proofs = ref.watch(proofsForPaymentProvider(widget.paymentId)).value ?? const <PaymentProof>[];
    final events = ref.watch(paymentEventsProvider(widget.paymentId)).value ?? const <PaymentVerificationEvent>[];
    final now = ref.watch(clockProvider)();
    final open = proofs.where((p) => p.status.isOpen).firstOrNull;
    final canSubmit = payment != null && payment.status == PaymentStatus.pending && open == null;
    final child = payment == null ? null : ref.watch(childProvider(payment.childId)).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.payProofTitle)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (payment != null)
              AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_rounded),
                  title: Text(
                    l.payProofFor(child?.firstName ?? '', f.money(payment.amount), f.dayMonth(payment.dueDate)),
                  ),
                  subtitle: Text(switch (displayStateOf(payment)) {
                    PaymentDisplayState.paid => l.payStatePaid,
                    PaymentDisplayState.proofSubmitted => l.payStateAwaiting,
                    PaymentDisplayState.underReview => l.payStateUnderReview,
                    PaymentDisplayState.rejected => l.payRejectedReason(payment.verification.rejectionReason ?? ''),
                    _ => l.paymentPending,
                  }, key: const Key('proof-state')),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            DemoBanner(text: l.payProofHint),
            if (canSubmit) ...[
              SectionHeader(l.payProofAction),
              PickerField(
                key: const Key('proof-date'),
                icon: Icons.event_rounded,
                label: '${l.payProofDate}: ${f.fullDate(_paidOn ?? now)}',
                filled: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _paidOn ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now,
                  );
                  if (d != null) setState(() => _paidOn = d);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const Key('proof-reference'),
                controller: _ref,
                maxLength: 60,
                decoration: InputDecoration(labelText: l.payProofReference),
              ),
              TextField(
                key: const Key('proof-note'),
                controller: _note,
                maxLength: 300,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(labelText: l.payProofNote),
              ),
              Text(l.payProofReceipt, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text(l.certTakePhoto),
                    onPressed: () => _pick(MediaPicker.takePhoto),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.attach_file_rounded, size: 18),
                    label: Text(l.certChooseFile),
                    onPressed: () => _pick(MediaPicker.pickDocument),
                  ),
                  if (AppConfig.isDemo)
                    ActionChip(
                      key: const Key('proof-demo-receipt'),
                      avatar: const Icon(Icons.science_rounded, size: 18),
                      label: Text(l.demoBadge),
                      onPressed: () => setState(
                        () => _receipt = PhotoUpload(
                          bytes: Uint8List.fromList(List.filled(4096, 1)),
                          fileName: 'qvitari.pdf',
                          mimeType: 'application/pdf',
                        ),
                      ),
                    ),
                ],
              ),
              if (_receipt != null)
                ListTile(
                  key: const Key('proof-file'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _receipt!.mimeType == 'application/pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                  ),
                  title: Text(_receipt!.fileName),
                  subtitle: Text('${(_receipt!.bytes.length / 1024).ceil()} KB'),
                ),
              if (_progress != null) ...[
                LinearProgressIndicator(value: _progress),
                Text(l.payProofUploading((_progress! * 100).round())),
              ],
              FormErrors(errors: _errors),
              const SizedBox(height: AppSpacing.md),
              LoadingButton(
                key: const Key('proof-submit'),
                label: l.payProofSubmit,
                icon: Icons.send_rounded,
                loading: _progress != null,
                onPressed: _submit,
              ),
            ],
            if (proofs.isNotEmpty) ...[
              SectionHeader(l.payHistory),
              for (final p in proofs)
                AppCard(
                  key: Key('my-proof-${p.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_rounded),
                    title: Text(l.paySubmittedOn(f.dateTime(p.submittedAt))),
                    subtitle: Text(
                      [
                        if (p.reference != null) p.reference!,
                        if (p.status == ProofStatus.rejected && p.rejectionReason != null)
                          l.payRejectedReason(p.rejectionReason!),
                        if (p.status == ProofStatus.approved && p.decidedAt != null)
                          l.payVerifiedBy(p.decidedByName ?? '', f.dateTime(p.decidedAt!)),
                      ].join('\n'),
                    ),
                    trailing: IconButton(
                      tooltip: l.payViewReceipt,
                      onPressed: () => openReceipt(context, ref, p),
                      icon: const Icon(Icons.visibility_rounded),
                    ),
                  ),
                ),
            ],
            if (events.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final e in events)
                Text(
                  '${f.dateTime(e.at)} · ${eventLabel(context, e.action)} · ${e.actorName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Coach / club admin: open payment confirmations they may decide.
class PaymentReviewScreen extends ConsumerWidget {
  const PaymentReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref.watch(reviewQueueProvider);
    final me = ref.watch(currentUserProvider);
    final groups = ref.watch(myGroupsProvider).value ?? const [];
    final reviewer = me != null && groups.any((g) => AccessPolicy.canVerifyPayments(me, g));
    return Scaffold(
      appBar: AppBar(title: Text(l.payReviewQueue)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<PaymentProof>>(
          value: queue,
          data: (list) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (!reviewer) DemoBanner(text: l.payNotReviewer),
              if (list.isEmpty) EmptyState(icon: Icons.task_alt_rounded, title: l.payReviewEmpty),
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ProofReviewCard(proof: p),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProofReviewCard extends ConsumerWidget {
  const ProofReviewCard({super.key, required this.proof});

  final PaymentProof proof;

  Future<void> _decide(BuildContext context, WidgetRef ref, bool approve) async {
    final l = context.l10n;
    String? reason;
    if (!approve) {
      final c = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.payRejectReasonTitle),
          content: TextField(
            key: const Key('reject-reason'),
            controller: c,
            maxLength: 300,
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            FilledButton(
              key: const Key('reject-ok'),
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: Text(l.payReject),
            ),
          ],
        ),
      );
      if (reason == null) return;
    }
    if (!context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(paymentProofsRepositoryProvider).review(proof.id, approve: approve, reason: reason),
      success: approve ? l.payApproved : l.payRejectedSnack,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final group = ref.watch(groupsByIdProvider)[proof.groupId];
    final payment = (ref.watch(groupPaymentsProvider(proof.groupId)).value ?? const <Payment>[])
        .where((p) => p.id == proof.paymentId)
        .firstOrNull;
    final child = ref.watch(childProvider(proof.childId)).value;
    return AppCard(
      key: Key('review-${proof.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [child?.fullName, group?.name].whereType<String>().where((x) => x.isNotEmpty).join(' · '),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (payment != null) Text('${f.money(payment.amount)} · ${l.dueOn(f.dayMonth(payment.dueDate))}'),
          Text('${l.payProofDate}: ${f.fullDate(proof.paidOn)}', style: Theme.of(context).textTheme.bodySmall),
          if (proof.reference != null)
            Text('${l.payProofReference}: ${proof.reference}', style: Theme.of(context).textTheme.bodySmall),
          if (proof.note != null)
            Text('${l.payProofNote}: ${proof.note}', style: Theme.of(context).textTheme.bodySmall),
          Text(l.paySubmittedOn(f.dateTime(proof.submittedAt)), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                key: Key('review-receipt-${proof.id}'),
                onPressed: () => openReceipt(context, ref, proof),
                icon: const Icon(Icons.visibility_rounded),
                label: Text(l.payViewReceipt),
              ),
              FilledButton.icon(
                key: Key('approve-${proof.id}'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () => _decide(context, ref, true),
                icon: const Icon(Icons.check_rounded),
                label: Text(l.payApprove),
              ),
              OutlinedButton.icon(
                key: Key('reject-${proof.id}'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () => _decide(context, ref, false),
                icon: const Icon(Icons.close_rounded),
                label: Text(l.payReject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Route helper for notification deep links.
void openPaymentReview(BuildContext context) => context.push(Routes.paymentReview);
