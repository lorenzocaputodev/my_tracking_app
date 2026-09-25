import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_tracking_app/theme/app_colors.dart';
import 'package:my_tracking_app/theme/app_stat_colors.dart';

/// Il widget Android e' nativo e non legge le ThemeExtension: replica i token
/// del tema scuro in `values/colors.xml`. Questa e' la corrispondenza.
final Map<String, Color> _widgetTokens = {
  'widget_scaffold': AppColors.dark.scaffold,
  'widget_surface': AppColors.dark.surface,
  'widget_surface_inset': AppColors.dark.surfaceInset,
  'widget_border': AppColors.dark.cardBorder,
  'widget_text_primary': AppColors.dark.textPrimary,
  'widget_text_muted': AppColors.dark.textMuted,
  'widget_text_faint': AppColors.dark.textFaint,
  'widget_action': AppColors.dark.action,
  'widget_on_action': AppColors.dark.onAction,
  'widget_count': AppStatColors.dark.count,
};

const _res = 'android/app/src/main/res';

Map<String, int> _readAndroidColors() {
  final xml = File('$_res/values/colors.xml').readAsStringSync();
  final pattern = RegExp(r'<color name="(\w+)">#([0-9A-Fa-f]{6,8})</color>');
  return {
    for (final m in pattern.allMatches(xml))
      m.group(1)!: int.parse(
        m.group(2)!.length == 6 ? 'FF${m.group(2)}' : m.group(2)!,
        radix: 16,
      ),
  };
}

void main() {
  test('ogni colore del widget coincide con il suo token Dart', () {
    final android = _readAndroidColors();
    _widgetTokens.forEach((name, token) {
      expect(android.containsKey(name), isTrue, reason: '$name manca in colors.xml');
      expect(
        android[name]!.toRadixString(16).toUpperCase(),
        token.toARGB32().toRadixString(16).toUpperCase(),
        reason: '$name non corrisponde al token Dart',
      );
    });
  });

  test('layout e drawable del widget non usano colori letterali', () {
    final files = [
      ...Directory('$_res/layout')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('widget')),
      ...Directory('$_res/drawable')
          .listSync()
          .whereType<File>()
          .where((f) => f.uri.pathSegments.last.startsWith('widget_')),
    ];
    expect(files, isNotEmpty);

    final literal = RegExp(r'android:(color|textColor|background)="#');
    for (final file in files) {
      expect(
        literal.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} contiene un colore letterale',
      );
    }
  });
}
