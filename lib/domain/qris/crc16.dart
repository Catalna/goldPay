import 'dart:typed_data';

/// CRC-16/CCITT-FALSE: poly 0x1021, init 0xFFFF, no reflection, xorout 0.
///
/// Used only as an integrity check of the QR payload, never as proof that a
/// merchant is genuine (docs/07 §6).
int crc16CcittFalse(List<int> bytes) {
  var crc = 0xFFFF;
  for (final byte in bytes) {
    crc ^= byte << 8;
    for (var bit = 0; bit < 8; bit++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc;
}

/// Four uppercase hex characters, as required by tag 63.
String crc16Hex(List<int> bytes) =>
    crc16CcittFalse(bytes).toRadixString(16).toUpperCase().padLeft(4, '0');

/// Convenience wrapper used by the parser.
String crc16HexOf(Uint8List bytes) => crc16Hex(bytes);
