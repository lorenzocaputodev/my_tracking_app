import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_setup_screen.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../l10n/l10n.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static List<_OnboardingSlide> _slides(AppLocalizations l10n) => [
        _OnboardingSlide(
          imagePath: 'assets/icon/logo_app.png',
          title: l10n.onboardingWelcomeTitle,
          description: l10n.onboardingWelcomeBody,
        ),
        _OnboardingSlide(
          icon: Icons.track_changes_rounded,
          title: l10n.onboardingTrackTitle,
          description: l10n.onboardingTrackBody,
        ),
        _OnboardingSlide(
          icon: Icons.tune_rounded,
          title: l10n.onboardingCustomizeTitle,
          description: l10n.onboardingCustomizeBody,
        ),
        _OnboardingSlide(
          icon: Icons.favorite_border_rounded,
          title: l10n.onboardingTimeTitle,
          description: l10n.onboardingTimeBody,
        ),
        _OnboardingSlide(
          icon: Icons.bolt_rounded,
          title: l10n.onboardingTapTitle,
          description: l10n.onboardingTapBody,
        ),
        _OnboardingSlide(
          icon: Icons.bar_chart_rounded,
          title: l10n.onboardingProgressTitle,
          description: l10n.onboardingProgressBody,
        ),
      ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProductSetupScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turquoise = context.accent;
    final slides = _slides(context.l10n);
    final isLast = _currentPage == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    context.l10n.skip,
                    style: TextStyle(fontFamily: AppFonts.sans,
                      color: turquoise.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  final isImage = slide.imagePath != null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isImage
                                ? Colors.transparent
                                : turquoise.withValues(alpha: 0.1),
                            border: Border.all(
                              color: turquoise.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: isImage
                                ? Image.asset(
                                    slide.imagePath!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    slide.icon,
                                    size: 52,
                                    color: turquoise,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: AppFonts.sans,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color:
                                context.colors.textHeading,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: AppFonts.sans,
                            fontSize: 16,
                            height: 1.6,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? turquoise
                              : turquoise.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLast
                          ? _completeOnboarding
                          : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.action,
                        foregroundColor: context.colors.onAction,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? context.l10n.start : context.l10n.next,
                        style: const TextStyle(fontFamily: AppFonts.sans,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String description;

  const _OnboardingSlide({
    this.icon,
    this.imagePath,
    required this.title,
    required this.description,
  });
}
