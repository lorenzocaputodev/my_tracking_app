import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

class SettingsSectionLabel extends StatelessWidget {
  final String text;

  /// Rientro a sinistra: 4 sopra una card, 0 in un modulo, dove le altre
  /// etichette partono dal bordo.
  final double inset;

  const SettingsSectionLabel(this.text, {super.key, this.inset = 4});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 28, 0, 10),
      child: Text(text, style: AppTextStyles.sectionLabel(context.accent)),
    );
  }
}

/// Card che raccoglie piu' righe, separate da un filo.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  /// Il filo parte dal testo: 56 con l'icona a sinistra, 16 senza.
  final double dividerIndent;

  const SettingsGroup({
    super.key,
    required this.children,
    this.dividerIndent = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.cardSubtle(colors),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: dividerIndent,
                color: colors.subtleBorder,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;

  /// Senza trailing la riga mostra una freccia se e' toccabile.
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;
  final bool enabled;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = color ?? context.accent;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: AppAlphas.accentMuted),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(width: 12),
          ] else
            const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color ?? colors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: colors.textFaint),
        ],
      ),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(onTap: enabled ? onTap : null, child: row),
    );
  }
}
