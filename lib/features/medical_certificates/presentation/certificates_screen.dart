import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/visuals.dart';
import '../../authentication/domain/access_policy.dart';
import '../../authentication/presentation/session_providers.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/children_providers.dart';
import '../domain/medical_certificate.dart';
import 'certificates_providers.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final child = ref.watch(childProvider(childId)).value;
    final certs = ref.watch(childCertificatesProvider(childId));
    final now = ref.watch(clockProvider)();
    final isParent = user != null && child != null && AccessPolicy.isParentOf(user, child);
    return Scaffold(
      appBar: AppBar(title: Text(l.certificatesTitle)),
      floatingActionButton: isParent
          ? FloatingActionButton.extended(
              key: const Key('upload-certificate'),
              onPressed: () => context.push(Routes.uploadCertificate(childId)),
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(l.uploadCertificate),
            )
          : null,
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: AsyncView<List<MedicalCertificate>>(
          value: certs,
          onRetry: () => ref.invalidate(childCertificatesProvider(childId)),
          data: (list) {
            final status = CertificatePolicy.childStatus(list, now);
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
              children: [
                _StatusHero(child: child, status: status, latest: list.firstOrNull, now: now),
                const SizedBox(height: AppSpacing.sm),
                DemoBanner(text: l.certRemindersNote),
                SectionHeader(l.certificatesTitle),
                if (list.isEmpty)
                  AppCard(
                    child: EmptyState(compact: true, icon: Icons.description_outlined, title: l.noCertificates),
                  )
                else
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _CertificateCard(cert: c, canDelete: isParent, now: now),
                    ),
                if (isParent) _AccessLog(childId: childId),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.child, required this.status, required this.latest, required this.now});

  final Child? child;
  final CertificateStatus status;
  final MedicalCertificate? latest;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final v = StatusVisual.certificate(context, status);
    final days = latest == null ? null : TbilisiTime.daysBetween(now, latest!.validUntil);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: v.color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(v.icon, color: v.color, size: 34),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child?.fullName ?? '', style: t.titleMedium),
                const SizedBox(height: 4),
                StatusPill.of(v),
                if (days != null) ...[
                  const SizedBox(height: 4),
                  Text(days >= 0 ? l.certExpiresIn(days) : l.certExpiredAgo(-days), style: t.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends ConsumerWidget {
  const _CertificateCard({required this.cert, required this.canDelete, required this.now});

  final MedicalCertificate cert;
  final bool canDelete;
  final DateTime now;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    try {
      final grant = await ref.read(certificatesRepositoryProvider).requestAccess(cert.id);
      if (!context.mounted) return;
      if (grant.demoBytes != null || grant.url.scheme.startsWith('demo')) {
        await showDialog<void>(
          context: context,
          builder: (_) => _DemoViewer(grant: grant),
        );
      } else {
        await launchUrl(grant.url, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.deleteCertificate,
      message: l.deleteCertificateConfirm,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (ok && context.mounted) {
      await runGuarded(context, () => ref.read(certificatesRepositoryProvider).delete(cert.id), success: l.certDeleted);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final v = StatusVisual.certificate(context, cert.statusOn(now));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cert.mimeType == 'application/pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(l.validUntil(f.fullDate(cert.validUntil)), style: Theme.of(context).textTheme.titleSmall),
              ),
              StatusPill.of(v, dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.issuedOn(f.fullDate(cert.issuedAt)), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('open-cert-${cert.id}'),
                  onPressed: () => _open(context, ref),
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(l.openFile),
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton.outlined(
                  tooltip: l.deleteCertificate,
                  color: AppColors.danger,
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Demo viewer: shows the 5-minute access countdown; never real content.
class _DemoViewer extends StatefulWidget {
  const _DemoViewer({required this.grant});

  final CertificateAccessGrant grant;

  @override
  State<_DemoViewer> createState() => _DemoViewerState();
}

class _DemoViewerState extends State<_DemoViewer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final left = widget.grant.expiresAt.difference(DateTime.now());
    final expired = left.isNegative;
    final bytes = widget.grant.demoBytes;
    final isImage = widget.grant.mimeType.startsWith('image/') && bytes != null && bytes.length > 100;
    return AlertDialog(
      title: Text(l.demoDocument),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: expired
                ? Center(child: Text(l.accessExpired, textAlign: TextAlign.center))
                : isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover),
                  )
                : const Icon(Icons.description_rounded, size: 72),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l.demoDocumentBody, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          StatusPill(
            label: expired ? l.accessExpired : l.accessExpiresIn(left.inMinutes + 1),
            color: expired ? AppColors.danger : AppColors.warning,
            icon: Icons.timer_rounded,
          ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
    );
  }
}

class _AccessLog extends ConsumerWidget {
  const _AccessLog({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final log = ref.watch(certificateAccessLogProvider(childId)).value ?? const [];
    if (log.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l.accessLog),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final e in log.take(10))
                ListTile(
                  dense: true,
                  leading: Icon(switch (e.action) {
                    'open' => Icons.visibility_rounded,
                    'denied' => Icons.block_rounded,
                    _ => Icons.delete_outline_rounded,
                  }),
                  title: Text(switch (e.action) {
                    'open' => l.accessLogOpen(e.userName),
                    'denied' => l.accessLogDenied(e.userName),
                    _ => l.accessLogDelete(e.userName),
                  }),
                  subtitle: Text(f.dateTime(e.at)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
