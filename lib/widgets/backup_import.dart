import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/my_tracking_provider.dart';
import '../services/product_notification_service.dart';
import '../theme/theme_context.dart';
import '../utils/backup_file_service.dart';

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

  if (!BackupFileService.isSupported) {
    showFeedback(
      'Import/export file disponibile solo su Android e Windows.',
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
        'Importazione file non supportata su questa piattaforma.',
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
        'Ripristino completato: ${_importSummary(outcome)}. '
        'Promemoria disattivati: permesso notifiche non concesso.',
      );
      return outcome;
    }
    showFeedback('Ripristino completato: ${_importSummary(outcome)}.');
    return outcome;
  } on FormatException catch (error) {
    showFeedback(
      error.message.isEmpty ? 'Backup CSV non valido' : error.message,
      error: true,
    );
  } on BackupRestoreException catch (error) {
    showFeedback(error.message, error: true);
  } catch (_) {
    showFeedback('Importazione CSV non riuscita.', error: true);
  }
  return null;
}

Future<bool> _confirmEmptyHistory(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Backup senza cronologia'),
      content: const Text(
        'Questo file non contiene nessuna registrazione. '
        'Importarlo sostituisce i dati attuali e la cronologia resta vuota.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Importa comunque'),
        ),
      ],
    ),
  );
  return ok == true;
}

String _importSummary(BackupImportOutcome outcome) {
  final parts = <String>[
    outcome.entries == 1
        ? '1 registrazione'
        : '${outcome.entries} registrazioni',
    outcome.products == 1 ? '1 prodotto' : '${outcome.products} prodotti',
  ];
  return parts.join(' e ');
}
