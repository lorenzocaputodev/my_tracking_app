import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../providers/my_tracking_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Obiettivi & Badge'), elevation: 0),
      body: Consumer<MyTrackingProvider>(
        builder: (context, provider, _) {
          final all = provider.allAchievements;
          final unlocked = provider.unlockedAchievements;
          final locked =
              all.where((achievement) => !achievement.isUnlocked).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _ProgressBanner(
                unlocked: unlocked.length,
                total: all.length,
                color: turquoise,
              ),
              const SizedBox(height: 16),
              _ReductionCard(provider: provider, color: turquoise),
              const SizedBox(height: 24),
              _SectionTitle(
                label: 'SBLOCCATI',
                count: unlocked.length,
                color: turquoise,
              ),
              const SizedBox(height: 12),
              unlocked.isEmpty
                  ? const _EmptyHint(
                      'Registra le prime attivit\u00E0 per sbloccare i badge!',
                    )
                  : _BadgeGrid(achievements: unlocked, color: turquoise),
              const SizedBox(height: 24),
              _SectionTitle(
                label: 'DA SBLOCCARE',
                count: locked.length,
                color: turquoise,
              ),
              const SizedBox(height: 12),
              locked.isEmpty
                  ? const _EmptyHint('Hai sbloccato tutti i badge! \u{1F389}')
                  : _BadgeGrid(
                      achievements: locked,
                      color: turquoise,
                      locked: true,
                    ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  final int unlocked;
  final int total;
  final Color color;

  const _ProgressBanner({
    required this.unlocked,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$unlocked / $total badge',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReductionCard extends StatelessWidget {
  final MyTrackingProvider provider;
  final Color color;

  const _ReductionCard({required this.provider, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = provider.reductionPlan;
    final isArchivedPlan = plan != null &&
        provider.archivedProducts.any(
          (product) => product.id == plan.productId,
        );

    if (plan == null) {
      return OutlinedButton.icon(
        onPressed: () => _showPlanSheet(
          context,
          provider,
          color,
          productId: provider.activeProduct.id,
        ),
        icon: Icon(Icons.trending_down_rounded, color: color),
        label: Text(
          'Imposta piano di riduzione',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          minimumSize: const Size(double.infinity, 0),
        ),
      );
    }

    final productName = provider.productNameById(plan.productId) ?? 'Prodotto';
    final progress = isArchivedPlan
        ? null
        : provider.reductionProgressForProduct(plan.productId);
    final recentAverage = progress?.recentAverage ??
        provider.averageDailyCountForRange(
          productId: plan.productId,
          start: DateTime.now().subtract(const Duration(days: 6)),
          end: DateTime.now(),
        );
    final status = progress?.status;
    final (statusLabel, statusColor) = isArchivedPlan
        ? ('SOSPESO', Colors.orangeAccent)
        : switch (status) {
            ReductionPlanStatus.ahead => (
                'AVANTI',
                Colors.greenAccent.shade700,
              ),
            ReductionPlanStatus.onTrack => ('IN LINEA', color),
            ReductionPlanStatus.behind => ('IN RITARDO', Colors.orangeAccent),
            null => ('ATTIVO', color),
          };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PIANO DI RIDUZIONE',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              _StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Prodotto: $productName',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PlanStat(
                  label: 'Inizio',
                  value: plan.startAverage.toStringAsFixed(1),
                  unit: 'unit\u00E0/g',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanStat(
                  label: 'Media 7 giorni',
                  value: recentAverage.toStringAsFixed(1),
                  unit: 'unit\u00E0/g',
                  highlight: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PlanStat(
                  label: 'Target oggi',
                  value: plan.currentWeekTarget.toStringAsFixed(1),
                  unit: 'unit\u00E0/g',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanStat(
                  label: 'Obiettivo finale',
                  value: plan.targetPerDay.toStringAsFixed(1),
                  unit: 'unit\u00E0/g',
                  highlight: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settimana ${plan.currentWeekNumber} / ${plan.totalWeeks}',
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey),
              ),
              Text(
                plan.isCompleted
                    ? 'Completato!'
                    : '${plan.daysRemaining} giorni rimanenti',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: plan.isCompleted ? Colors.greenAccent.shade700 : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: plan.progressFraction,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArchivedPlan
                        ? 'Piano sospeso. Ripristina il prodotto dalle impostazioni per riattivarlo.'
                        : switch (status) {
                            ReductionPlanStatus.ahead =>
                              'Sei sotto il target settimanale previsto.',
                            ReductionPlanStatus.onTrack =>
                              'Sei in linea con il piano attivo.',
                            ReductionPlanStatus.behind =>
                              'Sei sopra il target settimanale previsto.',
                            null => 'Piano attivo su questo prodotto.',
                          },
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isArchivedPlan
                      ? null
                      : () => _showPlanSheet(
                            context,
                            provider,
                            color,
                            productId: plan.productId,
                          ),
                  style: _outlinedButtonStyle(color),
                  child: Text(
                    isArchivedPlan ? 'Sospeso' : 'Modifica',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _confirmDeletePlan(context, provider),
                style: _outlinedButtonStyle(Colors.redAccent),
                child: Text(
                  'Elimina',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlinedButtonStyle(Color color) => OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      );

  Future<void> _confirmDeletePlan(
    BuildContext context,
    MyTrackingProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Elimina piano',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Vuoi eliminare il piano di riduzione?',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Elimina',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteReductionPlan();
    }
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final Color color;
  final bool locked;

  const _BadgeGrid({
    required this.achievements,
    required this.color,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) => _BadgeCard(
        achievement: achievements[index],
        color: color,
        locked: locked,
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Achievement achievement;
  final Color color;
  final bool locked;

  const _BadgeCard({
    required this.achievement,
    required this.color,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: locked
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.03))
              : color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locked ? Colors.transparent : color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: locked
                  ? const ColorFilter.matrix(<double>[
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ])
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: locked
                    ? Colors.grey
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (!locked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM', 'it').format(achievement.unlockedAt!),
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(achievement.emoji, style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 14),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                !locked && achievement.unlockedAt != null
                    ? 'Sbloccato il ${DateFormat('d MMMM yyyy', 'it').format(achievement.unlockedAt!)}'
                    : 'Non ancora sbloccato',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: !locked && achievement.unlockedAt != null
                      ? color
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Chiudi',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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

void _showPlanSheet(
  BuildContext context,
  MyTrackingProvider provider,
  Color color, {
  required String productId,
}) {
  final productName = provider.productNameById(productId) ?? 'Prodotto';
  final currentAverage = provider.dailyAverageForProduct(productId);
  final existingPlan = provider.reductionPlanForProduct(productId);
  double target =
      (existingPlan?.targetPerDay ?? (currentAverage / 2).clamp(0.0, 40.0))
          .clamp(0.0, 40.0);
  int weeks = existingPlan?.totalWeeks ?? 8;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final maxSlider = (currentAverage * 1.1).clamp(1.0, 40.0);

        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Piano di riduzione',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prodotto: $productName',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Media attuale: ${currentAverage.toStringAsFixed(1)} unit\u00E0/giorno',
                style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                'Obiettivo finale: ${target.toStringAsFixed(1)} unit\u00E0/giorno',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Slider(
                value: target.clamp(0.0, maxSlider),
                min: 0,
                max: maxSlider,
                divisions: (maxSlider * 2).round().clamp(2, 80),
                activeColor: color,
                inactiveColor: color.withValues(alpha: 0.15),
                onChanged: (value) => setState(() => target = value),
              ),
              const SizedBox(height: 12),
              Text(
                'Durata: $weeks settimane',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Slider(
                value: weeks.toDouble(),
                min: 2,
                max: 26,
                divisions: 24,
                activeColor: color,
                inactiveColor: color.withValues(alpha: 0.15),
                onChanged: (value) => setState(() => weeks = value.round()),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Riduzione di ${(currentAverage - target).toStringAsFixed(1)} unit\u00E0/g in $weeks settimane.',
                        style: GoogleFonts.dmSans(fontSize: 12, color: color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await provider.setReductionPlan(
                      productId: productId,
                      targetPerDay: target,
                      totalWeeks: weeks,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    existingPlan != null ? 'Aggiorna piano' : 'Imposta piano',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionTitle({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? highlight;

  const _PlanStat({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: _cardDecoration(isDark),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF161B1B) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
    ),
  );
}
