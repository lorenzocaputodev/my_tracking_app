import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/app_reminder_settings.dart';
import '../models/pack_config.dart';
import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../services/product_notification_service.dart';
import '../utils/backup_file_service.dart';
import '../utils/minutes_presets.dart';
import '../widgets/product_configuration_form.dart';
import 'add_product_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _packCostCtrl;
  late final TextEditingController _piecesCtrl;
  late final TextEditingController _directCostCtrl;
  late final TextEditingController _minutesCtrl;

  int _dailyGoal = 0;
  bool _tracksInventory = true;
  int? _selectedPresetMinutes;
  bool _minutesCustomMode = false;
  bool _isSaving = false;
  AppReminderSettings _globalReminderSettings =
      ProductNotificationService.defaultGlobalReminderSettings();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _packCostCtrl = TextEditingController();
    _piecesCtrl = TextEditingController();
    _directCostCtrl = TextEditingController();
    _minutesCtrl = TextEditingController();
    _reloadFromProvider();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _packCostCtrl.dispose();
    _piecesCtrl.dispose();
    _directCostCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameCtrl.text.trim();
    final minutes = int.tryParse(_minutesCtrl.text.trim());
    if (name.isEmpty || minutes == null || minutes < 0) {
      return false;
    }

    if (_tracksInventory) {
      final packCost = double.tryParse(_packCostCtrl.text.replaceAll(',', '.'));
      final pieces = int.tryParse(_piecesCtrl.text.trim());
      return packCost != null && packCost > 0 && pieces != null && pieces > 0;
    }

    final directCost = _directCostCtrl.text.trim();
    if (directCost.isEmpty) return true;
    final parsed = double.tryParse(directCost.replaceAll(',', '.'));
    return parsed != null && parsed >= 0;
  }

  void _syncMinutesSelection(int minutes) {
    _selectedPresetMinutes = presetForMinutes(minutes)?.minutes;
    _minutesCustomMode = _selectedPresetMinutes == null;
  }

  void _reloadFromProvider() {
    final config = context.read<MyTrackingProvider>().config;
    setState(() {
      _nameCtrl.text = config.name;
      _packCostCtrl.text = config.totalCost.toStringAsFixed(2);
      _piecesCtrl.text = '${config.pieces}';
      _directCostCtrl.text = config.directUnitCost?.toStringAsFixed(2) ?? '';
      _minutesCtrl.text = '${config.minutesLost}';
      _dailyGoal = config.dailyLimit;
      _tracksInventory = config.tracksInventory;
      _globalReminderSettings =
          context.read<MyTrackingProvider>().globalReminderSettings;
      _syncMinutesSelection(config.minutesLost);
    });
  }

  void _onMinutesPresetSelected(int value) {
    setState(() {
      if (value == customMinutesPresetValue) {
        _minutesCustomMode = true;
        _selectedPresetMinutes = null;
        if (presetForMinutes(int.tryParse(_minutesCtrl.text.trim()) ?? -999) !=
            null) {
          _minutesCtrl.clear();
        }
      } else {
        _minutesCustomMode = false;
        _selectedPresetMinutes = value;
        _minutesCtrl.text = '$value';
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final provider = context.read<MyTrackingProvider>();
      final directUnitCost = _directCostCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_directCostCtrl.text.replaceAll(',', '.'));

      await provider.updateActiveProductConfig(
        PackConfig(
          name: _nameCtrl.text.trim(),
          totalCost:
              double.tryParse(_packCostCtrl.text.replaceAll(',', '.')) ?? 0,
          pieces: int.tryParse(_piecesCtrl.text.trim()) ?? 20,
          minutesLost: int.parse(_minutesCtrl.text.trim()),
          dailyLimit: _dailyGoal,
          tracksInventory: _tracksInventory,
          directUnitCost: directUnitCost,
        ),
      );
      await provider.updateGlobalReminderSettings(_globalReminderSettings);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurazione salvata')),
    );
    Navigator.pop(context);
  }

  Future<void> _setGlobalReminderEnabled(bool value) async {
    if (value) {
      final granted = await ProductNotificationService.ensurePermission();
      if (!granted) {
        _showFeedback(
          'Permesso notifiche non concesso.',
          backgroundColor: Colors.orangeAccent,
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _globalReminderSettings = _globalReminderSettings.copyWith(
        enabled: value,
      );
    });
  }

  void _showFeedback(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

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
        backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.redAccent,
        );
        return;
      }
      _showFeedback('Backup CSV salvato');
    } catch (_) {
      _showFeedback(
        'Esportazione CSV non riuscita.',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  Future<void> _importBackupCsvFile() async {
    if (!BackupFileService.isSupported) {
      _showFeedback(
        'Import/export file disponibile solo su Android e Windows.',
        backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.redAccent,
        );
        return;
      }

      final provider = context.read<MyTrackingProvider>();
      await provider.importFullBackupCsv(file.content!);
      if (!mounted) return;
      _reloadFromProvider();
      _showFeedback('Backup completo ripristinato');
    } on FormatException catch (error) {
      _showFeedback(
        error.message.isEmpty ? 'Backup CSV non valido' : error.message,
        backgroundColor: Colors.redAccent,
      );
    } catch (_) {
      _showFeedback(
        'Importazione CSV non riuscita.',
        backgroundColor: Colors.redAccent,
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
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina definitivamente'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<MyTrackingProvider>().clearHistory();
    if (mounted) Navigator.pop(context);
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurazione')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('ASPETTO'),
            const SizedBox(height: 12),
            const _ThemeSelector(),
            const SizedBox(height: 32),
            _label('PRODOTTI TRACCIATI'),
            const SizedBox(height: 12),
            _ProductListCard(
              turquoise: accent,
              onProductActivated: _reloadFromProvider,
            ),
            const SizedBox(height: 32),
            Consumer<MyTrackingProvider>(
              builder: (_, provider, __) {
                if (!provider.activeProduct.tracksInventory) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('STATO ATTUALE'),
                    const SizedBox(height: 12),
                    _PackCard(turquoise: accent),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
            _label('PARAMETRI PRODOTTO'),
            const SizedBox(height: 12),
            Consumer<MyTrackingProvider>(
              builder: (_, provider, __) => ProductConfigurationForm(
                isDark: isDark,
                accentColor: accent,
                title: 'Modifica il prodotto selezionato',
                subtitle:
                    'Applica le modifiche premendo il pulsante "Salva parametri" qui sotto.',
                widgetMessage:
                    'Puoi aggiungere il widget Android dalla schermata Home e tenere questo prodotto sempre a portata di tap.',
                submitLabel: 'Salva parametri',
                nameController: _nameCtrl,
                packCostController: _packCostCtrl,
                piecesController: _piecesCtrl,
                directCostController: _directCostCtrl,
                minutesController: _minutesCtrl,
                tracksInventory: _tracksInventory,
                onTracksInventoryChanged: (value) =>
                    setState(() => _tracksInventory = value),
                dailyGoal: _dailyGoal,
                onDailyGoalChanged: (value) =>
                    setState(() => _dailyGoal = value),
                selectedPresetMinutes: _selectedPresetMinutes,
                minutesCustomMode: _minutesCustomMode,
                onMinutesPresetSelected: _onMinutesPresetSelected,
                onChanged: () => setState(() {}),
                notificationsSupported: ProductNotificationService.isSupported,
                showNotificationsSection: true,
                showWidgetHomeSection: true,
                globalReminderSettings: _globalReminderSettings,
                onGlobalReminderEnabledChanged: _setGlobalReminderEnabled,
                onGlobalReminderMinutesChanged: (value) => setState(() {
                  _globalReminderSettings = _globalReminderSettings.copyWith(
                    intervalMinutes: value,
                  );
                }),
                onSubmit: (_isSaving || !_canSave) ? null : _save,
                submitEnabled: !_isSaving && _canSave,
                isSubmitting: _isSaving,
                submitPlacement: FormSubmitPlacement.afterNotifications,
              ),
            ),
            const SizedBox(height: 32),
            _label('BACKUP & RIPRISTINO'),
            const SizedBox(height: 12),
            _BackupCard(
              turquoise: accent,
              onExport: _exportBackupCsvFile,
              onImport: _importBackupCsvFile,
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _confirmReset,
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              label: Text(
                'Reset totale cronologia',
                style: GoogleFonts.dmSans(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<MyTrackingProvider>(
      builder: (_, provider, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tema',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<AppThemePreference>(
                  expandedInsets: EdgeInsets.zero,
                  style: SegmentedButton.styleFrom(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: AppThemePreference.dark,
                      label: Text('Scuro'),
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemePreference.light,
                      label: Text('Chiaro'),
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemePreference.system,
                      label: Text('Sistema'),
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                    ),
                  ],
                  selected: {provider.themePreference},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      provider.setThemePreference(selection.first);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PackCard extends StatelessWidget {
  final Color turquoise;

  const _PackCard({required this.turquoise});

  ButtonStyle _actionButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: turquoise.withValues(alpha: 0.20),
      foregroundColor: turquoise,
      elevation: 0,
      minimumSize: const Size.fromHeight(45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _showCorrectDialog(
    BuildContext context,
    MyTrackingProvider provider,
  ) async {
    final controller = TextEditingController(text: '${provider.packRemaining}');
    String? errorText;

    final correctedValue = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Correggi scorta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inserisci il numero reale di unità rimaste per allineare la scorta attuale.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Unità rimaste',
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                final rawValue = controller.text.trim();
                if (rawValue.isEmpty) {
                  setDialogState(
                    () => errorText = 'Inserisci un numero intero.',
                  );
                  return;
                }

                final parsedValue = int.tryParse(rawValue);
                if (parsedValue == null) {
                  setDialogState(
                    () => errorText = 'Inserisci un numero intero valido.',
                  );
                  return;
                }
                if (parsedValue < 0) {
                  setDialogState(
                    () => errorText = 'Il valore non può essere negativo.',
                  );
                  return;
                }
                if (parsedValue > provider.config.pieces) {
                  setDialogState(
                    () => errorText =
                        'Il valore non può superare ${provider.config.pieces}.',
                  );
                  return;
                }

                Navigator.pop(dialogContext, parsedValue);
              },
              child: const Text('Conferma'),
            ),
          ],
        ),
      ),
    );

    if (correctedValue == null || !context.mounted) return;

    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;
      await context
          .read<MyTrackingProvider>()
          .correctActiveProductPackRemaining(correctedValue);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correzione scorta non riuscita.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyTrackingProvider>(
      builder: (_, provider, __) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: turquoise.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: turquoise.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Residuo in scorta',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${provider.packRemaining} / ${provider.config.pieces}',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: turquoise,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 32,
                    color: turquoise.withValues(alpha: 0.50),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: provider.openNewPack,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('REINTEGRA'),
                      style: _actionButtonStyle(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showCorrectDialog(context, provider),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('CORREGGI'),
                      style: _actionButtonStyle(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductListCard extends StatelessWidget {
  final Color turquoise;
  final VoidCallback onProductActivated;

  const _ProductListCard({
    required this.turquoise,
    required this.onProductActivated,
  });

  Future<void> _add(BuildContext context) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (added != true || !context.mounted) return;
    onProductActivated();
  }

  void _showFeedback(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _archiveProduct(
    BuildContext context,
    MyTrackingProvider provider,
    TrackedProduct product,
  ) async {
    final archived = await provider.archiveProduct(product.id);
    if (!context.mounted) return;
    if (archived) {
      onProductActivated();
      _showFeedback(context, '${product.name} archiviato');
      return;
    }
    _showFeedback(
      context,
      'Devi mantenere almeno un prodotto attivo',
      color: Colors.orangeAccent,
    );
  }

  Future<void> _restoreProduct(
    BuildContext context,
    MyTrackingProvider provider,
    TrackedProduct product,
  ) async {
    await provider.restoreProduct(product.id);
    if (!context.mounted) return;
    onProductActivated();
    _showFeedback(context, '${product.name} ripristinato');
  }

  Future<bool> _confirmDeleteArchived(
    BuildContext context,
    TrackedProduct product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare definitivamente?'),
        content: Text(
          'Questa azione rimuove ${product.name} e tutta la cronologia collegata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: turquoise,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  String _productStatusLabel(TrackedProduct product, bool active) {
    if (!product.tracksInventory) {
      return active
          ? 'Prodotto attivo \u2022 Tracciamento senza scorta'
          : 'Tracciamento senza scorta';
    }
    return active
        ? 'Prodotto attivo \u2022 ${product.packRemaining}/${product.pieces} in scorta'
        : '${product.pieces} unit\u00E0 per confezione';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<MyTrackingProvider>(
      builder: (_, provider, __) {
        final activeProducts = provider.activeProducts;
        final archivedProducts = provider.archivedProducts;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: turquoise.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: turquoise.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('ATTIVI'),
              ...activeProducts.map((product) {
                final active = product.id == provider.activeProduct.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121717)
                        : const Color(0xFFF9FCFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? Colors.greenAccent.withValues(alpha: 0.55)
                          : turquoise.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _productStatusLabel(product, active),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      active
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _archiveProduct(
                                      context, provider, product),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.archive_outlined,
                                      color: Colors.orangeAccent,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton(
                                  onPressed: () async {
                                    await provider.setActiveProduct(product.id);
                                    onProductActivated();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: turquoise.withValues(
                                      alpha: 0.16,
                                    ),
                                    foregroundColor: turquoise,
                                    minimumSize: const Size(0, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Attiva',
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _archiveProduct(
                                      context, provider, product),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.archive_outlined,
                                      color: Colors.orangeAccent,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                );
              }),
              if (archivedProducts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _sectionLabel('ARCHIVIATI'),
                ...archivedProducts.map((product) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF121717)
                          : const Color(0xFFF9FCFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Prodotto archiviato \u2022 storico conservato',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _restoreProduct(context, provider, product),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: turquoise,
                                side: BorderSide(
                                  color: turquoise.withValues(alpha: 0.35),
                                ),
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Ripristina',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                final confirmed = await _confirmDeleteArchived(
                                  context,
                                  product,
                                );
                                if (!confirmed || !context.mounted) return;
                                await provider
                                    .deleteArchivedProduct(product.id);
                                if (!context.mounted) return;
                                onProductActivated();
                                _showFeedback(
                                  context,
                                  '${product.name} eliminato definitivamente',
                                  color: Colors.redAccent,
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () => _add(context),
                icon: Icon(Icons.add_rounded, color: turquoise, size: 20),
                label: Text(
                  'Aggiungi prodotto tracciato',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: turquoise,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: turquoise.withValues(alpha: 0.40)),
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackupCard extends StatelessWidget {
  final Color turquoise;
  final Future<void> Function() onExport;
  final Future<void> Function() onImport;

  const _BackupCard({
    required this.turquoise,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: turquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: turquoise.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: onExport,
            icon: Icon(Icons.table_chart_outlined, size: 18, color: turquoise),
            label: Text(
              'Esporta file CSV',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: turquoise,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: turquoise.withValues(alpha: 0.30)),
              backgroundColor: turquoise.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onImport,
            icon: const Icon(
              Icons.table_view_rounded,
              size: 18,
              color: Colors.deepOrangeAccent,
            ),
            label: Text(
              'Importa file CSV',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: Colors.deepOrangeAccent,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(
                color: Colors.deepOrangeAccent.withValues(alpha: 0.30),
              ),
              backgroundColor: Colors.deepOrangeAccent.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
