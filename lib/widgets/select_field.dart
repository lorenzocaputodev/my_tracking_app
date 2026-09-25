import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import 'option_sheet.dart';

/// Campo di scelta con l'aspetto dei campi di testo: al tocco apre
/// [showOptionSheet] invece del menu a tendina Material.
class SelectField<T> extends StatelessWidget {
  final IconData icon;
  final String sheetTitle;
  final List<SheetOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  const SelectField({
    super.key,
    required this.icon,
    required this.sheetTitle,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = options.where((o) => o.value == value);
    final label = current.isEmpty
        ? ''
        : current.first.fieldLabel ?? current.first.label;

    return Material(
      color: colors.inputFill,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.field),
        onTap: () async {
          final picked = await showOptionSheet<T>(
            context,
            title: sheetTitle,
            options: options,
            selected: value,
          );
          if (picked != null && picked != value) onChanged(picked);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.textMuted),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: context.accent),
            ],
          ),
        ),
      ),
    );
  }
}
