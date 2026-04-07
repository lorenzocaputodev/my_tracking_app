import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      imagePath: 'assets/icon/logo_app.png',
      title: 'Benvenuto su\nMy Tracking App',
      description: 'Il tuo strumento personale per monitorare prodotti, '
          'abitudini, obiettivi e progressi in modo semplice, chiaro e completo.',
    ),
    _OnboardingSlide(
      icon: Icons.track_changes_rounded,
      title: 'Tieni traccia\ndi tutto',
      description: 'L\'app ti permette di tracciare pi\u00F9 prodotti in modo '
          'semplice e veloce. Ogni registrazione aggiorna subito i dati del '
          'prodotto attivo e costruisce una cronologia chiara delle tue abitudini.',
    ),
    _OnboardingSlide(
      icon: Icons.tune_rounded,
      title: 'Personalizza\nil tuo prodotto',
      description:
          'Puoi configurare ogni prodotto con nome, costo, modalit\u00E0 '
          'di tracciamento, limite giornaliero e altri parametri utili. L\'app '
          'calcola automaticamente i valori principali per ogni utilizzo.',
    ),
    _OnboardingSlide(
      icon: Icons.favorite_border_rounded,
      title: 'Quanto tempo\nti costa?',
      description:
          'Puoi impostare anche una stima dei minuti di vita persi per '
          'utilizzo. Non si tratta del tempo necessario a usare il prodotto, ma '
          'di una stima simbolica del suo impatto nel tempo sulla salute e sulla '
          'durata della vita. L\'app somma questo valore a ogni registrazione; '
          'se non \u00E8 rilevante, puoi lasciarlo a 0.',
    ),
    _OnboardingSlide(
      icon: Icons.bolt_rounded,
      title: 'Premi il bottone\nogni volta',
      description: 'Con un tap registri subito un utilizzo e aggiorni i dati '
          'della giornata. Se il prodotto usa la scorta, l\'app aggiorna anche '
          'il residuo. Puoi farlo rapidamente dall\'app e, su Android, anche dal '
          'widget per avere tutto ancora pi\u00F9 a portata di mano.',
    ),
    _OnboardingSlide(
      icon: Icons.bar_chart_rounded,
      title: 'Osserva\ni tuoi progressi',
      description: 'Consulta cronologia, statistiche e progressi per capire '
          'meglio le tue abitudini nel tempo. L\'app include grafici, obiettivi, '
          'badge, piano di riduzione, archivio prodotti e backup CSV, mantenendo '
          'tutti i dati salvati direttamente sul tuo dispositivo.',
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
    final turquoise = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Salta',
                  style: GoogleFonts.dmSans(
                    color: turquoise.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
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
                          style: GoogleFonts.dmSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark ? Colors.white54 : Colors.black54,
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
                    children: List.generate(_slides.length, (i) {
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
                        backgroundColor: turquoise,
                        foregroundColor: isDark ? Colors.black87 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLast ? 'INIZIA' : 'AVANTI',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 1.2,
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
