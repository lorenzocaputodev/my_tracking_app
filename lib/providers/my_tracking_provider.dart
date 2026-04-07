import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/achievement.dart';
import '../models/app_reminder_settings.dart';
import '../models/pack_config.dart';
import '../models/reduction_plan.dart';
import '../models/smoke_entry.dart';
import '../models/tracked_product.dart';
import '../services/product_notification_service.dart';
import '../utils/app_backup_csv.dart';
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
  final String message;

  const HomeInsight({required this.type, required this.message});
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

// Provider

class MyTrackingProvider extends ChangeNotifier {
  // Chiavi storage

  static const _keyProducts = 'tracked_products_v1';
  static const _keyActiveProduct = 'active_product_id';
  static const _keyEntries = 'smoke_entries';
  static const _keyAchievements = 'achievements_v2';
  static const _keyReductionPlan = 'reduction_plan';
  static const _keyTheme = 'app_theme_preference';
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

  // Stato
  List<TrackedProduct> _products = [];
  String _activeProductId = '';
  List<SmokeEntry> _entries = [];
  bool _isLoading = true;

  final Map<AchievementId, Achievement> _achievements = {};
  ReductionPlan? _reductionPlan;
  AppThemePreference _themePreference = AppThemePreference.dark;
  AppReminderSettings _globalReminderSettings = AppReminderSettings.defaults;

  Timer? _ticker;

  MyTrackingProvider() {
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Getter prodotto attivo

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
  AppReminderSettings get globalReminderSettings => _globalReminderSettings;

  double get dailyCost =>
      todayEntries.fold(0.0, (sum, entry) => sum + entry.costDeducted);
  int get dailyMinutesLost =>
      todayEntries.fold(0, (sum, entry) => sum + entry.minutesLost);
  double get totalCost => _entries.fold(0.0, (sum, e) => sum + e.costDeducted);
  Duration get totalTimeLost =>
      Duration(minutes: _entries.fold(0, (sum, e) => sum + e.minutesLost));

  String get timeSinceLastEntry {
    final sorted = entriesForProduct(_activeProductId)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (sorted.isEmpty) return 'Mai';
    final diff = DateTime.now().difference(sorted.first.timestamp);
    if (diff.inDays > 0) return '${diff.inDays}g fa';
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m fa';
    }
    if (diff.inMinutes > 0) return '${diff.inMinutes}m fa';
    return 'Adesso';
  }

  List<SmokeEntry> get todayEntries {
    final now = DateTime.now();
    return _entries
        .where(
          (e) =>
              e.productId == _activeProductId &&
              e.timestamp.year == now.year &&
              e.timestamp.month == now.month &&
              e.timestamp.day == now.day,
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

  // Statistiche per prodotto

  double dailyAverageForProduct(String productId) {
    final list = entriesForProduct(productId);
    if (list.isEmpty) return 0;
    return list.length / _distinctDays(list).length;
  }

  double get dailyAverage => dailyAverageForProduct(_activeProductId);

  int? peakHourForProduct(String productId) {
    final list = entriesForProduct(productId);
    if (list.isEmpty) return null;
    final counts = List.filled(24, 0);
    for (final e in list) {
      counts[e.timestamp.toLocal().hour]++;
    }
    int maxVal = 0, maxIdx = 0;
    for (int i = 0; i < 24; i++) {
      if (counts[i] > maxVal) {
        maxVal = counts[i];
        maxIdx = i;
      }
    }
    return maxVal > 0 ? maxIdx : null;
  }

  MapEntry<DateTime, int>? worstDayForProduct(String productId) {
    final list = entriesForProduct(productId);
    if (list.isEmpty) return null;
    final counts = <DateTime, int>{};
    for (final e in list) {
      final t = e.timestamp.toLocal();
      final day = DateTime(t.year, t.month, t.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  List<MapEntry<DateTime, int>> dailyCountsLastDaysForProduct(
    String productId,
    int n,
  ) {
    final today = DateTime.now();
    final list = entriesForProduct(productId);
    return List.generate(n, (i) {
      final d = today.subtract(Duration(days: n - 1 - i));
      final day = DateTime(d.year, d.month, d.day);
      final count = list.where((e) {
        final t = e.timestamp.toLocal();
        return t.year == day.year && t.month == day.month && t.day == day.day;
      }).length;
      return MapEntry(day, count);
    });
  }

  int currentStreakForProduct(String productId) {
    final list = entriesForProduct(productId);
    if (list.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    DateTime day = DateTime(now.year, now.month, now.day);
    if (!_hasEntriesOnForProduct(productId, day)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (_hasEntriesOnForProduct(productId, day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime? _firstEntryDateForProduct(String productId) {
    final list = entriesForProduct(productId);
    if (list.isEmpty) return null;
    final sorted = [...list]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final t = sorted.first.timestamp.toLocal();
    return DateTime(t.year, t.month, t.day);
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
    final first = _firstEntryDateForProduct(productId);
    if (first == null) return 0;
    final limit = p.dailyLimit;
    int streak = 0;
    var day = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    while (true) {
      if (day.isBefore(first)) break;
      final c = _countOnForProduct(productId, day);
      if (c >= limit) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
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

  ReductionPlan? get reductionPlan => _reductionPlan;
  ReductionPlan? get activeProductReductionPlan =>
      reductionPlanForProduct(_activeProductId);

  int? get peakHour => peakHourForProduct(_activeProductId);
  MapEntry<DateTime, int>? get worstDay => worstDayForProduct(_activeProductId);
  List<MapEntry<DateTime, int>> dailyCountsLastDays(int n) =>
      dailyCountsLastDaysForProduct(_activeProductId, n);
  int get currentStreak => currentStreakForProduct(_activeProductId);
  int get underLimitStreak => underLimitStreakForProduct(_activeProductId);

  HomeInsight? get homeInsight {
    final progress = reductionProgressForProduct(_activeProductId);
    if (progress != null) {
      return HomeInsight(
        type: switch (progress.status) {
          ReductionPlanStatus.ahead => HomeInsightType.planAhead,
          ReductionPlanStatus.onTrack => HomeInsightType.planOnTrack,
          ReductionPlanStatus.behind => HomeInsightType.planBehind,
        },
        message: switch (progress.status) {
          ReductionPlanStatus.ahead => 'Piano: avanti',
          ReductionPlanStatus.onTrack => 'Piano: in linea',
          ReductionPlanStatus.behind => 'Piano: in ritardo',
        },
      );
    }

    if (!dailyLimitReached && activeProduct.dailyLimit > 0) {
      final remaining = remainingToday;
      if (remaining != null && remaining > 0) {
        return HomeInsight(
          type: HomeInsightType.limitRemaining,
          message: remaining == 1
              ? 'Manca 1 unità al limite'
              : 'Mancano $remaining unità al limite',
        );
      }
    }

    final yesterday = countOnDayForProduct(
      _activeProductId,
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (dailyCount == 0 && yesterday == 0) return null;

    final delta = dailyCount - yesterday;
    final message = switch (delta) {
      > 0 => '+$delta rispetto a ieri',
      < 0 => '$delta rispetto a ieri',
      _ => '= rispetto a ieri',
    };
    return HomeInsight(
      type: HomeInsightType.comparedToYesterday,
      message: message,
    );
  }

  Map<String, int> hourProductCounts(int hour) {
    final m = <String, int>{};
    for (final e in _entries) {
      if (e.timestamp.toLocal().hour != hour) continue;
      m[e.productId] = (m[e.productId] ?? 0) + 1;
    }
    return m;
  }

  String? productNameById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id).name;
    } catch (_) {
      return null;
    }
  }

  // Init

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _hydrateFromPrefs(prefs);
    final mergedPending = await _consumePendingWidgetEntries(prefs);
    final migratedPlan = await _migrateLegacyReductionPlanIfNeeded(prefs);
    final migratedGlobalReminder =
        await _migrateLegacyGlobalReminderIfNeeded(prefs);

    try {
      _evaluateAchievements(persist: mergedPending);
    } catch (_) {}

    _activeProductId = _normalizeActiveProductId(_activeProductId);

    if (mergedPending) {
      await _persistEntriesOnly(prefs);
    }
    if (migratedPlan) {
      await _persistReductionPlanOnly(prefs);
    }
    if (migratedGlobalReminder) {
      await _persistGlobalReminderOnly(prefs);
    }

    _isLoading = false;
    notifyListeners();
    await syncWidgets();
    await _syncNotifications();
  }

  static AppThemePreference _parseTheme(String name) {
    for (final v in AppThemePreference.values) {
      if (v.name == name) return v;
    }
    return AppThemePreference.dark;
  }

  Future<void> drainOnResume() async {
    if (_isLoading) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _hydrateFromPrefs(prefs);
    final mergedPending = await _consumePendingWidgetEntries(prefs);
    final migratedPlan = await _migrateLegacyReductionPlanIfNeeded(prefs);
    final migratedGlobalReminder =
        await _migrateLegacyGlobalReminderIfNeeded(prefs);
    if (mergedPending) {
      _evaluateAchievements();
      await _persistEntriesOnly(prefs);
    }
    if (migratedPlan) {
      await _persistReductionPlanOnly(prefs);
    }
    if (migratedGlobalReminder) {
      await _persistGlobalReminderOnly(prefs);
    }
    notifyListeners();
    await syncWidgets();
    await _syncNotifications();
  }

  // Tema

  Future<void> setThemePreference(AppThemePreference value) async {
    _themePreference = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, value.name);
  }

  // Prodotti

  Future<void> setActiveProduct(String id) async {
    if (!_products.any((p) => p.id == id && !p.isArchived)) return;
    _activeProductId = id;
    notifyListeners();
    await _persistActiveProductSelection();
    await syncWidgets();
  }

  Future<void> addProduct(TrackedProduct product) async {
    _products = [..._products, product];
    _activeProductId = product.id;
    notifyListeners();
    await _persistProducts();
  }

  Future<void> updateGlobalReminderSettings(
      AppReminderSettings settings) async {
    _globalReminderSettings = settings;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await _persistGlobalReminderOnly(prefs);
    await _syncNotifications();
  }

  Future<void> updateActiveProductConfig(PackConfig cfg) async {
    final idx = _products.indexWhere((p) => p.id == _activeProductId);
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
  }

  Future<void> correctActiveProductPackRemaining(int packRemaining) async {
    final idx = _products.indexWhere((p) => p.id == _activeProductId);
    if (idx == -1) {
      throw StateError('Nessun prodotto attivo disponibile.');
    }

    final product = _products[idx];
    if (!product.tracksInventory) {
      throw StateError('La correzione della scorta non è disponibile.');
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
  }

  Future<bool> archiveProduct(String id) async {
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
  }

  Future<void> restoreProduct(String id) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final product = _products[idx];
    if (!product.isArchived) return;

    _products = List<TrackedProduct>.from(_products)
      ..[idx] = product.copyWith(isArchived: false);

    if (_activeProductId.isEmpty || _isArchivedProductId(_activeProductId)) {
      _activeProductId = id;
    }

    notifyListeners();
    await _persistProducts();
  }

  Future<void> deleteArchivedProduct(String id) async {
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

    if (_reductionPlan?.productId == id) {
      _reductionPlan = null;
    }

    await _persist();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) => deleteArchivedProduct(id);

  // Voci cronologia

  Future<void> logEntry({String? productId}) async {
    final pid = productId ?? _activeProductId;
    final pIdx = _products.indexWhere((p) => p.id == pid);
    if (pIdx == -1) return;
    final p = _products[pIdx];
    if (p.isArchived) return;
    if (p.tracksInventory && p.packRemaining <= 0) return;

    final entry = SmokeEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      costDeducted: p.unitCost,
      minutesLost: p.minutesLost,
      productId: pid,
    );
    _entries.add(entry);
    if (p.tracksInventory) {
      _products[pIdx] = p.copyWith(packRemaining: p.packRemaining - 1);
    }
    _evaluateAchievements();
    notifyListeners();
    await _persist();
  }

  Future<void> openNewPack() async {
    final idx = _products.indexWhere((p) => p.id == _activeProductId);
    if (idx == -1) return;
    final p = _products[idx];
    if (p.isArchived || !p.tracksInventory) return;
    _products = List<TrackedProduct>.from(_products)
      ..[idx] = p.copyWith(packRemaining: p.pieces);
    notifyListeners();
    await _persistProducts();
  }

  Future<void> deleteEntry(String id) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final entry = _entries[idx];
    final pIdx = _products.indexWhere((p) => p.id == entry.productId);
    if (pIdx != -1) {
      final pr = _products[pIdx];
      if (pr.tracksInventory && pr.packRemaining < pr.pieces) {
        _products = List<TrackedProduct>.from(_products)
          ..[pIdx] = pr.copyWith(packRemaining: pr.packRemaining + 1);
      }
    }
    _entries.removeAt(idx);
    _evaluateAchievements();
    notifyListeners();
    await _persist();
  }

  Future<void> undoLast() async {
    if (todayEntries.isEmpty) return;
    await deleteEntry(todayEntries.first.id);
  }

  Future<void> clearHistory() async {
    _entries.clear();
    _products = _products.map((p) => p.copyWith(packRemaining: 0)).toList();
    notifyListeners();
    await _persist();
  }

  // Piano di riduzione

  Future<void> setReductionPlan({
    String? productId,
    required double targetPerDay,
    required int totalWeeks,
  }) async {
    final boundProductId = productId ?? _activeProductId;
    if (boundProductId.isEmpty ||
        !_products.any((p) => p.id == boundProductId)) {
      return;
    }
    _reductionPlan = ReductionPlan(
      productId: boundProductId,
      startAverage: dailyAverageForProduct(boundProductId) > 0
          ? dailyAverageForProduct(boundProductId)
          : 1.0,
      targetPerDay: targetPerDay,
      totalWeeks: totalWeeks,
      startDate: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyReductionPlan,
      jsonEncode(_reductionPlan!.toJson()),
    );
    notifyListeners();
  }

  Future<void> deleteReductionPlan() async {
    _reductionPlan = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReductionPlan);
    notifyListeners();
  }

  // Achievement

  void _evaluateAchievements({bool persist = true}) {
    bool changed = false;

    void tryUnlock(AchievementId id) {
      if (!(_achievements[id]?.isUnlocked ?? false)) {
        _achievements[id] = Achievement.definition(id).unlock();
        changed = true;
      }
    }

    if (_entries.isNotEmpty) tryUnlock(AchievementId.firstEntry);

    final distinctDayCount = _distinctDays(_entries).length;
    if (distinctDayCount >= 7) tryUnlock(AchievementId.tracked7days);
    if (distinctDayCount >= 30) tryUnlock(AchievementId.tracked30days);

    final streak = currentStreakForProduct(_activeProductId);
    if (streak >= 3) tryUnlock(AchievementId.streak3);
    if (streak >= 7) tryUnlock(AchievementId.streak7);
    if (streak >= 14) tryUnlock(AchievementId.streak14);
    if (streak >= 30) tryUnlock(AchievementId.streak30);

    final lim = activeProduct.dailyLimit;
    if (lim > 0) {
      final ul = underLimitStreakForProduct(_activeProductId);
      if (ul >= 1) tryUnlock(AchievementId.underLimit1);
      if (ul >= 3) tryUnlock(AchievementId.underLimit3);
      if (ul >= 7) tryUnlock(AchievementId.underLimit7);
      if (ul >= 30) tryUnlock(AchievementId.underLimit30);
    }

    final plan = _reductionPlan;
    if (plan != null &&
        plan.productId.isNotEmpty &&
        plan.startAverage > 0 &&
        _products.any(
          (product) => product.id == plan.productId && !product.isArchived,
        )) {
      final currentAverage = dailyAverageForProduct(plan.productId);
      final reduction =
          (plan.startAverage - currentAverage) / plan.startAverage;
      if (reduction >= 0.10) tryUnlock(AchievementId.reduction10pct);
      if (reduction >= 0.25) tryUnlock(AchievementId.reduction25pct);
      if (reduction >= 0.50) tryUnlock(AchievementId.reduction50pct);
    }

    if (changed && persist) _persistAchievements();
  }

  Future<void> _persistAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _achievements.values.map((a) => a.toJson()).toList();
    await prefs.setString(_keyAchievements, jsonEncode(list));
  }

  ReductionPlan? reductionPlanForProduct(String productId) {
    final plan = _reductionPlan;
    if (plan == null ||
        plan.productId != productId ||
        _isArchivedProductId(productId)) {
      return null;
    }
    return plan;
  }

  ReductionPlanProgress? reductionProgressForProduct(String productId) {
    final plan = reductionPlanForProduct(productId);
    if (plan == null) return null;
    final recentAverage = averageDailyCountForRange(
      productId: productId,
      start: DateTime.now().subtract(const Duration(days: 6)),
      end: DateTime.now(),
    );
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
    final startDay = start != null ? _dateOnly(start) : null;
    final endDay = end != null ? _dateOnly(end) : null;
    final visibleProductIds =
        activeProducts.map((product) => product.id).toSet();

    return _entries.where((entry) {
      if (productId != null) {
        if (entry.productId != productId) return false;
      } else if (!visibleProductIds.contains(entry.productId)) {
        return false;
      }
      final entryDay = _dateOnly(entry.timestamp);
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
    final startDay = _dateOnly(start);
    final endDay = _dateOnly(end);
    final dayCount = endDay.difference(startDay).inDays + 1;
    if (dayCount <= 0) return 0;
    return entriesForRange(
          productId: productId,
          start: startDay,
          end: endDay,
        ).length /
        dayCount;
  }

  int countOnDayForProduct(String productId, DateTime day) {
    return _countOnForProduct(productId, _dateOnly(day));
  }

  int countOnDay(DateTime day, {String? productId}) {
    return entriesForRange(productId: productId, start: day, end: day).length;
  }

  WeeklyTrend weeklyTrend({String? productId}) {
    final now = DateTime.now();
    final currentAverage = averageDailyCountForRange(
      productId: productId,
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
    final previousAverage = averageDailyCountForRange(
      productId: productId,
      start: now.subtract(const Duration(days: 13)),
      end: now.subtract(const Duration(days: 7)),
    );
    return WeeklyTrend(
      currentAverage: currentAverage,
      previousAverage: previousAverage,
    );
  }

  double projectedMonthlyCost({String? productId}) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final entries = entriesForRange(
      productId: productId,
      start: monthStart,
      end: now,
    );
    final elapsedDays = now.day;
    if (elapsedDays <= 0 || entries.isEmpty) return 0;
    final costSoFar = entries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.costDeducted,
    );
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return (costSoFar / elapsedDays) * daysInMonth;
  }

  int projectedMonthlyUnits({String? productId}) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final entries = entriesForRange(
      productId: productId,
      start: monthStart,
      end: now,
    );
    final elapsedDays = now.day;
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
    if (entries.isEmpty) return null;
    final counts = <DateTime, int>{};
    for (final entry in entries) {
      final day = _dateOnly(entry.timestamp);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  MapEntry<DateTime, int>? bestDayForEntries(List<SmokeEntry> entries) {
    if (entries.isEmpty) return null;
    final counts = <DateTime, int>{};
    for (final entry in entries) {
      final day = _dateOnly(entry.timestamp);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value <= b.value ? a : b);
  }

  List<int> hourDistributionForEntries(List<SmokeEntry> entries) {
    final counts = List<int>.filled(24, 0);
    for (final entry in entries) {
      counts[entry.timestamp.toLocal().hour]++;
    }
    return counts;
  }

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  ReductionPlan? _normalizeReductionPlan(ReductionPlan? plan) {
    if (plan == null) return null;
    if (_products.isEmpty) return null;
    if (plan.productId.isEmpty) {
      final fallbackId = _normalizeActiveProductId(_activeProductId);
      return plan.copyWith(productId: fallbackId);
    }
    if (_products.any((product) => product.id == plan.productId)) {
      return plan;
    }
    return plan.copyWith(
      productId: _normalizeActiveProductId(_activeProductId),
    );
  }

  Future<bool> _migrateLegacyReductionPlanIfNeeded(SharedPreferences _) async {
    final normalized = _normalizeReductionPlan(_reductionPlan);
    if (normalized == null || _reductionPlan == null) {
      return false;
    }
    if (normalized.productId == _reductionPlan!.productId) {
      return false;
    }
    _reductionPlan = normalized;
    return true;
  }

  Future<bool> _migrateLegacyGlobalReminderIfNeeded(
    SharedPreferences prefs,
  ) async {
    return !prefs.containsKey(_keyGlobalReminderSettings);
  }

  Future<void> _persistReductionPlanOnly(SharedPreferences prefs) async {
    if (_reductionPlan == null) {
      await prefs.remove(_keyReductionPlan);
      return;
    }
    await prefs.setString(
      _keyReductionPlan,
      jsonEncode(_reductionPlan!.toJson()),
    );
  }

  Future<void> _persistGlobalReminderOnly(SharedPreferences prefs) async {
    await prefs.setString(
      _keyGlobalReminderSettings,
      jsonEncode(_globalReminderSettings.toJson()),
    );
    await prefs.remove(_keyGlobalDailySummarySettingsLegacy);
  }

  // Export e import

  Future<String> exportFullBackupCsv() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final data = AppBackupData(
      backupVersion: AppBackupCsv.backupVersion,
      exportedAt: DateTime.now().toUtc(),
      activeProductId: _normalizeActiveProductId(_activeProductId),
      themePreferenceName: _themePreference.name,
      onboardingDone: prefs.getBool(_keyOnboardingDone) ?? false,
      hasCompletedSetup: prefs.getBool(_keyHasCompletedSetup) ?? false,
      globalReminderSettings: _globalReminderSettings,
      products: List<TrackedProduct>.from(_products),
      entries: List<SmokeEntry>.from(_entries)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
      achievements: List<Achievement>.from(allAchievements),
      reductionPlan: _reductionPlan,
    );

    return AppBackupCsv.encode(data);
  }

  Future<void> importFullBackupCsv(String csv) async {
    final data = AppBackupCsv.decode(csv);
    await _restoreFullBackup(data);
  }

  Future<void> _restoreFullBackup(AppBackupData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    _products = List<TrackedProduct>.from(data.products);
    _entries = List<SmokeEntry>.from(data.entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _activeProductId = _normalizeActiveProductId(data.activeProductId);
    _globalReminderSettings = data.globalReminderSettings;
    _achievements
      ..clear()
      ..addEntries(data.achievements.map((a) => MapEntry(a.id, a)));
    _reductionPlan = _normalizeReductionPlan(data.reductionPlan);
    _themePreference = _parseTheme(data.themePreferenceName);

    final onboardingDone =
        data.onboardingDone || _products.isNotEmpty || _entries.isNotEmpty;
    final hasCompletedSetup = data.hasCompletedSetup || _products.isNotEmpty;

    await _persistCompleteState(
      prefs,
      onboardingDone: onboardingDone,
      hasCompletedSetup: hasCompletedSetup,
      clearWidgetTransientState: true,
      clearLegacyConfig: true,
    );

    notifyListeners();
    await syncWidgets();
    await _syncNotifications();
  }

  Future<void> syncWidgets() async {
    await _persistWidgetSnapshots();
    await WidgetBridge.updateWidgets();
  }

  Future<void> _persistWidgetSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
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
      final productDailyCount = _countTodayForProduct(product.id);
      productSnapshots[product.id] = <String, dynamic>{
        'activeProductId': product.id,
        'name': product.name,
        'tracksInventory': product.tracksInventory,
        'pieces': product.pieces,
        'packRemaining': product.packRemaining,
        'minutesLostPerUnit': product.minutesLost,
        'unitCost': product.unitCost,
        'dailyCount': productDailyCount,
        'dailyCost': productDailyCount * product.unitCost,
        'dailyMinutesLost': productDailyCount * product.minutesLost,
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

  Future<bool> _consumePendingWidgetEntries(SharedPreferences prefs) async {
    final raw = prefs.getString(_keyWidgetPendingEntries);
    if (raw == null || raw.trim().isEmpty) return false;

    List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      await prefs.setString(_keyWidgetPendingEntries, '[]');
      return true;
    }

    final existingIds = _entries.map((entry) => entry.id).toSet();
    var changed = false;
    for (final item in decoded) {
      try {
        final map = (item as Map).cast<String, dynamic>();
        final entry = SmokeEntry.fromJson(map);
        if (existingIds.add(entry.id)) {
          _entries.add(entry);
          changed = true;
        }
      } catch (_) {}
    }

    if (changed) {
      _entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    await prefs.setString(_keyWidgetPendingEntries, '[]');
    return changed || decoded.isNotEmpty;
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
    await prefs.setString(
      _keyProducts,
      jsonEncode(_products.map((product) => product.toJson()).toList()),
    );
    await prefs.setString(
      _keyGlobalReminderSettings,
      jsonEncode(_globalReminderSettings.toJson()),
    );
    await prefs.remove(_keyGlobalDailySummarySettingsLegacy);
    await prefs.setString(_keyActiveProduct, _activeProductId);
    await prefs.setStringList(
      _keyEntries,
      _entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    await prefs.setString(
      _keyAchievements,
      jsonEncode(_achievements.values.map((a) => a.toJson()).toList()),
    );
    if (_reductionPlan != null) {
      await prefs.setString(
        _keyReductionPlan,
        jsonEncode(_reductionPlan!.toJson()),
      );
    } else {
      await prefs.remove(_keyReductionPlan);
    }
    await prefs.setString(_keyTheme, _themePreference.name);
    await prefs.setBool(_keyOnboardingDone, onboardingDone);
    await prefs.setBool(_keyHasCompletedSetup, hasCompletedSetup);

    if (clearWidgetTransientState) {
      await prefs.remove(_keyWidgetPendingEntries);
      await prefs.remove(_keyWidgetSnapshot);
      await prefs.remove(_keyWidgetProductSnapshots);
    }

    if (clearLegacyConfig) {
      await prefs.remove(_keyConfigLegacy);
      await prefs.remove(_keyPackRemainingLegacy);
    }
  }

  void _hydrateFromPrefs(SharedPreferences prefs) {
    final productsJson = prefs.getString(_keyProducts);
    if (productsJson != null) {
      final list = jsonDecode(productsJson) as List<dynamic>;
      if (prefs.containsKey(_keyGlobalReminderSettings)) {
        final rawGlobalReminder = prefs.getString(_keyGlobalReminderSettings);
        if (rawGlobalReminder != null && rawGlobalReminder.trim().isNotEmpty) {
          try {
            _globalReminderSettings = AppReminderSettings.fromJson(
              (jsonDecode(rawGlobalReminder) as Map).cast<String, dynamic>(),
            );
          } catch (_) {
            _globalReminderSettings = AppReminderSettings.defaults;
          }
        } else {
          _globalReminderSettings = AppReminderSettings.defaults;
        }
      } else {
        _globalReminderSettings =
            AppReminderSettings.migrateFromLegacyProductMaps(list);
      }
      _products = list
          .map((e) => TrackedProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final legacy = prefs.getString(_keyConfigLegacy);
      final rem = prefs.getInt(_keyPackRemainingLegacy) ?? 0;
      final rawGlobalReminder = prefs.getString(_keyGlobalReminderSettings);
      if (rawGlobalReminder != null && rawGlobalReminder.trim().isNotEmpty) {
        try {
          _globalReminderSettings = AppReminderSettings.fromJson(
            (jsonDecode(rawGlobalReminder) as Map).cast<String, dynamic>(),
          );
        } catch (_) {
          _globalReminderSettings = AppReminderSettings.defaults;
        }
      } else {
        _globalReminderSettings = AppReminderSettings.defaults;
      }
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

    _activeProductId = prefs.getString(_keyActiveProduct) ??
        (activeProducts.isNotEmpty
            ? activeProducts.first.id
            : (_products.isNotEmpty ? _products.first.id : ''));

    final entriesJson = prefs.getStringList(_keyEntries) ?? [];
    _entries = entriesJson
        .map((s) => SmokeEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .where(
          (e) => e.timestamp.isAfter(
            DateTime.now().subtract(const Duration(days: 365)),
          ),
        )
        .toList();

    final themeStr = prefs.getString(_keyTheme);
    if (themeStr != null) _themePreference = _parseTheme(themeStr);

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

    _reductionPlan = null;
    final planJson = prefs.getString(_keyReductionPlan);
    if (planJson != null) {
      try {
        _reductionPlan = _normalizeReductionPlan(
          ReductionPlan.fromJson(jsonDecode(planJson) as Map<String, dynamic>),
        );
      } catch (_) {}
    }

    _activeProductId = _normalizeActiveProductId(_activeProductId);
  }

  // Aggregazioni e persistenza

  int _countTodayForProduct(String productId) {
    final now = DateTime.now();
    return _entries.where((e) {
      if (e.productId != productId) return false;
      final t = e.timestamp.toLocal();
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).length;
  }

  int _countOnForProduct(String productId, DateTime day) {
    return _entries.where((e) {
      if (e.productId != productId) return false;
      final t = e.timestamp.toLocal();
      return t.year == day.year && t.month == day.month && t.day == day.day;
    }).length;
  }

  bool _hasEntriesOnForProduct(String productId, DateTime day) =>
      _entries.any((e) {
        if (e.productId != productId) return false;
        final t = e.timestamp.toLocal();
        return t.year == day.year && t.month == day.month && t.day == day.day;
      });

  Set<DateTime> _distinctDays(List<SmokeEntry> entries) {
    final days = <DateTime>{};
    for (final e in entries) {
      final t = e.timestamp.toLocal();
      days.add(DateTime(t.year, t.month, t.day));
    }
    return days;
  }

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

  Future<void> _persistProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyProducts,
      jsonEncode(_products.map((p) => p.toJson()).toList()),
    );
    await _persistGlobalReminderOnly(prefs);
    await prefs.setString(_keyActiveProduct, _activeProductId);
    await _persistWidgetSnapshots();
    await WidgetBridge.updateWidgets();
    await _syncNotifications();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyEntries,
      _entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _persistProducts();
  }

  Future<void> _syncNotifications() async {
    await ProductNotificationService.syncAll(
      globalReminderSettings: _globalReminderSettings,
    );
  }
}
