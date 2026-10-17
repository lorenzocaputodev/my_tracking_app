import 'package:flutter/material.dart';

@immutable
class AppStatColors extends ThemeExtension<AppStatColors> {
  final Color count;
  final Color average;
  final Color volume;
  final Color peak;
  final Color streak;
  final Color cost;
  final Color projection;
  final Color estimate;
  final Color time;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color danger;
  final Color onDanger;

  const AppStatColors({
    required this.count,
    required this.average,
    required this.volume,
    required this.peak,
    required this.streak,
    required this.cost,
    required this.projection,
    required this.estimate,
    required this.time,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.danger,
    required this.onDanger,
  });

  static const AppStatColors dark = AppStatColors(
    count: Color(0xFF00CED1),
    average: Color(0xFF45C7D6),
    volume: Color(0xFF5FBFA8),
    peak: Color(0xFF2FA8AC),
    streak: Color(0xFF57C98A),
    cost: Color(0xFFE3A857),
    projection: Color(0xFFC8924B),
    estimate: Color(0xFFB8863F),
    time: Color(0xFFE8836B),
    positive: Color(0xFF4CAF7D),
    negative: Color(0xFFD99A4E),
    warning: Color(0xFFE0A64A),
    danger: Color(0xFFE5736B),
    onDanger: Color(0xFFFFFFFF),
  );

  static const AppStatColors light = AppStatColors(
    count: Color(0xFF00686B),
    average: Color(0xFF0E7C8C),
    volume: Color(0xFF2F7A69),
    peak: Color(0xFF2D6D72),
    streak: Color(0xFF1E7A4E),
    cost: Color(0xFF9A6B1E),
    projection: Color(0xFF86601F),
    estimate: Color(0xFF745420),
    time: Color(0xFFB5523A),
    positive: Color(0xFF19724F),
    negative: Color(0xFFB06A0E),
    warning: Color(0xFFC4761A),
    danger: Color(0xFFC0392B),
    onDanger: Color(0xFFFFFFFF),
  );

  @override
  AppStatColors copyWith({
    Color? count,
    Color? average,
    Color? volume,
    Color? peak,
    Color? streak,
    Color? cost,
    Color? projection,
    Color? estimate,
    Color? time,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? danger,
    Color? onDanger,
  }) {
    return AppStatColors(
      count: count ?? this.count,
      average: average ?? this.average,
      volume: volume ?? this.volume,
      peak: peak ?? this.peak,
      streak: streak ?? this.streak,
      cost: cost ?? this.cost,
      projection: projection ?? this.projection,
      estimate: estimate ?? this.estimate,
      time: time ?? this.time,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
    );
  }

  @override
  AppStatColors lerp(ThemeExtension<AppStatColors>? other, double t) {
    if (other is! AppStatColors) return this;
    return t < 0.5 ? this : other;
  }
}
