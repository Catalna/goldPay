import '../../../core/constants/copy_id.dart';
import '../../../core/constants/payment_source.dart';
import '../../../domain/entities/qris_parse_result.dart';

/// Maps domain values to the canonical copy. Widgets never build these
/// strings themselves (AGENTS.md).
String qrisErrorCopy(QrisErrorCode code) => switch (code) {
  QrisErrorCode.emptyPayload => CopyId.errorEmptyPayload,
  QrisErrorCode.payloadTooLarge => CopyId.errorPayloadTooLarge,
  QrisErrorCode.malformedTlv => CopyId.errorMalformedTlv,
  QrisErrorCode.truncatedValue => CopyId.errorTruncatedValue,
  QrisErrorCode.duplicateCriticalTag => CopyId.errorDuplicateCriticalTag,
  QrisErrorCode.unsupportedFormat => CopyId.errorUnsupportedFormat,
  QrisErrorCode.unsupportedCurrency => CopyId.errorUnsupportedCurrency,
  QrisErrorCode.invalidAmount => CopyId.errorInvalidAmount,
  QrisErrorCode.amountOutOfRange => CopyId.errorAmountOutOfRange,
};

String qrisWarningCopy(String code) => switch (code) {
  'CRC_MISMATCH' => CopyId.warningCrcMismatch,
  'CRC_MISSING' => CopyId.warningCrcMissing,
  'CRC_NOT_LAST' => CopyId.warningCrcNotLast,
  'TIP_PROMPT_IGNORED' => CopyId.warningTipPromptIgnored,
  'TIP_INCOMPLETE' => CopyId.warningTipIncomplete,
  'MISSING_MERCHANT_NAME' => CopyId.warningMissingMerchantName,
  'UNKNOWN_TAG_PRESENT' => CopyId.warningUnknownTagPresent,
  'DUPLICATE_NON_CRITICAL_TAG' => CopyId.warningDuplicateNonCriticalTag,
  'NON_ASCII_VALUE' => CopyId.warningNonAsciiValue,
  'UNEXPECTED_COUNTRY' => CopyId.warningUnexpectedCountry,
  'DYNAMIC_WITHOUT_AMOUNT' => CopyId.warningDynamicWithoutAmount,
  _ => CopyId.warningUnknownTagPresent,
};

String qrKindCopy(String wireName) => switch (wireName) {
  'static' => CopyId.valueQrTypeStatic,
  'dynamic' => CopyId.valueQrTypeDynamic,
  _ => CopyId.valueQrTypeUnknown,
};

String sourceCopy(String wireName) => switch (wireName) {
  PaymentSource.camera => CopyId.valueSourceCamera,
  PaymentSource.paste => CopyId.valueSourcePaste,
  PaymentSource.gallery => CopyId.valueSourceGallery,
  _ => CopyId.valueSourcePaste,
};

String merchantNameCopy(String? name) => name ?? CopyId.valueMerchantUnknown;
String merchantCityCopy(String? city) => city ?? CopyId.valueCityUnknown;
String issuerCopy(String? issuer) => issuer ?? CopyId.valueIssuerUnknown;
