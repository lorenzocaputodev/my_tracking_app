import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_decorations.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../theme/app_icons.dart';
import '../widgets/option_sheet.dart';
import '../widgets/product_configuration_form.dart';
import '../widgets/product_form_state.dart';
import '../widgets/save_bar.dart';
import '../l10n/l10n.dart';

class ProductSettingsScreen extends StatefulWidget {
  final String productId;

  const ProductSettingsScreen({super.key, required this.productId});

  @override
  State<ProductSettingsScreen> createState() => _ProductSettingsScreenState();
}

class _ProductSettingsScreenState extends State<ProductSettingsScreen> {
  final _form = ProductFormState();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String _savedSnapshot = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  TrackedProduct? _product(MyTrackingProvider provider) => provider.products
      .cast<TrackedProduct?>()
      .firstWhere((p) => p?.id == widget.productId, orElse: () => null);

  bool get _isDirty => _form.snapshot != _savedSnapshot;

  void _reload() {
    final product = _product(context.read<MyTrackingProvider>());
    if (product == null) return;
    setState(() {
      _form.load(product);
      _savedSnapshot = _form.snapshot;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || !_form.isValid) return;

    setState(() => _isSaving = true);
    try {
      await context.read<MyTrackingProvider>().updateProductConfig(
            _form.toConfig(),
            productId: widget.productId,
          );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    _reload();
    _showFeedback(context.l10n.changesSaved);
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
        title: Text(context.l10n.discardChangesTitle),
        content: Text(context.l10n.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> _onMenu(String action, MyTrackingProvider provider) async {
    final product = _product(provider);
    if (product == null) return;
    final l10n = context.l10n;
    switch (action) {
      case 'use':
        await provider.setActiveProduct(product.id);
        _showFeedback(l10n.productInUseFeedback(product.name));
      case 'archive':
        final archived = await provider.archiveProduct(product.id);
        if (!mounted) return;
        if (!archived) {
          _showFeedback(
            context.l10n.keepOneActiveProduct,
            color: context.stats.warning,
          );
          return;
        }
        _showFeedback(context.l10n.productArchived(product.name));
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
            IconButton(
              tooltip: context.l10n.moreActions,
              icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
              onPressed: () async {
                final action = await showOptionSheet<String>(
                  context,
                  title: product.name,
                  options: [
                    if (!isActive)
                      SheetOption(
                        'use',
                        context.l10n.useThisProduct,
                        subtitle: context.l10n.useThisProductSubtitle,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    SheetOption(
                      'archive',
                      context.l10n.archive,
                      subtitle: context.l10n.archiveSubtitle,
                      icon: AppIcons.archive,
                    ),
                  ],
                );
                if (action != null) await _onMenu(action, provider);
              },
            ),
          ],
        ),
        bottomNavigationBar: _isDirty
            ? SaveBar(
                message: context.l10n.unsavedChanges,
                onCancel: _reload,
                saveLabel: context.l10n.save,
                onSave: _isSaving ? null : _save,
              )
            : null,
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                form: _form,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Scorta ---

class _StockCard extends StatelessWidget {
  final TrackedProduct product;

  const _StockCard({required this.product});

  Future<void> _confirmNewPack(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.newPackTitle),
        content: Text(context.l10n.newPackBody(product.name, product.pieces)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.restock),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context
        .read<MyTrackingProvider>()
        .openNewPack(productId: product.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.stockRestocked)),
    );
  }

  Future<void> _showCorrectDialog(BuildContext context) async {
    final controller = TextEditingController(text: '${product.packRemaining}');
    String? errorText;

    final correctedValue = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.correctStockTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.correctStockBody),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.l10n.unitsLeft,
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
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final rawValue = controller.text.trim();
                if (rawValue.isEmpty) {
                  setDialogState(
                    () => errorText = context.l10n.enterWholeNumber,
                  );
                  return;
                }

                final parsedValue = int.tryParse(rawValue);
                if (parsedValue == null) {
                  setDialogState(
                    () => errorText = context.l10n.enterValidWholeNumber,
                  );
                  return;
                }
                if (parsedValue < 0) {
                  setDialogState(
                    () => errorText = context.l10n.valueNotNegative,
                  );
                  return;
                }
                if (parsedValue > product.pieces) {
                  setDialogState(
                    () => errorText =
                        context.l10n.valueAtMost(product.pieces),
                  );
                  return;
                }

                Navigator.pop(dialogContext, parsedValue);
              },
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future<void>.delayed(kThemeAnimationDuration, controller.dispose),
    );

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
          content: Text(context.l10n.correctStockFailed),
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
                context.l10n.stock,
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
                  onPressed: () => _confirmNewPack(context),
                  style: buttonStyle,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.l10n.restock),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showCorrectDialog(context),
                  style: buttonStyle,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(context.l10n.correct),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
