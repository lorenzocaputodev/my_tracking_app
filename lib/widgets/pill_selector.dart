import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';

/// Selettore a pillole, per poche opzioni brevi.
class PillSelector<T> extends StatelessWidget {
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  const PillSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in options.entries)
            GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: entry.key == value
                      ? context.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: entry.key == value
                        ? colors.onAction
                        : colors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
