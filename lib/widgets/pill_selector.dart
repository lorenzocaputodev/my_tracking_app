import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/app_motion.dart';
import '../theme/theme_context.dart';

/// Selettore a pillole, per poche opzioni brevi. La scelta usa il colore
/// d'azione dell'app, lo stesso di "HO USATO" e di "Salva", leggibile in
/// entrambi i temi.
class PillSelector<T> extends StatelessWidget {
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Occupa tutta la larghezza, dividendola in parti uguali.
  final bool expand;

  const PillSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget pill(MapEntry<T, String> entry) {
      final selected = entry.key == value;
      return GestureDetector(
        onTap: () => onChanged(entry.key),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          alignment: expand ? Alignment.center : null,
          padding: EdgeInsets.symmetric(
            horizontal: 11,
            vertical: expand ? 9 : 6,
          ),
          decoration: BoxDecoration(
            color:
                selected ? colors.action : colors.action.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            style: TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: expand ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: selected ? colors.onAction : colors.textMuted,
            ),
            child: Text(entry.value, maxLines: 1),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final entry in options.entries)
            expand ? Expanded(child: pill(entry)) : pill(entry),
        ],
      ),
    );
  }
}
