import 'package:flutter/material.dart';

@immutable
class AppStatColors extends ThemeExtension<AppStatColors> {
  final Color count;
  final Color average;
  final Color volume;
  final Color cost;
  final Color projection;
  final Color estimate;
  final Color time;
  final Color peak;
  final Color streak;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color danger;

  const AppStatColors({
    required this.count,
    required this.average,
    required this.volume,
    required this.cost,
    required this.projection,
    required this.estimate,
    required this.time,
    required this.peak,
    required this.streak,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.danger,
  });

  static final AppStatColors dark = AppStatColors(
    count: const Color(0xFF00CED1),
    average: const Color(0xFF00B8D4),
    volume: const Color(0xFF348B7B),
    cost: const Color(0xFFB64A63),
    projection: const Color(0xFFA56A13),
    estimate: const Color(0xFFB2842E),
    time: Colors.deepOrangeAccent,
    peak: const Color(0xFF00CED1).withValues(alpha: 0.78),
    streak: Colors.greenAccent.shade700,
    positive: const Color(0xFF19724F),
    negative: const Color(0xFFB06A0E),
    warning: Colors.orangeAccent,
    danger: Colors.redAccent,
  );

  static final AppStatColors light = AppStatColors(
    count: const Color(0xFF00686B),
    average: const Color(0xFF00B8D4),
    volume: const Color(0xFF348B7B),
    cost: const Color(0xFFB64A63),
    projection: const Color(0xFFA56A13),
    estimate: const Color(0xFFB2842E),
    time: Colors.deepOrangeAccent,
    peak: const Color(0xFF2D6D72),
    streak: Colors.greenAccent.shade700,
    positive: const Color(0xFF19724F),
    negative: const Color(0xFFB06A0E),
    warning: Colors.orangeAccent,
    danger: Colors.redAccent,
  );

  @override
  AppStatColors copyWith({
    Color? count,
    Color? average,
    Color? volume,
    Color? cost,
    Color? projection,
    Color? estimate,
    Color? time,
    Color? peak,
    Color? streak,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? danger,
  }) {
    return AppStatColors(
      count: count ?? this.count,
      average: average ?? this.average,
      volume: volume ?? this.volume,
      cost: cost ?? this.cost,
      projection: projection ?? this.projection,
      estimate: estimate ?? this.estimate,
      time: time ?? this.time,
      peak: peak ?? this.peak,
      streak: streak ?? this.streak,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppStatColors lerp(ThemeExtension<AppStatColors>? other, double t) {
    if (other is! AppStatColors) return this;
    return t < 0.5 ? this : other;
  }
}
