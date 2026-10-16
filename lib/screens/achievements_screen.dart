import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_fonts.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../theme/theme_context.dart';
import '../utils/app_clock.dart';
import '../utils/app_formatters.dart';
import '../utils/calendar_days.dart';
import '../l10n/l10n.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final turquoise = context.accent;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.achievementsTitle), elevation: 0),
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
                label: context.l10n.unlockedSection,
                count: unlocked.length,
                color: turquoise,
              ),
              const SizedBox(height: 12),
              unlocked.isEmpty
                  ? _EmptyHint(context.l10n.noBadgesYet)
                  : _BadgeGrid(achievements: unlocked, color: turquoise),
              const SizedBox(height: 24),
              _SectionTitle(
                label: context.l10n.lockedSection,
                count: locked.length,
                color: turquoise,
              ),
              const SizedBox(height: 12),
              locked.isEmpty
                  ? _EmptyHint(context.l10n.allBadgesUnlocked)
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

// --- Avanzamento e piano di riduzione ---

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
    final pct = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(context.colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.badgeProgress(unlocked, total),
                style: TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMuted,
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
    final plan = provider.activeProductReductionPlan;

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
          context.l10n.setReductionPlan,
          style: TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w700, color: color),
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

    final productName =
        provider.productNameById(plan.productId) ?? context.l10n.product;
    final progress = provider.reductionProgressForProduct(plan.productId);
    final recentAverage = progress?.recentAverage ??
        provider.averageDailyCountForRange(
          productId: plan.productId,
          start: addDays(dateOnly(appNow()), -6),
          end: appNow(),
        );
    final status = progress?.status;
    final (statusLabel, statusColor) = switch (status) {
      ReductionPlanStatus.ahead => (
          context.l10n.planStatusAhead,
          context.stats.positive,
        ),
      ReductionPlanStatus.onTrack => (context.l10n.planStatusOnTrack, color),
      ReductionPlanStatus.behind => (
          context.l10n.planStatusBehind,
          context.stats.warning,
        ),
      null => (context.l10n.planStatusActive, color),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(context.colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.reductionPlanSection,
                style: TextStyle(fontFamily: AppFonts.sans,
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
            context.l10n.productLabel(productName),
            style: const TextStyle(fontFamily: AppFonts.sans,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PlanStat(
                  label: context.l10n.planStart,
                  value: formatDecimal(plan.startAverage, decimals: 1),
                  unit: context.l10n.unitsPerDayShort,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanStat(
                  label: context.l10n.average7Days,
                  value: formatDecimal(recentAverage, decimals: 1),
                  unit: context.l10n.unitsPerDayShort,
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
                  label: context.l10n.targetToday,
                  value: formatDecimal(plan.currentWeekTarget, decimals: 1),
                  unit: context.l10n.unitsPerDayShort,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanStat(
                  label: context.l10n.finalGoal,
                  value: formatDecimal(plan.targetPerDay, decimals: 1),
                  unit: context.l10n.unitsPerDayShort,
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
                context.l10n.planWeek(plan.currentWeekNumber, plan.totalWeeks),
                style: const TextStyle(fontFamily: AppFonts.sans, fontSize: 12, color: Colors.grey),
              ),
              Text(
                plan.isCompleted
                    ? context.l10n.planCompleted
                    : context.l10n.daysRemaining(plan.daysRemaining),
                style: TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: plan.isCompleted ? context.stats.positive : color,
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
                    switch (status) {
                      ReductionPlanStatus.ahead =>
                        context.l10n.planAheadMessage,
                      ReductionPlanStatus.onTrack =>
                        context.l10n.planOnTrackMessage,
                      ReductionPlanStatus.behind =>
                        context.l10n.planBehindMessage,
                      null => context.l10n.planActiveMessage,
                    },
                    style: TextStyle(fontFamily: AppFonts.sans,
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
                  onPressed: () => _showPlanSheet(
                    context,
                    provider,
                    color,
                    productId: plan.productId,
                  ),
                  style: _outlinedButtonStyle(color),
                  child: Text(
                    context.l10n.edit,
                    style: const TextStyle(fontFamily: AppFonts.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () =>
                    _confirmDeletePlan(context, provider, plan.productId),
                style: _outlinedButtonStyle(context.stats.danger),
                child: Text(
                  context.l10n.delete,
                  style: TextStyle(fontFamily: AppFonts.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.stats.danger,
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
    String productId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.l10n.deletePlanTitle,
          style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w800),
        ),
        content: Text(
          context.l10n.deletePlanBody,
          style: const TextStyle(fontFamily: AppFonts.sans, ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.delete,
              style: TextStyle(color: context.stats.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteReductionPlan(productId: productId);
    }
  }
}

// --- Badge ---

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
        childAspectRatio: 0.72,
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
    final isDark = context.isDark;

    final l10n = context.l10n;
    final title = l10n.achievementTitle(achievement.id);
    final semanticLabel = locked || achievement.unlockedAt == null
        ? l10n.badgeLockedSemantics(title)
        : l10n.badgeUnlockedSemantics(
            title,
            DateFormat.yMMMMd(l10n.localeName).format(achievement.unlockedAt!),
          );

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: () => _showDetail(context),
      child: GestureDetector(
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
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: locked
                      ? context.colors.textMuted
                      : context.colors.textPrimary,
                ),
              ),
              if (!locked && achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat.MMMd(l10n.localeName)
                      .format(achievement.unlockedAt!),
                  style: TextStyle(fontFamily: AppFonts.sans,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(achievement.emoji, style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 14),
              Text(
                context.l10n.achievementTitle(achievement.id),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.achievementDescription(achievement.id),
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 13,
                  color: context.colors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                !locked && achievement.unlockedAt != null
                    ? context.l10n.unlockedOn(
                        DateFormat.yMMMMd(context.localeName)
                            .format(achievement.unlockedAt!),
                      )
                    : context.l10n.notUnlockedYet,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: AppFonts.sans,
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
                    context.l10n.close,
                    style: TextStyle(fontFamily: AppFonts.sans,
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

// --- Pannello del piano di riduzione ---

void _showPlanSheet(
  BuildContext context,
  MyTrackingProvider provider,
  Color color, {
  required String productId,
}) {
  final productName =
      provider.productNameById(productId) ?? context.l10n.product;
  final currentAverage = provider.recentDailyAverage(productId);
  final existingPlan = provider.reductionPlanForProduct(productId);
  final baseline = existingPlan?.startAverage ??
      (currentAverage > 0 ? currentAverage : 1.0);
  final maxSlider = (baseline * 1.1).clamp(1.0, 40.0);
  double target =
      (existingPlan?.targetPerDay ?? currentAverage / 2).clamp(0.0, maxSlider);
  int weeks = existingPlan?.totalWeeks ?? 8;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: context.colors.scaffold,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                context.l10n.reductionPlanSection,
                style: AppTextStyles.sectionLabel(context.accent),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.productLabel(productName),
                style: const TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.l10n.average14Days(
                  formatDecimal(currentAverage, decimals: 1),
                ),
                style: const TextStyle(fontFamily: AppFonts.sans, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.finalGoalValue(formatDecimal(target, decimals: 1)),
                style: const TextStyle(fontFamily: AppFonts.sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Slider(
                value: target,
                min: 0,
                max: maxSlider,
                divisions: (maxSlider * 2).round().clamp(2, 80),
                activeColor: color,
                inactiveColor: color.withValues(alpha: 0.15),
                onChanged: (value) => setState(() => target = value),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.planDuration(weeks),
                style: const TextStyle(fontFamily: AppFonts.sans,
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
                        context.l10n.planReductionSummary(
                          formatDecimal(baseline - target, decimals: 1),
                          weeks,
                        ),
                        style: TextStyle(fontFamily: AppFonts.sans, fontSize: 12, color: color),
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
                    backgroundColor: context.colors.action,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    existingPlan != null
                        ? context.l10n.updatePlan
                        : context.l10n.setPlan,
                    style: TextStyle(fontFamily: AppFonts.sans,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onAction,
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

// --- Componenti comuni ---

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
          style: TextStyle(fontFamily: AppFonts.sans,
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
            style: TextStyle(fontFamily: AppFonts.sans,
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
        style: TextStyle(fontFamily: AppFonts.sans,
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
    final accent = highlight ?? context.accent;

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
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.colors.textMuted,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: AppDecorations.card(context.colors),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: AppFonts.sans,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}
