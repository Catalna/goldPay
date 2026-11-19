import 'package:intl/intl.dart';

import '../constants/units.dart';

final NumberFormat _wholeNumber = NumberFormat.decimalPattern('id_ID');

/// Formats integer gold units as `0,1021 g`, without ever using `double`.
///
/// The displayed value is derived from the same integer that gets deducted,
/// so "what you see" always equals "what is stored" (docs/00 D-11, D-12).
String formatGoldUnits(int units) {
  final isNegative = units < 0;
  final absolute = units.abs();
  final whole = _wholeNumber.format(absolute ~/ kGoldUnitsPerGram);
  final fraction = (absolute % kGoldUnitsPerGram).toString().padLeft(4, '0');
  return '${isNegative ? '-' : ''}$whole,$fraction g';
}

/// Parses user input such as `1,25` or `0.0001` into integer units of
/// 0,0001 g. Returns null for anything that is not a non-negative number with
/// at most four decimals, so the caller can show a validation message.
int? parseGoldGramsToUnits(String input) {
  final text = input.trim().replaceAll(',', '.');
  final match = RegExp(r'^([0-9]{1,7})(?:\.([0-9]{1,4}))?$').firstMatch(text);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(4, '0');
  return whole * kGoldUnitsPerGram + int.parse(fraction);
}
