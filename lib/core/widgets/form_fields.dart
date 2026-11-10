import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

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
                  Expanded(child: Text(validationText(context, e) ?? e)),
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
