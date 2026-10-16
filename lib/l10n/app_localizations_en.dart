// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loading => 'Loading...';

  @override
  String get bootstrapErrorTitle => 'Startup failed';

  @override
  String get bootstrapErrorBody =>
      'Something went wrong while loading the app. You can try again without closing it.';

  @override
  String get retry => 'Try again';

  @override
  String get backupErrorEmpty => 'The CSV backup is empty.';

  @override
  String get backupErrorUnknownFormat => 'Unrecognized CSV backup format.';

  @override
  String get backupErrorMissingVersion => 'Missing backup version.';

  @override
  String backupErrorInvalidSection(int line) {
    return 'Invalid backup section at line $line.';
  }

  @override
  String backupErrorMissingHeader(String section) {
    return 'Missing header for section \"$section\".';
  }

  @override
  String backupErrorMissingProduct(String id) {
    return 'The history refers to a missing product: $id.';
  }

  @override
  String get backupErrorMissingMeta => 'The backup has no meta section.';

  @override
  String get backupErrorInvalidMetaHeader => 'Invalid meta header.';

  @override
  String get backupErrorMissingProducts =>
      'The backup has no products section.';

  @override
  String get backupErrorIncompleteProduct => 'Incomplete product row.';

  @override
  String get backupErrorMissingHistory => 'The backup has no history section.';

  @override
  String get backupErrorIncompleteEntry => 'Incomplete history row.';

  @override
  String get backupErrorIncompleteAchievement => 'Incomplete achievement row.';

  @override
  String get backupErrorIncompletePlan => 'Incomplete reduction plan row.';

  @override
  String backupErrorInvalidValue(String value) {
    return 'Invalid value in the backup: \"$value\".';
  }

  @override
  String backupErrorInvalidHeader(String section) {
    return 'Invalid $section header.';
  }

  @override
  String get backupSectionProducts => 'products';

  @override
  String get backupSectionHistory => 'history';

  @override
  String get backupSectionAchievements => 'achievements';

  @override
  String get backupSectionPlan => 'reduction plan';

  @override
  String get backupSectionReminder => 'global reminder';

  @override
  String backupErrorEntriesNotSaved(int stored, int total) {
    return 'Saved $stored of $total entries. The data was not restored: try again.';
  }

  @override
  String backupErrorProductsNotSaved(int stored, int total) {
    return 'Saved $stored of $total products. The data was not restored: try again.';
  }

  @override
  String get errorProductNotFound => 'Product not found.';

  @override
  String get errorStockCorrectionUnavailable =>
      'Stock adjustment is not available.';

  @override
  String get achFirstEntryTitle => 'First entry';

  @override
  String get achFirstEntryDesc => 'You logged your first unit.';

  @override
  String get achTracked7Title => '7 days of data';

  @override
  String get achTracked7Desc => 'Activity logged on 7 different days.';

  @override
  String get achTracked30Title => '30 days of data';

  @override
  String get achTracked30Desc => 'Activity logged on 30 different days.';

  @override
  String get achStreak3Title => '3 days in a row';

  @override
  String get achStreak3Desc => 'Active for 3 consecutive days.';

  @override
  String get achStreak7Title => 'Full week';

  @override
  String get achStreak7Desc => 'Active for 7 consecutive days.';

  @override
  String get achStreak14Title => 'Two weeks';

  @override
  String get achStreak14Desc => 'Active for 14 consecutive days.';

  @override
  String get achStreak30Title => 'Full month';

  @override
  String get achStreak30Desc => 'Active for 30 consecutive days.';

  @override
  String get achUnderLimit1Title => 'First day on target';

  @override
  String get achUnderLimit1Desc => '1 day under the daily limit.';

  @override
  String get achUnderLimit3Title => 'Three days on target';

  @override
  String get achUnderLimit3Desc => '3 consecutive days under the limit.';

  @override
  String get achUnderLimit7Title => 'Week on target';

  @override
  String get achUnderLimit7Desc => '7 consecutive days under the limit.';

  @override
  String get achUnderLimit30Title => 'Month under control';

  @override
  String get achUnderLimit30Desc => '30 consecutive days under the limit.';

  @override
  String get achReduction10Title => '-10% average';

  @override
  String get achReduction10Desc =>
      'Average down 10% from the start of the plan.';

  @override
  String get achReduction25Title => '-25% average';

  @override
  String get achReduction25Desc =>
      'Average down 25% from the start of the plan.';

  @override
  String get achReduction50Title => '-50% average';

  @override
  String get achReduction50Desc => 'You halved your average. Outstanding!';

  @override
  String get reminderChannelName => 'Logging reminders';

  @override
  String get reminderChannelDescription =>
      'General reminders to log your tracked products.';

  @override
  String get reminderNotificationTitle => 'Reminder';

  @override
  String get reminderNotificationBody =>
      'Remember to log your tracked products.';

  @override
  String productAddedInUse(String name) {
    return '$name added and in use';
  }

  @override
  String get backupFilesUnsupported =>
      'File import/export is only available on Android and Windows.';

  @override
  String get fileSaveUnsupported =>
      'Saving files is not supported on this platform.';

  @override
  String get backupSaved => 'CSV backup saved';

  @override
  String get backupExportFailed => 'CSV export failed.';

  @override
  String get browserOpenFailed => 'Unable to open the browser.';

  @override
  String get clearHistoryTitle => 'Delete everything?';

  @override
  String get clearHistoryBody =>
      'This permanently deletes all the history logged so far.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String stockCount(int remaining, int total) {
    return '$remaining/$total in stock';
  }

  @override
  String get noStock => 'No stock tracking';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProducts => 'PRODUCTS';

  @override
  String get addProduct => 'Add product';

  @override
  String archivedCount(int count) {
    return 'Archived ($count)  ›';
  }

  @override
  String get settingsSectionApp => 'APP';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get system => 'System';

  @override
  String get language => 'Language';

  @override
  String get widgetTheme => 'Widget theme';

  @override
  String get settingsSectionData => 'DATA';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get exportBackupSubtitle => 'Save a CSV file with all your data';

  @override
  String get importBackup => 'Import backup';

  @override
  String get importBackupSubtitle => 'Replaces your current data';

  @override
  String get settingsSectionAbout => 'ABOUT';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String installedVersion(String version) {
    return 'Installed version $version · opens GitHub';
  }

  @override
  String get opensReleasesPage => 'Opens the releases page on GitHub';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get widgetHint =>
      'Long-press your phone\'s home screen to add the widget.';

  @override
  String get inUseBadge => 'IN USE';

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get notificationPermissionDenied =>
      'Notification permission not granted.';

  @override
  String get remindMeEvery => 'Remind me every';

  @override
  String get reminders => 'Reminders';

  @override
  String get remindersSubtitle => 'Reminds you to log';

  @override
  String get androidOnly => 'Only available on Android';

  @override
  String get frequency => 'Frequency';

  @override
  String every(String interval) {
    return 'Every $interval';
  }

  @override
  String get fileImportUnsupported =>
      'Importing files is not supported on this platform.';

  @override
  String restoreCompleted(String summary) {
    return 'Restore complete: $summary.';
  }

  @override
  String restoreCompletedRemindersOff(String summary) {
    return 'Restore complete: $summary. Reminders turned off: notification permission not granted.';
  }

  @override
  String get backupInvalid => 'Invalid CSV backup';

  @override
  String get backupImportFailed => 'CSV import failed.';

  @override
  String get emptyBackupTitle => 'Backup with no history';

  @override
  String get emptyBackupBody =>
      'This file contains no entries. Importing it replaces your current data and leaves the history empty.';

  @override
  String get importAnyway => 'Import anyway';

  @override
  String restoreSummary(String entries, String products) {
    return '$entries and $products';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String productsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String productRestored(String name) {
    return '$name restored';
  }

  @override
  String get deletePermanentlyTitle => 'Delete permanently?';

  @override
  String deletePermanentlyBody(String name) {
    return 'This removes $name and all its history.';
  }

  @override
  String productDeleted(String name) {
    return '$name permanently deleted';
  }

  @override
  String get archivedTitle => 'Archived';

  @override
  String get archivedIntro =>
      'Archived products don\'t appear on the home screen, but their history is kept. Restoring them brings them back as they were.';

  @override
  String get noArchivedProducts => 'No archived products';

  @override
  String get historyKept => 'History kept';

  @override
  String get restore => 'Restore';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get newProduct => 'New product';

  @override
  String get setupTitle => 'Set up your product';

  @override
  String get startTracking => 'Start tracking';

  @override
  String get haveBackup => 'I already have a backup';

  @override
  String get haveBackupSubtitle => 'Restore your data from a CSV file';

  @override
  String get setupQuestion => 'What do you want to track?';

  @override
  String get setupSubtitle =>
      'You can change everything in Settings at any time.';

  @override
  String get remindersSection => 'REMINDERS';

  @override
  String get onboardingWelcomeTitle => 'Welcome to\nMy Tracking App';

  @override
  String get onboardingWelcomeBody =>
      'Keep an eye on how much you use, how much you spend and how your habits change. All your data stays on your phone.';

  @override
  String get onboardingTrackTitle => 'Keep track\nof everything';

  @override
  String get onboardingTrackBody =>
      'You can follow several products at once. Each one has its own history, costs and goal.';

  @override
  String get onboardingCustomizeTitle => 'Customize\nyour product';

  @override
  String get onboardingCustomizeBody =>
      'Enter the name, cost and pack size, and a daily limit if you want one: the app works out the cost of each use.';

  @override
  String get onboardingTimeTitle => 'How much time\ndoes it cost you?';

  @override
  String get onboardingTimeBody =>
      'You can add an estimate of the minutes of life lost per use: it\'s a symbolic value, not the time it takes to use it. If you don\'t need it, choose “No estimate”.';

  @override
  String get onboardingTapTitle => 'One tap\nto log';

  @override
  String get onboardingTapBody =>
      'Tap I USED IT every time, or log everything at the end of the day. If you tap by mistake you can undo right away, and on Android there\'s also a widget.';

  @override
  String get onboardingProgressTitle => 'Watch\nyour progress';

  @override
  String get onboardingProgressBody =>
      'History by day, week and month, achievements and a reduction plan. With backups you never lose anything.';

  @override
  String get skip => 'Skip';

  @override
  String get start => 'Get started';

  @override
  String get next => 'Next';

  @override
  String get historyTitle => 'History';

  @override
  String get achievementsTooltip => 'Achievements and badges';

  @override
  String get today => 'Today';

  @override
  String get lifeLostToday => 'Life lost today';

  @override
  String get totalSpent => 'Total spent';

  @override
  String lastEntry(String time) {
    return 'LAST: $time';
  }

  @override
  String get logButton => 'I USED IT';

  @override
  String loggedToday(int count) {
    return 'Logged · $count today';
  }

  @override
  String get undo => 'Undo';

  @override
  String get creatorMessage => 'App created by Lorenzo Caputo, with love <3';

  @override
  String stockFinished(String name) {
    return '📦 Out of $name!';
  }

  @override
  String overLimit(int count, int limit) {
    return 'Over your limit ($count/$limit)';
  }

  @override
  String dailyLimitReached(int count, int limit) {
    return 'Daily limit reached ($count/$limit)';
  }

  @override
  String get newStockButton => 'NEW\nPACK';

  @override
  String get productInUse => 'Product in use';

  @override
  String get todayCaps => 'TODAY';

  @override
  String get unitCost => 'Unit cost';

  @override
  String get costPerUse => 'Cost per use';

  @override
  String labelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get never => 'Never';

  @override
  String get justNow => 'Just now';

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String hoursMinutesAgo(int hours, int minutes) {
    return '${hours}h ${minutes}m ago';
  }

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get insightPlanAhead => 'Plan: ahead';

  @override
  String get insightPlanOnTrack => 'Plan: on track';

  @override
  String get insightPlanBehind => 'Plan: behind';

  @override
  String insightLimitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units left before the limit',
      one: '1 unit left before the limit',
    );
    return '$_temp0';
  }

  @override
  String insightComparedToYesterday(String delta) {
    return '$delta compared to yesterday';
  }

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody => 'Unsaved changes will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String productInUseFeedback(String name) {
    return '$name in use';
  }

  @override
  String get keepOneActiveProduct =>
      'You need to keep at least one active product';

  @override
  String productArchived(String name) {
    return '$name archived';
  }

  @override
  String get moreActions => 'More actions';

  @override
  String get useThisProduct => 'Use this product';

  @override
  String get useThisProductSubtitle =>
      'Becomes the one you log from the home screen';

  @override
  String get archive => 'Archive';

  @override
  String get archiveSubtitle => 'Hidden from the home screen; history is kept';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get save => 'Save';

  @override
  String get newPackTitle => 'New pack?';

  @override
  String newPackBody(String name, int pieces) {
    return '$name stock goes back to $pieces/$pieces.';
  }

  @override
  String get restock => 'Restock';

  @override
  String get stockRestocked => 'Stock refilled';

  @override
  String get correctStockTitle => 'Adjust stock';

  @override
  String get correctStockBody =>
      'Enter the actual number of units left to update the current stock.';

  @override
  String get unitsLeft => 'Units left';

  @override
  String get enterWholeNumber => 'Enter a whole number.';

  @override
  String get enterValidWholeNumber => 'Enter a valid whole number.';

  @override
  String get valueNotNegative => 'The value can\'t be negative.';

  @override
  String valueAtMost(int max) {
    return 'The value can\'t be more than $max.';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get correctStockFailed => 'Stock adjustment failed.';

  @override
  String get stock => 'Stock';

  @override
  String get correct => 'Adjust';

  @override
  String get productNameLabel => 'PRODUCT NAME';

  @override
  String get productNameHint => 'E.g. Cigarettes';

  @override
  String get enterName => 'Enter a name';

  @override
  String get productModeLabel => 'PRODUCT MODE';

  @override
  String get packCostLabel => 'PACK COST';

  @override
  String get packCostHint => 'E.g. 6.00';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get unitsPerPackLabel => 'UNITS / ESTIMATED USES PER PACK';

  @override
  String get unitsPerPackHint => 'E.g. 20';

  @override
  String get enterNumber => 'Enter a number';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get unitsPerPackHelp =>
      'You can also enter the average number of uses you get from one pack.';

  @override
  String get costPerUseLabel => 'COST PER USE';

  @override
  String get costPerUseHint => 'Optional, e.g. 0.10';

  @override
  String get costPerUseHelp =>
      'Leave empty to log uses only, without calculating costs.';

  @override
  String get minutesLostLabel => 'MINUTES OF LIFE LOST PER USE';

  @override
  String get enterValue => 'Enter a value';

  @override
  String get dailyGoalLabel => 'DAILY GOAL';

  @override
  String get noDailyLimit => 'No daily limit';

  @override
  String dailyGoalText(int count) {
    return 'I want to stay under $count a day';
  }

  @override
  String get noLimit => 'No limit';

  @override
  String get zeroNoLimit => '0 = no limit set';

  @override
  String get withStock => 'With stock';

  @override
  String get withStockHelp =>
      'The product uses a remaining stock and can be restocked when it runs out.';

  @override
  String get noStockHelp =>
      'The product only logs uses, without tracking packs or remaining stock.';

  @override
  String get minutesLostSheetTitle => 'Minutes of life lost';

  @override
  String get noEstimate => 'No estimate';

  @override
  String get noEstimateSubtitle => 'Doesn\'t count life lost';

  @override
  String minutesEstimate(int count) {
    return '$count min (estimate)';
  }

  @override
  String minutesPresetLabel(String name, String estimate) {
    return '$name — $estimate';
  }

  @override
  String get presetCigarette => 'Cigarette';

  @override
  String get presetEcigarette => 'E-cigarette';

  @override
  String get presetHeatedTobacco => 'Heated tobacco device';

  @override
  String get presetCigar => 'Cigar';

  @override
  String get presetHookah => 'Hookah (session)';

  @override
  String get custom => 'Custom…';

  @override
  String get minutesPerUse => 'Minutes per use';

  @override
  String get last7Days => 'LAST 7 DAYS';

  @override
  String averagePerDay(String value) {
    return 'average $value/day';
  }

  @override
  String get weekdaysShort => 'MON,TUE,WED,THU,FRI,SAT,SUN';

  @override
  String get openCsv => 'Open CSV';

  @override
  String get saveCsv => 'Save CSV';

  @override
  String get unreadableBackupFile =>
      'Unreadable file: use the CSV backup exported by the app, without editing it.';

  @override
  String get last7DaysTitle => 'Last 7 days';

  @override
  String get last30DaysTitle => 'Last 30 days';

  @override
  String get entireHistory => 'Entire history';

  @override
  String get customPeriod => 'Custom period';

  @override
  String get selectRange => 'Select range';

  @override
  String get noDataLogged => 'No data logged';

  @override
  String get noDataLoggedBody =>
      'Your history will appear here after your first uses.';

  @override
  String get noFilterResults => 'No results for the selected filter';

  @override
  String get noFilterResultsBody =>
      'Try another product or a wider date range.';

  @override
  String get filters => 'FILTERS';

  @override
  String get product => 'Product';

  @override
  String get allProducts => 'All products';

  @override
  String get statistics => 'STATISTICS';

  @override
  String get periodOverview => 'Period overview';

  @override
  String get periodOverviewSubtitle =>
      'Averages and summary for the selected filter';

  @override
  String get periodTotal => 'Period total';

  @override
  String get mixedProductsNote =>
      'Different products aren\'t added together: choose a product to see averages and trends.';

  @override
  String get periodAveragePerDay => 'Period avg/day';

  @override
  String get trend7Days => '7-day trend';

  @override
  String get average30Days => '30-day average';

  @override
  String unitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
    );
    return '$_temp0';
  }

  @override
  String get costsAndProjections => 'Costs and projections';

  @override
  String get costsAndProjectionsSubtitle =>
      'Current spending and future estimates';

  @override
  String get periodCost => 'Period cost';

  @override
  String get monthlyProjection => 'Monthly projection';

  @override
  String get annualEstimate => 'Annual estimate';

  @override
  String get monthlyEstimate => 'Monthly estimate';

  @override
  String get estimatedAnnualCost => 'Estimated annual cost';

  @override
  String get habitsAndTimes => 'Habits and times';

  @override
  String get habitsAndTimesSubtitle => 'Pace, days and most active time of day';

  @override
  String get peakHour => 'Peak hour';

  @override
  String underLimitStreak(int count, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consecutive days under the limit ($limit)',
      one: '1 consecutive day under the limit ($limit)',
    );
    return '$_temp0';
  }

  @override
  String activeStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Active for $count consecutive days',
      one: 'Active for 1 consecutive day',
    );
    return '$_temp0';
  }

  @override
  String get bestDay => 'Best day';

  @override
  String get worstDay => 'Worst day';

  @override
  String get hourlyDistribution => 'HOURLY DISTRIBUTION';

  @override
  String thinDataNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Estimates based on $count days of data: they will become reliable after a few more days.',
      one:
          'Estimates based on one day of data: they will become reliable after a few more days.',
    );
    return '$_temp0';
  }

  @override
  String get trend30Days => '30-DAY TREND';

  @override
  String get sevenDays => '7 days';

  @override
  String get thirtyDays => '30 days';

  @override
  String get all => 'All';

  @override
  String get customShort => 'Custom';

  @override
  String weekOf(String label) {
    return 'Week of $label';
  }

  @override
  String get entriesSection => 'ENTRIES';

  @override
  String get days => 'Days';

  @override
  String get weeks => 'Weeks';

  @override
  String get months => 'Months';

  @override
  String get entryRemoved => 'Entry removed';

  @override
  String get achievementsTitle => 'Achievements & Badges';

  @override
  String get unlockedSection => 'UNLOCKED';

  @override
  String get noBadgesYet => 'Log your first activity to unlock badges!';

  @override
  String get lockedSection => 'LOCKED';

  @override
  String get allBadgesUnlocked => 'You\'ve unlocked every badge! 🎉';

  @override
  String badgeProgress(int unlocked, int total) {
    return '$unlocked / $total badges';
  }

  @override
  String get setReductionPlan => 'Set a reduction plan';

  @override
  String get planStatusAhead => 'AHEAD';

  @override
  String get planStatusOnTrack => 'ON TRACK';

  @override
  String get planStatusBehind => 'BEHIND';

  @override
  String get planStatusActive => 'ACTIVE';

  @override
  String get reductionPlanSection => 'REDUCTION PLAN';

  @override
  String productLabel(String name) {
    return 'Product: $name';
  }

  @override
  String get planStart => 'Start';

  @override
  String get unitsPerDayShort => 'units/day';

  @override
  String get average7Days => '7-day average';

  @override
  String get targetToday => 'Today\'s target';

  @override
  String get finalGoal => 'Final goal';

  @override
  String planWeek(int current, int total) {
    return 'Week $current / $total';
  }

  @override
  String get planCompleted => 'Completed!';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get planAheadMessage => 'You\'re below this week\'s target.';

  @override
  String get planOnTrackMessage => 'You\'re on track with your plan.';

  @override
  String get planBehindMessage => 'You\'re above this week\'s target.';

  @override
  String get planActiveMessage => 'Plan active for this product.';

  @override
  String get edit => 'Edit';

  @override
  String get deletePlanTitle => 'Delete plan';

  @override
  String get deletePlanBody => 'Do you want to delete the reduction plan?';

  @override
  String badgeLockedSemantics(String title) {
    return '$title, locked';
  }

  @override
  String badgeUnlockedSemantics(String title, String date) {
    return '$title, unlocked on $date';
  }

  @override
  String unlockedOn(String date) {
    return 'Unlocked on $date';
  }

  @override
  String get notUnlockedYet => 'Not unlocked yet';

  @override
  String get close => 'Close';

  @override
  String average14Days(String value) {
    return 'Average over the last 14 days: $value units/day';
  }

  @override
  String finalGoalValue(String value) {
    return 'Final goal: $value units/day';
  }

  @override
  String planDuration(int count) {
    return 'Duration: $count weeks';
  }

  @override
  String planReductionSummary(String value, int weeks) {
    return 'Reduction of $value units/day over $weeks weeks.';
  }

  @override
  String get updatePlan => 'Update plan';

  @override
  String get setPlan => 'Set plan';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';
}
