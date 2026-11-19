/// Persisted transaction. Only `completed_demo` is ever written (D-09).
///
/// No raw payload, merchant PAN, image path, or personal data is stored
/// (docs/10 §9).
final class DemoTransaction {
  const DemoTransaction({
    required this.id,
    required this.attemptId,
    required this.createdAt,
    required this.paymentAmountIdr,
    required this.qrFeeIdr,
    required this.totalIdr,
    required this.goldPriceDisplayIdrPerGram,
    required this.goldBuybackPriceIdrPerGram,
    required this.goldUnits,
    required this.goldValueIdr,
    required this.roundingIdr,
    required this.balanceBeforeUnits,
    required this.balanceAfterUnits,
    required this.merchantName,
    required this.merchantCity,
    required this.merchantIssuerGui,
    required this.qrKind,
    required this.crcValid,
    required this.warningCodes,
    required this.source,
    required this.pricingConfigVersion,
    required this.disclosureVersion,
  });

  static const String statusCompletedDemo = 'completed_demo';

  final String id;
  final String attemptId;
  final DateTime createdAt;
  final int paymentAmountIdr;
  final int qrFeeIdr;
  final int totalIdr;

  final int goldPriceDisplayIdrPerGram;
  final int goldBuybackPriceIdrPerGram;
  final int goldUnits;
  final int goldValueIdr;
  final int roundingIdr;

  final int balanceBeforeUnits;
  final int balanceAfterUnits;

  final String? merchantName;
  final String? merchantCity;
  final String? merchantIssuerGui;
  final String qrKind;
  final bool crcValid;
  final List<String> warningCodes;
  final String source;

  final String pricingConfigVersion;
  final String disclosureVersion;

  String get status => statusCompletedDemo;
}
