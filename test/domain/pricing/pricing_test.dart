import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/core/constants/demo_config.dart';
import 'package:goldpay_demo/domain/entities/conversion_quote.dart';
import 'package:goldpay_demo/domain/pricing/gold_conversion_calculator.dart';
import 'package:goldpay_demo/domain/pricing/quote_validator.dart';

const DemoPricingConfig config = DemoPricingConfig.standard;
final DateTime now = DateTime.utc(2026, 1, 19, 10, 30);

ConversionQuote quote({
  int payment = 150000,
  int fee = 0,
  int balance = 12500,
}) {
  return buildConversionQuote(
    config: config,
    quoteId: 'quote-test',
    paymentAmountIdr: payment,
    qrFeeIdr: fee,
    balanceBeforeUnits: balance,
    now: now,
  );
}

void main() {
  group('conversion ceiling', () {
    test('F01/F02: 150.000 -> 1.021 units (0,1021 g)', () {
      final q = quote();
      expect(q.totalIdr, 150000);
      expect(q.goldUnits, 1021);
      expect(q.goldValueIdr, 150087);
      expect(q.roundingIdr, 87);
      expect(q.balanceAfterUnits, 11479);
      expect(q.shortfallUnits, 0);
    });

    test('F04: 100.000 + 5.000 QR fee -> 715 units', () {
      final q = quote(payment: 100000, fee: 5000);
      expect(q.totalIdr, 105000);
      expect(q.goldUnits, 715);
      expect(q.goldValueIdr, 105105);
      expect(q.roundingIdr, 105);
      expect(q.balanceAfterUnits, 11785);
    });

    test('minimum 1.000 -> 7 units, never zero', () {
      final q = quote(payment: 1000, balance: 12500);
      expect(q.goldUnits, 7);
      expect(q.goldValueIdr, 1029);
      expect(q.roundingIdr, 29);
    });

    test('maximum 1.000.000 -> 6.803 units', () {
      final q = quote(payment: 1000000, balance: 12500);
      expect(q.goldUnits, 6803);
      expect(q.goldValueIdr, 1000041);
      expect(q.roundingIdr, 41);
    });

    test('rounding is always between 0 and one unit of gold', () {
      const pricePerUnit = 147;
      for (final amount in [1000, 1234, 5000, 99999, 150000, 1000000]) {
        final q = quote(payment: amount, balance: 1000000);
        expect(q.roundingIdr, greaterThanOrEqualTo(0));
        expect(q.roundingIdr, lessThan(pricePerUnit));
      }
    });

    test('quote copies price snapshot and expires after five minutes', () {
      final q = quote();
      expect(q.goldPriceDisplayIdrPerGram, 1500000);
      expect(q.goldBuybackPriceIdrPerGram, 1470000);
      expect(q.convenienceFeeIdr, 0);
      expect(q.pricingConfigVersion, 'demo-2026-01');
      expect(q.createdAt, now);
      expect(q.validUntil, now.add(const Duration(minutes: 5)));
      expect(
        q.isExpiredAt(now.add(const Duration(minutes: 4, seconds: 59))),
        isFalse,
      );
      expect(q.isExpiredAt(q.validUntil), isTrue);
    });

    test('shortfall is expressed in units and rupiah', () {
      final q = quote(balance: 100);
      expect(q.balanceAfterUnits, -921);
      expect(q.shortfallUnits, 921);
      expect(q.shortfallIdr, 135387);
    });
  });

  group('quote validation', () {
    test('accepts a fresh, affordable quote', () {
      final q = quote();
      expect(
        validateQuote(quote: q, config: config, balanceUnits: 12500, now: now),
        isNull,
      );
    });

    test('rejects zero and out-of-range amounts', () {
      QuoteIssue? check(int payment) => validateQuote(
        quote: quote(payment: payment),
        config: config,
        balanceUnits: 12500,
        now: now,
      );

      expect(check(0), QuoteIssue.invalidAmount);
      expect(check(999), QuoteIssue.belowMinimum);
      expect(check(1000001), QuoteIssue.aboveMaximum);
    });

    test('rejects insufficient live balance', () {
      final q = quote(balance: 12500);
      expect(
        validateQuote(quote: q, config: config, balanceUnits: 500, now: now),
        QuoteIssue.insufficientBalance,
      );
    });

    test('rejects an expired quote', () {
      final q = quote();
      expect(
        validateQuote(
          quote: q,
          config: config,
          balanceUnits: 12500,
          now: q.validUntil.add(const Duration(seconds: 1)),
        ),
        QuoteIssue.expired,
      );
    });

    test('rejects an invalid pricing configuration', () {
      const broken = DemoPricingConfig(
        version: 'broken',
        goldPriceDisplayIdrPerGram: 100,
        goldBuybackPriceIdrPerGram: 200,
        convenienceFeeIdr: 0,
        initialBalanceUnits: 12500,
        minPaymentIdr: 1000,
        maxPaymentIdr: 1000000,
      );
      final q = buildConversionQuote(
        config: broken,
        quoteId: 'broken',
        paymentAmountIdr: 10000,
        qrFeeIdr: 0,
        balanceBeforeUnits: 12500,
        now: now,
      );
      expect(
        validateQuote(quote: q, config: broken, balanceUnits: 12500, now: now),
        QuoteIssue.invalidPricingConfig,
      );
    });
  });
}
