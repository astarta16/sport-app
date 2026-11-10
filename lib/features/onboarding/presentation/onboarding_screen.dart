import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/settings.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(appSettingsProvider.notifier).completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final slides = [
      (
        Icons.calendar_month_rounded,
        l.onboardingTitle1,
        l.onboardingBody1,
        const [Color(0xFF1D4ED8), Color(0xFF5B8CFF)],
      ),
      (Icons.forum_rounded, l.onboardingTitle2, l.onboardingBody2, const [Color(0xFF0F766E), Color(0xFF22C55E)]),
      (
        Icons.health_and_safety_rounded,
        l.onboardingTitle3,
        l.onboardingBody3,
        const [Color(0xFF6D28D9), Color(0xFFDB2777)],
      ),
    ];
    final last = _page == slides.length - 1;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l.onboardingSkip, style: const TextStyle(color: Colors.white70)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (icon, title, body, colors) = slides[i];
                    return LayoutBuilder(
                      builder: (context, c) {
                        // Scale the illustration to the window height (phone
                        // landscape, Split View) and keep text readable on iPad.
                        final art = (c.maxHeight * 0.4).clamp(96.0, 260.0);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: c.maxHeight),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      key: ValueKey(i),
                                      tween: Tween(begin: 0.85, end: 1),
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOutBack,
                                      builder: (_, s, child) => Transform.scale(scale: s, child: child),
                                      child: Container(
                                        width: art,
                                        height: art,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: colors,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colors.last.withValues(alpha: 0.4),
                                              blurRadius: 60,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Icon(icon, size: art * 0.44, color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(height: (c.maxHeight * 0.06).clamp(12.0, 48.0)),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      body,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyLarge
                                          ?.copyWith(color: Colors.white70, height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.volt : Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.volt, foregroundColor: AppColors.navy),
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          ),
                    child: Text(last ? l.onboardingStart : l.next),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
