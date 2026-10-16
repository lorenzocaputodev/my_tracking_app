import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/my_tracking_provider.dart';
import '../theme/theme_context.dart';
import '../widgets/backup_import.dart';
import '../widgets/product_configuration_form.dart';
import '../widgets/product_form_state.dart';
import '../widgets/reminder_settings.dart';
import '../widgets/save_bar.dart';
import '../widgets/settings_rows.dart';
import 'home_screen.dart';
import '../l10n/l10n.dart';

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

    try {
      await context.read<MyTrackingProvider>().addProduct(_form.toNewProduct());
      await prefs.setBool('hasCompletedSetup', true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

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
    final turquoise = context.accent;
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.l10n.setupTitle),
      ),
      bottomNavigationBar: SaveBar(
        saveLabel: context.l10n.startTracking,
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
                  title: context.l10n.haveBackup,
                  subtitle: context.l10n.haveBackupSubtitle,
                  onTap: _importBackup,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ProductConfigurationForm(
              isDark: isDark,
              accentColor: turquoise,
              title: context.l10n.setupQuestion,
              subtitle: context.l10n.setupSubtitle,
              form: _form,
              onChanged: () => setState(() {}),
            ),
            SettingsSectionLabel(context.l10n.remindersSection, inset: 0),
            SettingsGroup(children: reminderRows(context)),
          ],
        ),
      ),
    );
  }
}
