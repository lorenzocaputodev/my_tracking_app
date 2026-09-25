import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/pack_config.dart';
import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_decorations.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../utils/app_formatters.dart';
import '../utils/minutes_presets.dart';
import '../widgets/product_configuration_form.dart';
import '../widgets/save_bar.dart';

/// Scorta e parametri di un prodotto, anche se non e' quello in uso.
/// "Salva" compare in una barra fissa solo quando c'e' qualcosa da salvare.
class ProductSettingsScreen extends StatefulWidget {
  final String productId;

  const ProductSettingsScreen({super.key, required this.productId});

  @override
  State<ProductSettingsScreen> createState() => _ProductSettingsScreenState();
}

class _ProductSettingsScreenState extends State<ProductSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _packCostCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _directCostCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();

  int _dailyGoal = 0;
  bool _tracksInventory = true;
  int? _selectedPresetMinutes;
  bool _minutesCustomMode = false;
  bool _isSaving = false;
  String _savedSnapshot = '';

  @override
  void initState() {
    super.initState();
    _reload();
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

  TrackedProduct? _product(MyTrackingProvider provider) => provider.products
      .cast<TrackedProduct?>()
      .firstWhere((p) => p?.id == widget.productId, orElse: () => null);

  /// Stato del modulo in una stringa: se differisce da quello caricato ci
  /// sono modifiche da salvare.
  String _snapshot() => [
        _nameCtrl.text.trim(),
        _packCostCtrl.text.trim(),
        _piecesCtrl.text.trim(),
        _directCostCtrl.text.trim(),
        _minutesCtrl.text.trim(),
        _dailyGoal,
        _tracksInventory,
      ].join('|');

  bool get _isDirty => _snapshot() != _savedSnapshot;

  void _reload() {
    final product = _product(context.read<MyTrackingProvider>());
    if (product == null) return;
    setState(() {
      _nameCtrl.text = product.name;
      _packCostCtrl.text = formatDecimal(product.totalCost);
      _piecesCtrl.text = '${product.pieces}';
      _directCostCtrl.text = product.directUnitCost == null
          ? ''
          : formatDecimal(product.directUnitCost!);
      _minutesCtrl.text = '${product.minutesLost}';
      _dailyGoal = product.dailyLimit;
      _tracksInventory = product.tracksInventory;
      _selectedPresetMinutes = presetForMinutes(product.minutesLost)?.minutes;
      _minutesCustomMode = _selectedPresetMinutes == null;
      _savedSnapshot = _snapshot();
    });
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
      final directUnitCost = _directCostCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_directCostCtrl.text.replaceAll(',', '.'));

      await context.read<MyTrackingProvider>().updateProductConfig(
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
            productId: widget.productId,
          );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    _reload();
    _showFeedback('Modifiche salvate');
  }

  void _showFeedback(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scartare le modifiche?'),
        content: const Text('Le modifiche non salvate andranno perse.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Scarta'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> _onMenu(String action, MyTrackingProvider provider) async {
    final product = _product(provider);
    if (product == null) return;
    switch (action) {
      case 'use':
        await provider.setActiveProduct(product.id);
        _showFeedback('${product.name} in uso');
      case 'archive':
        final archived = await provider.archiveProduct(product.id);
        if (!mounted) return;
        if (!archived) {
          _showFeedback(
            'Devi mantenere almeno un prodotto attivo',
            color: context.stats.warning,
          );
          return;
        }
        _showFeedback('${product.name} archiviato');
        Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTrackingProvider>();
    final product = _product(provider);
    if (product == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final isActive = provider.activeProduct.id == product.id;
    final accent = context.accent;
    final colors = context.colors;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(product.name),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
              onSelected: (value) => _onMenu(value, provider),
              itemBuilder: (_) => [
                if (!isActive)
                  const PopupMenuItem(
                    value: 'use',
                    child: Text('Usa questo prodotto'),
                  ),
                const PopupMenuItem(value: 'archive', child: Text('Archivia')),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _isDirty
            ? SaveBar(
                message: 'Modifiche non salvate',
                onCancel: _reload,
                saveLabel: 'Salva',
                onSave: (_isSaving || !_canSave) ? null : _save,
              )
            : null,
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (product.tracksInventory) ...[
                _StockCard(product: product),
                const SizedBox(height: 28),
              ],
              ProductConfigurationForm(
                isDark: context.isDark,
                accentColor: accent,
                title: '',
                subtitle: '',
                widgetMessage: '',
                submitLabel: '',
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
                notificationsSupported: false,
                showNotificationsSection: false,
                showWidgetHomeSection: false,
                onSubmit: null,
                submitEnabled: false,
                isSubmitting: _isSaving,
                submitPlacement: FormSubmitPlacement.none,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final TrackedProduct product;

  const _StockCard({required this.product});

  Future<void> _showCorrectDialog(BuildContext context) async {
    final controller = TextEditingController(text: '${product.packRemaining}');
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
                if (parsedValue > product.pieces) {
                  setDialogState(
                    () => errorText =
                        'Il valore non può superare ${product.pieces}.',
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

    controller.dispose();

    if (correctedValue == null || !context.mounted) return;

    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;
      await context
          .read<MyTrackingProvider>()
          .correctPackRemaining(correctedValue, productId: product.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Correzione scorta non riuscita.'),
          backgroundColor: context.stats.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final colors = context.colors;
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: accent.withValues(alpha: 0.20),
      foregroundColor: accent,
      elevation: 0,
      minimumSize: const Size.fromHeight(45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSubtle(colors),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Scorta',
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontSize: 13,
                  color: colors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${product.packRemaining} / ${product.pieces}',
                style: TextStyle(
                  fontFamily: AppFonts.sans,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context
                      .read<MyTrackingProvider>()
                      .openNewPack(productId: product.id),
                  style: buttonStyle,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintegra'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showCorrectDialog(context),
                  style: buttonStyle,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Correggi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
