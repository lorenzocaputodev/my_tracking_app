import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/my_tracking_provider.dart';
import '../utils/app_clock.dart';
import '../utils/app_formatters.dart';
import '../widgets/action_button.dart';
import '../widgets/option_sheet.dart';
import '../widgets/stats_card.dart';
import '../widgets/week_bars.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'achievements_screen.dart';
import '../theme/app_fonts.dart';
import '../theme/app_dimens.dart';
import '../theme/app_decorations.dart';
import '../theme/theme_context.dart';
import '../theme/app_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final turquoise = theme.colorScheme.primary;

    return Consumer<MyTrackingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context, turquoise),
          body: _buildBody(context, provider, isDark, turquoise),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, Color turquoise) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.history_rounded, color: turquoise),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        ),
      ),
      title: Text(
        'My Tracking App',
        style: TextStyle(fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
          color: turquoise,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.emoji_events_rounded, color: turquoise),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AchievementsScreen()),
          ),
        ),
        IconButton(
          icon: Icon(Icons.tune_rounded, color: turquoise),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    MyTrackingProvider provider,
    bool isDark,
    Color turquoise,
  ) {
    final size = MediaQuery.of(context).size;
    final usesInventory = provider.activeProduct.tracksInventory;
    final isPackEmpty = usesInventory && provider.packRemaining <= 0;
    final showMinutes = provider.config.minutesLost > 0;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _ProductChip(provider: provider),
          if (provider.dailyLimitReached) ...[
            const SizedBox(height: 8),
            _DailyLimitBanner(
              count: provider.dailyCount,
              limit: provider.config.dailyLimit,
            ),
          ],
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fit = _fitCenter(
                  context,
                  available: constraints.maxHeight,
                  buttonSize: size.width * 0.55,
                  hasInsight: provider.homeInsight != null,
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DailyCounter(
                          count: provider.dailyCount,
                          fontSize: fit.counterSize,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ULTIMA: ${provider.timeSinceLastEntry.toUpperCase()}',
                          style: TextStyle(fontFamily: AppFonts.sans,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: turquoise.withValues(alpha: 0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (fit.showInsight) ...[
                          const SizedBox(height: 10),
                          _HomeInsightBadge(
                            insight: provider.homeInsight!,
                            accent: turquoise,
                          ),
                        ],
                        SizedBox(height: fit.above),
                        if (isPackEmpty)
                          _OpenPackButton(
                            size: size.width * 0.55,
                            provider: provider,
                          )
                        else
                          ActionButton(
                            size: size.width * 0.55,
                            actionLabel: 'HO USATO',
                            onLongPress: () =>
                                _showCreatorEasterEgg(context, turquoise),
                            onTap: () async {
                              if (provider.activeProduct.tracksInventory &&
                                  provider.packRemaining <= 0) {
                                return;
                              }
                              final entry = await provider.logEntry();
                              if (entry == null || !context.mounted) return;
                              if (provider.activeProduct.tracksInventory &&
                                  provider.packRemaining == 0) {
                                _showPackFinishedAlert(context, provider);
                                return;
                              }
                              _showUndoLogged(context, provider, entry.id);
                            },
                          ),
                        if (fit.showCost) ...[
                          SizedBox(height: fit.below),
                          _SubLabel(provider: provider),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _WeekStrip(provider: provider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: StatsCard(
                    icon: Icons.euro_rounded,
                    label: 'Oggi',
                    value: formatEuro(provider.dailyCost),
                    accent: turquoise,
                  ),
                ),
                if (showMinutes) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.timer_rounded,
                      label: 'Vita persa oggi',
                      value: _formatMinutes(provider.dailyMinutesLost),
                      accent: context.stats.time,
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: StatsCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Totale speso',
                    value: formatEuro(provider.totalCost),
                    accent: turquoise.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Adatta la parte centrale della home allo spazio che resta sopra le
  /// card. Con posto a sufficienza tutto resta com'e' (spazi di 40 e 30);
  /// quando manca (piu' prodotti, banner del limite) riduce prima gli spazi,
  /// poi toglie la riga del costo, poi rimpicciolisce il contatore, e solo
  /// alla fine toglie il suggerimento. "HO USATO" non cambia mai dimensione.
  ({
    double above,
    double below,
    bool showInsight,
    bool showCost,
    double counterSize,
  }) _fitCenter(
    BuildContext context, {
    required double available,
    required double buttonSize,
    required bool hasInsight,
  }) {
    final t = MediaQuery.textScalerOf(context).scale(1);
    const minAbove = 12.0, minBelow = 8.0;
    var showInsight = hasInsight;
    var showCost = true;
    var counterSize = 92.0;

    // Contatore con OGGI, riga ULTIMA, pulsante, e le parti facoltative.
    double content() =>
        (counterSize + 16) * t +
        8 +
        16 * t +
        buttonSize +
        (showInsight ? 10 + 36 * t : 0) +
        (showCost ? 16 * t : 0);
    // Le altezze del testo sono stime: 8 di margine per non toccare la card.
    double needed() => content() + minAbove + (showCost ? minBelow : 0) + 8;

    if (needed() > available) showCost = false;
    if (needed() > available) counterSize = 64;
    if (needed() > available) showInsight = false;

    final free = available - content() - 8;
    return (
      above: showCost
          ? (free * 4 / 7).clamp(minAbove, 40.0)
          : free.clamp(minAbove, 40.0),
      below: showCost ? (free * 3 / 7).clamp(minBelow, 30.0) : 0,
      showInsight: showInsight,
      showCost: showCost,
      counterSize: counterSize,
    );
  }

  /// Dopo ogni tocco, per qualche secondo, si puo' annullare: rimedia al
  /// tocco di troppo senza impedire di registrarne piu' di fila, come fa chi
  /// segna tutto a fine giornata.
  void _showUndoLogged(
    BuildContext context,
    MyTrackingProvider provider,
    String entryId,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Registrato · ${provider.dailyCount} oggi'),
          duration: const Duration(seconds: 3),
          // Con un'azione Flutter lo lascerebbe a schermo finche' non lo si
          // chiude: qui deve sparire da solo.
          persist: false,
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () => provider.deleteEntry(entryId),
          ),
        ),
      );
  }

  void _showCreatorEasterEgg(BuildContext context, Color accent) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A2F2F), const Color(0xFF0D1818)]
                      : [const Color(0xFFE8FAFA), Colors.white],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded, color: accent, size: 44),
                    const SizedBox(height: 20),
                    Text(
                      'Applicazione creata da Lorenzo Caputo, with love <3',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: AppFonts.sans,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: context.colors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: accent.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Bye Bye',
                          style: TextStyle(fontFamily: AppFonts.sans,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPackFinishedAlert(
    BuildContext context,
    MyTrackingProvider provider,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📦 ${provider.config.name} terminato!'),
        backgroundColor: context.stats.warning,
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'Reintegra',
          textColor: Colors.black,
          onPressed: () => provider.openNewPack(),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _DailyLimitBanner extends StatelessWidget {
  final int count;
  final int limit;
  const _DailyLimitBanner({required this.count, required this.limit});

  @override
  Widget build(BuildContext context) {
    final over = count > limit;
    final color = over ? context.stats.danger : context.stats.warning;
    final message = over
        ? 'Sopra il limite impostato ($count/$limit)'
        : 'Limite giornaliero raggiunto ($count/$limit)';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            over ? Icons.trending_up_rounded : Icons.warning_amber_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(fontFamily: AppFonts.sans,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenPackButton extends StatelessWidget {
  final double size;
  final MyTrackingProvider provider;
  const _OpenPackButton({required this.size, required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => provider.openNewPack(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.stats.warning.withValues(alpha: 0.1),
          border: Border.all(
            color: context.stats.warning.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.stats.warning.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_box_rounded,
              size: 44,
              color: context.stats.warning,
            ),
            const SizedBox(height: 10),
            Text(
              'NUOVA\nSCORTA',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w900,
                color: context.stats.warning,
                fontSize: 14,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prodotto in uso e scorta, in un'unica pillola. Con piu' prodotti si
/// tocca per cambiarlo: sostituisce il vecchio menu a tendina, che occupava
/// mezza schermata.
class _ProductChip extends StatelessWidget {
  final MyTrackingProvider provider;
  const _ProductChip({required this.provider});

  Future<void> _choose(BuildContext context) async {
    final picked = await showOptionSheet<String>(
      context,
      title: 'Prodotto in uso',
      selected: provider.activeProduct.id,
      options: [
        for (final p in provider.activeProducts)
          SheetOption(
            p.id,
            p.name,
            icon: p.tracksInventory ? AppIcons.stock : AppIcons.noStock,
            subtitle: p.tracksInventory
                ? '${p.packRemaining}/${p.pieces} in scorta'
                : 'Senza scorta',
          ),
      ],
    );
    if (picked != null) await provider.setActiveProduct(picked);
  }

  @override
  Widget build(BuildContext context) {
    final product = provider.activeProduct;
    final canSwitch = provider.activeProducts.length > 1;
    if (!product.tracksInventory && !canSwitch) return const SizedBox.shrink();

    final accent = context.accent;
    final remaining = provider.packRemaining;
    final isZero = product.tracksInventory && remaining == 0;
    final stockColor = isZero
        ? context.stats.danger
        : (remaining <= 5 ? context.stats.warning : accent);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isZero
            ? context.stats.danger.withValues(alpha: 0.1)
            : accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: isZero
              ? context.stats.danger.withValues(alpha: 0.3)
              : accent.withValues(alpha: canSwitch ? 0.3 : 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              product.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: canSwitch ? accent : accent.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (canSwitch) ...[
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 18, color: accent),
          ],
          if (product.tracksInventory) ...[
            Container(
              height: 12,
              width: 1,
              color: accent.withValues(alpha: 0.2),
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            Icon(AppIcons.stock, size: 14, color: stockColor),
            const SizedBox(width: 6),
            Text(
              '$remaining / ${product.pieces}',
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: stockColor,
              ),
            ),
          ],
        ],
      ),
    );

    if (!canSwitch) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _choose(context),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: chip,
      ),
    );
  }
}

class _DailyCounter extends StatelessWidget {
  final int count;
  final double fontSize;
  const _DailyCounter({required this.count, this.fontSize = 92});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Text(
            '$count',
            key: ValueKey(count),
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
        ),
        const Text(
          'OGGI',
          style: TextStyle(fontFamily: AppFonts.sans,
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  final MyTrackingProvider provider;
  const _SubLabel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final label = provider.activeProduct.tracksInventory
        ? 'Costo unitario'
        : 'Costo per utilizzo';
    return Text(
      '$label: ${formatEuro(provider.config.unitCost)}',
      style: TextStyle(fontFamily: AppFonts.sans,
        fontSize: 12,
        color: Colors.grey.withValues(alpha: 0.6),
      ),
    );
  }
}

class _HomeInsightBadge extends StatelessWidget {
  final HomeInsight insight;
  final Color accent;

  const _HomeInsightBadge({required this.insight, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = switch (insight.type) {
      HomeInsightType.planAhead => (
          Icons.trending_down_rounded,
          context.stats.positive,
        ),
      HomeInsightType.planOnTrack => (Icons.track_changes_rounded, accent),
      HomeInsightType.planBehind => (
          Icons.trending_up_rounded,
          context.stats.warning,
        ),
      HomeInsightType.limitRemaining => (Icons.flag_rounded, accent),
      HomeInsightType.comparedToYesterday => (
          Icons.compare_arrows_rounded,
          isDark ? Colors.white70 : const Color(0xFF1A6770),
        ),
    };
    final backgroundAlpha = isDark ? 0.10 : 0.16;
    final borderAlpha = isDark ? 0.28 : 0.36;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            insight.message,
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final MyTrackingProvider provider;
  const _WeekStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.entriesForProduct(provider.activeProduct.id);
    if (WeekBars.countsFor(entries, appNow()).every((c) => c == 0)) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: AppDecorations.cardSubtle(context.colors),
      child: WeekBars(
        entries: entries,
        dailyLimit: provider.config.dailyLimit,
      ),
    );
  }
}
