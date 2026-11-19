/// Parser result types (docs/07 §1). Pure data, no Flutter imports.
library;

/// QR kind as declared by tag 01. Names avoid Dart reserved words.
enum QrKind {
  staticQr,
  dynamicQr,
  unknown;

  /// Value used in docs, tests and receipts.
  String get wireName => switch (this) {
    QrKind.staticQr => 'static',
    QrKind.dynamicQr => 'dynamic',
    QrKind.unknown => 'unknown',
  };
}

enum QrisErrorCode {
  emptyPayload('EMPTY_PAYLOAD'),
  payloadTooLarge('PAYLOAD_TOO_LARGE'),
  malformedTlv('MALFORMED_TLV'),
  truncatedValue('TRUNCATED_VALUE'),
  duplicateCriticalTag('DUPLICATE_CRITICAL_TAG'),
  unsupportedFormat('UNSUPPORTED_FORMAT'),
  unsupportedCurrency('UNSUPPORTED_CURRENCY'),
  invalidAmount('INVALID_AMOUNT'),
  amountOutOfRange('AMOUNT_OUT_OF_RANGE');

  const QrisErrorCode(this.code);
  final String code;
}

enum QrisWarning {
  crcMismatch('CRC_MISMATCH'),
  crcMissing('CRC_MISSING'),
  crcNotLast('CRC_NOT_LAST'),
  tipPromptIgnored('TIP_PROMPT_IGNORED'),
  tipIncomplete('TIP_INCOMPLETE'),
  missingMerchantName('MISSING_MERCHANT_NAME'),
  unknownTagPresent('UNKNOWN_TAG_PRESENT'),
  duplicateNonCriticalTag('DUPLICATE_NON_CRITICAL_TAG'),
  nonAsciiValue('NON_ASCII_VALUE'),
  unexpectedCountry('UNEXPECTED_COUNTRY'),
  dynamicWithoutAmount('DYNAMIC_WITHOUT_AMOUNT');

  const QrisWarning(this.code);
  final String code;
}

sealed class QrisParseResult {
  const QrisParseResult();
}

final class QrisSuccess extends QrisParseResult {
  const QrisSuccess({
    required this.kind,
    required this.amountIdr,
    required this.qrFeeIdr,
    required this.merchantName,
    required this.merchantCity,
    required this.merchantIssuerGui,
    required this.terminalLabel,
    required this.crcValid,
    required this.warnings,
  });

  final QrKind kind;

  /// Null when the QR does not carry tag 54.
  final int? amountIdr;

  /// Tip/convenience fee written in the QR (tags 55/56/57), in rupiah.
  final int qrFeeIdr;

  final String? merchantName;
  final String? merchantCity;

  /// GUI from sub-tag 00 of a merchant account template (26–51).
  final String? merchantIssuerGui;

  /// Terminal label from tag 62 sub-tag 07.
  final String? terminalLabel;

  final bool crcValid;
  final List<QrisWarning> warnings;

  bool get isAmountReadOnly => kind == QrKind.dynamicQr && amountIdr != null;
}

final class QrisFailure extends QrisParseResult {
  const QrisFailure(this.code, {this.detailForDev = ''});

  final QrisErrorCode code;

  /// Debug only. Never render this to users (docs/07 §1).
  final String detailForDev;
}
