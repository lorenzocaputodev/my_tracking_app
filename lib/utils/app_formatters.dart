import '../l10n/l10n.dart';

String formatDecimal(num value, {int decimals = 2}) {
  final text = value.toStringAsFixed(decimals);
  return L10n.isItalian ? text.replaceAll('.', ',') : text;
}

String formatMoney(
  num amount, {
  int decimals = 2,
}) {
  final number = formatDecimal(amount, decimals: decimals);
  final symbol = L10n.currency.symbol;
  return L10n.isItalian ? '$number $symbol' : '$symbol$number';
}

String formatSignedPercent(double value) {
  final rounded = value.round();
  if (rounded > 0) return '+$rounded%';
  return '$rounded%';
}
