import 'package:intl/intl.dart';

final NumberFormat _decimalPattern = NumberFormat.decimalPattern('id_ID');

/// `Rp150.000` — no space, no decimals (docs/18_UI_COPY_ID.md §11).
String formatRupiah(int amountIdr) {
  final digits = _decimalPattern.format(amountIdr.abs());
  return amountIdr < 0 ? '-Rp$digits' : 'Rp$digits';
}
