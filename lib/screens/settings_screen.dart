import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../utils/backup_file_service.dart';
import '../widgets/pill_selector.dart';
import '../widgets/reminder_settings.dart';
import '../widgets/settings_rows.dart';
import 'add_product_screen.dart';
import 'archived_products_screen.dart';
import 'product_settings_screen.dart';
import '../theme/app_icons.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTrackingProvider>();
    final colors = context.colors;
    final accent = context.accent;
    final danger = context.stats.danger;
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
                      ? AppIcons.stock
                      : AppIcons.noStock,
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
              ...reminderRows(context),
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
