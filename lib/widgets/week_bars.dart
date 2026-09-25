import 'package:flutter/material.dart';

import '../models/smoke_entry.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../utils/app_clock.dart';
import '../utils/app_formatters.dart';

const _weekdays = ['LUN', 'MAR', 'MER', 'GIO', 'VEN', 'SAB', 'DOM'];

/// Registrazioni degli ultimi sette giorni, oggi compreso: una barra per
/// giorno con il totale sopra. Con un limite giornaliero mostra la linea
/// del limite e colora in ambra i giorni che l'hanno superato.
///
/// Usa i totali giornalieri e non gli orari, che non sono affidabili per
/// chi registra tutto insieme a fine giornata.
class WeekBars extends StatelessWidget {
  final List<SmokeEntry> entries;
  final int dailyLimit;
  final double barHeight;

  const WeekBars({
    super.key,
    required this.entries,
    this.dailyLimit = 0,
    this.barHeight = 40,
  });

  /// Margine sopra la barra piu' alta, perche' la linea del limite resti
  /// visibile anche quando il limite e' il massimo.
  static const _headroom = 6.0;

  /// Totale e nome del giorno, sotto le barre: cosi' la linea del limite
  /// non attraversa mai del testo.
  static const _labelsHeight = 34.0;

  static List<int> countsFor(List<SmokeEntry> entries, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(7, 0);
    for (final e in entries) {
      final t = e.timestamp.toLocal();
      final days = DateTime.utc(today.year, today.month, today.day)
          .difference(DateTime.utc(t.year, t.month, t.day))
          .inDays;
      if (days >= 0 && days < 7) counts[6 - days]++;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = context.accent;
    final warning = context.stats.warning;
    final now = appNow();
    final counts = countsFor(entries, now);
    final scale = [...counts, dailyLimit, 1].reduce((a, b) => a > b ? a : b);
    final average = counts.reduce((a, b) => a + b) / 7;
    final small = AppTextStyles.microCaps(colors.textFaint);

    Color barColor(int i) {
      if (counts[i] == 0) return colors.textFaint.withValues(alpha: 0.3);
      if (dailyLimit > 0 && counts[i] > dailyLimit) return warning;
      return i == 6 ? accent : accent.withValues(alpha: 0.45);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('ULTIMI 7 GIORNI', style: AppTextStyles.sectionLabel(accent)),
            const Spacer(),
            Text(
              'media ${formatDecimal(average, decimals: 1)}/giorno',
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: _headroom + barHeight + _labelsHeight,
          child: Stack(
            children: [
              if (dailyLimit > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  // Stessa formula dell'altezza delle barre: una barra pari
                  // al limite arriva esattamente alla linea.
                  bottom: _labelsHeight + 6 + (barHeight - 6) * dailyLimit / scale,
                  child: Row(
                    children: [
                      for (var i = 0; i < 40; i++)
                        Expanded(
                          child: Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            color: warning.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 18,
                            height: counts[i] == 0
                                ? 4
                                : 6 + (barHeight - 6) * counts[i] / scale,
                            decoration: BoxDecoration(
                              color: barColor(i),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(
                            height: _labelsHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${counts[i]}',
                                  style: TextStyle(
                                    fontFamily: AppFonts.sans,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: i == 6 ? accent : colors.textBody,
                                  ),
                                ),
                                Text(
                                  i == 6
                                      ? 'OGGI'
                                      : _weekdays[now
                                              .subtract(Duration(days: 6 - i))
                                              .weekday -
                                          1],
                                  style: i == 6
                                      ? small.copyWith(color: accent)
                                      : small,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
