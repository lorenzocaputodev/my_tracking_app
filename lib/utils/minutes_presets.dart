class MinutesPreset {
  final String label;
  final int minutes;

  const MinutesPreset(this.label, this.minutes);
}

const int customMinutesPresetValue = -1;

const List<MinutesPreset> minutesPresets = [
  MinutesPreset('0 — disabilita conteggio vita persa', 0),
  MinutesPreset('Sigaretta — 11 min (stima)', 11),
  MinutesPreset('Sigaretta elettronica — 5 min (stima)', 5),
  MinutesPreset('Riscaldatore di tabacco — 6 min (stima)', 6),
  MinutesPreset('Sigaro — 30 min (stima)', 30),
  MinutesPreset('Narghilè (sessione) — 20 min (stima)', 20),
];

MinutesPreset? presetForMinutes(int minutes) {
  for (final preset in minutesPresets) {
    if (preset.minutes == minutes) return preset;
  }
  return null;
}

bool isPresetMinutesValue(int minutes) => presetForMinutes(minutes) != null;
