import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_tracking_app/theme/app_colors.dart';
import 'package:my_tracking_app/theme/app_dimens.dart';
import 'package:my_tracking_app/theme/app_fonts.dart';
import 'package:my_tracking_app/theme/app_stat_colors.dart';
import 'package:my_tracking_app/theme/app_theme.dart';

void main() {
  group('superfici', () {
    test('tema scuro', () {
      final c = AppColors.dark;
      expect(c.scaffold, const Color(0xFF0A0A0A));
      expect(c.surface, const Color(0xFF161B1B));
      expect(c.surfaceElevated, const Color(0xFF1C1C1E));
      expect(c.surfaceSunken, const Color(0xFF1E2A2A));
      expect(c.cardBorder, Colors.white.withValues(alpha: 0.05));
      expect(c.subtleBorder, Colors.white.withValues(alpha: 0.03));
      expect(c.textPrimary, Colors.white);
      expect(c.textMuted, Colors.grey);
      expect(c.textFaint, Colors.white38);
      expect(c.inputFill, Colors.white.withValues(alpha: 0.06));
    });

    test('tema chiaro', () {
      final c = AppColors.light;
      expect(c.scaffold, const Color(0xFFF3F7F7));
      expect(c.surface, Colors.white);
      expect(c.cardBorder, Colors.black.withValues(alpha: 0.05));
      expect(c.subtleBorder, Colors.black.withValues(alpha: 0.06));
      expect(c.textPrimary, const Color(0xFF132222));
      expect(c.textMuted, const Color(0xFF556B6D));
      expect(c.textFaint, const Color(0xFF607274));
      expect(c.inputFill, const Color(0xFFE8F0F0));
    });
  });

  group('tavolozza statistiche', () {
    test('i ruoli condivisi coincidono fra i due temi', () {
      expect(AppStatColors.dark.average, AppStatColors.light.average);
      expect(AppStatColors.dark.volume, AppStatColors.light.volume);
      expect(AppStatColors.dark.cost, AppStatColors.light.cost);
      expect(AppStatColors.dark.projection, AppStatColors.light.projection);
      expect(AppStatColors.dark.estimate, AppStatColors.light.estimate);
      expect(AppStatColors.dark.positive, AppStatColors.light.positive);
      expect(AppStatColors.dark.negative, AppStatColors.light.negative);
    });

    test('i valori attuali sono ancorati', () {
      expect(AppStatColors.dark.average, const Color(0xFF00B8D4));
      expect(AppStatColors.dark.volume, const Color(0xFF348B7B));
      expect(AppStatColors.dark.cost, const Color(0xFFB64A63));
      expect(AppStatColors.dark.projection, const Color(0xFFA56A13));
      expect(AppStatColors.dark.estimate, const Color(0xFFB2842E));
      expect(AppStatColors.dark.positive, const Color(0xFF19724F));
      expect(AppStatColors.dark.negative, const Color(0xFFB06A0E));
      expect(AppStatColors.light.peak, const Color(0xFF2D6D72));
      expect(AppStatColors.dark.count, AppTheme.darkPrimary);
      expect(AppStatColors.light.count, AppTheme.lightPrimary);
    });
  });

  group('dimensioni e font', () {
    test('raggi', () {
      expect(AppRadii.chip, 12);
      expect(AppRadii.field, 14);
      expect(AppRadii.card, 20);
      expect(AppRadii.sheet, 24);
    });

    test('famiglie', () {
      expect(AppFonts.sans, 'DM Sans');
      expect(AppFonts.display, 'Nunito');
    });
  });

  group('tema', () {
    test('espone entrambe le extension', () {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.of(brightness);
        expect(theme.extension<AppColors>(), isNotNull);
        expect(theme.extension<AppStatColors>(), isNotNull);
      }
    });

    test('le extension corrispondono alla brightness', () {
      expect(
        AppTheme.of(Brightness.dark).extension<AppColors>()!.surface,
        AppColors.dark.surface,
      );
      expect(
        AppTheme.of(Brightness.light).extension<AppColors>()!.surface,
        AppColors.light.surface,
      );
    });

    test('lerp commuta di scatto, senza dissolvenza', () {
      final a = AppColors.dark;
      final b = AppColors.light;
      expect(a.lerp(b, 0.2).surface, a.surface);
      expect(a.lerp(b, 0.8).surface, b.surface);
    });

    test('la barra di stato segue il tema', () {
      expect(
        AppTheme.of(Brightness.light).appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.dark,
      );
      expect(
        AppTheme.of(Brightness.dark).appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.light,
      );
    });
  });
}
