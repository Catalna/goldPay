import 'package:flutter/services.dart';

/// Formats rupiah digits as `150.000` while typing. The widget reads the
/// integer from [digitsOnly], never from the formatted string.
final class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final remaining = trimmed.length - i;
      buffer.write(trimmed[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Extracts the integer amount from formatted input such as `Rp1.500.000`.
int parseRupiahDigits(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}
