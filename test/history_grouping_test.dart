import 'package:flutter_test/flutter_test.dart';

import 'package:my_tracking_app/models/smoke_entry.dart';
import 'package:my_tracking_app/utils/history_grouping.dart';

SmokeEntry _at(DateTime t) => SmokeEntry(
      id: t.toIso8601String(),
      timestamp: t,
      costDeducted: 0.3,
      minutesLost: 11,
    );

void main() {
  test('una settimana a cavallo di due mesi resta una sola settimana', () {
    final periods = groupHistory([
      _at(DateTime(2026, 8, 31, 9)),
      _at(DateTime(2026, 9, 6, 22)),
      _at(DateTime(2026, 9, 7, 8)),
    ], HistoryGrouping.weeks);

    expect(periods, hasLength(2));
    expect(periods.last.start, DateTime(2026, 8, 31));
    expect(periods.last.end, DateTime(2026, 9, 7));
    expect(periods.last.count, 2);
    expect(periods.last.perWeekday, [1, 0, 0, 0, 0, 0, 1]);
    expect(periods.first.start, DateTime(2026, 9, 7));
  });

  test('i totali sommano costo e minuti delle voci del periodo', () {
    final day = groupHistory([
      _at(DateTime(2026, 9, 25, 8)),
      _at(DateTime(2026, 9, 25, 22)),
    ], HistoryGrouping.days).single;

    expect(day.cost, closeTo(0.6, 1e-9));
    expect(day.minutes, 22);
    expect(day.entries.first.timestamp.hour, 22, reason: 'piu recente prima');
  });

  test('la media del mese conta i giorni vuoti, ma non quelli non ancora vissuti '
      'ne quelli prima di iniziare a tracciare', () {
    final month = groupHistory([
      _at(DateTime(2026, 9, 11, 9)),
      _at(DateTime(2026, 9, 11, 10)),
      _at(DateTime(2026, 9, 20, 9)),
    ], HistoryGrouping.months).single;

    expect(
      month.dailyAverage(
        today: DateTime(2026, 9, 20, 18),
        trackingStart: DateTime(2026, 9, 11, 9),
      ),
      closeTo(0.3, 1e-9),
    );
    expect(
      month.dailyAverage(
        today: DateTime(2026, 11, 1),
        trackingStart: DateTime(2026, 1, 1),
      ),
      closeTo(0.1, 1e-9),
    );
  });
}
