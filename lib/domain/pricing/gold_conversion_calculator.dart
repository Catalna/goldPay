import '../../core/constants/demo_config.dart';
import '../../core/math/ceil_div.dart';
import '../entities/conversion_quote.dart';

/// How long a demo quote stays valid (docs/00 D-18).
const Duration kQuoteValidity = Duration(minutes: 5);

/// Builds a quote from integer inputs only. No rounding is hidden: the gold
/// value is rounded up to the next 0,0001 g and the difference is exposed as
/// [ConversionQuote.roundingIdr].
ConversionQuote buildConversionQuote({
  required DemoPricingConfig config,
  required String quoteId,
  required int paymentAmountIdr,
  required int qrFeeIdr,
  required int balanceBeforeUnits,
  required DateTime now,
}) {
  final totalIdr = paymentAmountIdr + qrFeeIdr + config.convenienceFeeIdr;
  final goldUnits = ceilDiv(
    totalIdr * 10000,
    config.goldBuybackPriceIdrPerGram,
  );
  final goldValueIdr = goldUnits * config.goldBuybackPriceIdrPerGram ~/ 10000;
  final createdAt = now.toUtc();

  return ConversionQuote(
    quoteId: quoteId,
    createdAt: createdAt,
    validUntil: createdAt.add(kQuoteValidity),
    pricingConfigVersion: config.version,
    paymentAmountIdr: paymentAmountIdr,
    qrFeeIdr: qrFeeIdr,
    convenienceFeeIdr: config.convenienceFeeIdr,
    totalIdr: totalIdr,
    goldPriceDisplayIdrPerGram: config.goldPriceDisplayIdrPerGram,
    goldBuybackPriceIdrPerGram: config.goldBuybackPriceIdrPerGram,
    goldUnits: goldUnits,
    goldValueIdr: goldValueIdr,
    roundingIdr: goldValueIdr - totalIdr,
    balanceBeforeUnits: balanceBeforeUnits,
    balanceAfterUnits: balanceBeforeUnits - goldUnits,
    disclosureVersion: config.version,
  );
}
