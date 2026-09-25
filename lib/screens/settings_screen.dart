import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../services/product_notification_service.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../utils/backup_file_service.dart';
import '../widgets/pill_selector.dart';
import '../widgets/product_configuration_form.dart';
import '../widgets/settings_rows.dart';
import 'add_product_screen.dart';
import 'archived_products_screen.dart';
import 'product_settings_screen.dart';

/// Impostazioni generali: prodotti, preferenze dell'app e dati. I parametri
/// di un prodotto stanno nella sua pagina, [ProductSettingsScreen].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showFeedback(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void _open(Widget screen) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      );

  /// Un prodotto nuovo diventa quello in uso: lo diciamo, altrimenti la
  /// home cambierebbe senza spiegazione.
  Future<void> _addProduct() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (added != true || !mounted) return;
    final name = context.read<MyTrackingProvider>().activeProduct.name;
    _showFeedback('$name aggiunto e in uso');
  }

  // Promemoria: si salvano subito, non c'e' un pulsante da premere.

  Future<void> _setReminderEnabled(bool value) async {
    final provider = context.read<MyTrackingProvider>();
    if (value) {
      final warningColor = context.stats.warning;
      final granted = await ProductNotificationService.ensurePermission();
      if (!granted) {
        _showFeedback(
          'Permesso notifiche non concesso.',
          backgroundColor: warningColor,
        );
        return;
      }
    }
    await provider.updateGlobalReminderSettings(
      provider.globalReminderSettings.copyWith(enabled: value),
    );
  }

  Future<void> _pickReminderInterval() async {
    final provider = context.read<MyTrackingProvider>();
    final current = provider.globalReminderSettings.intervalMinutes;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Ricordamelo ogni',
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ctx.colors.textPrimary,
                ),
              ),
            ),
            for (final option in reminderIntervalOptions)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(option.label),
                trailing: option.minutes == current
                    ? Icon(Icons.check_rounded, color: ctx.accent)
                    : null,
                onTap: () => Navigator.pop(ctx, option.minutes),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    await provider.updateGlobalReminderSettings(
      provider.globalReminderSettings.copyWith(intervalMinutes: picked),
    );
  }

  // Backup

  String _backupFileName() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'my_tracking_app_backup_$year$month$day'
        '_$hour$minute.csv';
  }

  Future<void> _exportBackupCsvFile() async {
    if (!BackupFileService.isSupported) {
      _showFeedback(
        'Import/export file disponibile solo su Android e Windows.',
        backgroundColor: context.stats.danger,
      );
      return;
    }

    try {
      final csv =
          await context.read<MyTrackingProvider>().exportFullBackupCsv();
      final result = await BackupFileService.saveCsvFile(
        fileName: _backupFileName(),
        content: csv,
      );
      if (!mounted || result.status == BackupFileSaveStatus.cancelled) return;
      if (result.status == BackupFileSaveStatus.unsupported) {
        _showFeedback(
          'Salvataggio file non supportato su questa piattaforma.',
          backgroundColor: context.stats.danger,
        );
        return;
      }
      _showFeedback('Backup CSV salvato');
    } catch (_) {
      _showFeedback(
        'Esportazione CSV non riuscita.',
        backgroundColor: context.stats.danger,
      );
    }
  }

  Future<void> _importBackupCsvFile() async {
    if (!BackupFileService.isSupported) {
      _showFeedback(
        'Import/export file disponibile solo su Android e Windows.',
        backgroundColor: context.stats.danger,
      );
      return;
    }

    try {
      final file = await BackupFileService.pickCsvFile();
      if (!mounted || file.status == BackupFileReadStatus.cancelled) return;
      if (file.status == BackupFileReadStatus.unsupported ||
          file.content == null) {
        _showFeedback(
          'Importazione file non supportata su questa piattaforma.',
          backgroundColor: context.stats.danger,
        );
        return;
      }

      await context.read<MyTrackingProvider>().importFullBackupCsv(
            file.content!,
          );
      _showFeedback('Backup completo ripristinato');
    } on FormatException catch (error) {
      if (!mounted) return;
      _showFeedback(
        error.message.isEmpty ? 'Backup CSV non valido' : error.message,
        backgroundColor: context.stats.danger,
      );
    } catch (_) {
      if (!mounted) return;
      _showFeedback(
        'Importazione CSV non riuscita.',
        backgroundColor: context.stats.danger,
      );
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancella tutto?'),
        content: const Text(
          'Questa azione elimina permanentemente tutta la cronologia registrata finora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.stats.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<MyTrackingProvider>().clearHistory();
    if (mounted) Navigator.pop(context);
  }

  String _productSubtitle(TrackedProduct product) => product.tracksInventory
      ? '${product.packRemaining}/${product.pieces} in scorta'
      : 'Senza scorta';

  String _intervalLabel(int minutes) => reminderIntervalOptions
      .firstWhere(
        (o) => o.minutes == minutes,
        orElse: () => reminderIntervalOptions[2],
      )
      .label;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTrackingProvider>();
    final colors = context.colors;
    final accent = context.accent;
    final danger = context.stats.danger;
    final reminders = provider.globalReminderSettings;
    final notificationsSupported = ProductNotificationService.isSupported;
    final archivedCount = provider.archivedProducts.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const SettingsSectionLabel('PRODOTTI'),
          SettingsGroup(
            children: [
              for (final product in provider.activeProducts)
                SettingsRow(
                  icon: product.tracksInventory
                      ? Icons.inventory_2_rounded
                      : Icons.show_chart_rounded,
                  title: product.name,
                  subtitle: _productSubtitle(product),
                  onTap: () =>
                      _open(ProductSettingsScreen(productId: product.id)),
                  trailing: product.id == provider.activeProduct.id
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _InUseBadge(color: accent),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.textFaint,
                            ),
                          ],
                        )
                      : null,
                ),
              SettingsRow(
                icon: Icons.add_rounded,
                title: 'Aggiungi prodotto',
                trailing: const SizedBox.shrink(),
                onTap: _addProduct,
              ),
            ],
          ),
          if (archivedCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _open(const ArchivedProductsScreen()),
                style: TextButton.styleFrom(foregroundColor: colors.textMuted),
                child: Text('Archiviati ($archivedCount)  ›'),
              ),
            ),
          const SettingsSectionLabel('APP'),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.contrast_rounded,
                title: 'Tema',
                trailing: PillSelector<AppThemePreference>(
                  options: const {
                    AppThemePreference.dark: 'Scuro',
                    AppThemePreference.light: 'Chiaro',
                    AppThemePreference.system: 'Sistema',
                  },
                  value: provider.themePreference,
                  onChanged: provider.setThemePreference,
                ),
              ),
              SettingsRow(
                icon: Icons.notifications_rounded,
                title: 'Promemoria',
                subtitle: notificationsSupported
                    ? 'Ti ricorda di registrare'
                    : 'Disponibile solo su Android',
                enabled: notificationsSupported,
                trailing: Switch(
                  value: notificationsSupported && reminders.enabled,
                  onChanged:
                      notificationsSupported ? _setReminderEnabled : null,
                ),
              ),
              if (notificationsSupported && reminders.enabled)
                SettingsRow(
                  icon: Icons.schedule_rounded,
                  title: 'Frequenza',
                  onTap: _pickReminderInterval,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ogni ${_intervalLabel(reminders.intervalMinutes)}',
                        style: TextStyle(
                          fontFamily: AppFonts.sans,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textFaint,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SettingsSectionLabel('DATI'),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.upload_rounded,
                title: 'Esporta backup',
                subtitle: 'Salva un file CSV con tutti i dati',
                onTap: _exportBackupCsvFile,
              ),
              SettingsRow(
                icon: Icons.download_rounded,
                title: 'Importa backup',
                subtitle: 'Sostituisce i dati attuali',
                onTap: _importBackupCsvFile,
              ),
            ],
          ),
          const SizedBox(height: 28),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.delete_sweep_rounded,
                title: 'Cancella cronologia',
                color: danger,
                trailing: const SizedBox.shrink(),
                onTap: _confirmReset,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.widgets_outlined, size: 16, color: colors.textFaint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tieni premuto sulla schermata Home del telefono per '
                  'aggiungere il widget.',
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 12,
                    color: colors.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InUseBadge extends StatelessWidget {
  final Color color;
  const _InUseBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlphas.accentMuted),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        'IN USO',
        style: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}
