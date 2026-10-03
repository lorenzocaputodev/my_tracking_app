import '../models/smoke_entry.dart';
import 'calendar_days.dart';

enum HistoryGrouping { days, weeks, months }

class HistoryPeriod {
  final DateTime start;

  final DateTime end;
  final List<SmokeEntry> entries;

  const HistoryPeriod({
    required this.start,
    required this.end,
    required this.entries,
  });

  int get count => entries.length;

  double get cost => entries.fold(0.0, (sum, e) => sum + e.costDeducted);

  int get minutes => entries.fold(0, (sum, e) => sum + e.minutesLost);

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  List<int> get perWeekday {
    final counts = List<int>.filled(7, 0);
    for (final e in entries) {
      counts[e.timestamp.toLocal().weekday - 1]++;
    }
    return counts;
  }

  double dailyAverage({
    required DateTime today,
    required DateTime trackingStart,
  }) {
    final from = _day(trackingStart).isAfter(start) ? _day(trackingStart) : start;
    final tomorrow = addDays(today, 1);
    final to = tomorrow.isBefore(end) ? tomorrow : end;
    final days = daysBetween(from, to);
    return days <= 0 ? 0 : count / days;
  }
}

List<HistoryPeriod> groupHistory(
  List<SmokeEntry> entries,
  HistoryGrouping grouping,
) {
  final byStart = <DateTime, List<SmokeEntry>>{};
  for (final e in entries) {
    byStart.putIfAbsent(periodStart(e.timestamp, grouping), () => []).add(e);
  }
  final starts = byStart.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final s in starts)
      HistoryPeriod(
        start: s,
        end: periodEnd(s, grouping),
        entries: byStart[s]!
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      ),
  ];
}

DateTime periodStart(DateTime timestamp, HistoryGrouping grouping) {
  final d = _day(timestamp.toLocal());
  return switch (grouping) {
    HistoryGrouping.days => d,
    HistoryGrouping.weeks => DateTime(d.year, d.month, d.day - (d.weekday - 1)),
    HistoryGrouping.months => DateTime(d.year, d.month),
  };
}

DateTime periodEnd(DateTime start, HistoryGrouping grouping) {
  return switch (grouping) {
    HistoryGrouping.days => DateTime(start.year, start.month, start.day + 1),
    HistoryGrouping.weeks => DateTime(start.year, start.month, start.day + 7),
    HistoryGrouping.months => DateTime(start.year, start.month + 1),
  };
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);
