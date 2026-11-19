import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/providers.dart';
import 'package:goldpay_demo/core/constants/demo_config.dart';
import 'package:goldpay_demo/domain/transaction/demo_payment_orchestrator.dart';
import 'package:goldpay_demo/domain/transaction/transaction_state.dart';
import 'package:goldpay_demo/features/checkout/application/checkout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const DemoPricingConfig config = DemoPricingConfig.standard;

const PaymentDraft dynamicDraft = PaymentDraft(
  source: 'camera',
  qrKind: 'dynamic',
  merchantName: 'Warung Bu Tini',
  merchantCity: 'Jakarta',
  merchantIssuerGui: 'ID.CO.BANKCONTOH.WWW',
  crcValid: true,
  warningCodes: [],
  paymentAmountIdr: 150000,
  qrFeeIdr: 0,
  amountReadOnly: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        checkoutDelayProvider.overrideWithValue(Duration.zero),
      ],
    );
    await container.read(demoStateProvider.future);
  });

  tearDown(() => container.dispose());

  test(
    'confirm commits one transaction and updates the visible balance',
    () async {
      final checkout = container.read(checkoutProvider.notifier);
      checkout.start(dynamicDraft);
      final quote = checkout.createQuote(config: config, balanceUnits: 12500);
      expect(quote, isNotNull);
      expect(quote!.goldUnits, 1021);

      final outcome = await checkout.confirm(config: config);

      expect(outcome, isA<DemoCommitted>());
      final state = container.read(checkoutProvider);
      expect(state.transaction, isNotNull);
      expect(state.transaction!.goldUnits, 1021);
      expect(container.read(demoStateProvider).value!.balanceUnits, 11479);
      expect(
        container.read(demoStateProvider).value!.transactions,
        hasLength(1),
      );
    },
  );

  test('a double tap commits exactly once', () async {
    final checkout = container.read(checkoutProvider.notifier);
    checkout.start(dynamicDraft);
    checkout.createQuote(config: config, balanceUnits: 12500);

    final results = await Future.wait([
      checkout.confirm(config: config),
      checkout.confirm(config: config),
    ]);

    expect(results.whereType<DemoCommitted>(), hasLength(1));
    expect(results.whereType<DemoRejected>(), isEmpty);
    expect(container.read(demoStateProvider).value!.transactions, hasLength(1));
    expect(container.read(demoStateProvider).value!.balanceUnits, 11479);
  });

  test(
    'forced failure leaves the balance untouched and is consumed once',
    () async {
      container.read(forceFailureProvider.notifier).set(true);

      final checkout = container.read(checkoutProvider.notifier);
      checkout.start(dynamicDraft);
      checkout.createQuote(config: config, balanceUnits: 12500);

      final first = await checkout.confirm(config: config);
      expect(first, isA<DemoRejected>());
      expect((first as DemoRejected).code, 'FORCED_FAILURE');
      expect(container.read(demoStateProvider).value!.balanceUnits, 12500);
      expect(container.read(demoStateProvider).value!.transactions, isEmpty);
      expect(container.read(forceFailureProvider), isFalse);

      // The retry path re-quotes and succeeds.
      final retryQuote = checkout.refreshQuote(
        config: config,
        balanceUnits: 12500,
      );
      expect(retryQuote, isNotNull);
      final second = await checkout.confirm(config: config);

      expect(second, isA<DemoCommitted>());
      expect(container.read(demoStateProvider).value!.balanceUnits, 11479);
    },
  );

  test('an expired quote cannot be confirmed', () async {
    final checkout = container.read(checkoutProvider.notifier);
    checkout.start(dynamicDraft);

    // Built ten minutes ago, so `validUntil` is already in the past.
    final expired = checkout.createQuote(
      config: config,
      balanceUnits: 12500,
      now: DateTime.now().subtract(const Duration(minutes: 10)),
    );
    expect(expired, isNotNull);
    expect(expired!.isExpiredAt(DateTime.now()), isTrue);

    final outcome = await checkout.confirm(config: config);
    expect(outcome, isA<DemoRejected>());
    expect((outcome as DemoRejected).code, 'QUOTE_EXPIRED');
    expect(container.read(demoStateProvider).value!.balanceUnits, 12500);
    expect(container.read(demoStateProvider).value!.transactions, isEmpty);
  });
}
