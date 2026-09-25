String formatDecimal(num value, {int decimals = 2}) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

String formatEuro(
  num amount, {
  int decimals = 2,
}) {
  return '${formatDecimal(amount, decimals: decimals)} \u20AC';
}

String formatSignedInt(int value) {
  if (value > 0) return '+$value';
  return '$value';
}

String formatSignedPercent(double value) {
  final rounded = value.round();
  if (rounded > 0) return '+$rounded%';
  return '$rounded%';
}
