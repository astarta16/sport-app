import '../../../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../trainings/domain/training.dart';
import '../domain/medical_certificate.dart';

/// Two steps (spec §7.1): consent screen first, then file + dates.
class UploadCertificateScreen extends ConsumerStatefulWidget {
  const UploadCertificateScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<UploadCertificateScreen> createState() => _UploadCertificateScreenState();
}

class _UploadCertificateScreenState extends ConsumerState<UploadCertificateScreen> {
  bool _consent = false;
  bool _consentStepDone = false;
  PhotoUpload? _file;
  DateTime? _issued;
  DateTime? _validUntil;
  bool _saving = false;
  List<String> _errors = const [];

  Future<void> _pick(Future<PhotoUpload?> Function() picker) async {
    try {
      final f = await picker();
      if (f != null) setState(() => _file = f);
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
  }

  Future<void> _submit() async {
    final upload = CertificateUpload(
      childId: widget.childId,
      bytes: _file?.bytes ?? const [],
      fileName: _file?.fileName ?? '',
      mimeType: _file?.mimeType ?? '',
      issuedAt: _issued ?? DateTime.now(),
      validUntil: _validUntil ?? DateTime.fromMillisecondsSinceEpoch(0),
      consentGiven: _consent,
    );
    final errors = [
      if (_file == null) 'fileEmpty',
      if (_issued == null || _validUntil == null) 'required',
      ...CertificatePolicy.validateUpload(upload).where((e) => !(e == 'fileEmpty' && _file == null)),
    ];
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final ok = await runGuarded(
      context,
      () => ref.read(certificatesRepositoryProvider).upload(upload),
      success: context.l10n.certUploaded,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.popOrHome();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.uploadCertificate)),
      body: ConstrainedContent(
        maxWidth: Breakpoints.readable,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _consentStepDone ? _form(context) : _consentStep(context),
          ),
        ),
      ),
    );
  }

  Widget _consentStep(BuildContext context) {
    final l = context.l10n;
    Widget block(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return ListView(
      key: const ValueKey('consent'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l.certConsentTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        block(Icons.data_object_rounded, l.certConsentWhat, l.certConsentWhatBody),
        block(Icons.lock_person_rounded, l.certConsentWho, l.certConsentWhoBody),
        block(Icons.delete_sweep_rounded, l.certConsentDelete, l.certConsentDeleteBody),
        CheckboxListTile(
          key: const Key('cert-consent'),
          contentPadding: EdgeInsets.zero,
          value: _consent,
          onChanged: (v) => setState(() => _consent = v ?? false),
          title: Text(l.certConsentAgree, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.md),
        LoadingButton(
          key: const Key('cert-consent-continue'),
          label: l.continueLabel,
          onPressed: _consent ? () => setState(() => _consentStepDone = true) : null,
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final scheme = Theme.of(context).colorScheme;
    Future<void> pickDate(bool issued) async {
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: issued ? (_issued ?? now) : (_validUntil ?? now.add(const Duration(days: 365))),
        firstDate: now.subtract(const Duration(days: 365 * 3)),
        lastDate: now.add(const Duration(days: 365 * 3)),
      );
      if (d != null) setState(() => issued ? _issued = d : _validUntil = d);
    }

    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            children: [
              Icon(_file == null ? Icons.cloud_upload_rounded : Icons.task_rounded, size: 48, color: scheme.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _file == null ? l.fileRequirements : l.fileSelected(_file!.fileName),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text(l.takePhoto),
                    onPressed: () => _pick(MediaPicker.takePhoto),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.photo_library_rounded, size: 18),
                    label: Text(l.fromGallery),
                    onPressed: () => _pick(MediaPicker.pickOnePhoto),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: Text(l.pickDocument),
                    onPressed: () => _pick(MediaPicker.pickDocument),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outline),
          ),
          leading: const Icon(Icons.event_rounded),
          title: Text(l.issueDate),
          subtitle: Text(_issued == null ? '—' : f.fullDate(_issued!)),
          onTap: () => pickDate(true),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outline),
          ),
          leading: const Icon(Icons.event_available_rounded),
          title: Text(l.expiryDate),
          subtitle: Text(_validUntil == null ? '—' : f.fullDate(_validUntil!)),
          onTap: () => pickDate(false),
        ),
        for (final e in _errors.toSet())
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(validationText(context, e) ?? e, style: const TextStyle(color: AppColors.danger)),
          ),
        const SizedBox(height: AppSpacing.lg),
        LoadingButton(label: l.uploadCertificate, icon: Icons.lock_rounded, loading: _saving, onPressed: _submit),
      ],
    );
  }
}
