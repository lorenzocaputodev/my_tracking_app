import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/my_tracking_provider.dart';
import '../services/product_notification_service.dart';
import '../theme/theme_context.dart';
import '../utils/backup_file_service.dart';
import '../l10n/l10n.dart';

// --- Importazione backup ---

Future<BackupImportOutcome?> importBackupFromFile(BuildContext context) async {
  void showFeedback(String message, {bool error = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? context.stats.danger : null,
      ),
    );
  }

  final l10n = context.l10n;
  if (!BackupFileService.isSupported) {
    showFeedback(
      l10n.backupFilesUnsupported,
      error: true,
    );
    return null;
  }

  try {
    final file = await BackupFileService.pickCsvFile();
    if (!context.mounted || file.status == BackupFileReadStatus.cancelled) {
      return null;
    }
    if (file.status == BackupFileReadStatus.unsupported ||
        file.content == null) {
      showFeedback(
        l10n.fileImportUnsupported,
        error: true,
      );
      return null;
    }

    final provider = context.read<MyTrackingProvider>();
    final data = provider.readBackupCsv(file.content!);

    if (data.entries.isEmpty && !await _confirmEmptyHistory(context)) {
      return null;
    }
    if (!context.mounted) return null;

    final outcome = await provider.restoreBackup(data);
    final reminders = provider.globalReminderSettings;
    if (reminders.enabled &&
        ProductNotificationService.isSupported &&
        !await ProductNotificationService.ensurePermission()) {
      await provider.updateGlobalReminderSettings(
        reminders.copyWith(enabled: false),
      );
      showFeedback(
        l10n.restoreCompletedRemindersOff(_importSummary(l10n, outcome)),
      );
      return outcome;
    }
    showFeedback(l10n.restoreCompleted(_importSummary(l10n, outcome)));
    return outcome;
  } on FormatException catch (error) {
    showFeedback(
      error.message.isEmpty ? l10n.backupInvalid : error.message,
      error: true,
    );
  } on BackupRestoreException catch (error) {
    showFeedback(error.message, error: true);
  } catch (_) {
    showFeedback(l10n.backupImportFailed, error: true);
  }
  return null;
}

Future<bool> _confirmEmptyHistory(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.emptyBackupTitle),
      content: Text(context.l10n.emptyBackupBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.importAnyway),
        ),
      ],
    ),
  );
  return ok == true;
}

String _importSummary(AppLocalizations l10n, BackupImportOutcome outcome) =>
    l10n.restoreSummary(
      l10n.entriesCount(outcome.entries),
      l10n.productsCount(outcome.products),
    );
