import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../utils/minutes_presets.dart';
import '../widgets/product_configuration_form.dart';
import '../widgets/save_bar.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _packCostCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _directCostCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController(text: '11');
  final _formKey = GlobalKey<FormState>();

  // Stessi valori iniziali della configurazione al primo avvio.
  int _dailyGoal = 10;
  bool _isSaving = false;
  bool _tracksInventory = true;
  int? _selectedPresetMinutes = 11;
  bool _minutesCustomMode = false;

  @override
  void initState() {
    super.initState();
    _syncMinutesSelection(11);
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
      final cost = double.tryParse(_packCostCtrl.text.replaceAll(',', '.'));
      final pieces = int.tryParse(_piecesCtrl.text.trim());
      return cost != null && cost > 0 && pieces != null && pieces > 0;
    }
    final directCost = _directCostCtrl.text.trim();
    if (directCost.isEmpty) return true;
    final parsed = double.tryParse(directCost.replaceAll(',', '.'));
    return parsed != null && parsed >= 0;
  }

  void _syncMinutesSelection(int minutes) {
    final preset = presetForMinutes(minutes);
    _selectedPresetMinutes = preset?.minutes;
    _minutesCustomMode = preset == null;
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
    if (!_formKey.currentState!.validate() || !_canSave) return;

    setState(() => _isSaving = true);
    try {
      final directUnitCost = _directCostCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_directCostCtrl.text.replaceAll(',', '.'));

      await context.read<MyTrackingProvider>().addProduct(
            TrackedProduct.createNew(
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo prodotto')),
      bottomNavigationBar: SaveBar(
        saveLabel: 'Aggiungi prodotto',
        onSave: _isSaving ? null : _save,
      ),
      body: Form(
        key: _formKey,
        // Dopo il primo errore il messaggio sparisce appena il campo e' giusto.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            ProductConfigurationForm(
              isDark: isDark,
              accentColor: accent,
              title: '',
              subtitle: '',
              widgetMessage:
                  'Dopo il salvataggio potrai selezionare questo prodotto nell\'app e usarlo anche dal widget Android.',
              submitLabel: 'Aggiungi prodotto',
              nameController: _nameCtrl,
              packCostController: _packCostCtrl,
              piecesController: _piecesCtrl,
              directCostController: _directCostCtrl,
              minutesController: _minutesCtrl,
              tracksInventory: _tracksInventory,
              onTracksInventoryChanged: (value) =>
                  setState(() => _tracksInventory = value),
              dailyGoal: _dailyGoal,
              onDailyGoalChanged: (value) => setState(() => _dailyGoal = value),
              selectedPresetMinutes: _selectedPresetMinutes,
              minutesCustomMode: _minutesCustomMode,
              onMinutesPresetSelected: _onMinutesPresetSelected,
              onChanged: () => setState(() {}),
              notificationsSupported: false,
              showNotificationsSection: false,
              showWidgetHomeSection: false,
              onSubmit: (_isSaving || !_canSave) ? null : _save,
              submitEnabled: !_isSaving && _canSave,
              isSubmitting: _isSaving,
              submitPlacement: FormSubmitPlacement.none,
            ),
          ],
        ),
      ),
    );
  }
}
