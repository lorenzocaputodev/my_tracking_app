class MinutesPreset {
  final int minutes;

  const MinutesPreset(this.minutes);
}

const int customMinutesPresetValue = -1;

const List<MinutesPreset> minutesPresets = [
  MinutesPreset(0),
  MinutesPreset(11),
  MinutesPreset(5),
  MinutesPreset(6),
  MinutesPreset(30),
  MinutesPreset(20),
];

MinutesPreset? presetForMinutes(int minutes) {
  for (final preset in minutesPresets) {
    if (preset.minutes == minutes) return preset;
  }
  return null;
}
