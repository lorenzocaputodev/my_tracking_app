import 'package:flutter/material.dart';

import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';

/// Barra fissa in fondo ai moduli. Con [message] e [onCancel] mostra
/// "Modifiche non salvate · Annulla · Salva"; senza, solo il pulsante a
/// tutta larghezza.
class SaveBar extends StatelessWidget {
  final String saveLabel;
  final VoidCallback? onSave;
  final String? message;
  final VoidCallback? onCancel;

  const SaveBar({
    super.key,
    required this.saveLabel,
    required this.onSave,
    this.message,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = FilledButton(
      onPressed: onSave,
      style: FilledButton.styleFrom(
        backgroundColor: colors.action,
        foregroundColor: colors.onAction,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
      child: Text(
        saveLabel,
        style: const TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: message == null
              ? SizedBox(width: double.infinity, child: button)
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        message!,
                        style: TextStyle(
                          fontFamily: AppFonts.sans,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('Annulla'),
                      ),
                    const SizedBox(width: 8),
                    button,
                  ],
                ),
        ),
      ),
    );
  }
}
