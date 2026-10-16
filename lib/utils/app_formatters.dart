import '../l10n/l10n.dart';

String formatDecimal(num value, {int decimals = 2}) {
  final text = value.toStringAsFixed(decimals);
  return L10n.isItalian ? text.replaceAll('.', ',') : text;
}

String formatEuro(
  num amount, {
  int decimals = 2,
}) {
  final number = formatDecimal(amount, decimals: decimals);
  return L10n.isItalian ? '$number \u20AC' : '\u20AC$number';
}

String formatSignedPercent(double value) {
  final rounded = value.round();
  if (rounded > 0) return '+$rounded%';
  return '$rounded%';
}
