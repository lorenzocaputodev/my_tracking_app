import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/my_tracking_provider.dart';
import '../theme/theme_context.dart';
import '../widgets/product_configuration_form.dart';
import '../widgets/product_form_state.dart';
import '../widgets/save_bar.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _form = ProductFormState();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || !_form.isValid) return;

    setState(() => _isSaving = true);
    try {
      await context.read<MyTrackingProvider>().addProduct(_form.toNewProduct());
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
    final accent = context.accent;
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo prodotto')),
      bottomNavigationBar: SaveBar(
        saveLabel: 'Aggiungi prodotto',
        onSave: _isSaving ? null : _save,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            ProductConfigurationForm(
              isDark: isDark,
              accentColor: accent,
              title: '',
              subtitle: '',
              form: _form,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
