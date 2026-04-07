String formatEuro(
  num amount, {
  int decimals = 2,
}) {
  return '\u20AC${amount.toStringAsFixed(decimals)}';
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
