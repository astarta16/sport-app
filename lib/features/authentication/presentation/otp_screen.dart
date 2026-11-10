import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.verificationId, required this.phone});

  final String verificationId;
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  late String _vid = widget.verificationId;
  bool _loading = false;
  String? _error;
  int _seconds = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final err = Validators.otp(_code.text);
    if (err != null) {
      setState(() => _error = validationText(context, err));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyCode(_vid, _code.text);
      // The router redirects once the session stream updates.
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      _vid = await ref.read(authRepositoryProvider).sendCode(widget.phone);
      _startTimer();
    } catch (e) {
      if (mounted) showAppSnack(context, errorText(context, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final demo = ref.watch(appModeProvider) == AppMode.demo;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.otpTitle, style: t.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.otpSubtitle(Validators.formatPhone(widget.phone)),
                style: t.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                key: const Key('otp-field'),
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textAlign: TextAlign.center,
                maxLength: 6,
                style: t.headlineMedium?.copyWith(letterSpacing: 14),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(counterText: '', hintText: '••••••', errorText: _error),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              if (demo) ...[const SizedBox(height: AppSpacing.sm), DemoBanner(text: l.demoOtpHint)],
              const SizedBox(height: AppSpacing.lg),
              LoadingButton(label: l.verify, loading: _loading, onPressed: _verify),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _seconds > 0 ? null : _resend,
                  child: Text(_seconds > 0 ? l.resendIn(_seconds) : l.resendCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
