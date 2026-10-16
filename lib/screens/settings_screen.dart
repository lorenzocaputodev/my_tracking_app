import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../utils/backup_file_service.dart';
import '../widgets/backup_import.dart';
import '../widgets/pill_selector.dart';
import '../widgets/reminder_settings.dart';
import '../widgets/settings_rows.dart';
import 'add_product_screen.dart';
import 'archived_products_screen.dart';
import 'product_settings_screen.dart';
import '../theme/app_icons.dart';
import '../l10n/l10n.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _releasesPage = Uri.https(
    'github.com',
    '/lorenzocaputodev/my_tracking_app/releases/latest',
  );

  late final Future<String> _version =
      PackageInfo.fromPlatform().then((info) => info.version);

  void _showFeedback(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void _open(Widget screen) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      );

  Future<void> _addProduct() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (added != true || !mounted) return;
    final name = context.read<MyTrackingProvider>().activeProduct.name;
    _showFeedback(context.l10n.productAddedInUse(name));
  }

  // --- Backup ---

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
        context.l10n.backupFilesUnsupported,
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
          context.l10n.fileSaveUnsupported,
          backgroundColor: context.stats.danger,
        );
        return;
      }
      _showFeedback(context.l10n.backupSaved);
    } catch (_) {
      _showFeedback(
        context.l10n.backupExportFailed,
        backgroundColor: context.stats.danger,
      );
    }
  }

  // --- Aggiornamenti ---

  Future<void> _openReleasesPage() async {
    var opened = false;
    try {
      opened = await launchUrl(
        _releasesPage,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!opened && mounted) {
      _showFeedback(
        context.l10n.browserOpenFailed,
        backgroundColor: context.stats.danger,
      );
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.clearHistoryTitle),
        content: Text(context.l10n.clearHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.stats.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<MyTrackingProvider>().clearHistory();
    if (mounted) Navigator.pop(context);
  }

  String _productSubtitle(TrackedProduct product) => product.tracksInventory
      ? context.l10n.stockCount(product.packRemaining, product.pieces)
      : context.l10n.noStock;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTrackingProvider>();
    final colors = context.colors;
    final accent = context.accent;
    final danger = context.stats.danger;
    final archivedCount = provider.archivedProducts.length;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          SettingsSectionLabel(context.l10n.settingsSectionProducts),
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
                title: context.l10n.addProduct,
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
                child: Text(context.l10n.archivedCount(archivedCount)),
              ),
            ),
          SettingsSectionLabel(context.l10n.settingsSectionApp),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.contrast_rounded,
                title: context.l10n.theme,
                trailing: PillSelector<AppThemePreference>(
                  options: {
                    AppThemePreference.dark: context.l10n.themeDark,
                    AppThemePreference.light: context.l10n.themeLight,
                    AppThemePreference.system: context.l10n.system,
                  },
                  value: provider.themePreference,
                  onChanged: provider.setThemePreference,
                ),
              ),
              SettingsRow(
                icon: Icons.translate_rounded,
                title: context.l10n.language,
                trailing: PillSelector<AppLanguagePreference>(
                  options: {
                    AppLanguagePreference.italian: context.l10n.languageItalian,
                    AppLanguagePreference.english: context.l10n.languageEnglish,
                    AppLanguagePreference.system: context.l10n.system,
                  },
                  value: provider.languagePreference,
                  onChanged: provider.setLanguagePreference,
                ),
              ),
              SettingsRow(
                icon: Icons.widgets_outlined,
                title: context.l10n.widgetTheme,
                trailing: PillSelector<bool>(
                  options: {
                    true: context.l10n.themeDark,
                    false: context.l10n.themeLight,
                  },
                  value: provider.widgetDark,
                  onChanged: provider.setWidgetDark,
                ),
              ),
              ...reminderRows(context),
            ],
          ),
          SettingsSectionLabel(context.l10n.settingsSectionData),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.upload_rounded,
                title: context.l10n.exportBackup,
                subtitle: context.l10n.exportBackupSubtitle,
                onTap: _exportBackupCsvFile,
              ),
              SettingsRow(
                icon: Icons.download_rounded,
                title: context.l10n.importBackup,
                subtitle: context.l10n.importBackupSubtitle,
                onTap: () => importBackupFromFile(context),
              ),
            ],
          ),
          SettingsSectionLabel(context.l10n.settingsSectionAbout),
          SettingsGroup(
            children: [
              FutureBuilder<String>(
                future: _version,
                builder: (context, snapshot) => SettingsRow(
                  icon: Icons.system_update_alt_rounded,
                  title: context.l10n.checkForUpdates,
                  subtitle: snapshot.hasData
                      ? context.l10n.installedVersion(snapshot.data!)
                      : context.l10n.opensReleasesPage,
                  onTap: _openReleasesPage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SettingsGroup(
            children: [
              SettingsRow(
                icon: Icons.delete_sweep_rounded,
                title: context.l10n.clearHistory,
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
                  context.l10n.widgetHint,
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
        context.l10n.inUseBadge,
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
