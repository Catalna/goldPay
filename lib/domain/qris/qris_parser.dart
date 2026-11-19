import 'dart:convert';
import 'dart:typed_data';

import '../../core/math/ceil_div.dart';
import '../entities/qris_parse_result.dart';
import 'crc16.dart';
import 'tlv.dart';

const int _maxPayloadBytes = 1024;

const Set<String> _criticalTags = {'00', '01', '53', '54', '58'};

const Set<String> _knownRootTags = {
  '00',
  '01',
  '52',
  '53',
  '54',
  '55',
  '56',
  '57',
  '58',
  '59',
  '60',
  '61',
  '62',
  '63',
};

final RegExp _amountPattern = RegExp(r'^[0-9]{1,13}(\.[0-9]{1,2})?$');
final RegExp _fixedFeePattern = RegExp(r'^([0-9]{1,13})(?:\.([0-9]{1,2}))?$');
final RegExp _percentPattern = RegExp(r'^([0-9]{1,3})(?:\.([0-9]{1,2}))?$');

/// Reads a QRIS/EMVCo payload. Pure function, never throws on user input.
///
/// It reports what the payload says; it does not verify the merchant, open
/// links, or decide whether the payment is allowed (docs/07 §12).
QrisParseResult parseQris(String payload) {
  final trimmed = payload.trim();
  if (trimmed.isEmpty) {
    return const QrisFailure(QrisErrorCode.emptyPayload);
  }

  final bytes = Uint8List.fromList(utf8.encode(trimmed));
  if (bytes.length > _maxPayloadBytes) {
    return QrisFailure(
      QrisErrorCode.payloadTooLarge,
      detailForDev: '${bytes.length} bytes',
    );
  }

  // A URL or arbitrary text is reported as an unsupported format, while a
  // payload that starts like EMV but is broken gets the specific TLV error.
  if (!trimmed.startsWith('00')) {
    return const QrisFailure(
      QrisErrorCode.unsupportedFormat,
      detailForDev: 'payload does not start with tag 00',
    );
  }

  final root = parseTlv(bytes);
  switch (root) {
    case TlvInvalid(:final kind, :final detail):
      return QrisFailure(
        kind == TlvInvalidKind.truncated
            ? QrisErrorCode.truncatedValue
            : QrisErrorCode.malformedTlv,
        detailForDev: detail,
      );
    case TlvParsed(:final elements):
      return _parseElements(bytes, elements);
  }
}

QrisParseResult _parseElements(
  Uint8List payloadBytes,
  List<TlvElement> elements,
) {
  final warnings = <QrisWarning>{};
  final byTag = <String, TlvElement>{};

  for (final element in elements) {
    final existing = byTag[element.tag];
    if (existing != null) {
      if (_criticalTags.contains(element.tag)) {
        return QrisFailure(
          QrisErrorCode.duplicateCriticalTag,
          detailForDev: 'tag ${element.tag} at offset ${element.offset}',
        );
      }
      warnings.add(QrisWarning.duplicateNonCriticalTag);
      continue;
    }
    byTag[element.tag] = element;
  }

  final format = byTag['00'];
  if (format == null) {
    return const QrisFailure(
      QrisErrorCode.unsupportedFormat,
      detailForDev: 'missing payload format indicator',
    );
  }
  if (_text(format) != '01') {
    return QrisFailure(
      QrisErrorCode.unsupportedFormat,
      detailForDev: 'tag 00 = ${_text(format)}',
    );
  }

  final currency = byTag['53'];
  if (currency != null && _text(currency) != '360') {
    return QrisFailure(
      QrisErrorCode.unsupportedCurrency,
      detailForDev: 'tag 53 = ${_text(currency)}',
    );
  }

  for (final element in elements) {
    if (!_isKnownRootTag(element.tag)) {
      warnings.add(QrisWarning.unknownTagPresent);
    }
  }

  if (byTag['58'] != null && _text(byTag['58']!) != 'ID') {
    warnings.add(QrisWarning.unexpectedCountry);
  }

  var amountIdr = 0;
  final amountElement = byTag['54'];
  if (amountElement != null) {
    final parsed = _parseAmount(_text(amountElement));
    switch (parsed) {
      case _AmountInvalid():
        return QrisFailure(
          QrisErrorCode.invalidAmount,
          detailForDev: 'tag 54 = ${_text(amountElement)}',
        );
      case _AmountZero():
        return const QrisFailure(QrisErrorCode.amountOutOfRange);
      case _AmountOk(:final value):
        amountIdr = value;
    }
  }

  var kind = switch (_textOrNull(byTag['01'])) {
    '11' => QrKind.staticQr,
    '12' => QrKind.dynamicQr,
    _ => QrKind.unknown,
  };
  final hasAmount = amountElement != null;
  if (kind == QrKind.dynamicQr && !hasAmount) {
    kind = QrKind.unknown;
    warnings.add(QrisWarning.dynamicWithoutAmount);
  }

  final qrFeeIdr = _readQrFee(byTag, amountIdr, hasAmount, warnings);

  var crcValid = false;
  final crcElement = byTag['63'];
  if (crcElement == null) {
    warnings.add(QrisWarning.crcMissing);
  } else if (crcElement.offset + crcElement.byteLength != payloadBytes.length) {
    warnings.add(QrisWarning.crcNotLast);
  } else {
    final expected = crc16Hex(payloadBytes.sublist(0, crcElement.offset + 4));
    final actual = String.fromCharCodes(crcElement.value).toUpperCase();
    crcValid = actual == expected;
    if (!crcValid) {
      warnings.add(QrisWarning.crcMismatch);
    }
  }

  final merchantName = _readDisplayValue(byTag['59'], warnings);
  if (merchantName == null) {
    warnings.add(QrisWarning.missingMerchantName);
  }
  final merchantCity = _readDisplayValue(byTag['60'], warnings);

  final issuerGui = _readIssuerGui(byTag, warnings);
  final terminalLabel = _readTerminalLabel(byTag, warnings);

  return QrisSuccess(
    kind: kind,
    amountIdr: hasAmount ? amountIdr : null,
    qrFeeIdr: qrFeeIdr,
    merchantName: merchantName,
    merchantCity: merchantCity,
    merchantIssuerGui: issuerGui,
    terminalLabel: terminalLabel,
    crcValid: crcValid,
    warnings: [
      for (final warning in QrisWarning.values)
        if (warnings.contains(warning)) warning,
    ],
  );
}

bool _isKnownRootTag(String tag) {
  if (_knownRootTags.contains(tag)) return true;
  final number = int.tryParse(tag);
  return number != null && number >= 26 && number <= 51;
}

String _text(TlvElement element) =>
    utf8.decode(element.value, allowMalformed: true);

String? _textOrNull(TlvElement? element) =>
    element == null ? null : _text(element);

sealed class _AmountParse {
  const _AmountParse();
}

final class _AmountOk extends _AmountParse {
  const _AmountOk(this.value);
  final int value;
}

final class _AmountInvalid extends _AmountParse {
  const _AmountInvalid();
}

final class _AmountZero extends _AmountParse {
  const _AmountZero();
}

_AmountParse _parseAmount(String raw) {
  if (!_amountPattern.hasMatch(raw)) return const _AmountInvalid();
  final dot = raw.indexOf('.');
  if (dot >= 0) {
    final fraction = raw.substring(dot + 1);
    if (fraction != '00') return const _AmountInvalid();
  }
  final whole = int.tryParse(dot >= 0 ? raw.substring(0, dot) : raw);
  if (whole == null) return const _AmountInvalid();
  if (whole <= 0) return const _AmountZero();
  return _AmountOk(whole);
}

int _readQrFee(
  Map<String, TlvElement> byTag,
  int amountIdr,
  bool hasAmount,
  Set<QrisWarning> warnings,
) {
  final indicator = _textOrNull(byTag['55']);
  if (indicator == null) {
    if (byTag.containsKey('56') || byTag.containsKey('57')) {
      warnings.add(QrisWarning.tipIncomplete);
    }
    return 0;
  }

  switch (indicator) {
    case '01':
      warnings.add(QrisWarning.tipPromptIgnored);
      return 0;
    case '02':
      final fixed = _textOrNull(byTag['56']);
      final fee = fixed == null ? null : _parseFixedFee(fixed);
      if (fee == null) warnings.add(QrisWarning.tipIncomplete);
      return fee ?? 0;
    case '03':
      final percent = _textOrNull(byTag['57']);
      final hundredths = percent == null
          ? null
          : _parsePercentHundredths(percent);
      if (hundredths == null || !hasAmount) {
        warnings.add(QrisWarning.tipIncomplete);
        return 0;
      }
      return ceilDiv(amountIdr * hundredths, 10000);
    default:
      warnings.add(QrisWarning.tipIncomplete);
      return 0;
  }
}

/// Parses a fixed fee, rounding up to whole rupiah. Returns null if invalid.
int? _parseFixedFee(String raw) {
  final match = _fixedFeePattern.firstMatch(raw);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final fraction = match.group(2);
  if (fraction == null || fraction == '00') return whole;
  return whole + 1;
}

/// `"5"` → 500, `"2.5"` → 250, `"0.05"` → 5. Returns null if invalid.
int? _parsePercentHundredths(String raw) {
  final match = _percentPattern.firstMatch(raw);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final fraction = match.group(2);
  if (fraction == null) return whole * 100;
  final padded = fraction.padRight(2, '0');
  return whole * 100 + int.parse(padded);
}

String? _readDisplayValue(TlvElement? element, Set<QrisWarning> warnings) {
  if (element == null) return null;
  final decoded = utf8.decode(element.value, allowMalformed: true);
  if (_hasReplacementChar(decoded)) {
    warnings.add(QrisWarning.nonAsciiValue);
  }
  final clean = _sanitize(decoded);
  return clean.isEmpty ? null : clean;
}

String? _readIssuerGui(
  Map<String, TlvElement> byTag,
  Set<QrisWarning> warnings,
) {
  for (var tag = 26; tag <= 51; tag++) {
    final element = byTag[tag.toString().padLeft(2, '0')];
    if (element == null) continue;
    final nested = parseTlv(element.value, depth: 1);
    if (nested is TlvInvalid) continue;

    final sub = <String, TlvElement>{};
    for (final child in (nested as TlvParsed).elements) {
      sub.putIfAbsent(child.tag, () => child);
    }
    final guiElement = sub['00'];
    if (guiElement == null) continue;
    final gui = _readDisplayValue(guiElement, warnings);
    if (gui != null) return gui;
  }
  return null;
}

String? _readTerminalLabel(
  Map<String, TlvElement> byTag,
  Set<QrisWarning> warnings,
) {
  final additional = byTag['62'];
  if (additional == null) return null;
  final nested = parseTlv(additional.value, depth: 1);
  if (nested is TlvInvalid) return null;

  final sub = <String, TlvElement>{};
  for (final child in (nested as TlvParsed).elements) {
    sub.putIfAbsent(child.tag, () => child);
  }
  return _readDisplayValue(sub['07'], warnings);
}

/// Trims, removes control/bidi characters, turns line breaks into spaces and
/// collapses runs of whitespace (docs/07 §7).
String _sanitize(String raw) {
  final withoutBreaks = raw
      .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
      .replaceAll(RegExp('[\u0000-\u001F\u007F-\u009F]'), '')
      .replaceAll(RegExp('[\u202A-\u202E\u2066-\u2069]'), '')
      .replaceAll('\uFFFD', '');
  final collapsed = withoutBreaks.replaceAll(RegExp(r'\s{2,}'), ' ');
  return collapsed.trim();
}

bool _hasReplacementChar(String value) => value.contains('\uFFFD');
