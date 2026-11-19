import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/core/constants/demo_config.dart';
import 'package:goldpay_demo/core/formatters/gold.dart';
import 'package:goldpay_demo/core/formatters/money.dart';

void main() {
  group('formatGoldUnits', () {
    test('renders exactly four decimals from integer units', () {
      expect(formatGoldUnits(12500), '1,2500 g');
      expect(formatGoldUnits(1021), '0,1021 g');
      expect(formatGoldUnits(11479), '1,1479 g');
      expect(formatGoldUnits(7), '0,0007 g');
      expect(formatGoldUnits(0), '0,0000 g');
    });

    test('adds thousand separators for large balances', () {
      expect(formatGoldUnits(12345678), '1.234,5678 g');
    });

    test('handles negatives without losing the unit suffix', () {
      expect(formatGoldUnits(-1021), '-0,1021 g');
    });
  });

  group('formatRupiah', () {
    test('uses dot separators and no space after Rp', () {
      expect(formatRupiah(150000), 'Rp150.000');
      expect(formatRupiah(1470000), 'Rp1.470.000');
      expect(formatRupiah(0), 'Rp0');
    });

    test('places the minus sign before the symbol', () {
      expect(formatRupiah(-2500), '-Rp2.500');
    });
  });

  group('DemoPricingConfig', () {
    test('matches the locked demo values', () {
      const config = DemoPricingConfig.standard;
      expect(config.goldPriceDisplayIdrPerGram, 1500000);
      expect(config.goldBuybackPriceIdrPerGram, 1470000);
      expect(config.convenienceFeeIdr, 0);
      expect(config.initialBalanceUnits, 12500);
      expect(config.spreadBasisPoints, 200);
    });

    test('balance value uses the buyback price, not the display price', () {
      const config = DemoPricingConfig.standard;
      expect(config.initialBalanceValueIdr, 1837500);
    });
  });
}
