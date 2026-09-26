import 'package:flutter/material.dart';

import '../models/smoke_entry.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../utils/app_clock.dart';
import '../utils/app_formatters.dart';
import '../utils/history_grouping.dart';
import 'pill_selector.dart';
import 'tappable_card.dart';

const _months = [
  'Gennaio',
  'Febbraio',
  'Marzo',
  'Aprile',
  'Maggio',
  'Giugno',
  'Luglio',
  'Agosto',
  'Settembre',
  'Ottobre',
  'Novembre',
  'Dicembre',
];
const _monthsShort = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];
const _weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

/// Intervallo della settimana, ristretto al filtro del periodo: con "7
/// giorni" la settimana iniziata prima mostra solo i giorni inclusi.
String _weekLabel(HistoryPeriod p, DateTimeRange? range) {
  var first = p.start;
  var last = DateTime(p.end.year, p.end.month, p.end.day - 1);
  if (range != null) {
    if (range.start.isAfter(first)) first = range.start;
    if (range.end.isBefore(last)) last = range.end;
  }
  if (first.year == last.year &&
      first.month == last.month &&
      first.day == last.day) {
    return '${first.day} ${_monthsShort[first.month - 1]}';
  }
  return first.month == last.month
      ? '${first.day} – ${last.day} ${_monthsShort[last.month - 1]}'
      : '${first.day} ${_monthsShort[first.month - 1]} – '
          '${last.day} ${_monthsShort[last.month - 1]}';
}

String _dayLabel(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_monthsShort[d.month - 1]}';

String _monthLabel(DateTime d) => '${_months[d.month - 1]} ${d.year}';

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Elenco della cronologia raggruppato per giorni, settimane o mesi.
/// Toccando un mese si vedono le sue settimane, toccando una settimana i
/// suoi giorni; toccando un giorno si aprono le singole registrazioni.
class HistoryPeriodList extends StatefulWidget {
  final List<SmokeEntry> entries;
  final MyTrackingProvider provider;

  /// Periodo del filtro, giorni inclusi: le etichette e le medie non lo
  /// oltrepassano.
  final DateTimeRange? range;

  const HistoryPeriodList({
    super.key,
    required this.entries,
    required this.provider,
    this.range,
  });

  @override
  State<HistoryPeriodList> createState() => _HistoryPeriodListState();
}

class _HistoryPeriodListState extends State<HistoryPeriodList> {
  HistoryGrouping _grouping = HistoryGrouping.weeks;
  HistoryPeriod? _drill;
  String? _drillLabel;
  final Set<DateTime> _openDays = {};

  void _setGrouping(HistoryGrouping g) => setState(() {
        _grouping = g;
        _drill = null;
        _drillLabel = null;
      });

  void _drillInto(HistoryPeriod p, HistoryGrouping next, String label) =>
      setState(() {
        _grouping = next;
        _drill = p;
        _drillLabel = label;
      });

  @override
  Widget build(BuildContext context) {
    final drill = _drill;
    final entries = drill == null
        ? widget.entries
        : widget.entries
            .where((e) => drill.contains(e.timestamp.toLocal()))
            .toList();
    final periods = groupHistory(entries, _grouping);
    final range = widget.range;
    // Con prodotti diversi le quantita' non si sommano come "unita'".
    final unit = widget.entries.map((e) => e.productId).toSet().length > 1
        ? 'registrazioni'
        : 'unità';

    final rows = <Widget>[];
    switch (_grouping) {
      case HistoryGrouping.months:
        var trackingStart = widget.entries
            .map((e) => e.timestamp.toLocal())
            .reduce((a, b) => a.isBefore(b) ? a : b);
        var today = appNow();
        if (range != null) {
          if (range.start.isAfter(trackingStart)) trackingStart = range.start;
          if (range.end.isBefore(today)) today = range.end;
        }
        for (var i = 0; i < periods.length; i++) {
          final p = periods[i];
          final avg =
              p.dailyAverage(today: today, trackingStart: trackingStart);
          double? delta;
          final prev = i + 1 < periods.length ? periods[i + 1] : null;
          if (prev != null && prev.end == p.start) {
            final prevAvg =
                prev.dailyAverage(today: today, trackingStart: trackingStart);
            if (prevAvg > 0) delta = (avg - prevAvg) / prevAvg * 100;
          }
          rows.add(_SummaryRow(
            title: _monthLabel(p.start),
            subtitle: '${p.count} $unit · ${formatEuro(p.cost)} · '
                'media ${formatDecimal(avg, decimals: 1)}/giorno',
            trailing: delta == null ? null : _Delta(delta),
            onTap: () => _drillInto(
              p,
              HistoryGrouping.weeks,
              _monthLabel(p.start),
            ),
          ));
        }
      case HistoryGrouping.weeks:
        for (final p in periods) {
          rows.add(_SummaryRow(
            title: _weekLabel(p, range),
            subtitle: '${p.count} $unit · ${formatEuro(p.cost)}',
            trailing: _MiniWeek(perDay: p.perWeekday),
            onTap: () => _drillInto(
              p,
              HistoryGrouping.days,
              'Settimana ${_weekLabel(p, range)}',
            ),
          ));
        }
      case HistoryGrouping.days:
        for (final p in periods) {
          final open = _openDays.contains(p.start);
          final minutes = p.minutes > 0 ? ' · ${p.minutes}m' : '';
          rows.add(_SummaryRow(
            title: _dayLabel(p.start),
            subtitle: '${p.count} $unit · ${formatEuro(p.cost)}$minutes',
            expanded: open,
            onTap: () => setState(
              () => open ? _openDays.remove(p.start) : _openDays.add(p.start),
            ),
            children: open
                ? [
                    for (final e in p.entries)
                      _EntryRow(entry: e, provider: widget.provider),
                  ]
                : const [],
          ));
        }
    }

    final colors = context.colors;
    final accent = context.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'REGISTRAZIONI',
                style: AppTextStyles.sectionLabel(accent),
              ),
            ),
            const Spacer(),
            PillSelector<HistoryGrouping>(
              options: const {
                HistoryGrouping.days: 'Giorni',
                HistoryGrouping.weeks: 'Settimane',
                HistoryGrouping.months: 'Mesi',
              },
              value: _grouping,
              onChanged: _setGrouping,
            ),
          ],
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          alignment: Alignment.topLeft,
          child: _drillLabel == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: InkWell(
                    onTap: () => _setGrouping(
                      _grouping == HistoryGrouping.days
                          ? HistoryGrouping.weeks
                          : HistoryGrouping.months,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: AppAlphas.accentMuted),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _drillLabel!,
                            style: TextStyle(
                              fontFamily: AppFonts.sans,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.close_rounded, size: 16, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Cambiando vista o periodo l'elenco sfuma nel nuovo e la card
        // si ridimensiona, invece di sostituirsi di colpo.
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.curve,
            switchOutCurve: AppMotion.curve,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, if (current != null) current],
            ),
            child: TappableCard(
              key: ValueKey('${_grouping.name}-${_drill?.start}'),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: colors.subtleBorder),
                    rows[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool? expanded;
  final List<Widget> children;

  const _SummaryRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.expanded,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppFonts.sans,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppFonts.sans,
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
                if (expanded == null)
                  Icon(Icons.chevron_right_rounded, color: colors.textFaint)
                else
                  AnimatedRotation(
                    turns: expanded! ? 0.5 : 0,
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: colors.textFaint,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: children.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(children: children),
                ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final SmokeEntry entry;
  final MyTrackingProvider provider;

  const _EntryRow({required this.entry, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final productName =
        provider.productNameById(entry.productId) ?? provider.config.name;
    final minutes = entry.minutesLost > 0 ? '  ·  −${entry.minutesLost}m' : '';

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        // Il messenger va preso prima dell'attesa: la riga sparisce.
        final messenger = ScaffoldMessenger.of(context);
        final deleted = await provider.deleteEntry(entry.id);
        if (deleted == null) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Registrazione rimossa'),
              duration: const Duration(seconds: 4),
              // Con un'azione Flutter lo lascerebbe a schermo finche' non lo
              // si chiude: qui deve sparire da solo.
              persist: false,
              action: SnackBarAction(
                label: 'Annulla',
                onPressed: () => provider.restoreEntry(deleted),
              ),
            ),
          );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: context.stats.danger.withValues(alpha: 0.8),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                _hhmm(entry.timestamp.toLocal()),
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.accent,
                ),
              ),
            ),
            Expanded(
              child: Text(
                productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontSize: 13,
                  color: colors.textBody,
                ),
              ),
            ),
            Text(
              '${formatEuro(entry.costDeducted)}$minutes',
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 12,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniWeek extends StatelessWidget {
  final List<int> perDay;
  const _MiniWeek({required this.perDay});

  @override
  Widget build(BuildContext context) {
    final peak = perDay.fold<int>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final c in perDay)
            Container(
              width: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: c == 0 ? 3 : 4 + 24 * c / peak,
              decoration: BoxDecoration(
                color: c == 0
                    ? context.colors.textFaint.withValues(alpha: 0.3)
                    : context.accent.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  final double percent;
  const _Delta(this.percent);

  @override
  Widget build(BuildContext context) {
    final down = percent <= 0;
    final color = down ? context.stats.positive : context.stats.negative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlphas.accentMuted),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '${down ? '↓' : '↑'} ${percent.abs().round()}%',
        style: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
