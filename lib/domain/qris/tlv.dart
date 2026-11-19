import 'dart:typed_data';

/// One EMVCo TLV element. [value] is a view into the payload bytes.
final class TlvElement {
  const TlvElement({
    required this.tag,
    required this.value,
    required this.offset,
  });

  /// Two ASCII digits.
  final String tag;

  /// Raw value bytes; length is declared by the TLV header, in bytes.
  final Uint8List value;

  /// Byte offset of the tag inside the payload.
  final int offset;

  int get byteLength => 4 + value.length;
}

enum TlvInvalidKind { malformed, truncated }

sealed class TlvOutcome {
  const TlvOutcome();
}

final class TlvParsed extends TlvOutcome {
  const TlvParsed(this.elements);
  final List<TlvElement> elements;
}

final class TlvInvalid extends TlvOutcome {
  const TlvInvalid(this.kind, this.detail);
  final TlvInvalidKind kind;
  final String detail;
}

/// Parses a TLV byte range. Never throws for malformed user input.
///
/// Length is the declared byte count, not `String.length` (docs/07 §2).
/// [depth] guards against nesting deeper than root + one level.
TlvOutcome parseTlv(Uint8List bytes, {int depth = 0}) {
  if (depth > 1) {
    return const TlvInvalid(TlvInvalidKind.malformed, 'nested depth exceeds 1');
  }

  final elements = <TlvElement>[];
  var offset = 0;

  while (offset < bytes.length) {
    if (bytes.length - offset < 4) {
      return TlvInvalid(
        TlvInvalidKind.truncated,
        'only ${bytes.length - offset} bytes left at offset $offset',
      );
    }

    final tagHigh = bytes[offset];
    final tagLow = bytes[offset + 1];
    final lenHigh = bytes[offset + 2];
    final lenLow = bytes[offset + 3];

    if (!_isDigit(tagHigh) || !_isDigit(tagLow)) {
      return TlvInvalid(
        TlvInvalidKind.malformed,
        'tag is not two digits at offset $offset',
      );
    }
    if (!_isDigit(lenHigh) || !_isDigit(lenLow)) {
      return TlvInvalid(
        TlvInvalidKind.malformed,
        'length is not two digits at offset $offset',
      );
    }

    final length = (lenHigh - 0x30) * 10 + (lenLow - 0x30);
    final valueStart = offset + 4;
    final valueEnd = valueStart + length;
    if (valueEnd > bytes.length) {
      return TlvInvalid(
        TlvInvalidKind.truncated,
        'declared $length bytes at offset $offset, '
        'only ${bytes.length - valueStart} available',
      );
    }

    elements.add(
      TlvElement(
        tag: String.fromCharCodes([tagHigh, tagLow]),
        value: Uint8List.sublistView(bytes, valueStart, valueEnd),
        offset: offset,
      ),
    );

    offset = valueEnd;
  }

  return TlvParsed(elements);
}

bool _isDigit(int byte) => byte >= 0x30 && byte <= 0x39;
