import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/medical_certificate.dart';

/// Opens a certificate through the short-lived, audited grant (never a
/// stored public URL). Images render in-app; PDFs open in the system viewer.
Future<void> previewCertificate(BuildContext context, WidgetRef ref, MedicalCertificate cert) async {
  try {
    final grant = await ref.read(certificatesRepositoryProvider).requestAccess(cert.id);
    if (!context.mounted) return;
    if (grant.demoBytes != null || grant.url.scheme.startsWith('demo')) {
      await showDialog<void>(
        context: context,
        builder: (_) => CertificateViewer(grant: grant, fileName: cert.fileName),
      );
    } else {
      await launchUrl(grant.url, mode: LaunchMode.inAppBrowserView);
    }
  } catch (e) {
    if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
  }
}

/// Download = explicit purpose (logged separately) after a sensitivity
/// warning. The file goes through the system share/save sheet from a
/// temporary location; nothing is written to the photo gallery.
Future<void> downloadCertificate(BuildContext context, WidgetRef ref, MedicalCertificate cert) async {
  final l = context.l10n;
  final ok = await confirmDialog(
    context,
    title: l.certDownload,
    message: '${l.certSensitiveWarning}\n\n${l.certAccessLogged}',
    confirmLabel: l.certDownloadConfirm,
  );
  if (!ok || !context.mounted) return;
  try {
    final grant = await ref
        .read(certificatesRepositoryProvider)
        .requestAccess(cert.id, purpose: CertificateAccessPurpose.download);
    final bytes = grant.demoBytes;
    if (bytes != null) {
      final name = cert.fileName.isEmpty ? 'certificate.pdf' : cert.fileName;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(Uint8List.fromList(bytes), name: name, mimeType: cert.mimeType)],
          fileNameOverrides: [name],
        ),
      );
    } else {
      // Production: 5-minute signed URL; the browser handles the download.
      await launchUrl(grant.url, mode: LaunchMode.externalApplication);
    }
    if (context.mounted) showAppSnack(context, l.certSavedTemp);
  } catch (e) {
    if (context.mounted) showAppSnack(context, errorText(context, e), error: true);
  }
}

/// In-app viewer with the access countdown (5-minute grant).
class CertificateViewer extends StatefulWidget {
  const CertificateViewer({super.key, required this.grant, this.fileName = ''});

  final CertificateAccessGrant grant;
  final String fileName;

  @override
  State<CertificateViewer> createState() => _CertificateViewerState();
}

class _CertificateViewerState extends State<CertificateViewer> {
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
      key: const Key('certificate-viewer'),
      title: Text(widget.fileName.isEmpty ? l.demoDocument : widget.fileName, overflow: TextOverflow.ellipsis),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 220,
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
                      child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppColors.danger),
                        Text(l.certPdfPreview),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l.certAccessLogged, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            StatusPill(
              label: expired ? l.accessExpired : l.accessExpiresIn(left.inMinutes + 1),
              color: expired ? AppColors.danger : AppColors.warning,
              icon: Icons.timer_rounded,
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
    );
  }
}
