import 'package:flutter/material.dart';

import '../../features/trainings/domain/training.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'visuals.dart';

/// Mandatory cancellation reason (v1.1 §7): quick choice + 5–300 chars.
/// Returns null when dismissed. Validation mirrors the security rules.
Future<CancelReason?> showCancelReasonDialog(BuildContext context, {required String title}) {
  return showDialog<CancelReason>(
    context: context,
    builder: (_) => _CancelReasonDialog(title: title),
  );
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog({required this.title});

  final String title;

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  CancelReasonCode? _code;
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final err = CancelReason.validate(_code, _text.text);
    if (err != null) {
      setState(() => _error = validationText(context, err));
      return;
    }
    Navigator.pop(context, CancelReason(_code!, _text.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      key: const Key('cancel-reason-dialog'),
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.cancelReasonHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final c in CancelReasonCode.values)
                    ChoiceChip(
                      key: Key('cancel-reason-${c.name}'),
                      label: Text(cancelReasonLabel(context, c)),
                      selected: _code == c,
                      onSelected: (_) => setState(() {
                        _code = c;
                        _error = null;
                        if (_text.text.trim().isEmpty && c != CancelReasonCode.other) {
                          _text.text = cancelReasonLabel(context, c);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('cancel-reason-text'),
                controller: _text,
                maxLength: CancelReason.maxLength,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: l.cancelReasonTextLabel, errorText: _error),
                onChanged: (_) => setState(() => _error = null),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('cancel-reason-submit'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _submit,
          child: Text(l.cancelAction),
        ),
      ],
    );
  }
}
