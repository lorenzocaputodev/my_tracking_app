import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);

  static const Duration medium = Duration(milliseconds: 250);

  static const Curve curve = Curves.easeOutCubic;
}
