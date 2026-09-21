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
      expect(c.cardBorder, Colors.black.withValues(alpha: 0.10));
      expect(c.subtleBorder, Colors.black.withValues(alpha: 0.06));
      expect(
        c.subtleBorder.a,
        lessThan(c.cardBorder.a),
        reason: 'il bordo sottile deve essere piu leggero di quello normale',
      );
      expect(c.textPrimary, const Color(0xFF132222));
      expect(c.textMuted, const Color(0xFF556B6D));
      expect(c.textFaint, const Color(0xFF607274));
      expect(c.inputFill, const Color(0xFFE8F0F0));
    });
  });

  group('tavolozza statistiche', () {
    test('ogni ruolo ha una variante distinta per tema', () {
      const d = AppStatColors.dark;
      const l = AppStatColors.light;
      final pairs = <String, List<Color>>{
        'average': [d.average, l.average],
        'volume': [d.volume, l.volume],
        'cost': [d.cost, l.cost],
        'projection': [d.projection, l.projection],
        'estimate': [d.estimate, l.estimate],
        'time': [d.time, l.time],
        'streak': [d.streak, l.streak],
      };
      pairs.forEach((role, colors) {
        expect(colors[0], isNot(colors[1]), reason: '$role non e differenziato');
      });
    });

    test('le varianti scure sono piu chiare di quelle chiare', () {
      const d = AppStatColors.dark;
      const l = AppStatColors.light;
      final pairs = <String, List<Color>>{
        'cost': [d.cost, l.cost],
        'projection': [d.projection, l.projection],
        'estimate': [d.estimate, l.estimate],
        'average': [d.average, l.average],
        'volume': [d.volume, l.volume],
        'time': [d.time, l.time],
      };
      pairs.forEach((role, colors) {
        expect(
          colors[0].computeLuminance(),
          greaterThan(colors[1].computeLuminance()),
          reason: '$role: la variante scura deve reggere su fondo scuro',
        );
      });
    });

    test('i valori attuali sono ancorati', () {
      expect(AppStatColors.dark.cost, const Color(0xFFE3A857));
      expect(AppStatColors.light.cost, const Color(0xFF9A6B1E));
      expect(AppStatColors.dark.time, const Color(0xFFE8836B));
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
