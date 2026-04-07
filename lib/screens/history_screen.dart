import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/smoke_entry.dart';
import '../providers/my_tracking_provider.dart';
import '../utils/app_formatters.dart';
import '../widgets/tracking_input_decoration.dart';

enum _HistoryProductFilter { all, specific }

enum _HistoryPeriodPreset { today, sevenDays, thirtyDays, all, custom }

enum _HistoryStatsSection { overview, costs, habits }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryProductFilter _productFilter = _HistoryProductFilter.all;
  _HistoryPeriodPreset _periodPreset = _HistoryPeriodPreset.all;
  String? _selectedProductId;
  DateTimeRange? _customRange;

  String? _effectiveProductId(MyTrackingProvider provider) {
    return switch (_productFilter) {
      _HistoryProductFilter.all => null,
      _HistoryProductFilter.specific => provider.activeProducts.any(
          (product) => product.id == _selectedProductId,
        )
            ? _selectedProductId
            : provider.activeProducts.isNotEmpty
                ? provider.activeProducts.first.id
                : null,
    };
  }

  DateTimeRange _selectedRange(MyTrackingProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (_periodPreset) {
      _HistoryPeriodPreset.today => DateTimeRange(start: today, end: today),
      _HistoryPeriodPreset.sevenDays => DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      _HistoryPeriodPreset.thirtyDays => DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        ),
      _HistoryPeriodPreset.all => _allAvailableRange(provider),
      _HistoryPeriodPreset.custom => _customRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 29)),
            end: today,
          ),
    };
  }

  String _productDropdownValue(MyTrackingProvider provider) {
    return switch (_productFilter) {
      _HistoryProductFilter.all => '__all__',
      _HistoryProductFilter.specific =>
        _effectiveProductId(provider) ?? '__all__',
    };
  }

  String _periodLabel() {
    return switch (_periodPreset) {
      _HistoryPeriodPreset.today => 'Oggi',
      _HistoryPeriodPreset.sevenDays => 'Ultimi 7 giorni',
      _HistoryPeriodPreset.thirtyDays => 'Ultimi 30 giorni',
      _HistoryPeriodPreset.all => 'Tutta la cronologia',
      _HistoryPeriodPreset.custom => 'Periodo personalizzato',
    };
  }

  DateTimeRange _allAvailableRange(MyTrackingProvider provider) {
    final today = _dateOnly(DateTime.now());
    final effectiveProductId = _effectiveProductId(provider);
    final sourceEntries = effectiveProductId == null
        ? provider.visibleEntries
        : provider.entriesForProduct(effectiveProductId);
    if (sourceEntries.isEmpty) {
      return DateTimeRange(start: today, end: today);
    }

    var earliest = _dateOnly(sourceEntries.first.timestamp);
    for (final entry in sourceEntries.skip(1)) {
      final day = _dateOnly(entry.timestamp);
      if (day.isBefore(earliest)) {
        earliest = day;
      }
    }

    return DateTimeRange(start: earliest, end: today);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _customRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 29)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('it'),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
      helpText: 'Seleziona intervallo',
      saveText: 'Conferma',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _customRange = DateTimeRange(
        start: _dateOnly(picked.start),
        end: _dateOnly(picked.end),
      );
      _periodPreset = _HistoryPeriodPreset.custom;
    });
  }

  Future<void> _setCustomPeriod() async {
    if (_periodPreset == _HistoryPeriodPreset.custom && _customRange != null) {
      return;
    }
    await _pickCustomRange();
  }

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Cronologia'), elevation: 0),
      body: Consumer<MyTrackingProvider>(
        builder: (context, provider, _) {
          final effectiveProductId = _effectiveProductId(provider);
          final selectedRange = _selectedRange(provider);
          final filteredEntries = provider
              .entriesForRange(
                productId: effectiveProductId,
                start: selectedRange.start,
                end: selectedRange.end,
              )
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          final chartEntries = effectiveProductId == null
              ? provider.visibleEntries.toList()
              : provider.entriesForProduct(effectiveProductId);

          if (provider.visibleEntries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _HistoryFiltersCard(
                  provider: provider,
                  productValue: _productDropdownValue(provider),
                  periodPreset: _periodPreset,
                  customRange: _customRange,
                  onProductChanged: (value) {
                    setState(() {
                      if (value == '__all__') {
                        _productFilter = _HistoryProductFilter.all;
                      } else {
                        _productFilter = _HistoryProductFilter.specific;
                        _selectedProductId = value;
                      }
                    });
                  },
                  onPresetSelected: (preset) async {
                    if (preset == _HistoryPeriodPreset.custom) {
                      await _setCustomPeriod();
                      return;
                    }
                    setState(() => _periodPreset = preset);
                  },
                  onCustomRangeTap: _pickCustomRange,
                ),
                const SizedBox(height: 20),
                _EmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  color: turquoise,
                  title: 'Nessun dato registrato',
                  message:
                      'La cronologia apparir\u00E0 qui dopo i primi utilizzi.',
                ),
              ],
            );
          }

          final grouped = _groupEntriesByDay(filteredEntries);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _HistoryFiltersCard(
                provider: provider,
                productValue: _productDropdownValue(provider),
                periodPreset: _periodPreset,
                customRange: _customRange,
                onProductChanged: (value) {
                  setState(() {
                    if (value == '__all__') {
                      _productFilter = _HistoryProductFilter.all;
                    } else {
                      _productFilter = _HistoryProductFilter.specific;
                      _selectedProductId = value;
                    }
                  });
                },
                onPresetSelected: (preset) async {
                  if (preset == _HistoryPeriodPreset.custom) {
                    await _setCustomPeriod();
                    return;
                  }
                  setState(() => _periodPreset = preset);
                },
                onCustomRangeTap: _pickCustomRange,
              ),
              const SizedBox(height: 8),
              _WeeklyChart(entries: chartEntries),
              _MonthlyChart(entries: chartEntries),
              _StatsPanel(
                provider: provider,
                entries: filteredEntries,
                selectedProductId: effectiveProductId,
                selectedRange: selectedRange,
                periodLabel: _periodLabel(),
              ),
              if (filteredEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _EmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    color: turquoise,
                    title: 'Nessun risultato nel filtro selezionato',
                    message:
                        'Prova un altro prodotto o un intervallo di date pi\u00F9 ampio.',
                  ),
                )
              else
                ...grouped.entries.map((group) {
                  final dayEntries = group.value;
                  final dayTotal = dayEntries.fold<double>(
                    0,
                    (sum, entry) => sum + entry.costDeducted,
                  );
                  final dayMinutes = dayEntries.fold<int>(
                    0,
                    (sum, entry) => sum + entry.minutesLost,
                  );
                  final minutesPart =
                      dayMinutes > 0 ? ' \u2022 ${dayMinutes}m' : '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 20,
                          bottom: 10,
                          left: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                group.key.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  color: turquoise,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${dayEntries.length} unit\u00E0 \u2022 ${formatEuro(dayTotal)}$minutesPart',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...dayEntries.map(
                        (entry) => _EntryTile(entry: entry, provider: provider),
                      ),
                    ],
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryFiltersCard extends StatelessWidget {
  final MyTrackingProvider provider;
  final String productValue;
  final _HistoryPeriodPreset periodPreset;
  final DateTimeRange? customRange;
  final ValueChanged<String> onProductChanged;
  final ValueChanged<_HistoryPeriodPreset> onPresetSelected;
  final VoidCallback onCustomRangeTap;

  const _HistoryFiltersCard({
    required this.provider,
    required this.productValue,
    required this.periodPreset,
    required this.customRange,
    required this.onProductChanged,
    required this.onPresetSelected,
    required this.onCustomRangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final turquoise = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTRI',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: turquoise,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: productValue,
            borderRadius: BorderRadius.circular(14),
            decoration: trackingInputDecoration(
              hint: 'Prodotto',
              icon: Icons.inventory_2_rounded,
              isDark: isDark,
              accentColor: turquoise,
              label: 'Prodotto',
            ),
            items: [
              const DropdownMenuItem(
                value: '__all__',
                child: Text('Tutti i prodotti'),
              ),
              ...provider.activeProducts.map(
                (product) => DropdownMenuItem(
                  value: product.id,
                  child: Text(product.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onProductChanged(value);
              }
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HistoryPeriodPreset.values.map((preset) {
              final selected = preset == periodPreset;
              return ChoiceChip(
                label: Text(_periodPresetLabel(preset)),
                selected: selected,
                labelStyle: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF314344)),
                ),
                selectedColor: turquoise,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                side: BorderSide(
                  color: selected
                      ? Colors.transparent
                      : turquoise.withValues(alpha: 0.18),
                ),
                onSelected: (_) => onPresetSelected(preset),
              );
            }).toList(),
          ),
          if (periodPreset == _HistoryPeriodPreset.custom) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCustomRangeTap,
              icon: Icon(Icons.date_range_rounded, color: turquoise),
              label: Text(
                customRange == null
                    ? 'Seleziona intervallo'
                    : '${DateFormat('d MMM', 'it').format(customRange!.start)} \u2192 ${DateFormat('d MMM', 'it').format(customRange!.end)}',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: turquoise,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: turquoise,
                side: BorderSide(color: turquoise.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsPanel extends StatefulWidget {
  final MyTrackingProvider provider;
  final List<SmokeEntry> entries;
  final String? selectedProductId;
  final DateTimeRange selectedRange;
  final String periodLabel;

  const _StatsPanel({
    required this.provider,
    required this.entries,
    required this.selectedProductId,
    required this.selectedRange,
    required this.periodLabel,
  });

  @override
  State<_StatsPanel> createState() => _StatsPanelState();
}

class _StatsPanelState extends State<_StatsPanel> {
  final Set<_HistoryStatsSection> _expandedSections = <_HistoryStatsSection>{};

  bool get _isSingleProduct => widget.selectedProductId != null;

  String _formatHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  void _toggleSection(_HistoryStatsSection section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCost = widget.entries.fold<double>(
      0,
      (sum, entry) => sum + entry.costDeducted,
    );
    final dayCount =
        widget.selectedRange.end.difference(widget.selectedRange.start).inDays +
            1;
    final periodAverage = widget.provider.averageDailyCountForRange(
      productId: widget.selectedProductId,
      start: widget.selectedRange.start,
      end: widget.selectedRange.end,
    );
    final thirtyDayAverage = widget.provider.averageDailyCountForRange(
      productId: widget.selectedProductId,
      start: DateTime.now().subtract(const Duration(days: 29)),
      end: DateTime.now(),
    );
    final trend = widget.provider.weeklyTrend(
      productId: widget.selectedProductId,
    );
    final peakHour = widget.provider.peakHourForEntries(widget.entries);
    final bestDay = widget.provider.bestDayForEntries(widget.entries);
    final worstDay = widget.provider.worstDayForEntries(widget.entries);
    final hourCounts = widget.provider.hourDistributionForEntries(
      widget.entries,
    );
    final maxHourCount = hourCounts.fold<int>(0, (a, b) => a > b ? a : b);
    final monthlyProjectionUnits = widget.provider.projectedMonthlyUnits(
      productId: widget.selectedProductId,
    );
    final monthlyProjectionCost = widget.provider.projectedMonthlyCost(
      productId: widget.selectedProductId,
    );
    final annualUnitsEstimate =
        dayCount > 0 ? ((widget.entries.length / dayCount) * 365).round() : 0;
    final annualCostEstimate = dayCount > 0 ? (totalCost / dayCount) * 365 : 0;
    final streak = _isSingleProduct
        ? widget.provider.currentStreakForProduct(widget.selectedProductId!)
        : 0;
    final singleProduct = _isSingleProduct
        ? widget.provider.activeProducts.firstWhere(
            (item) => item.id == widget.selectedProductId,
          )
        : null;
    final underLimitStreak = _isSingleProduct
        ? widget.provider.underLimitStreakForProduct(widget.selectedProductId!)
        : 0;
    final trendColor = trend.deltaPercent <= 0
        ? const Color(0xFF19724F)
        : const Color(0xFFB06A0E);
    const projectionColor = Color(0xFFA56A13);
    const costColor = Color(0xFFB64A63);
    final peakColor =
        isDark ? turquoise.withValues(alpha: 0.78) : const Color(0xFF2D6D72);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STATISTICHE',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: turquoise,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                widget.periodLabel.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatsSectionCard(
            title: 'Panoramica periodo',
            subtitle: 'Medie e riepilogo del filtro selezionato',
            accentColor: turquoise,
            isDark: isDark,
            isExpanded:
                _expandedSections.contains(_HistoryStatsSection.overview),
            onTap: () => _toggleSection(_HistoryStatsSection.overview),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Media periodo/g',
                        value: periodAverage.toStringAsFixed(1),
                        icon: Icons.show_chart_rounded,
                        color: turquoise,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatItem(
                        label: 'Trend 7g',
                        value: formatSignedPercent(trend.deltaPercent),
                        icon: Icons.trending_up_rounded,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Media 30 giorni',
                        value: thirtyDayAverage.toStringAsFixed(1),
                        icon: Icons.calendar_view_month_rounded,
                        color: const Color(0xFF00B8D4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatItem(
                        label: 'Totale periodo',
                        value: '${widget.entries.length} unit\u00E0',
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFF348B7B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StatsSectionCard(
            title: 'Costi e proiezioni',
            subtitle: 'Spesa attuale e stime future',
            accentColor: const Color(0xFFA56A13),
            isDark: isDark,
            isExpanded: _expandedSections.contains(_HistoryStatsSection.costs),
            onTap: () => _toggleSection(_HistoryStatsSection.costs),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Costo periodo',
                        value: formatEuro(totalCost),
                        icon: Icons.euro_rounded,
                        color: costColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatItem(
                        label: 'Proiezione mese',
                        value: monthlyProjectionUnits > 0
                            ? '$monthlyProjectionUnits unit\u00E0'
                            : '-',
                        icon: Icons.insights_rounded,
                        color: projectionColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Stima annua',
                        value: annualUnitsEstimate > 0
                            ? '$annualUnitsEstimate unit\u00E0'
                            : '-',
                        icon: Icons.calendar_today_rounded,
                        color: const Color(0xFFB2842E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatItem(
                        label: 'Stima mese',
                        value: monthlyProjectionCost > 0
                            ? formatEuro(monthlyProjectionCost, decimals: 0)
                            : formatEuro(0, decimals: 0),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _StatItem(
                  label: 'Costo annuo stimato',
                  value: annualCostEstimate > 0
                      ? formatEuro(annualCostEstimate, decimals: 0)
                      : formatEuro(0, decimals: 0),
                  icon: Icons.savings_rounded,
                  color: Colors.deepOrangeAccent,
                  fullWidth: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StatsSectionCard(
            title: 'Abitudini e orari',
            subtitle: 'Ritmo, giorni e fascia oraria pi\u00F9 attiva',
            accentColor: peakColor,
            isDark: isDark,
            isExpanded: _expandedSections.contains(_HistoryStatsSection.habits),
            onTap: () => _toggleSection(_HistoryStatsSection.habits),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Ora picco',
                        value: peakHour != null ? _formatHour(peakHour) : '-',
                        icon: Icons.access_time_rounded,
                        color: peakColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                if (singleProduct != null &&
                    singleProduct.dailyLimit > 0 &&
                    underLimitStreak > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: turquoise.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, size: 16, color: turquoise),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            underLimitStreak == 1
                                ? '1 giorno consecutivo sotto il limite (${singleProduct.dailyLimit})'
                                : '$underLimitStreak giorni consecutivi sotto il limite (${singleProduct.dailyLimit})',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: turquoise,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_isSingleProduct && streak > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade700.withValues(
                        alpha: isDark ? 0.10 : 0.07,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: Colors.greenAccent.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            streak == 1
                                ? 'Attivo da 1 giorno consecutivo'
                                : 'Attivo da $streak giorni consecutivi',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.greenAccent.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (bestDay != null || worstDay != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (bestDay != null)
                        Expanded(
                          child: _DayHighlight(
                            label: 'Giorno migliore',
                            date: bestDay.key,
                            count: bestDay.value,
                            color: Colors.greenAccent.shade700,
                            isDark: isDark,
                          ),
                        ),
                      if (bestDay != null && worstDay != null)
                        const SizedBox(width: 10),
                      if (worstDay != null)
                        Expanded(
                          child: _DayHighlight(
                            label: 'Giorno peggiore',
                            date: worstDay.key,
                            count: worstDay.value,
                            color: Colors.redAccent,
                            isDark: isDark,
                          ),
                        ),
                    ],
                  ),
                ],
                if (maxHourCount > 0) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text(
                    'DISTRIBUZIONE ORARIA',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HourHeatmap(
                    entries: widget.entries,
                    hourCounts: hourCounts,
                    maxCount: maxHourCount,
                    turquoise: turquoise,
                    isDark: isDark,
                    productNameById: widget.provider.productNameById,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isExpanded;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;
  final Widget child;

  const _StatsSectionCard({
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.025)
            : accentColor.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: isExpanded ? 0.18 : 0.10),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: accentColor,
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: child,
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                  sizeCurve: Curves.easeOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF161B1B)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourHeatmap extends StatelessWidget {
  final List<SmokeEntry> entries;
  final List<int> hourCounts;
  final int maxCount;
  final Color turquoise;
  final bool isDark;
  final String? Function(String id) productNameById;

  const _HourHeatmap({
    required this.entries,
    required this.hourCounts,
    required this.maxCount,
    required this.turquoise,
    required this.isDark,
    required this.productNameById,
  });

  String _tooltipForHour(int hour) {
    final countsByProduct = <String, int>{};
    for (final entry in entries) {
      if (entry.timestamp.toLocal().hour != hour) continue;
      countsByProduct[entry.productId] =
          (countsByProduct[entry.productId] ?? 0) + 1;
    }
    if (countsByProduct.isEmpty) {
      return '${hour.toString().padLeft(2, '0')}:00 \u2014 0';
    }
    final parts = countsByProduct.entries.map((item) {
      final name = productNameById(item.key) ?? item.key;
      return '$name \u00D7${item.value}';
    }).toList();
    return '${hour.toString().padLeft(2, '0')}:00 \u2014 ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(6, (col) {
              final hour = row * 6 + col;
              final count = hourCounts[hour];
              final intensity = maxCount > 0 ? count / maxCount : 0.0;
              final isHot = intensity > 0.6;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message: _tooltipForHour(hour),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: count == 0
                            ? turquoise.withValues(alpha: isDark ? 0.06 : 0.04)
                            : turquoise.withValues(
                                alpha: 0.15 + intensity * 0.75,
                              ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          hour.toString().padLeft(2, '0'),
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: count == 0
                                ? Colors.grey.withValues(alpha: 0.4)
                                : (isHot ? Colors.white : turquoise),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey : const Color(0xFF5E7274);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.08 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHighlight extends StatelessWidget {
  final String label;
  final DateTime date;
  final int count;
  final Color color;
  final bool isDark;

  const _DayHighlight({
    required this.label,
    required this.date,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('d MMM', 'it').format(date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              formatted,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

double _niceYInterval(double maxY) {
  if (maxY <= 4) return 1;
  if (maxY <= 10) return 2;
  if (maxY <= 20) return 4;
  if (maxY <= 40) return 8;
  if (maxY <= 80) return 16;
  return (maxY / 4).ceilToDouble();
}

double _niceAxisMax(double rawMax) {
  if (rawMax <= 0) return 4.0;
  final interval = _niceYInterval(rawMax);
  return ((rawMax / interval).ceil() + 1) * interval;
}

double _yAxisReservedSize(double maxY) {
  final digits = maxY.toInt().toString().length;
  return digits >= 3 ? 48 : 40;
}

int _maxVisibleBottomLabels(double width, {double minLabelWidth = 44}) {
  if (width <= 0) return 2;
  return (width / minLabelWidth).floor().clamp(2, 8);
}

int _adaptiveBottomInterval(
  int points,
  double width, {
  double minLabelWidth = 44,
}) {
  final visible = _maxVisibleBottomLabels(width, minLabelWidth: minLabelWidth);
  return ((points - 1) / (visible - 1)).ceil().clamp(1, points);
}

bool _shouldShowXAxisLabel({
  required int index,
  required int total,
  required int interval,
  int? highlightIndex,
}) {
  if (index == 0 || index == total - 1) return true;
  if (highlightIndex != null && index == highlightIndex) return true;
  return index % interval == 0;
}

class _WeeklyChart extends StatelessWidget {
  final List<SmokeEntry> entries;

  const _WeeklyChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = _dateOnly(DateTime.now());
    final days = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    final countPerDay = {for (final day in days) day: 0};
    for (final entry in entries) {
      final day = _dateOnly(entry.timestamp);
      if (countPerDay.containsKey(day)) {
        countPerDay[day] = countPerDay[day]! + 1;
      }
    }

    final rawMax = countPerDay.values.fold<double>(
      0,
      (max, value) => max > value ? max : value.toDouble(),
    );
    final maxY = _niceAxisMax(rawMax);
    final yInterval = _niceYInterval(maxY);

    final bars = days.asMap().entries.map((item) {
      final index = item.key;
      final day = item.value;
      final count = countPerDay[day]!.toDouble();
      final isToday = day == today;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count,
            color: isToday ? turquoise : turquoise.withValues(alpha: 0.4),
            width: 18,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: turquoise.withValues(alpha: 0.05),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'ULTIMI 7 GIORNI',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: turquoise,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final intervalX = _adaptiveBottomInterval(
                  days.length,
                  constraints.maxWidth,
                  minLabelWidth: 36,
                );
                final todayIndex = days.indexOf(today);
                return BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: turquoise.withValues(alpha: 0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: _yAxisReservedSize(maxY),
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value != 0 &&
                                value != maxY &&
                                (value % yInterval) != 0) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                '${value.toInt()}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index < 0 || index >= days.length) {
                              return const SizedBox.shrink();
                            }
                            if (!_shouldShowXAxisLabel(
                              index: index,
                              total: days.length,
                              interval: intervalX,
                              highlightIndex: todayIndex,
                            )) {
                              return const SizedBox.shrink();
                            }
                            final day = days[index];
                            final isToday = day == today;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                isToday
                                    ? 'oggi'
                                    : DateFormat(
                                        'E',
                                        'it',
                                      ).format(day).toLowerCase(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: isToday
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isToday ? turquoise : Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: bars,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            isDark ? const Color(0xFF1E2A2A) : Colors.white,
                        getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                          '${rod.toY.toInt()}',
                          GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                            color: turquoise,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<SmokeEntry> entries;

  const _MonthlyChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = _dateOnly(DateTime.now());
    final days = List.generate(30, (index) {
      return today.subtract(Duration(days: 29 - index));
    });

    final countPerDay = {for (final day in days) day: 0};
    for (final entry in entries) {
      final day = _dateOnly(entry.timestamp);
      if (countPerDay.containsKey(day)) {
        countPerDay[day] = countPerDay[day]! + 1;
      }
    }

    final spots = <FlSpot>[
      for (var index = 0; index < days.length; index++)
        FlSpot(index.toDouble(), countPerDay[days[index]]!.toDouble()),
    ];

    final rawMax = countPerDay.values.fold<double>(
      0,
      (max, value) => max > value ? max : value.toDouble(),
    );
    final maxY = _niceAxisMax(rawMax);
    final yInterval = _niceYInterval(maxY);

    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'TREND ULTIMI 30 GIORNI',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: turquoise,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final intervalX = _adaptiveBottomInterval(
                  days.length,
                  constraints.maxWidth,
                );
                final todayIndex = days.length - 1;
                return LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 29,
                    minY: 0,
                    maxY: maxY,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: turquoise.withValues(alpha: 0.06),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: _yAxisReservedSize(maxY),
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value != meta.min &&
                                value != meta.max &&
                                (value % yInterval) != 0) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                '${value.toInt()}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: intervalX.toDouble(),
                          getTitlesWidget: (value, _) {
                            final index = value.round();
                            if (index < 0 || index >= days.length) {
                              return const SizedBox.shrink();
                            }
                            if (!_shouldShowXAxisLabel(
                              index: index,
                              total: days.length,
                              interval: intervalX,
                              highlightIndex: todayIndex,
                            )) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat('d/M', 'it').format(days[index]),
                              style: GoogleFonts.dmSans(
                                fontSize: 8,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        color: turquoise,
                        barWidth: 2.5,
                        isCurved: true,
                        curveSmoothness: 0.2,
                        preventCurveOverShooting: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: turquoise.withValues(alpha: 0.12),
                          cutOffY: 0,
                          applyCutOffY: true,
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) =>
                            isDark ? const Color(0xFF1E2A2A) : Colors.white,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x.round().clamp(0, 29);
                            final count = countPerDay[days[index]]!;
                            return LineTooltipItem(
                              '${DateFormat('d MMM', 'it').format(days[index])}: $count',
                              GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                color: turquoise,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final SmokeEntry entry;
  final MyTrackingProvider provider;

  const _EntryTile({required this.entry, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final turquoise = Theme.of(context).colorScheme.primary;
    final productName =
        provider.productNameById(entry.productId) ?? provider.config.name;
    final time = DateFormat('HH:mm').format(entry.timestamp.toLocal());
    final showMinutes = entry.minutesLost > 0;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await provider.deleteEntry(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$productName rimosso'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B1B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: turquoise.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: turquoise,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Costo: ${formatEuro(entry.costDeducted)}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (showMinutes)
              Text(
                '-${entry.minutesLost}m',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<SmokeEntry>> _groupEntriesByDay(List<SmokeEntry> entries) {
  final grouped = <String, List<SmokeEntry>>{};
  for (final entry in entries) {
    final key = DateFormat('EEEE d MMMM yyyy', 'it').format(entry.timestamp);
    grouped.putIfAbsent(key, () => []).add(entry);
  }
  return grouped;
}

String _periodPresetLabel(_HistoryPeriodPreset preset) {
  return switch (preset) {
    _HistoryPeriodPreset.today => 'Oggi',
    _HistoryPeriodPreset.sevenDays => '7 giorni',
    _HistoryPeriodPreset.thirtyDays => '30 giorni',
    _HistoryPeriodPreset.all => 'Tutto',
    _HistoryPeriodPreset.custom => 'Personalizzato',
  };
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
