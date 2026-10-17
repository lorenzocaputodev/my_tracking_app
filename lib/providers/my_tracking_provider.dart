import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../l10n/l10n.dart';
import '../models/achievement.dart';
import '../models/app_reminder_settings.dart';
import '../models/pack_config.dart';
import '../models/reduction_plan.dart';
import '../models/smoke_entry.dart';
import '../models/tracked_product.dart';
import '../services/product_notification_service.dart';
import '../utils/app_backup_csv.dart';
import '../utils/app_clock.dart';
import '../utils/calendar_days.dart';
import '../utils/widget_bridge.dart';

enum AppThemePreference { dark, light, system }

enum HomeInsightType {
  planAhead,
  planOnTrack,
  planBehind,
  limitRemaining,
  comparedToYesterday,
}

enum ReductionPlanStatus { ahead, onTrack, behind }

class HomeInsight {
  final HomeInsightType type;
  final int value;

  const HomeInsight({required this.type, this.value = 0});
}

class BackupImportOutcome {
  final int products;
  final int entries;
  final int unlockedAchievements;
  final int reductionPlans;

  const BackupImportOutcome({
    required this.products,
    required this.entries,
    required this.unlockedAchievements,
    required this.reductionPlans,
  });
}

class BackupRestoreException implements Exception {
  final String message;

  const BackupRestoreException(this.message);

  @override
  String toString() => message;
}

class ReductionPlanProgress {
  final ReductionPlan plan;
  final double recentAverage;
  final double currentTarget;
  final ReductionPlanStatus status;

  const ReductionPlanProgress({
    required this.plan,
    required this.recentAverage,
    required this.currentTarget,
    required this.status,
  });
}

class WeeklyTrend {
  final double currentAverage;
  final double previousAverage;

  const WeeklyTrend({
    required this.currentAverage,
    required this.previousAverage,
  });

  double get deltaPercent {
    if (previousAverage <= 0) {
      return currentAverage > 0 ? 100 : 0;
    }
    return ((currentAverage - previousAverage) / previousAverage) * 100;
  }
}

// --- Provider ---

class MyTrackingProvider extends ChangeNotifier {
  // --- Chiavi storage ---

  static const _keyProducts = 'tracked_products_v1';
  static const _keyActiveProduct = 'active_product_id';
  static const _keyEntries = 'smoke_entries';
  static const _keyAchievements = 'achievements_v2';
  static const _keyReductionPlans = 'reduction_plans_v2';
  static const _keyReductionPlanLegacy = 'reduction_plan';
  static const _keyTheme = 'app_theme_preference';
  static const _keyWidgetTheme = 'widget_theme';
  static const _keyLanguage = appLanguagePreferenceKey;
  static const _keyCurrency = appCurrencyKey;
  static const _keyLastBackup = 'last_backup_export';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyHasCompletedSetup = 'hasCompletedSetup';
  static const _keyConfigLegacy = 'pack_config';
  static const _keyPackRemainingLegacy = 'pack_remaining';
  static const _keyGlobalReminderSettings = 'global_reminder_settings_v1';
  static const _keyGlobalDailySummarySettingsLegacy =
      'global_daily_summary_settings_v1';
  static const _keyWidgetSnapshot = 'widget_snapshot_v1';
  static const _keyWidgetProductSnapshots = 'widget_product_snapshots_v2';
  static const _keyWidgetPendingEntries = 'widget_pending_entries_v1';
  static const _keyWidgetPendingEntryPrefix = 'widget_pending_entry_v2_';

  // --- Stato ---
  List<TrackedProduct> _products = [];
  String _activeProductId = '';
  List<SmokeEntry> _entries = [];
  bool _isLoading = true;

  final Map<AchievementId, Achievement> _achievements = {};
  final Map<String, ReductionPlan> _reductionPlans = {};
  AppThemePreference _themePreference = AppThemePreference.dark;
  bool _widgetDark = true;
  AppLanguagePreference _languagePreference;
  AppCurrency _currency = AppCurrency.eur;
  DateTime? _lastBackupAt;
  AppReminderSettings _globalReminderSettings = AppReminderSettings.defaults;

  Timer? _ticker;
  bool _isForeground = true;

  MyTrackingProvider({
    AppLanguagePreference initialLanguage = AppLanguagePreference.system,
  }) : _languagePreference = initialLanguage {
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => notifyListeners(),
    );
  }

  Future<void> _queue = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  void setForeground(bool value) {
    if (_isForeground == value) return;
    _isForeground = value;
    if (value) {
      _startTicker();
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  // --- Getter prodotto attivo ---

  TrackedProduct get activeProduct {
    for (final p in _products) {
      if (p.id == _activeProductId && !p.isArchived) return p;
    }
    if (activeProducts.isNotEmpty) return activeProducts.first;
    if (_products.isNotEmpty) return _products.first;
    return const TrackedProduct(
      id: '',
      name: '',
      totalCost: 0,
      pieces: 1,
      minutesLost: 0,
      dailyLimit: 0,
      packRemaining: 0,
      tracksInventory: true,
      isArchived: false,
    );
  }

  List<TrackedProduct> get products => List.unmodifiable(_products);
  List<TrackedProduct> get activeProducts =>
      List.unmodifiable(_products.where((product) => !product.isArchived));
  List<TrackedProduct> get archivedProducts =>
      List.unmodifiable(_products.where((product) => product.isArchived));
  List<SmokeEntry> get visibleEntries => List.unmodifiable(
        _entries.where((entry) => _isActiveProductId(entry.productId)),
      );

  PackConfig get config => PackConfig(
        name: activeProduct.name,
        totalCost: activeProduct.totalCost,
        pieces: activeProduct.pieces,
        minutesLost: activeProduct.minutesLost,
        dailyLimit: activeProduct.dailyLimit,
        tracksInventory: activeProduct.tracksInventory,
        directUnitCost: activeProduct.directUnitCost,
      );

  List<SmokeEntry> get entries => List.unmodifiable(_entries);

  int get dailyCount => _countTodayForProduct(_activeProductId);
  int get packRemaining => activeProduct.packRemaining;
  bool get isLoading => _isLoading;
  AppThemePreference get themePreference => _themePreference;
  bool get widgetDark => _widgetDark;
  AppLanguagePreference get languagePreference => _languagePreference;
  AppCurrency get currency => _currency;
  DateTime? get lastBackupAt => _lastBackupAt;
  AppReminderSettings get globalReminderSettings => _globalReminderSettings;

  double get dailyCost =>
      todayEntries.fold(0.0, (sum, entry) => sum + entry.costDeducted);
  int get dailyMinutesLost =>
      todayEntries.fold(0, (sum, entry) => sum + entry.minutesLost);
  double get totalCost => entriesForProduct(_activeProductId)
      .fold(0.0, (sum, e) => sum + e.costDeducted);

  Duration? get timeSinceLastEntry {
    DateTime? last;
    for (final e in _entries) {
      if (e.productId != _activeProductId) continue;
      if (last == null || e.timestamp.isAfter(last)) last = e.timestamp;
    }
    if (last == null) return null;
    return appNow().difference(last);
  }

  List<SmokeEntry> get todayEntries {
    final today = dateOnly(appNow());
    return _entries
        .where(
          (e) =>
              e.productId == _activeProductId && dateOnly(e.timestamp) == today,
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<SmokeEntry> entriesForProduct(String productId) =>
      _entries.where((e) => e.productId == productId).toList();

  bool get dailyLimitReached =>
      activeProduct.dailyLimit > 0 && dailyCount >= activeProduct.dailyLimit;

  int? get remainingToday => activeProduct.dailyLimit > 0
      ? activeProduct.dailyLimit - dailyCount
      : null;

  // --- Statistiche per prodotto ---

  DateTime? _firstDayForProduct(String productId) {
    final list = entriesForProduct(productId);
    if (list.isEmpty) return null;
    return list
        .map((e) => dateOnly(e.timestamp))
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  double recentDailyAverage(String productId, {int days = 14}) {
    final first = _firstDayForProduct(productId);
    if (first == null) return 0;
    final today = dateOnly(appNow());
    if (!first.isBefore(today)) {
      return _countOnForProduct(productId, today).toDouble();
    }
    final end = addDays(today, -1);
    var start = addDays(end, -(days - 1));
    if (first.isAfter(start)) start = first;
    return averageDailyCountForRange(
      productId: productId,
      start: start,
      end: end,
    );
  }

  int currentStreakForProduct(String productId) {
    final counts = _countsPerDay(entriesForProduct(productId));
    if (counts.isEmpty) return 0;
    int streak = 0;
    var day = dateOnly(appNow());
    if (!counts.containsKey(day)) {
      day = addDays(day, -1);
    }
    while (counts.containsKey(day)) {
      streak++;
      day = addDays(day, -1);
    }
    return streak;
  }

  int underLimitStreakForProduct(String productId) {
    TrackedProduct? p;
    for (final x in _products) {
      if (x.id == productId) {
        p = x;
        break;
      }
    }
    if (p == null || p.dailyLimit <= 0) return 0;
    final counts = _countsPerDay(entriesForProduct(productId));
    if (counts.isEmpty) return 0;
    final first = counts.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    final limit = p.dailyLimit;
    final today = dateOnly(appNow());
    if ((counts[today] ?? 0) >= limit) return 0;
    int streak = 0;
    var day = addDays(today, -1);
    while (!day.isBefore(first) && (counts[day] ?? 0) < limit) {
      streak++;
      day = addDays(day, -1);
    }
    return streak;
  }

  List<Achievement> get allAchievements => AchievementId.values
      .map((id) => _achievements[id] ?? Achievement.definition(id))
      .toList();

  List<Achievement> get unlockedAchievements {
    return allAchievements.where((a) => a.isUnlocked).toList()
      ..sort(
        (a, b) => (b.unlockedAt ?? DateTime(0))
            .compareTo(a.unlockedAt ?? DateTime(0)),
      );
  }

  ReductionPlan? get activeProductReductionPlan =>
      reductionPlanForProduct(_activeProductId);

  List<ReductionPlan> get reductionPlans =>
      List.unmodifiable(_reductionPlans.values);

  HomeInsight? get homeInsight {
    final progress = reductionProgressForProduct(_activeProductId);
    if (progress != null) {
      return HomeInsight(
        type: switch (progress.status) {
          ReductionPlanStatus.ahead => HomeInsightType.planAhead,
          ReductionPlanStatus.onTrack => HomeInsightType.planOnTrack,
          ReductionPlanStatus.behind => HomeInsightType.planBehind,
        },
      );
    }

    if (!dailyLimitReached && activeProduct.dailyLimit > 0) {
      final remaining = remainingToday;
      if (remaining != null && remaining > 0) {
        return HomeInsight(
          type: HomeInsightType.limitRemaining,
          value: remaining,
        );
      }
    }

    final yesterday = countOnDayForProduct(
      _activeProductId,
      addDays(dateOnly(appNow()), -1),
    );
    if (dailyCount == 0 && yesterday == 0) return null;

    return HomeInsight(
      type: HomeInsightType.comparedToYesterday,
      value: dailyCount - yesterday,
    );
  }

  String? productNameById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id).name;
    } catch (_) {
      return null;
    }
  }

  // --- Init ---

  Future<void> init() async {
    await _reloadFromPrefs();
    _isLoading = false;
    notifyListeners();
    await syncWidgets();
    await _syncNotifications();
  }

  Future<void> _reloadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _hydrateFromPrefs(prefs);
    final pendingKeys = _consumePendingWidgetEntries(prefs);
    final migratedPlan = _needsReductionPlanRewrite(prefs);
    final migratedGlobalReminder =
        !prefs.containsKey(_keyGlobalReminderSettings);

    var achievementsChanged = false;
    try {
      achievementsChanged = _evaluateAchievements();
    } catch (_) {}

    if (achievementsChanged) {
      await _persistAchievements();
    }
    if (pendingKeys != null) {
      await _persistEntriesOnly(prefs);
      await _persistProductsOnly(prefs);
      for (final key in pendingKeys) {
        await prefs.remove(key);
      }
    }
    if (migratedPlan) {
      await _persistReductionPlansOnly(prefs);
    }
    if (migratedGlobalReminder) {
      await _persistGlobalReminderOnly(prefs);
    }
  }

  static AppThemePreference _parseTheme(String name) {
    for (final v in AppThemePreference.values) {
      if (v.name == name) return v;
    }
    return AppThemePreference.dark;
  }

  Future<void> drainOnResume() => _serialized(() async {
        if (_isLoading) return;
        await _reloadFromPrefs();
        notifyListeners();
        await syncWidgets();
        await _syncNotifications();
      });

  // --- Tema ---

  Future<void> setThemePreference(AppThemePreference value) =>
      _serialized(() async {
        _themePreference = value;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyTheme, value.name);
      });

  Future<void> setLanguagePreference(AppLanguagePreference value) =>
      _serialized(() async {
        _languagePreference = value;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLanguage, value.name);
        await _applyLanguageOutsideApp();
      });

  Future<void> onSystemLocaleChanged() async {
    if (_languagePreference != AppLanguagePreference.system) return;
    await _applyLanguageOutsideApp();
  }

  Future<void> _applyLanguageOutsideApp() async {
    await WidgetBridge.updateWidgets();
    await ProductNotificationService.refreshChannel();
  }

  Future<void> setWidgetDark(bool dark) => _serialized(() async {
        _widgetDark = dark;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyWidgetTheme, dark ? 'dark' : 'light');
        await WidgetBridge.updateWidgets();
      });

  // --- Valuta ---

  void _applyCurrency(AppCurrency value) {
    _currency = value;
    L10n.currency = value;
  }

  Future<void> setCurrency(AppCurrency value) => _serialized(() async {
        _applyCurrency(value);
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyCurrency, value.name);
        await WidgetBridge.updateWidgets();
      });

  // --- Ultimo backup ---

  Future<void> markBackupExported() => _serialized(() async {
        final now = appNow();
        _lastBackupAt = now;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastBackup, now.toIso8601String());
      });

  // --- Prodotti ---

  Future<void> setActiveProduct(String id) => _serialized(() async {
        if (!_products.any((p) => p.id == id && !p.isArchived)) return;
        _activeProductId = id;
        notifyListeners();
        await _persistActiveProductSelection();
        await syncWidgets();
      });

  Future<void> addProduct(TrackedProduct product) => _serialized(() async {
        _products = [..._products, product];
        _activeProductId = product.id;
        notifyListeners();
        await _persistProducts();
      });

  Future<void> updateGlobalReminderSettings(AppReminderSettings settings) =>
      _serialized(() async {
        _globalReminderSettings = settings;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await _persistGlobalReminderOnly(prefs);
        await _syncNotifications();
      });

  Future<void> updateProductConfig(PackConfig cfg, {String? productId}) =>
      _serialized(() async {
        final pid = productId ?? _activeProductId;
        final idx = _products.indexWhere((p) => p.id == pid);
        if (idx == -1) return;
        final cur = _products[idx];
        var next = cur.copyWith(
          name: cfg.name,
          totalCost: cfg.totalCost,
          pieces: cfg.pieces,
          minutesLost: cfg.minutesLost,
          dailyLimit: cfg.dailyLimit,
          tracksInventory: cfg.tracksInventory,
          directUnitCost: cfg.directUnitCost,
          clearDirectUnitCost: cfg.directUnitCost == null,
        );
        if (next.tracksInventory && next.packRemaining > next.pieces) {
          next = next.copyWith(packRemaining: next.pieces);
        }
        if (!cur.tracksInventory &&
            next.tracksInventory &&
            next.packRemaining <= 0 &&
            next.pieces > 0) {
          next = next.copyWith(packRemaining: next.pieces);
        }
        _products = List<TrackedProduct>.from(_products)..[idx] = next;
        notifyListeners();
        await _persistProducts();
      });

  Future<void> correctPackRemaining(
    int packRemaining, {
    String? productId,
  }) =>
      _serialized(() async {
        final pid = productId ?? _activeProductId;
        final idx = _products.indexWhere((p) => p.id == pid);
        if (idx == -1) {
          throw StateError(L10n.current.errorProductNotFound);
        }

        final product = _products[idx];
        if (!product.tracksInventory) {
          throw StateError(L10n.current.errorStockCorrectionUnavailable);
        }
        if (packRemaining < 0 || packRemaining > product.pieces) {
          throw RangeError.range(
            packRemaining,
            0,
            product.pieces,
            'packRemaining',
          );
        }

        _products = List<TrackedProduct>.from(_products)
          ..[idx] = product.copyWith(packRemaining: packRemaining);
        notifyListeners();
        await _persistProducts();
      });

  Future<bool> archiveProduct(String id) => _serialized(() async {
        final idx = _products.indexWhere((p) => p.id == id);
        if (idx == -1) return false;
        final product = _products[idx];
        if (product.isArchived || activeProducts.length <= 1) return false;

        _products = List<TrackedProduct>.from(_products)
          ..[idx] = product.copyWith(isArchived: true);

        if (_activeProductId == id) {
          _activeProductId = _normalizeActiveProductId(_activeProductId);
        }

        notifyListeners();
        await _persistProducts();
        return true;
      });

  Future<void> restoreProduct(String id) => _serialized(() async {
        final idx = _products.indexWhere((p) => p.id == id);
        if (idx == -1) return;
        final product = _products[idx];
        if (!product.isArchived) return;

        _products = List<TrackedProduct>.from(_products)
          ..[idx] = product.copyWith(isArchived: false);

        if (_activeProductId.isEmpty ||
            _isArchivedProductId(_activeProductId)) {
          _activeProductId = id;
        }

        notifyListeners();
        await _persistProducts();
      });

  Future<void> deleteArchivedProduct(String id) => _serialized(() async {
        final product = _products.cast<TrackedProduct?>().firstWhere(
              (item) => item?.id == id,
              orElse: () => null,
            );
        if (product == null || !product.isArchived) {
          return;
        }
        _entries = _entries.where((e) => e.productId != id).toList();
        final nextProducts = _products.where((p) => p.id != id).toList();
        _products = nextProducts;

        if (_activeProductId == id) {
          _activeProductId = _normalizeActiveProductId(_activeProductId);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyActiveProduct, _activeProductId);
        }

        final hadPlan = _reductionPlans.remove(id) != null;

        await _persist();
        if (hadPlan) {
          await _persistReductionPlansOnly(
            await SharedPreferences.getInstance(),
          );
        }
        notifyListeners();
      });

  // --- Voci cronologia ---

  Future<SmokeEntry?> logEntry({String? productId}) => _serialized(() async {
        final pid = productId ?? _activeProductId;
        final pIdx = _products.indexWhere((p) => p.id == pid);
        if (pIdx == -1) return null;
        final p = _products[pIdx];
        if (p.isArchived) return null;
        if (p.tracksInventory && p.packRemaining <= 0) return null;

        final entry = SmokeEntry(
          id: const Uuid().v4(),
          timestamp: appNow(),
          costDeducted: p.unitCost,
          minutesLost: p.minutesLost,
          productId: pid,
        );
        _entries.add(entry);
        if (p.tracksInventory) {
          _products[pIdx] = p.copyWith(packRemaining: p.packRemaining - 1);
        }
        final badgesChanged = _evaluateAchievements();
        notifyListeners();
        await _persist();
        if (badgesChanged) await _persistAchievements();
        return entry;
      });

  Future<void> openNewPack({String? productId}) => _serialized(() async {
        final pid = productId ?? _activeProductId;
        final idx = _products.indexWhere((p) => p.id == pid);
        if (idx == -1) return;
        final p = _products[idx];
        if (p.isArchived || !p.tracksInventory) return;
        _products = List<TrackedProduct>.from(_products)
          ..[idx] = p.copyWith(packRemaining: p.pieces);
        notifyListeners();
        await _persistProducts();
      });

  Future<({SmokeEntry entry, bool stockReturned})?> deleteEntry(
    String id,
  ) =>
      _serialized(() async {
        final idx = _entries.indexWhere((e) => e.id == id);
        if (idx == -1) return null;
        final entry = _entries[idx];
        var stockReturned = false;
        final pIdx = _products.indexWhere((p) => p.id == entry.productId);
        if (pIdx != -1) {
          final pr = _products[pIdx];
          if (pr.tracksInventory &&
              pr.packRemaining < pr.pieces &&
              _isFromCurrentPack(entry, pr)) {
            _products = List<TrackedProduct>.from(_products)
              ..[pIdx] = pr.copyWith(packRemaining: pr.packRemaining + 1);
            stockReturned = true;
          }
        }
        _entries.removeAt(idx);
        final badgesChanged = _evaluateAchievements();
        notifyListeners();
        await _persist();
        if (badgesChanged) await _persistAchievements();
        return (entry: entry, stockReturned: stockReturned);
      });

  bool _isFromCurrentPack(SmokeEntry entry, TrackedProduct product) {
    final usedFromPack = product.pieces - product.packRemaining;
    if (usedFromPack <= 0) return false;
    final newer = _entries
        .where(
          (e) =>
              e.productId == product.id &&
              e.id != entry.id &&
              !e.timestamp.isBefore(entry.timestamp),
        )
        .length;
    return newer < usedFromPack;
  }

  Future<void> restoreEntry(
    ({SmokeEntry entry, bool stockReturned}) deleted,
  ) =>
      _serialized(() async {
        final entry = deleted.entry;
        if (_entries.any((e) => e.id == entry.id)) return;
        final at =
            _entries.indexWhere((e) => e.timestamp.isAfter(entry.timestamp));
        _entries.insert(at == -1 ? _entries.length : at, entry);
        if (deleted.stockReturned) {
          final pIdx = _products.indexWhere((p) => p.id == entry.productId);
          if (pIdx != -1 && _products[pIdx].packRemaining > 0) {
            final pr = _products[pIdx];
            _products = List<TrackedProduct>.from(_products)
              ..[pIdx] = pr.copyWith(packRemaining: pr.packRemaining - 1);
          }
        }
        final badgesChanged = _evaluateAchievements();
        notifyListeners();
        await _persist();
        if (badgesChanged) await _persistAchievements();
      });

  Future<void> clearHistory() => _serialized(() async {
        _entries.clear();
        notifyListeners();
        await _persist();
      });

  // --- Piano di riduzione ---

  Future<void> setReductionPlan({
    String? productId,
    required double targetPerDay,
    required int totalWeeks,
  }) =>
      _serialized(() async {
        final boundProductId = productId ?? _activeProductId;
        if (boundProductId.isEmpty ||
            !_products.any((p) => p.id == boundProductId)) {
          return;
        }
        final existing = _reductionPlans[boundProductId];
        final recentAverage = recentDailyAverage(boundProductId);
        _reductionPlans[boundProductId] = ReductionPlan(
          productId: boundProductId,
          startAverage: existing?.startAverage ??
              (recentAverage > 0 ? recentAverage : 1.0),
          targetPerDay: targetPerDay,
          totalWeeks: totalWeeks,
          startDate: existing?.startDate ?? appNow(),
        );
        final prefs = await SharedPreferences.getInstance();
        await _persistReductionPlansOnly(prefs);
        notifyListeners();
      });

  Future<void> deleteReductionPlan({String? productId}) =>
      _serialized(() async {
        final targetId = productId ?? _activeProductId;
        if (_reductionPlans.remove(targetId) == null) return;
        final prefs = await SharedPreferences.getInstance();
        await _persistReductionPlansOnly(prefs);
        notifyListeners();
      });

  // --- Achievement ---

  bool _evaluateAchievements() {
    bool changed = false;

    Map<AchievementId, DateTime>? reached;

    void tryUnlock(AchievementId id) {
      if (!(_achievements[id]?.isUnlocked ?? false)) {
        reached ??= _achievementDatesFromHistory();
        _achievements[id] = Achievement.definition(id).unlock(reached![id]);
        changed = true;
      }
    }

    if (_entries.isNotEmpty) tryUnlock(AchievementId.firstEntry);

    final distinctDayCount = _distinctDays(_entries).length;
    if (distinctDayCount >= 7) tryUnlock(AchievementId.tracked7days);
    if (distinctDayCount >= 30) tryUnlock(AchievementId.tracked30days);

    var streak = 0;
    var underLimit = 0;
    for (final product in _products) {
      if (product.isArchived) continue;
      final productStreak = currentStreakForProduct(product.id);
      if (productStreak > streak) streak = productStreak;
      if (product.dailyLimit > 0) {
        final productUnderLimit = underLimitStreakForProduct(product.id);
        if (productUnderLimit > underLimit) underLimit = productUnderLimit;
      }
    }

    if (streak >= 3) tryUnlock(AchievementId.streak3);
    if (streak >= 7) tryUnlock(AchievementId.streak7);
    if (streak >= 14) tryUnlock(AchievementId.streak14);
    if (streak >= 30) tryUnlock(AchievementId.streak30);

    if (underLimit >= 1) tryUnlock(AchievementId.underLimit1);
    if (underLimit >= 3) tryUnlock(AchievementId.underLimit3);
    if (underLimit >= 7) tryUnlock(AchievementId.underLimit7);
    if (underLimit >= 30) tryUnlock(AchievementId.underLimit30);

    var reduction = 0.0;
    for (final plan in _reductionPlans.values) {
      if (plan.productId.isEmpty || plan.startAverage <= 0) continue;
      if (!_products.any(
        (product) => product.id == plan.productId && !product.isArchived,
      )) {
        continue;
      }
      if (appNow().difference(plan.startDate).inDays < 7) continue;
      final baselineFrom = plan.startDate.subtract(const Duration(days: 14));
      if (!_entries.any(
        (e) =>
            e.productId == plan.productId &&
            e.timestamp.isBefore(plan.startDate) &&
            !e.timestamp.isBefore(baselineFrom),
      )) {
        continue;
      }
      final currentAverage = recentDailyAverage(plan.productId, days: 7);
      final planReduction =
          (plan.startAverage - currentAverage) / plan.startAverage;
      if (planReduction > reduction) reduction = planReduction;
    }

    if (reduction >= 0.10) tryUnlock(AchievementId.reduction10pct);
    if (reduction >= 0.25) tryUnlock(AchievementId.reduction25pct);
    if (reduction >= 0.50) tryUnlock(AchievementId.reduction50pct);

    return changed;
  }

  Map<AchievementId, DateTime> _achievementDatesFromHistory() {
    final dates = <AchievementId, DateTime>{};
    if (_entries.isEmpty) return dates;

    void reach(AchievementId id, DateTime at) {
      final current = dates[id];
      if (current == null || at.isBefore(current)) dates[id] = at;
    }

    Map<DateTime, DateTime> firstTimestampPerDay(Iterable<SmokeEntry> list) {
      final firsts = <DateTime, DateTime>{};
      for (final entry in list) {
        final day = dateOnly(entry.timestamp);
        final current = firsts[day];
        if (current == null || entry.timestamp.isBefore(current)) {
          firsts[day] = entry.timestamp;
        }
      }
      return firsts;
    }

    final allDays = firstTimestampPerDay(_entries);
    final sortedDays = allDays.keys.toList()..sort();
    reach(AchievementId.firstEntry, allDays[sortedDays.first]!);
    if (sortedDays.length >= 7) {
      reach(AchievementId.tracked7days, allDays[sortedDays[6]]!);
    }
    if (sortedDays.length >= 30) {
      reach(AchievementId.tracked30days, allDays[sortedDays[29]]!);
    }

    const streakBadges = {
      3: AchievementId.streak3,
      7: AchievementId.streak7,
      14: AchievementId.streak14,
      30: AchievementId.streak30,
    };
    const underLimitBadges = {
      1: AchievementId.underLimit1,
      3: AchievementId.underLimit3,
      7: AchievementId.underLimit7,
      30: AchievementId.underLimit30,
    };
    final today = dateOnly(appNow());

    for (final product in _products) {
      if (product.isArchived) continue;
      final productEntries = entriesForProduct(product.id);
      final firsts = firstTimestampPerDay(productEntries);
      if (firsts.isEmpty) continue;
      final days = firsts.keys.toList()..sort();

      var run = 0;
      DateTime? previous;
      for (final day in days) {
        run = previous != null && addDays(previous, 1) == day ? run + 1 : 1;
        previous = day;
        final badge = streakBadges[run];
        if (badge != null) reach(badge, firsts[day]!);
      }

      if (product.dailyLimit <= 0) continue;
      final counts = _countsPerDay(productEntries);
      run = 0;
      for (var day = days.first; day.isBefore(today); day = addDays(day, 1)) {
        run = (counts[day] ?? 0) < product.dailyLimit ? run + 1 : 0;
        final badge = underLimitBadges[run];
        if (badge != null) reach(badge, addDays(day, 1));
      }
    }
    return dates;
  }

  String _encodeAchievements() =>
      jsonEncode(_achievements.values.map((a) => a.toJson()).toList());

  Future<void> _persistAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAchievements, _encodeAchievements());
  }

  ReductionPlan? reductionPlanForProduct(String productId) {
    if (productId.isEmpty || _isArchivedProductId(productId)) return null;
    return _reductionPlans[productId];
  }

  ReductionPlanProgress? reductionProgressForProduct(String productId) {
    final plan = reductionPlanForProduct(productId);
    if (plan == null) return null;
    final recentAverage = recentDailyAverage(productId, days: 7);
    final currentTarget = plan.currentWeekTarget;
    final delta = recentAverage - currentTarget;
    final status = delta <= -0.5
        ? ReductionPlanStatus.ahead
        : delta >= 0.5
            ? ReductionPlanStatus.behind
            : ReductionPlanStatus.onTrack;
    return ReductionPlanProgress(
      plan: plan,
      recentAverage: recentAverage,
      currentTarget: currentTarget,
      status: status,
    );
  }

  List<SmokeEntry> entriesForRange({
    String? productId,
    DateTime? start,
    DateTime? end,
  }) {
    final startDay = start != null ? dateOnly(start) : null;
    final endDay = end != null ? dateOnly(end) : null;
    final visibleProductIds =
        activeProducts.map((product) => product.id).toSet();

    return _entries.where((entry) {
      if (productId != null) {
        if (entry.productId != productId) return false;
      } else if (!visibleProductIds.contains(entry.productId)) {
        return false;
      }
      final entryDay = dateOnly(entry.timestamp);
      if (startDay != null && entryDay.isBefore(startDay)) return false;
      if (endDay != null && entryDay.isAfter(endDay)) return false;
      return true;
    }).toList();
  }

  double averageDailyCountForRange({
    String? productId,
    required DateTime start,
    required DateTime end,
  }) {
    final startDay = dateOnly(start);
    final endDay = dateOnly(end);
    final dayCount = daysBetween(startDay, endDay) + 1;
    if (dayCount <= 0) return 0;
    return entriesForRange(
          productId: productId,
          start: startDay,
          end: endDay,
        ).length /
        dayCount;
  }

  int countOnDayForProduct(String productId, DateTime day) {
    return _countOnForProduct(productId, dateOnly(day));
  }

  WeeklyTrend weeklyTrend({String? productId}) {
    final today = dateOnly(appNow());
    final currentAverage = averageDailyCountForRange(
      productId: productId,
      start: addDays(today, -6),
      end: today,
    );
    final previousAverage = averageDailyCountForRange(
      productId: productId,
      start: addDays(today, -13),
      end: addDays(today, -7),
    );
    return WeeklyTrend(
      currentAverage: currentAverage,
      previousAverage: previousAverage,
    );
  }

  double projectedMonthlyCost({String? productId}) {
    final now = appNow();
    final monthStart = DateTime(now.year, now.month, 1);
    final entries = entriesForRange(
      productId: productId,
      start: monthStart,
      end: now,
    );
    final elapsedDays = _trackedDaysThisMonth(productId, monthStart, now);
    if (elapsedDays <= 0 || entries.isEmpty) return 0;
    final costSoFar = entries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.costDeducted,
    );
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return (costSoFar / elapsedDays) * daysInMonth;
  }

  int _trackedDaysThisMonth(
    String? productId,
    DateTime monthStart,
    DateTime now,
  ) {
    final source =
        productId == null ? visibleEntries : entriesForProduct(productId);
    if (source.isEmpty) return 0;
    var first = dateOnly(source.first.timestamp);
    for (final entry in source.skip(1)) {
      final day = dateOnly(entry.timestamp);
      if (day.isBefore(first)) first = day;
    }
    final start = first.isAfter(monthStart) ? first : monthStart;
    final today = dateOnly(now);
    if (today.isBefore(start)) return 0;
    var days = 1;
    for (var day = start; day.isBefore(today); day = addDays(day, 1)) {
      days++;
    }
    return days;
  }

  int projectedMonthlyUnits({String? productId}) {
    final now = appNow();
    final monthStart = DateTime(now.year, now.month, 1);
    final entries = entriesForRange(
      productId: productId,
      start: monthStart,
      end: now,
    );
    final elapsedDays = _trackedDaysThisMonth(productId, monthStart, now);
    if (elapsedDays <= 0 || entries.isEmpty) return 0;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return ((entries.length / elapsedDays) * daysInMonth).round();
  }

  int? peakHourForEntries(List<SmokeEntry> entries) {
    if (entries.isEmpty) return null;
    final counts = List.filled(24, 0);
    for (final entry in entries) {
      counts[entry.timestamp.toLocal().hour]++;
    }
    var maxValue = 0;
    var maxIndex = 0;
    for (var i = 0; i < counts.length; i++) {
      if (counts[i] > maxValue) {
        maxValue = counts[i];
        maxIndex = i;
      }
    }
    return maxValue > 0 ? maxIndex : null;
  }

  MapEntry<DateTime, int>? worstDayForEntries(List<SmokeEntry> entries) {
    final counts = _countsPerDay(entries);
    if (counts.length < 2) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  MapEntry<DateTime, int>? bestDayForEntries(List<SmokeEntry> entries) {
    final counts = _countsPerDay(entries);
    if (counts.length < 2) return null;
    return counts.entries.reduce((a, b) => a.value <= b.value ? a : b);
  }

  Map<DateTime, int> _countsPerDay(List<SmokeEntry> entries) {
    final counts = <DateTime, int>{};
    for (final entry in entries) {
      final day = dateOnly(entry.timestamp);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  List<int> hourDistributionForEntries(List<SmokeEntry> entries) {
    final counts = List<int>.filled(24, 0);
    for (final entry in entries) {
      counts[entry.timestamp.toLocal().hour]++;
    }
    return counts;
  }

  Map<String, ReductionPlan> _normalizeReductionPlans(
    Iterable<ReductionPlan> plans,
  ) {
    final normalized = <String, ReductionPlan>{};
    if (_products.isEmpty) return normalized;

    final knownIds = _products.map((product) => product.id).toSet();
    for (final plan in plans) {
      final boundId = plan.productId.isEmpty
          ? _normalizeActiveProductId(_activeProductId)
          : plan.productId;
      if (boundId.isEmpty || !knownIds.contains(boundId)) continue;
      if (normalized.containsKey(boundId)) continue;
      normalized[boundId] =
          plan.productId == boundId ? plan : plan.copyWith(productId: boundId);
    }
    return normalized;
  }

  bool _needsReductionPlanRewrite(SharedPreferences prefs) {
    return prefs.containsKey(_keyReductionPlanLegacy) ||
        !prefs.containsKey(_keyReductionPlans);
  }

  Future<void> _persistReductionPlansOnly(SharedPreferences prefs) async {
    await prefs.setString(_keyReductionPlans, _encodeReductionPlans());
    await prefs.remove(_keyReductionPlanLegacy);
  }

  String _encodeReductionPlans() {
    return jsonEncode(
      _reductionPlans.map((id, plan) => MapEntry(id, plan.toJson())),
    );
  }

  Future<void> _persistGlobalReminderOnly(SharedPreferences prefs) async {
    await prefs.setString(
      _keyGlobalReminderSettings,
      jsonEncode(_globalReminderSettings.toJson()),
    );
    await prefs.remove(_keyGlobalDailySummarySettingsLegacy);
  }

  // --- Export e import ---

  Future<String> exportFullBackupCsv() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final data = AppBackupData(
      backupVersion: AppBackupCsv.backupVersion,
      exportedAt: appNow().toUtc(),
      activeProductId: _normalizeActiveProductId(_activeProductId),
      themePreferenceName: _themePreference.name,
      languagePreferenceName: _languagePreference.name,
      currencyName: _currency.name,
      onboardingDone: prefs.getBool(_keyOnboardingDone) ?? false,
      hasCompletedSetup: prefs.getBool(_keyHasCompletedSetup) ?? false,
      globalReminderSettings: _globalReminderSettings,
      products: List<TrackedProduct>.from(_products),
      entries: List<SmokeEntry>.from(_entries)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
      achievements: List<Achievement>.from(allAchievements),
      reductionPlans: List<ReductionPlan>.from(_reductionPlans.values),
    );

    return AppBackupCsv.encode(data);
  }

  AppBackupData readBackupCsv(String csv) => AppBackupCsv.decode(csv);

  Future<BackupImportOutcome> restoreBackup(AppBackupData data) =>
      _serialized(() async {
        await _restoreFullBackup(data);
        return BackupImportOutcome(
          products: _products.length,
          entries: _entries.length,
          unlockedAchievements:
              _achievements.values.where((a) => a.isUnlocked).length,
          reductionPlans: _reductionPlans.length,
        );
      });

  Future<void> _restoreFullBackup(AppBackupData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final previousProducts = _products;
    final previousEntries = _entries;
    final previousActiveProductId = _activeProductId;
    final previousReminderSettings = _globalReminderSettings;
    final previousAchievements = Map.of(_achievements);
    final previousPlans = Map.of(_reductionPlans);
    final previousTheme = _themePreference;
    final previousLanguage = _languagePreference;
    final previousCurrency = _currency;
    final previousOnboardingDone = prefs.getBool(_keyOnboardingDone) ?? false;
    final previousSetupDone = prefs.getBool(_keyHasCompletedSetup) ?? false;

    _products = List<TrackedProduct>.from(data.products);
    _entries = List<SmokeEntry>.from(data.entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _activeProductId = _normalizeActiveProductId(data.activeProductId);
    _globalReminderSettings = data.globalReminderSettings;
    _achievements
      ..clear()
      ..addEntries(data.achievements.map((a) => MapEntry(a.id, a)));
    _reductionPlans
      ..clear()
      ..addAll(_normalizeReductionPlans(data.reductionPlans));
    _themePreference = _parseTheme(data.themePreferenceName);
    if (data.languagePreferenceName != null) {
      _languagePreference =
          parseLanguagePreference(data.languagePreferenceName);
    }
    if (data.currencyName != null) {
      _applyCurrency(parseCurrency(data.currencyName));
    }
    _dateUndatedAchievements();
    _evaluateAchievements();

    final onboardingDone =
        data.onboardingDone || _products.isNotEmpty || _entries.isNotEmpty;
    final hasCompletedSetup = data.hasCompletedSetup || _products.isNotEmpty;

    try {
      await _persistCompleteState(
        prefs,
        onboardingDone: onboardingDone,
        hasCompletedSetup: hasCompletedSetup,
        clearWidgetTransientState: true,
        clearLegacyConfig: true,
      );
      await _verifyPersistedState(prefs);
    } catch (_) {
      _products = previousProducts;
      _entries = previousEntries;
      _activeProductId = previousActiveProductId;
      _globalReminderSettings = previousReminderSettings;
      _achievements
        ..clear()
        ..addAll(previousAchievements);
      _reductionPlans
        ..clear()
        ..addAll(previousPlans);
      _themePreference = previousTheme;
      _languagePreference = previousLanguage;
      _applyCurrency(previousCurrency);
      try {
        await _persistCompleteState(
          prefs,
          onboardingDone: previousOnboardingDone,
          hasCompletedSetup: previousSetupDone,
        );
      } catch (_) {}
      notifyListeners();
      await syncWidgets();
      rethrow;
    }

    notifyListeners();
    await syncWidgets();
    await _syncNotifications();
  }

  void _dateUndatedAchievements() {
    Map<AchievementId, DateTime>? reached;
    for (final achievement in _achievements.values.toList()) {
      final at = achievement.unlockedAt;
      if (at == null || at.millisecondsSinceEpoch != 0) continue;
      reached ??= _achievementDatesFromHistory();
      _achievements[achievement.id] = Achievement.definition(achievement.id)
          .unlock(reached[achievement.id]);
    }
  }

  Future<void> _verifyPersistedState(SharedPreferences prefs) async {
    await prefs.reload();

    final storedEntries = prefs.getStringList(_keyEntries)?.length ?? 0;
    if (storedEntries != _entries.length) {
      throw BackupRestoreException(
        L10n.current.backupErrorEntriesNotSaved(
          storedEntries,
          _entries.length,
        ),
      );
    }

    final storedProductsJson = prefs.getString(_keyProducts);
    final storedProducts = storedProductsJson == null
        ? 0
        : (jsonDecode(storedProductsJson) as List<dynamic>).length;
    if (storedProducts != _products.length) {
      throw BackupRestoreException(
        L10n.current.backupErrorProductsNotSaved(
          storedProducts,
          _products.length,
        ),
      );
    }
  }

  Future<void> syncWidgets() async {
    await _persistWidgetSnapshots();
    await WidgetBridge.updateWidgets();
  }

  Future<void> _persistWidgetSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final now = appNow();
    final fallbackSnapshot = <String, dynamic>{
      'activeProductId': '',
      'dayKeyLocal': _dayKeyFor(now),
      'updatedAtEpochMs': now.millisecondsSinceEpoch,
    };

    if (_products.isEmpty) {
      await prefs.setString(
        _keyWidgetProductSnapshots,
        jsonEncode(<String, dynamic>{}),
      );
      await prefs.setString(_keyWidgetSnapshot, jsonEncode(fallbackSnapshot));
      return;
    }

    final productSnapshots = <String, dynamic>{};
    for (final product in _products) {
      final productEntries = entriesForProduct(product.id);
      final today = dateOnly(now);
      final todayEntries = productEntries
          .where((entry) => dateOnly(entry.timestamp) == today)
          .toList();
      final productDailyCount = todayEntries.length;
      productSnapshots[product.id] = <String, dynamic>{
        'activeProductId': product.id,
        'name': product.name,
        'tracksInventory': product.tracksInventory,
        'pieces': product.pieces,
        'packRemaining': product.packRemaining,
        'minutesLostPerUnit': product.minutesLost,
        'unitCost': product.unitCost,
        'dailyCount': productDailyCount,
        'dailyCost': todayEntries.fold<double>(
          0.0,
          (sum, entry) => sum + entry.costDeducted,
        ),
        'dailyMinutesLost': todayEntries.fold<int>(
          0,
          (sum, entry) => sum + entry.minutesLost,
        ),
        'totalSpentForActive': productEntries.fold<double>(
          0.0,
          (sum, entry) => sum + entry.costDeducted,
        ),
        'dayKeyLocal': _dayKeyFor(now),
        'updatedAtEpochMs': now.millisecondsSinceEpoch,
      };
    }

    await prefs.setString(
      _keyWidgetProductSnapshots,
      jsonEncode(productSnapshots),
    );
    final activeSnapshotId = _normalizeActiveProductId(_activeProductId);
    await prefs.setString(
      _keyWidgetSnapshot,
      jsonEncode(productSnapshots[activeSnapshotId] ?? fallbackSnapshot),
    );
  }

  Future<void> _persistActiveProductSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProduct, _activeProductId);
  }

  String _dayKeyFor(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  List<String>? _consumePendingWidgetEntries(SharedPreferences prefs) {
    final pending = <Object?>[];
    final legacyRaw = prefs.getString(_keyWidgetPendingEntries);
    if (legacyRaw != null && legacyRaw.trim().isNotEmpty) {
      try {
        pending.addAll(jsonDecode(legacyRaw) as List<dynamic>);
      } catch (_) {}
    }
    final entryKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(_keyWidgetPendingEntryPrefix))
        .toList();
    for (final key in entryKeys) {
      try {
        pending.add(jsonDecode(prefs.getString(key) ?? ''));
      } catch (_) {}
    }
    if (legacyRaw == null && entryKeys.isEmpty) return null;

    final existingIds = _entries.map((entry) => entry.id).toSet();
    var changed = false;
    for (final item in pending) {
      try {
        final map = (item as Map).cast<String, dynamic>();
        final entry = SmokeEntry.fromJson(map);
        if (existingIds.add(entry.id)) {
          _entries.add(entry);
          changed = true;
          if (map['deductStock'] == true) _deductWidgetStock(entry.productId);
        }
      } catch (_) {}
    }

    if (changed) {
      _entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return [if (legacyRaw != null) _keyWidgetPendingEntries, ...entryKeys];
  }

  void _deductWidgetStock(String productId) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx == -1) return;
    final product = _products[idx];
    if (!product.tracksInventory || product.packRemaining <= 0) return;
    _products = List<TrackedProduct>.from(_products)
      ..[idx] = product.copyWith(packRemaining: product.packRemaining - 1);
  }

  Future<void> _removePendingWidgetEntries(SharedPreferences prefs) async {
    await prefs.remove(_keyWidgetPendingEntries);
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_keyWidgetPendingEntryPrefix)) await prefs.remove(key);
    }
  }

  Future<void> _persistEntriesOnly(SharedPreferences prefs) async {
    await prefs.setStringList(
      _keyEntries,
      _entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> _persistCompleteState(
    SharedPreferences prefs, {
    required bool onboardingDone,
    required bool hasCompletedSetup,
    bool clearWidgetTransientState = false,
    bool clearLegacyConfig = false,
  }) async {
    await _persistProductsOnly(prefs);
    await _persistEntriesOnly(prefs);
    await prefs.setString(_keyAchievements, _encodeAchievements());
    await _persistReductionPlansOnly(prefs);
    await prefs.setString(_keyTheme, _themePreference.name);
    await prefs.setString(_keyLanguage, _languagePreference.name);
    await prefs.setString(_keyCurrency, _currency.name);
    await prefs.setBool(_keyOnboardingDone, onboardingDone);
    await prefs.setBool(_keyHasCompletedSetup, hasCompletedSetup);

    if (clearWidgetTransientState) {
      await _removePendingWidgetEntries(prefs);
      await prefs.remove(_keyWidgetSnapshot);
      await prefs.remove(_keyWidgetProductSnapshots);
    }

    if (clearLegacyConfig) {
      await prefs.remove(_keyConfigLegacy);
      await prefs.remove(_keyPackRemainingLegacy);
    }
  }

  static AppReminderSettings _decodeReminderSettings(String? raw) {
    if (raw == null || raw.trim().isEmpty) return AppReminderSettings.defaults;
    try {
      return AppReminderSettings.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return AppReminderSettings.defaults;
    }
  }

  void _hydrateFromPrefs(SharedPreferences prefs) {
    final productsJson = prefs.getString(_keyProducts);
    List<dynamic>? list;
    try {
      list = productsJson == null
          ? null
          : jsonDecode(productsJson) as List<dynamic>;
    } catch (_) {
      list = null;
    }
    _globalReminderSettings =
        list != null && !prefs.containsKey(_keyGlobalReminderSettings)
            ? AppReminderSettings.migrateFromLegacyProductMaps(list)
            : _decodeReminderSettings(
                prefs.getString(_keyGlobalReminderSettings),
              );
    if (list != null) {
      final parsedProducts = <TrackedProduct>[];
      for (final e in list) {
        try {
          parsedProducts
              .add(TrackedProduct.fromJson(e as Map<String, dynamic>));
        } catch (_) {}
      }
      _products = parsedProducts;
    } else {
      final legacy = prefs.getString(_keyConfigLegacy);
      final rem = prefs.getInt(_keyPackRemainingLegacy) ?? 0;
      if (legacy != null) {
        try {
          final tp = TrackedProduct.fromLegacyPackConfig(
            legacyJson: jsonDecode(legacy),
            packRemaining: rem,
          );
          _products = [tp];
        } catch (_) {
          _products = [];
        }
      } else {
        _products = [];
      }
    }

    _activeProductId = prefs.getString(_keyActiveProduct) ?? '';

    final entriesJson = prefs.getStringList(_keyEntries) ?? [];
    final parsedEntries = <SmokeEntry>[];
    for (final raw in entriesJson) {
      try {
        parsedEntries.add(
          SmokeEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {}
    }
    parsedEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _entries = parsedEntries;

    final themeStr = prefs.getString(_keyTheme);
    if (themeStr != null) _themePreference = _parseTheme(themeStr);
    _widgetDark = prefs.getString(_keyWidgetTheme) != 'light';
    _languagePreference =
        parseLanguagePreference(prefs.getString(_keyLanguage));
    _applyCurrency(parseCurrency(prefs.getString(_keyCurrency)));
    _lastBackupAt = DateTime.tryParse(prefs.getString(_keyLastBackup) ?? '');

    _achievements.clear();
    final achJson = prefs.getString(_keyAchievements);
    if (achJson != null) {
      try {
        final list = jsonDecode(achJson) as List<dynamic>;
        for (final item in list) {
          try {
            final a = Achievement.fromJson(item as Map<String, dynamic>);
            _achievements[a.id] = a;
          } catch (_) {}
        }
      } catch (_) {}
    }

    _activeProductId = _normalizeActiveProductId(_activeProductId);

    final loadedPlans = <ReductionPlan>[];
    final plansJson = prefs.getString(_keyReductionPlans);
    if (plansJson != null) {
      try {
        final decoded = (jsonDecode(plansJson) as Map).cast<String, dynamic>();
        for (final value in decoded.values) {
          try {
            loadedPlans.add(
              ReductionPlan.fromJson((value as Map).cast<String, dynamic>()),
            );
          } catch (_) {}
        }
      } catch (_) {}
    } else {
      final legacyJson = prefs.getString(_keyReductionPlanLegacy);
      if (legacyJson != null) {
        try {
          loadedPlans.add(
            ReductionPlan.fromJson(
              jsonDecode(legacyJson) as Map<String, dynamic>,
            ),
          );
        } catch (_) {}
      }
    }

    _reductionPlans
      ..clear()
      ..addAll(_normalizeReductionPlans(loadedPlans));
  }

  // --- Aggregazioni e persistenza ---

  int _countTodayForProduct(String productId) =>
      _countOnForProduct(productId, dateOnly(appNow()));

  int _countOnForProduct(String productId, DateTime day) => _entries
      .where((e) => e.productId == productId && dateOnly(e.timestamp) == day)
      .length;

  Set<DateTime> _distinctDays(List<SmokeEntry> entries) =>
      entries.map((e) => dateOnly(e.timestamp)).toSet();

  String _normalizeActiveProductId(String candidate) {
    if (_products.any(
      (product) => product.id == candidate && !product.isArchived,
    )) {
      return candidate;
    }
    if (activeProducts.isNotEmpty) {
      return activeProducts.first.id;
    }
    if (_products.isNotEmpty) {
      return _products.first.id;
    }
    return '';
  }

  bool _isActiveProductId(String productId) => _products.any(
        (product) => product.id == productId && !product.isArchived,
      );

  bool _isArchivedProductId(String productId) =>
      _products.any((product) => product.id == productId && product.isArchived);

  Future<void> _persistProductsOnly(SharedPreferences prefs) async {
    await prefs.setString(
      _keyProducts,
      jsonEncode(_products.map((p) => p.toJson()).toList()),
    );
    await _persistGlobalReminderOnly(prefs);
    await prefs.setString(_keyActiveProduct, _activeProductId);
  }

  Future<void> _persistProducts() async {
    await _persistProductsOnly(await SharedPreferences.getInstance());
    await syncWidgets();
    await _syncNotifications();
  }

  Future<void> _persist() async {
    await _persistEntriesOnly(await SharedPreferences.getInstance());
    await _persistProducts();
  }

  Future<void> _syncNotifications() async {
    await ProductNotificationService.syncAll(
      globalReminderSettings: _globalReminderSettings,
    );
  }
}
