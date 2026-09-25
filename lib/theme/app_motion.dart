import 'package:flutter/animation.dart';

/// Tempi e curve delle animazioni, uguali in tutta l'app.
abstract final class AppMotion {
  /// Cambi di stato piccoli: una pillola, una freccia che ruota.
  static const Duration fast = Duration(milliseconds: 180);

  /// Contenuti che cambiano o si aprono: un elenco, una sezione.
  static const Duration medium = Duration(milliseconds: 250);

  static const Curve curve = Curves.easeOutCubic;
}
