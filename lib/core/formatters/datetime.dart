import 'package:intl/intl.dart';

/// `19 Nov 2026, 14.05` — local time, Indonesian month names (docs/18 §11).
String formatDateTimeId(DateTime value) {
  final local = value.toLocal();
  return DateFormat("d MMM yyyy, HH.mm", 'id_ID').format(local);
}

/// `14.05` — used by the quote countdown header.
String formatTimeId(DateTime value) {
  return DateFormat('HH.mm', 'id_ID').format(value.toLocal());
}
