import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/my_tracking_provider.dart';
import '../widgets/backup_import.dart';
import '../widgets/product_configuration_form.dart';
import '../widgets/product_form_state.dart';
import '../widgets/reminder_settings.dart';
import '../widgets/save_bar.dart';
import '../widgets/settings_rows.dart';
import 'home_screen.dart';

class ProductSetupScreen extends StatefulWidget {
  const ProductSetupScreen({super.key});

  @override
  State<ProductSetupScreen> createState() => _ProductSetupScreenState();
}

class _ProductSetupScreenState extends State<ProductSetupScreen> {
  final _form = ProductFormState();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || !_form.isValid) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final provider = context.read<MyTrackingProvider>();
    await provider.addProduct(_form.toNewProduct());
    await prefs.setBool('hasCompletedSetup', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _importBackup() async {
    if (_isSaving) return;
    final outcome = await importBackupFromFile(context);
    if (outcome == null || !mounted) return;
    if (context.read<MyTrackingProvider>().activeProducts.isEmpty) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turquoise = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Configura il tuo prodotto'),
      ),
      bottomNavigationBar: SaveBar(
        saveLabel: 'Inizia a tracciare',
        onSave: _isSaving ? null : _finish,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            SettingsGroup(
              children: [
                SettingsRow(
                  icon: Icons.download_rounded,
                  title: 'Ho già un backup',
                  subtitle: 'Ripristina i tuoi dati da un file CSV',
                  onTap: _importBackup,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ProductConfigurationForm(
              isDark: isDark,
              accentColor: turquoise,
              title: 'Cosa vuoi tracciare?',
              subtitle:
                  'Puoi modificare tutto nelle impostazioni in qualsiasi momento.',
              form: _form,
              onChanged: () => setState(() {}),
            ),
            const SettingsSectionLabel('PROMEMORIA', inset: 0),
            SettingsGroup(children: reminderRows(context)),
          ],
        ),
      ),
    );
  }
}
