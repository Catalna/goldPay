import '../../core/math/ceil_div.dart';

/// A quote is a snapshot: prices, fee and balance are copied, never read from
/// the live config after the fact (docs/08 §5).
final class ConversionQuote {
  const ConversionQuote({
    required this.quoteId,
    required this.createdAt,
    required this.validUntil,
    required this.pricingConfigVersion,
    required this.paymentAmountIdr,
    required this.qrFeeIdr,
    required this.convenienceFeeIdr,
    required this.totalIdr,
    required this.goldPriceDisplayIdrPerGram,
    required this.goldBuybackPriceIdrPerGram,
    required this.goldUnits,
    required this.goldValueIdr,
    required this.roundingIdr,
    required this.balanceBeforeUnits,
    required this.balanceAfterUnits,
    required this.disclosureVersion,
  });

  final String quoteId;
  final DateTime createdAt;
  final DateTime validUntil;
  final String pricingConfigVersion;

  final int paymentAmountIdr;
  final int qrFeeIdr;
  final int convenienceFeeIdr;
  final int totalIdr;

  final int goldPriceDisplayIdrPerGram;
  final int goldBuybackPriceIdrPerGram;

  /// Integer units of 0,0001 g; this is exactly what gets deducted.
  final int goldUnits;
  final int goldValueIdr;
  final int roundingIdr;

  final int balanceBeforeUnits;
  final int balanceAfterUnits;

  final String disclosureVersion;

  bool isExpiredAt(DateTime now) => !now.isBefore(validUntil);

  int get shortfallUnits =>
      goldUnits > balanceBeforeUnits ? goldUnits - balanceBeforeUnits : 0;

  int get shortfallIdr {
    if (shortfallUnits == 0) return 0;
    return ceilDiv(shortfallUnits * goldBuybackPriceIdrPerGram, 10000);
  }
}
