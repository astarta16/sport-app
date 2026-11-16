import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../features/trainings/domain/training.dart' show PhotoUpload;
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

/// Tappable read-only field that opens a picker (date, time, …).
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.icon, required this.label, required this.onTap, required this.filled});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: filled ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// v1.9.1 (M21): the localized text for a validation code; an unknown code
/// is never shown raw but as a generic "please check this field" message.
String fieldErrorText(BuildContext context, String code) =>
    validationText(context, code) ?? context.l10n.m191FieldGenericError;

/// Localized validation errors shown under a form.
class FormErrors extends StatelessWidget {
  const FormErrors({super.key, required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('form-errors'),
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in errors.toSet())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Expanded(child: Text(fieldErrorText(context, e))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Date + time pickers in one row.
class DateTimeRow extends StatelessWidget {
  const DateTimeRow({
    super.key,
    required this.date,
    required this.time,
    required this.onDate,
    required this.onTime,
    required this.firstDate,
    this.lastDate,
    this.keyPrefix = 'dt',
  });

  final DateTime? date;
  final TimeOfDay? time;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<TimeOfDay> onTime;
  final DateTime firstDate;
  final DateTime? lastDate;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    return Row(
      children: [
        Expanded(
          child: PickerField(
            key: Key('$keyPrefix-date'),
            icon: Icons.calendar_today_rounded,
            label: date == null ? l.dateLabel : f.weekdayDayMonth(date!),
            filled: date != null,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: date ?? firstDate,
                firstDate: firstDate,
                lastDate: lastDate ?? firstDate.add(const Duration(days: 366)),
              );
              if (d != null) onDate(d);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 120,
          child: PickerField(
            key: Key('$keyPrefix-time'),
            icon: Icons.schedule_rounded,
            label: time == null ? l.timeLabel : time!.format(context),
            filled: time != null,
            onTap: () async {
              final tm = await showTimePicker(
                context: context,
                initialTime: time ?? const TimeOfDay(hour: 17, minute: 0),
              );
              if (tm != null) onTime(tm);
            },
          ),
        ),
      ],
    );
  }
}

/// Where a picked file comes from (v1.9.1, M20/M22).
enum FileSource { camera, gallery, file }

/// The picked file, shown right under the picker buttons (v1.9.1, M20/M22):
/// thumbnail for an image or a PDF icon, name, size, Replace and Remove.
class PickedFileCard extends StatelessWidget {
  const PickedFileCard({
    super.key,
    required this.file,
    required this.onRemove,
    this.onReplace,
    this.keyPrefix = 'file',
  });

  final PhotoUpload file;
  final VoidCallback? onRemove;

  /// Shows a Replace menu with the three sources when given.
  final ValueChanged<FileSource>? onReplace;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isImage = file.mimeType.startsWith('image/');
    final thumb = isImage && file.bytes.length > 100
        ? ClipRRect(
            key: Key('$keyPrefix-thumb'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Image.memory(
              Uint8List.fromList(file.bytes),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.image_rounded, size: 40),
            ),
          )
        : SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              size: 40,
              color: isImage ? scheme.primary : AppColors.danger,
            ),
          );
    return AppCard(
      key: Key('$keyPrefix-card'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          thumb,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(l.m191FileSize((file.bytes.length / 1024).ceil()), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onReplace != null)
            PopupMenuButton<FileSource>(
              key: Key('$keyPrefix-replace'),
              tooltip: l.m191ReplaceFile,
              enabled: onRemove != null,
              onSelected: onReplace,
              icon: const Icon(Icons.swap_horiz_rounded),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: FileSource.camera,
                  child: ListTile(leading: const Icon(Icons.photo_camera_rounded), title: Text(l.takePhoto)),
                ),
                PopupMenuItem(
                  value: FileSource.gallery,
                  child: ListTile(leading: const Icon(Icons.photo_library_rounded), title: Text(l.m191PhotoLibrary)),
                ),
                PopupMenuItem(
                  value: FileSource.file,
                  child: ListTile(leading: const Icon(Icons.picture_as_pdf_rounded), title: Text(l.m191PdfFile)),
                ),
              ],
            ),
          IconButton(
            key: Key('$keyPrefix-remove'),
            tooltip: l.m191RemoveFile,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

/// Camera / Photo library / PDF file buttons (v1.9.1, M20/M22).
class FileSourceButtons extends StatelessWidget {
  const FileSourceButtons({super.key, required this.onPick, this.keyPrefix = 'file', this.extra = const []});

  final ValueChanged<FileSource>? onPick;
  final String keyPrefix;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget b(FileSource s, IconData icon, String label) => OutlinedButton.icon(
      key: Key('$keyPrefix-pick-${s.name}'),
      onPressed: onPick == null ? null : () => onPick!(s),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        b(FileSource.camera, Icons.photo_camera_rounded, l.takePhoto),
        b(FileSource.gallery, Icons.photo_library_rounded, l.m191PhotoLibrary),
        b(FileSource.file, Icons.picture_as_pdf_rounded, l.m191PdfFile),
        ...extra,
      ],
    );
  }
}
