import 'dart:convert';

import '../models/achievement.dart';
import '../models/app_reminder_settings.dart';
import '../models/reduction_plan.dart';
import '../models/smoke_entry.dart';
import '../models/tracked_product.dart';

enum BackupFileKind { fullBackup, invalid }

class AppBackupData {
  final String backupVersion;
  final DateTime exportedAt;
  final String activeProductId;
  final String themePreferenceName;
  final bool onboardingDone;
  final bool hasCompletedSetup;
  final AppReminderSettings globalReminderSettings;
  final List<TrackedProduct> products;
  final List<SmokeEntry> entries;
  final List<Achievement> achievements;
  final ReductionPlan? reductionPlan;

  const AppBackupData({
    required this.backupVersion,
    required this.exportedAt,
    required this.activeProductId,
    required this.themePreferenceName,
    required this.onboardingDone,
    required this.hasCompletedSetup,
    required this.globalReminderSettings,
    required this.products,
    required this.entries,
    required this.achievements,
    required this.reductionPlan,
  });
}

class AppBackupCsv {
  static const String backupVersion = '5';
  static const String backupMarker = '__MY_TRACKING_APP_BACKUP__';
  static const String sectionMarker = '__SECTION__';

  static const String metaSection = 'meta';
  static const String globalReminderSection = 'global_reminder';
  static const String productsSection = 'products';
  static const String entriesSection = 'entries';
  static const String achievementsSection = 'achievements';
  static const String reductionPlanSection = 'reduction_plan';

  static BackupFileKind detectKind(String raw) {
    final lines = const LineSplitter().convert(_normalize(raw));
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final row = parseRow(line);
      if (row.isNotEmpty && row.first == backupMarker) {
        return BackupFileKind.fullBackup;
      }
      break;
    }
    return BackupFileKind.invalid;
  }

  static String encode(AppBackupData data) {
    final buffer = StringBuffer()
      ..writeln(_encodeRow(<String>[backupMarker, data.backupVersion]))
      ..writeln(_encodeRow(<String>[sectionMarker, metaSection]))
      ..writeln(_encodeRow(<String>['key', 'value']));

    final metaRows = <List<String>>[
      <String>['backupVersion', data.backupVersion],
      <String>['exportedAtIso', data.exportedAt.toIso8601String()],
      <String>['activeProductId', data.activeProductId],
      <String>['themePreference', data.themePreferenceName],
      <String>['onboardingDone', '${data.onboardingDone}'],
      <String>['hasCompletedSetup', '${data.hasCompletedSetup}'],
    ];
    for (final row in metaRows) {
      buffer.writeln(_encodeRow(row));
    }

    buffer
      ..writeln(_encodeRow(<String>[sectionMarker, globalReminderSection]))
      ..writeln(_encodeRow(<String>['enabled', 'intervalMinutes']))
      ..writeln(
        _encodeRow(<String>[
          data.globalReminderSettings.enabled ? 'true' : 'false',
          '${data.globalReminderSettings.intervalMinutes}',
        ]),
      );

    buffer
      ..writeln(_encodeRow(<String>[sectionMarker, productsSection]))
      ..writeln(
        _encodeRow(<String>[
          'id',
          'name',
          'totalCost',
          'pieces',
          'minutesLost',
          'dailyLimit',
          'packRemaining',
          'tracksInventory',
          'directUnitCost',
          'isArchived',
        ]),
      );
    for (final product in data.products) {
      buffer.writeln(
        _encodeRow(<String>[
          product.id,
          product.name,
          '${product.totalCost}',
          '${product.pieces}',
          '${product.minutesLost}',
          '${product.dailyLimit}',
          '${product.packRemaining}',
          product.tracksInventory ? 'true' : 'false',
          product.directUnitCost == null ? '' : '${product.directUnitCost}',
          product.isArchived ? 'true' : 'false',
        ]),
      );
    }

    buffer
      ..writeln(_encodeRow(<String>[sectionMarker, entriesSection]))
      ..writeln(
        _encodeRow(<String>[
          'id',
          'timestamp',
          'costDeducted',
          'minutesLost',
          'productId',
        ]),
      );
    for (final entry in data.entries) {
      buffer.writeln(
        _encodeRow(<String>[
          entry.id,
          entry.timestamp.toIso8601String(),
          '${entry.costDeducted}',
          '${entry.minutesLost}',
          entry.productId,
        ]),
      );
    }

    buffer
      ..writeln(_encodeRow(<String>[sectionMarker, achievementsSection]))
      ..writeln(_encodeRow(<String>['id', 'isUnlocked', 'unlockedAt']));
    for (final achievement in data.achievements) {
      buffer.writeln(
        _encodeRow(<String>[
          achievement.id.name,
          achievement.isUnlocked ? 'true' : 'false',
          achievement.unlockedAt?.toIso8601String() ?? '',
        ]),
      );
    }

    buffer
      ..writeln(_encodeRow(<String>[sectionMarker, reductionPlanSection]))
      ..writeln(
        _encodeRow(<String>[
          'productId',
          'startAverage',
          'targetPerDay',
          'totalWeeks',
          'startDate',
        ]),
      );
    if (data.reductionPlan != null) {
      final plan = data.reductionPlan!;
      buffer.writeln(
        _encodeRow(<String>[
          plan.productId,
          '${plan.startAverage}',
          '${plan.targetPerDay}',
          '${plan.totalWeeks}',
          plan.startDate.toIso8601String(),
        ]),
      );
    }

    return buffer.toString();
  }

  static AppBackupData decode(String raw) {
    final lines = const LineSplitter().convert(_normalize(raw));
    final nonEmptyLines =
        lines.where((line) => line.trim().isNotEmpty).toList(growable: false);
    if (nonEmptyLines.isEmpty) {
      throw const FormatException('Backup CSV vuoto.');
    }

    final markerRow = parseRow(nonEmptyLines.first);
    if (markerRow.length < 2 || markerRow.first != backupMarker) {
      throw const FormatException('Formato backup CSV non riconosciuto.');
    }

    final version = markerRow[1].trim();
    if (version.isEmpty) {
      throw const FormatException('Versione backup mancante.');
    }

    final sections = <String, List<List<String>>>{};
    int index = 1;
    while (index < nonEmptyLines.length) {
      final sectionRow = parseRow(nonEmptyLines[index]);
      if (sectionRow.length < 2 || sectionRow.first != sectionMarker) {
        throw FormatException(
          'Sezione backup non valida alla riga ${index + 1}.',
        );
      }
      final sectionName = sectionRow[1].trim();
      index++;
      if (index >= nonEmptyLines.length) {
        throw FormatException('Header mancante per la sezione "$sectionName".');
      }

      final rows = <List<String>>[parseRow(nonEmptyLines[index])];
      index++;
      while (index < nonEmptyLines.length) {
        final row = parseRow(nonEmptyLines[index]);
        if (row.isNotEmpty && row.first == sectionMarker) {
          break;
        }
        rows.add(row);
        index++;
      }
      sections[sectionName] = rows;
    }

    final meta = _decodeMeta(sections[metaSection]);
    final globalReminderSettings = _decodeGlobalReminder(
      sections[globalReminderSection],
      sections[productsSection],
    );
    final products = _decodeProducts(sections[productsSection]);
    final entries = _decodeEntries(sections[entriesSection]);
    final achievements = _decodeAchievements(sections[achievementsSection]);
    final reductionPlan = _decodeReductionPlan(sections[reductionPlanSection]);

    final productIds = products.map((product) => product.id).toSet();
    for (final entry in entries) {
      if (!productIds.contains(entry.productId)) {
        throw FormatException(
          'La cronologia fa riferimento a un prodotto mancante: ${entry.productId}.',
        );
      }
    }

    return AppBackupData(
      backupVersion: meta['backupVersion']?.trim().isNotEmpty == true
          ? meta['backupVersion']!.trim()
          : version,
      exportedAt: DateTime.tryParse(meta['exportedAtIso'] ?? '') ??
          DateTime.now().toUtc(),
      activeProductId: meta['activeProductId'] ?? '',
      themePreferenceName: meta['themePreference'] ?? 'dark',
      onboardingDone: _parseBool(meta['onboardingDone']),
      hasCompletedSetup: _parseBool(meta['hasCompletedSetup']),
      globalReminderSettings: globalReminderSettings,
      products: products,
      entries: entries,
      achievements: achievements,
      reductionPlan: reductionPlan,
    );
  }

  static List<String> parseRow(String line) {
    final out = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
        if (inQuotes && nextIsQuote) {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        out.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    out.add(buffer.toString());
    return out;
  }

  static String _normalize(String raw) => raw.replaceFirst('\uFEFF', '').trim();

  static String _encodeRow(List<String> cells) {
    return cells.map(_escapeCell).join(',');
  }

  static String _escapeCell(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  static Map<String, String> _decodeMeta(List<List<String>>? rows) {
    final sectionRows = rows ?? <List<String>>[];
    if (sectionRows.isEmpty) {
      throw const FormatException('Sezione meta mancante nel backup.');
    }
    final header = sectionRows.first;
    if (header.length < 2 || header[0] != 'key' || header[1] != 'value') {
      throw const FormatException('Header meta non valido.');
    }

    final meta = <String, String>{};
    for (final row in sectionRows.skip(1)) {
      if (row.isEmpty || row.first.trim().isEmpty) continue;
      final key = row[0].trim();
      final value = row.length > 1 ? row[1] : '';
      meta[key] = value;
    }
    return meta;
  }

  static List<TrackedProduct> _decodeProducts(List<List<String>>? rows) {
    final sectionRows = rows ?? <List<String>>[];
    if (sectionRows.isEmpty) {
      throw const FormatException('Sezione prodotti mancante nel backup.');
    }
    final header = sectionRows.first;
    _expectHeader(
      header,
      <String>[
        'id',
        'name',
        'totalCost',
        'pieces',
        'minutesLost',
        'dailyLimit',
        'packRemaining',
      ],
      'prodotti',
    );

    final headerIndex = <String, int>{
      for (var i = 0; i < header.length; i++) header[i]: i,
    };

    String readCell(List<String> row, String column) {
      final index = headerIndex[column];
      if (index == null || index >= row.length) return '';
      return row[index];
    }

    return sectionRows.skip(1).where((row) => row.isNotEmpty).map((row) {
      if (row.length < 7) {
        throw const FormatException('Riga prodotti incompleta.');
      }

      return TrackedProduct(
        id: row[0],
        name: row[1],
        totalCost: double.parse(row[2]),
        pieces: int.parse(row[3]),
        minutesLost: int.parse(row[4]),
        dailyLimit: int.parse(row[5]),
        packRemaining: int.parse(row[6]),
        tracksInventory: headerIndex.containsKey('tracksInventory')
            ? _parseBool(readCell(row, 'tracksInventory'))
            : true,
        directUnitCost: readCell(row, 'directUnitCost').trim().isEmpty
            ? null
            : double.parse(readCell(row, 'directUnitCost')),
        isArchived: headerIndex.containsKey('isArchived')
            ? _parseBool(readCell(row, 'isArchived'))
            : false,
      );
    }).toList();
  }

  static List<SmokeEntry> _decodeEntries(List<List<String>>? rows) {
    final sectionRows = rows ?? <List<String>>[];
    if (sectionRows.isEmpty) {
      throw const FormatException('Sezione cronologia mancante nel backup.');
    }
    _expectHeader(
        sectionRows.first,
        <String>[
          'id',
          'timestamp',
          'costDeducted',
          'minutesLost',
          'productId',
        ],
        'cronologia');

    return sectionRows.skip(1).where((row) => row.isNotEmpty).map((row) {
      if (row.length < 5) {
        throw const FormatException('Riga cronologia incompleta.');
      }
      return SmokeEntry(
        id: row[0],
        timestamp: DateTime.parse(row[1]),
        costDeducted: double.parse(row[2]),
        minutesLost: int.parse(row[3]),
        productId: row[4],
      );
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static List<Achievement> _decodeAchievements(List<List<String>>? rows) {
    final sectionRows = rows ?? <List<String>>[];
    if (sectionRows.isEmpty) {
      return AchievementId.values
          .map((id) => Achievement.definition(id))
          .toList(growable: false);
    }

    _expectHeader(
        sectionRows.first,
        <String>[
          'id',
          'isUnlocked',
          'unlockedAt',
        ],
        'achievement');

    final imported = <AchievementId, Achievement>{};
    for (final row in sectionRows.skip(1)) {
      if (row.isEmpty || row.first.trim().isEmpty) continue;
      if (row.length < 3) {
        throw const FormatException('Riga achievement incompleta.');
      }
      final id = AchievementId.values.byName(row[0].trim());
      final unlocked = _parseBool(row[1]);
      final unlockedAt = row[2].trim().isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
          : DateTime.parse(row[2]);
      imported[id] = unlocked
          ? Achievement.definition(id).copyWithUnlockedAt(unlockedAt)
          : Achievement.definition(id);
    }

    return AchievementId.values
        .map((id) => imported[id] ?? Achievement.definition(id))
        .toList(growable: false);
  }

  static ReductionPlan? _decodeReductionPlan(List<List<String>>? rows) {
    final sectionRows = rows ?? <List<String>>[];
    if (sectionRows.isEmpty) return null;

    _expectHeader(
      sectionRows.first,
      sectionRows.first.length >= 5
          ? <String>[
              'productId',
              'startAverage',
              'targetPerDay',
              'totalWeeks',
              'startDate',
            ]
          : <String>['startAverage', 'targetPerDay', 'totalWeeks', 'startDate'],
      'piano di riduzione',
    );
    if (sectionRows.length < 2 ||
        sectionRows[1].every((cell) => cell.isEmpty)) {
      return null;
    }

    final row = sectionRows[1];
    if (row.length < 4) {
      throw const FormatException('Riga piano di riduzione incompleta.');
    }
    final hasProductId = sectionRows.first.length >= 5;
    return ReductionPlan(
      productId: hasProductId ? row[0] : '',
      startAverage: double.parse(row[hasProductId ? 1 : 0]),
      targetPerDay: double.parse(row[hasProductId ? 2 : 1]),
      totalWeeks: int.parse(row[hasProductId ? 3 : 2]),
      startDate: DateTime.parse(row[hasProductId ? 4 : 3]),
    );
  }

  static void _expectHeader(
    List<String> actual,
    List<String> expected,
    String sectionName,
  ) {
    if (actual.length < expected.length) {
      throw FormatException('Header $sectionName non valido.');
    }
    for (var i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) {
        throw FormatException('Header $sectionName non valido.');
      }
    }
  }

  static bool _parseBool(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static AppReminderSettings _decodeGlobalReminder(
    List<List<String>>? rows,
    List<List<String>>? productRows,
  ) {
    final sectionRows = rows ?? <List<String>>[];
    if (sectionRows.isNotEmpty) {
      _expectHeader(
        sectionRows.first,
        <String>['enabled', 'intervalMinutes'],
        'promemoria globale',
      );
      if (sectionRows.length >= 2 && sectionRows[1].isNotEmpty) {
        final row = sectionRows[1];
        return AppReminderSettings(
          enabled: row.isNotEmpty ? _parseBool(row[0]) : false,
          intervalMinutes: row.length > 1 ? int.tryParse(row[1]) ?? 120 : 120,
        );
      }
      return AppReminderSettings.defaults;
    }

    final legacyRows = productRows ?? <List<String>>[];
    if (legacyRows.isEmpty) return AppReminderSettings.defaults;

    final header = legacyRows.first;
    final enabledIndex = header.indexOf('periodicReminderEnabled');
    final minutesIndex = header.indexOf('periodicReminderMinutes');
    if (enabledIndex == -1 || minutesIndex == -1) {
      return AppReminderSettings.defaults;
    }

    final enabledIntervals = <int>[];
    for (final row in legacyRows.skip(1)) {
      if (row.isEmpty) continue;
      final enabled =
          enabledIndex < row.length && _parseBool(row[enabledIndex]);
      if (!enabled) continue;
      final minutes =
          minutesIndex < row.length ? int.tryParse(row[minutesIndex]) : null;
      enabledIntervals.add(
        AppReminderSettings.fromJson(
          <String, dynamic>{
            'enabled': true,
            'intervalMinutes': minutes,
          },
        ).intervalMinutes,
      );
    }

    if (enabledIntervals.isEmpty) {
      return AppReminderSettings.defaults;
    }
    final distinctIntervals = enabledIntervals.toSet();
    if (distinctIntervals.length != 1) {
      return AppReminderSettings.defaults;
    }
    return AppReminderSettings(
      enabled: true,
      intervalMinutes: distinctIntervals.first,
    );
  }

}

extension on Achievement {
  Achievement copyWithUnlockedAt(DateTime? unlockedAt) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      unlockedAt: unlockedAt,
    );
  }
}
