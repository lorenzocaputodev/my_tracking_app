import 'package:flutter/widgets.dart';

import '../models/pack_config.dart';
import '../models/tracked_product.dart';
import '../utils/app_formatters.dart';
import '../utils/minutes_presets.dart';

// --- Stato del form prodotto ---

class ProductFormState {
  final name = TextEditingController();
  final packCost = TextEditingController();
  final pieces = TextEditingController();
  final directCost = TextEditingController();
  final minutes = TextEditingController(text: '0');

  int dailyGoal = 10;
  bool tracksInventory = true;
  int? selectedPresetMinutes = 0;
  bool minutesCustomMode = false;

  static double? _decimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void load(TrackedProduct product) {
    name.text = product.name;
    packCost.text = formatDecimal(product.totalCost);
    pieces.text = '${product.pieces}';
    directCost.text = product.directUnitCost == null
        ? ''
        : formatDecimal(product.directUnitCost!);
    minutes.text = '${product.minutesLost}';
    dailyGoal = product.dailyLimit;
    tracksInventory = product.tracksInventory;
    selectedPresetMinutes = presetForMinutes(product.minutesLost)?.minutes;
    minutesCustomMode = selectedPresetMinutes == null;
  }

  String get snapshot => [
        name.text.trim(),
        packCost.text.trim(),
        pieces.text.trim(),
        directCost.text.trim(),
        minutes.text.trim(),
        dailyGoal,
        tracksInventory,
      ].join('|');

  bool get isValid {
    final minutesValue = int.tryParse(minutes.text.trim());
    if (name.text.trim().isEmpty || minutesValue == null || minutesValue < 0) {
      return false;
    }
    if (tracksInventory) {
      final cost = _decimal(packCost.text);
      final count = int.tryParse(pieces.text.trim());
      return cost != null && cost > 0 && count != null && count > 0;
    }
    if (directCost.text.trim().isEmpty) return true;
    final parsed = _decimal(directCost.text);
    return parsed != null && parsed >= 0;
  }

  void selectMinutesPreset(int value) {
    if (value == customMinutesPresetValue) {
      minutesCustomMode = true;
      selectedPresetMinutes = null;
      if (presetForMinutes(int.tryParse(minutes.text.trim()) ?? -999) !=
          null) {
        minutes.clear();
      }
    } else {
      minutesCustomMode = false;
      selectedPresetMinutes = value;
      minutes.text = '$value';
    }
  }

  PackConfig toConfig() => PackConfig(
        name: name.text.trim(),
        totalCost: _decimal(packCost.text) ?? 0,
        pieces: int.tryParse(pieces.text.trim()) ?? 20,
        minutesLost: int.parse(minutes.text.trim()),
        dailyLimit: dailyGoal,
        tracksInventory: tracksInventory,
        directUnitCost:
            directCost.text.trim().isEmpty ? null : _decimal(directCost.text),
      );

  TrackedProduct toNewProduct() {
    final config = toConfig();
    return TrackedProduct.createNew(
      name: config.name,
      totalCost: config.totalCost,
      pieces: config.pieces,
      minutesLost: config.minutesLost,
      dailyLimit: config.dailyLimit,
      tracksInventory: config.tracksInventory,
      directUnitCost: config.directUnitCost,
    );
  }

  void dispose() {
    name.dispose();
    packCost.dispose();
    pieces.dispose();
    directCost.dispose();
    minutes.dispose();
  }
}
