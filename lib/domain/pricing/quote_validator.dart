import '../../core/constants/demo_config.dart';
import '../entities/conversion_quote.dart';

/// Reasons a quote cannot be confirmed. Ordered by the checks in docs/08 §6.
enum QuoteIssue {
  invalidAmount,
  belowMinimum,
  aboveMaximum,
  invalidPricingConfig,
  insufficientBalance,
  expired;

  String get code => switch (this) {
    QuoteIssue.invalidAmount => 'INVALID_AMOUNT',
    QuoteIssue.belowMinimum => 'BELOW_MINIMUM',
    QuoteIssue.aboveMaximum => 'ABOVE_MAXIMUM',
    QuoteIssue.invalidPricingConfig => 'INVALID_PRICING_CONFIG',
    QuoteIssue.insufficientBalance => 'INSUFFICIENT_BALANCE',
    QuoteIssue.expired => 'QUOTE_EXPIRED',
  };
}

/// Re-validates a quote against the current balance before committing.
///
/// Returns null when the quote is still usable. The balance check deliberately
/// uses [balanceUnits] (live state), not the snapshot inside the quote.
QuoteIssue? validateQuote({
  required ConversionQuote quote,
  required DemoPricingConfig config,
  required int balanceUnits,
  required DateTime now,
}) {
  if (quote.paymentAmountIdr <= 0) {
    return QuoteIssue.invalidAmount;
  }
  if (quote.paymentAmountIdr < config.minPaymentIdr) {
    return QuoteIssue.belowMinimum;
  }
  if (quote.paymentAmountIdr > config.maxPaymentIdr) {
    return QuoteIssue.aboveMaximum;
  }
  if (quote.qrFeeIdr < 0 || quote.convenienceFeeIdr != 0) {
    return QuoteIssue.invalidPricingConfig;
  }
  if (quote.goldBuybackPriceIdrPerGram <= 0 ||
      quote.goldPriceDisplayIdrPerGram < quote.goldBuybackPriceIdrPerGram) {
    return QuoteIssue.invalidPricingConfig;
  }
  if (quote.goldUnits <= 0) {
    return QuoteIssue.invalidPricingConfig;
  }
  if (quote.goldUnits > balanceUnits) {
    return QuoteIssue.insufficientBalance;
  }
  if (quote.isExpiredAt(now)) {
    return QuoteIssue.expired;
  }
  return null;
}
