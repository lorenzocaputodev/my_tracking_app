import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'settings_rows.dart';

class SheetOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  /// Testo nel campo chiuso, se diverso da [label].
  final String? fieldLabel;

  const SheetOption(
    this.value,
    this.label, {
    this.subtitle,
    this.icon,
    this.fieldLabel,
  });
}

/// Scelta da un elenco, dal basso, con le stesse righe delle impostazioni.
/// Unico modo di scegliere fra opzioni nell'app: prodotto in uso, filtro
/// della cronologia, frequenza del promemoria, minuti di vita persi.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final accent = ctx.accent;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
                  child: Text(
                    title.toUpperCase(),
                    style: AppTextStyles.sectionLabel(accent),
                  ),
                ),
                SettingsGroup(
                  dividerIndent: options.any((o) => o.icon != null) ? 56 : 16,
                  children: [
                    for (final option in options)
                      SettingsRow(
                        icon: option.icon,
                        title: option.label,
                        subtitle: option.subtitle,
                        onTap: () => Navigator.pop(ctx, option.value),
                        trailing: option.value == selected
                            ? Icon(Icons.check_rounded, color: accent)
                            : const SizedBox(width: 24),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
