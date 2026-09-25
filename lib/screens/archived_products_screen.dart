import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../widgets/settings_rows.dart';
import '../theme/app_icons.dart';

class ArchivedProductsScreen extends StatelessWidget {
  const ArchivedProductsScreen({super.key});

  void _showFeedback(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _restore(
    BuildContext context,
    MyTrackingProvider provider,
    TrackedProduct product,
  ) async {
    await provider.restoreProduct(product.id);
    if (!context.mounted) return;
    _showFeedback(context, '${product.name} ripristinato');
  }

  Future<void> _delete(
    BuildContext context,
    MyTrackingProvider provider,
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
              backgroundColor: context.stats.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await provider.deleteArchivedProduct(product.id);
    if (!context.mounted) return;
    _showFeedback(
      context,
      '${product.name} eliminato definitivamente',
      color: context.stats.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTrackingProvider>();
    final archived = provider.archivedProducts;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Archiviati')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'I prodotti archiviati non compaiono in home, ma la loro '
              'cronologia resta. Ripristinandoli tornano come prima.',
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 13,
                color: colors.textMuted,
              ),
            ),
          ),
          if (archived.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  'Nessun prodotto archiviato',
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    color: colors.textFaint,
                  ),
                ),
              ),
            )
          else
            SettingsGroup(
              children: [
                for (final product in archived)
                  SettingsRow(
                    icon: AppIcons.archive,
                    title: product.name,
                    subtitle: 'Storico conservato',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _restore(context, provider, product),
                          child: const Text('Ripristina'),
                        ),
                        IconButton(
                          tooltip: 'Elimina definitivamente',
                          onPressed: () => _delete(context, provider, product),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: context.stats.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
