import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/my_tracking_provider.dart';
import '../utils/app_formatters.dart';
import '../widgets/action_button.dart';
import '../widgets/stats_card.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'achievements_screen.dart';

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
        style: GoogleFonts.dmSans(
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
          _ProductPickerBar(provider: provider, turquoise: turquoise),
          if (provider.activeProducts.length > 1) const SizedBox(height: 8),
          if (usesInventory)
            _PackStatusChip(
              name: provider.config.name,
              remaining: provider.packRemaining,
              total: provider.config.pieces,
            ),
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
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DailyCounter(count: provider.dailyCount),
                        const SizedBox(height: 8),
                        Text(
                          'ULTIMA: ${provider.timeSinceLastEntry.toUpperCase()}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: turquoise.withValues(alpha: 0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (provider.homeInsight != null) ...[
                          const SizedBox(height: 10),
                          _HomeInsightBadge(
                            insight: provider.homeInsight!,
                            accent: turquoise,
                          ),
                        ],
                        const SizedBox(height: 40),
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
                              await provider.logEntry();
                              if (provider.activeProduct.tracksInventory &&
                                  provider.packRemaining == 0 &&
                                  context.mounted) {
                                _showPackFinishedAlert(context, provider);
                              }
                            },
                          ),
                        const SizedBox(height: 30),
                        _SubLabel(provider: provider),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                      accent: Colors.redAccent,
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
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
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
                        child: Text(
                          'Bye Bye',
                          style: GoogleFonts.dmSans(
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
        backgroundColor: Colors.orangeAccent,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RICARICA',
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

class _ProductPickerBar extends StatelessWidget {
  final MyTrackingProvider provider;
  final Color turquoise;

  const _ProductPickerBar({required this.provider, required this.turquoise});

  @override
  Widget build(BuildContext context) {
    if (provider.activeProducts.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: turquoise.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: turquoise.withValues(alpha: 0.12)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: provider.activeProduct.id,
            isExpanded: true,
            icon: Icon(Icons.expand_more_rounded, color: turquoise, size: 22),
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            items: provider.activeProducts
                .map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      p.name,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) {
              if (id != null) provider.setActiveProduct(id);
            },
          ),
        ),
      ),
    );
  }
}

class _DailyLimitBanner extends StatelessWidget {
  final int count;
  final int limit;
  const _DailyLimitBanner({required this.count, required this.limit});

  @override
  Widget build(BuildContext context) {
    final over = count > limit;
    final color = over ? Colors.redAccent : Colors.orangeAccent;
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
              style: GoogleFonts.dmSans(
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
          color: Colors.orangeAccent.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_box_rounded,
              size: 44,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 10),
            Text(
              'NUOVA\nSCORTA',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w900,
                color: Colors.orangeAccent,
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

class _PackStatusChip extends StatelessWidget {
  final String name;
  final int remaining;
  final int total;
  const _PackStatusChip({
    required this.name,
    required this.remaining,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;
    final isLow = remaining <= 5;
    final isZero = remaining == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isZero
            ? Colors.redAccent.withValues(alpha: 0.1)
            : turquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isZero
              ? Colors.redAccent.withValues(alpha: 0.3)
              : turquoise.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color:
                  isZero ? Colors.redAccent : turquoise.withValues(alpha: 0.6),
              letterSpacing: 1.0,
            ),
          ),
          Container(
            height: 12,
            width: 1,
            color: turquoise.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Icon(
            Icons.inventory_2_rounded,
            size: 14,
            color: isZero
                ? Colors.redAccent
                : (isLow ? Colors.orangeAccent : turquoise),
          ),
          const SizedBox(width: 6),
          Text(
            '$remaining / $total',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isZero
                  ? Colors.redAccent
                  : (isLow ? Colors.orangeAccent : turquoise),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCounter extends StatelessWidget {
  final int count;
  const _DailyCounter({required this.count});

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
            style: GoogleFonts.dmSans(
              fontSize: 92,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
        ),
        Text(
          'OGGI',
          style: GoogleFonts.dmSans(
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
      style: GoogleFonts.dmSans(
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
          Colors.greenAccent.shade700,
        ),
      HomeInsightType.planOnTrack => (Icons.track_changes_rounded, accent),
      HomeInsightType.planBehind => (
          Icons.trending_up_rounded,
          Colors.orangeAccent,
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
            style: GoogleFonts.dmSans(
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
