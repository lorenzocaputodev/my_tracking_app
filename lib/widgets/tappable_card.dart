import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';
import '../theme/app_dimens.dart';
import '../theme/theme_context.dart';

/// Card con righe toccabili. L'evidenziazione del tocco (InkWell) si
/// disegna sul primo Material sopra di lei: senza un Material dentro il
/// ritaglio arrotondato finirebbe sullo sfondo della pagina e sborderebbe
/// negli angoli della card.
class TappableCard extends StatelessWidget {
  final Widget child;
  const TappableCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.cardSubtle(context.colors),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}
