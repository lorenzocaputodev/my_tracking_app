import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tracked_product.dart';
import '../providers/my_tracking_provider.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../widgets/settings_rows.dart';
import '../theme/app_icons.dart';
import '../l10n/l10n.dart';

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
    _showFeedback(context, context.l10n.productRestored(product.name));
  }

  Future<void> _delete(
    BuildContext context,
    MyTrackingProvider provider,
    TrackedProduct product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deletePermanentlyTitle),
        content: Text(context.l10n.deletePermanentlyBody(product.name)),
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
    if (confirmed != true || !context.mounted) return;
    await provider.deleteArchivedProduct(product.id);
    if (!context.mounted) return;
    _showFeedback(
      context,
      context.l10n.productDeleted(product.name),
      color: context.stats.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTrackingProvider>();
    final archived = provider.archivedProducts;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.archivedTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              context.l10n.archivedIntro,
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
                  context.l10n.noArchivedProducts,
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
                    subtitle: context.l10n.historyKept,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _restore(context, provider, product),
                          child: Text(context.l10n.restore),
                        ),
                        IconButton(
                          tooltip: context.l10n.deletePermanently,
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
