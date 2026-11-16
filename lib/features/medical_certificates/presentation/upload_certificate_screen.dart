import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/services/error_reporter.dart';
import '../../../core/services/media_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/unsaved_changes_guard.dart';
import '../../../core/widgets/visuals.dart';
import '../../children/presentation/children_providers.dart';
import '../../sports/presentation/sports_providers.dart';
import '../../trainings/domain/training.dart';
import '../domain/medical_certificate.dart';
import '../../sports/presentation/sport_label.dart';
import 'certificates_providers.dart';

/// Two steps (spec §7.1): consent screen first, then file + dates.
class UploadCertificateScreen extends ConsumerStatefulWidget {
  const UploadCertificateScreen({super.key, required this.childId, this.replaceCertId});

  final String childId;

  /// Replace flow: the new certificate supersedes this one.
  final String? replaceCertId;

  @override
  ConsumerState<UploadCertificateScreen> createState() => _UploadCertificateScreenState();
}

class _UploadCertificateScreenState extends ConsumerState<UploadCertificateScreen> {
  bool _consent = false;
  bool _consentStepDone = false;
  PhotoUpload? _file;
  DateTime? _issued;
  DateTime? _validUntil;
  String? _sportId;
  bool _sportInit = false;
  bool _saving = false;
  List<String> _errors = const [];

  // v1.9.1 (M20/M25): failed upload shown inline (inputs kept); dirty guard.
  Object? _uploadError;
  bool _saved = false;
  String? _initialSportId;

  bool get _dirty =>
      !_saved && (_consent || _file != null || _issued != null || _validUntil != null || _sportId != _initialSportId);

  static const _fileErrors = {'fileEmpty', 'fileType', 'fileTooLarge'};

  Future<void> _pick(FileSource source) async {
    try {
      final f = await switch (source) {
        FileSource.camera => MediaPicker.takePhoto(),
        FileSource.gallery => MediaPicker.pickOnePhoto(),
        FileSource.file => MediaPicker.pickDocument(),
      };
      if (f != null && mounted) {
        setState(() {
          _file = f;
          _errors = _errors.where((e) => !_fileErrors.contains(e)).toList();
        });
      }
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
      sportId: _sportId,
      replacesCertId: widget.replaceCertId,
    );
    final errors = [
      if (_file == null) 'fileEmpty',
      if (_issued == null || _validUntil == null) 'required',
      ...CertificatePolicy.validateUpload(upload).where((e) => !(e == 'fileEmpty' && _file == null)),
    ];
    setState(() {
      _errors = errors;
      _uploadError = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(certificatesRepositoryProvider).upload(upload);
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'ui-action');
      // Everything the parent entered stays; the banner offers a retry.
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadError = e;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    showAppSnack(context, context.l10n.certUploaded);
    context.popOrHome();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return UnsavedChangesGuard(
      dirty: _dirty,
      child: Scaffold(
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
    final t = Theme.of(context).textTheme;
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

    final child = ref.watch(childProvider(widget.childId)).value;
    final sports = ref.watch(sportsByIdProvider);
    final certs = ref.watch(childCertificatesProvider(widget.childId)).value ?? const <MedicalCertificate>[];
    if (!_sportInit && widget.replaceCertId != null) {
      final old = certs.where((c) => c.id == widget.replaceCertId).firstOrNull;
      if (old != null) {
        _sportInit = true;
        _sportId = old.sportId;
        _initialSportId = old.sportId;
      }
    }
    // The certificate that applies today: the one being replaced, or the
    // current one (latest expiry wins, see CertificatePolicy.current).
    final existing = widget.replaceCertId != null
        ? certs.where((c) => c.id == widget.replaceCertId).firstOrNull
        : CertificatePolicy.current(certs, sportId: _sportId);
    final fileErrors = _errors.where(_fileErrors.contains).toSet();
    final otherErrors = _errors.where((e) => !_fileErrors.contains(e)).toSet();
    Widget errorLine(String e) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(fieldErrorText(context, e), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    Widget dateTile(Key key, IconData icon, String title, DateTime? value, bool issued) => ListTile(
      key: key,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline),
      ),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value == null ? '—' : f.fullDate(value)),
      onTap: _saving ? null : () => pickDate(issued),
    );
    return ListView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (widget.replaceCertId != null) ...[DemoBanner(text: l.certReplace), const SizedBox(height: AppSpacing.sm)],
        if (existing != null) ...[
          Builder(
            builder: (context) {
              final status = existing.statusOn(DateTime.now());
              final visual = StatusVisual.certificate(context, status);
              return AppFeedbackBanner(
                key: const Key('cert-existing'),
                tone: switch (status) {
                  CertificateStatus.valid => FeedbackTone.success,
                  CertificateStatus.expiring => FeedbackTone.warning,
                  _ => FeedbackTone.error,
                },
                title: l.m191CertExistingValid(visual.label, f.fullDate(existing.validUntil)),
                message: widget.replaceCertId != null ? l.m191CertReplacesExisting : l.m191CertAddsToExisting,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppFormSection(
          title: l.uploadCertificate,
          hint: l.m191FileGuidance(CertificatePolicy.maxBytes ~/ (1024 * 1024)),
          children: [
            if (_file == null)
              FileSourceButtons(
                keyPrefix: 'cert',
                onPick: _saving ? null : _pick,
                extra: [
                  if (AppConfig.isDemo)
                    OutlinedButton.icon(
                      key: const Key('cert-demo-file'),
                      onPressed: _saving
                          ? null
                          : () => setState(
                              () => _file = PhotoUpload(
                                bytes: Uint8List.fromList(List.filled(4096, 1)),
                                fileName: 'cnoba.pdf',
                                mimeType: 'application/pdf',
                              ),
                            ),
                      icon: const Icon(Icons.science_rounded, size: 18),
                      label: Text(l.demoBadge),
                    ),
                ],
              )
            else
              PickedFileCard(
                keyPrefix: 'cert-file',
                file: _file!,
                onRemove: _saving ? null : () => setState(() => _file = null),
                onReplace: _pick,
              ),
            ...fileErrors.map(errorLine),
          ],
        ),
        dateTile(const Key('cert-issued'), Icons.event_rounded, l.issueDate, _issued, true),
        const SizedBox(height: AppSpacing.sm),
        dateTile(const Key('cert-valid-until'), Icons.event_available_rounded, l.expiryDate, _validUntil, false),
        ...otherErrors.map(errorLine),
        if ((child?.sportIds.length ?? 0) > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            key: const Key('cert-sport'),
            initialValue: _sportId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.certSportLabel),
            items: [
              DropdownMenuItem(value: null, child: Text(l.certAllSports)),
              for (final s in child!.sportIds) DropdownMenuItem(value: s, child: Text(sports[s]?.label(context) ?? s)),
            ],
            onChanged: _saving ? null : (v) => setState(() => _sportId = v),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_person_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text.rich(
                key: const Key('cert-who-can-see'),
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l.certConsentWho}: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: l.certConsentWhoBody),
                  ],
                ),
                style: t.bodySmall,
              ),
            ),
          ],
        ),
        if (_saving) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(key: Key('cert-progress')),
          const SizedBox(height: 4),
          Text(l.m191Uploading, style: t.bodySmall),
        ],
        if (_uploadError != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppFeedbackBanner(
            key: const Key('cert-upload-error'),
            tone: FeedbackTone.error,
            title: l.m191UploadFailedTitle,
            message: l.m191InputsKept(errorText(context, _uploadError!)),
            actionLabel: l.retry,
            onAction: _submit,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        LoadingButton(
          key: const Key('cert-submit'),
          label: l.uploadCertificate,
          icon: Icons.lock_rounded,
          loading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
