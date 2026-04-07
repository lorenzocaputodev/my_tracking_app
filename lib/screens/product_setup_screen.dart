import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_reminder_settings.dart';
import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../services/product_notification_service.dart';
import '../utils/minutes_presets.dart';
import '../widgets/product_configuration_form.dart';
import 'home_screen.dart';

class ProductSetupScreen extends StatefulWidget {
  const ProductSetupScreen({super.key});

  @override
  State<ProductSetupScreen> createState() => _ProductSetupScreenState();
}

class _ProductSetupScreenState extends State<ProductSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _packCostCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _directCostCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _dailyGoal = 10;
  bool _isSaving = false;
  bool _tracksInventory = true;
  int? _selectedPresetMinutes = 11;
  bool _minutesCustomMode = false;
  AppReminderSettings _globalReminderSettings =
      ProductNotificationService.defaultGlobalReminderSettings();

  @override
  void initState() {
    super.initState();
    _minutesCtrl.text = '11';
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

  bool get _canContinue {
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

  Future<void> _setGlobalReminderEnabled(bool value) async {
    if (value) {
      final granted = await ProductNotificationService.ensurePermission();
      if (!granted) {
        _showPermissionFeedback();
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

  TrackedProduct _buildProduct() {
    final totalCost =
        double.tryParse(_packCostCtrl.text.replaceAll(',', '.')) ?? 0;
    final pieces = int.tryParse(_piecesCtrl.text.trim()) ?? 20;
    final directUnitCost = _directCostCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_directCostCtrl.text.replaceAll(',', '.'));

    return TrackedProduct.createNew(
      name: _nameCtrl.text.trim(),
      totalCost: totalCost,
      pieces: pieces,
      minutesLost: int.parse(_minutesCtrl.text.trim()),
      dailyLimit: _dailyGoal,
      tracksInventory: _tracksInventory,
      directUnitCost: directUnitCost,
    );
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || !_canContinue) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final provider = context.read<MyTrackingProvider>();
    await provider.updateGlobalReminderSettings(_globalReminderSettings);
    await provider.addProduct(_buildProduct());
    await prefs.setBool('hasCompletedSetup', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showPermissionFeedback() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Permesso notifiche non concesso. Attivazione annullata.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Configura il tuo prodotto',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            ProductConfigurationForm(
              isDark: isDark,
              accentColor: turquoise,
              title: 'Cosa vuoi tracciare?',
              subtitle:
                  'Puoi modificare tutto nelle impostazioni in qualsiasi momento.',
              widgetMessage:
                  'Dopo il setup potrai aggiungere il widget Android dalla schermata Home e tenere il prodotto sempre a portata di tap.',
              submitLabel: 'Inizia a tracciare!',
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
              onSubmit: (_isSaving || !_canContinue) ? null : _finish,
              submitEnabled: !_isSaving && _canContinue,
              isSubmitting: _isSaving,
              submitPlacement: FormSubmitPlacement.bottom,
            ),
          ],
        ),
      ),
    );
  }
}
