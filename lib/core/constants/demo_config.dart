import 'units.dart';

/// Synthetic demo configuration. Never present these values as live pricing.
/// Locked in docs/00_DECISION_LOG.md D-14 … D-17.
class DemoPricingConfig {
  const DemoPricingConfig({
    required this.version,
    required this.goldPriceDisplayIdrPerGram,
    required this.goldBuybackPriceIdrPerGram,
    required this.convenienceFeeIdr,
    required this.initialBalanceUnits,
    required this.minPaymentIdr,
    required this.maxPaymentIdr,
  });

  final String version;
  final int goldPriceDisplayIdrPerGram;
  final int goldBuybackPriceIdrPerGram;
  final int convenienceFeeIdr;
  final int initialBalanceUnits;
  final int minPaymentIdr;
  final int maxPaymentIdr;

  static const DemoPricingConfig standard = DemoPricingConfig(
    version: 'demo-2026-01',
    goldPriceDisplayIdrPerGram: 1500000,
    goldBuybackPriceIdrPerGram: 1470000,
    convenienceFeeIdr: 0,
    initialBalanceUnits: 12500,
    minPaymentIdr: 1000,
    maxPaymentIdr: 1000000,
  );

  /// Spread between displayed price and buyback price, in basis points.
  int get spreadBasisPoints {
    if (goldPriceDisplayIdrPerGram <= 0) return 0;
    final diff = goldPriceDisplayIdrPerGram - goldBuybackPriceIdrPerGram;
    return diff * 10000 ~/ goldPriceDisplayIdrPerGram;
  }

  /// Illustrative rupiah value of the demo balance, at the buyback price.
  int get initialBalanceValueIdr =>
      initialBalanceUnits * goldBuybackPriceIdrPerGram ~/ kGoldUnitsPerGram;
}
