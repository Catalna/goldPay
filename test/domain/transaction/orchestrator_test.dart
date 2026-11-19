import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/providers.dart';
import 'package:goldpay_demo/core/constants/demo_config.dart';
import 'package:goldpay_demo/core/errors/result.dart';
import 'package:goldpay_demo/data/prefs_demo_repository.dart';
import 'package:goldpay_demo/domain/entities/conversion_quote.dart';
import 'package:goldpay_demo/domain/entities/demo_state.dart';
import 'package:goldpay_demo/domain/entities/demo_transaction.dart';
import 'package:goldpay_demo/domain/pricing/gold_conversion_calculator.dart';
import 'package:goldpay_demo/domain/transaction/demo_payment_orchestrator.dart';
import 'package:goldpay_demo/domain/transaction/transaction_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const DemoPricingConfig config = DemoPricingConfig.standard;
final DateTime now = DateTime.utc(2026, 1, 19, 14, 12);

DemoState stateWith({
  int balance = 12500,
  List<DemoTransaction> transactions = const [],
}) {
  return buildInitialDemoState(
    config: config,
    appVersion: '0.1.0+1',
    now: now,
  ).copyWith(balanceUnits: balance, transactions: transactions);
}

ConversionQuote quoteFor({
  int amount = 150000,
  int fee = 0,
  int balance = 12500,
  String id = 'quote-1',
  DateTime? at,
}) {
  return buildConversionQuote(
    config: config,
    quoteId: id,
    paymentAmountIdr: amount,
    qrFeeIdr: fee,
    balanceBeforeUnits: balance,
    now: at ?? now,
  );
}

const PaymentDraft draft = PaymentDraft(
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

final class _FailingRepository implements DemoRepository {
  @override
  Future<Result<DemoState>> load() async =>
      const Err(Failure('STORAGE_CORRUPT'));

  @override
  Future<Result<DemoState>> resetTo(DemoState state) async =>
      const Err(Failure('STORAGE_WRITE_FAILED'));

  @override
  Future<Result<DemoState>> writeAtomic({
    required DemoState previous,
    required DemoState next,
  }) async => const Err(Failure('STORAGE_WRITE_FAILED'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrefsDemoRepository repository;
  late DemoPaymentOrchestrator orchestrator;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = PrefsDemoRepository(
      prefs,
      () => buildInitialDemoState(
        config: config,
        appVersion: '0.1.0+1',
        now: now,
      ),
    );
    orchestrator = DemoPaymentOrchestrator(repository);
  });

  test('commits one record and deducts exactly the quoted units', () async {
    final state = stateWith();
    final outcome = await orchestrator.commit(
      quote: quoteFor(),
      draft: draft,
      currentState: state,
      config: config,
      attemptId: 'attempt-1',
      now: now,
    );

    expect(outcome, isA<DemoCommitted>());
    final committed = outcome as DemoCommitted;
    expect(committed.transaction.goldUnits, 1021);
    expect(committed.transaction.balanceAfterUnits, 11479);
    expect(committed.state.balanceUnits, 11479);
    expect(committed.state.transactions.single.attemptId, 'attempt-1');

    final loaded = await repository.load();
    expect((loaded as Ok<DemoState>).value.balanceUnits, 11479);
  });

  test('same attemptId is idempotent and never deducts twice', () async {
    final state = stateWith();
    final first = await orchestrator.commit(
      quote: quoteFor(),
      draft: draft,
      currentState: state,
      config: config,
      attemptId: 'attempt-1',
      now: now,
    );
    final afterFirst = (first as DemoCommitted).state;

    final second = await orchestrator.commit(
      quote: quoteFor(id: 'quote-2'),
      draft: draft,
      currentState: afterFirst,
      config: config,
      attemptId: 'attempt-1',
      now: now,
    );

    final recovered = second as DemoCommitted;
    expect(recovered.recoveredAttempt, isTrue);
    expect(recovered.state.balanceUnits, 11479);
    expect(recovered.state.transactions, hasLength(1));
  });

  test('rejects insufficient balance without writing', () async {
    final state = stateWith(balance: 500);
    await repository.resetTo(state);

    final outcome = await orchestrator.commit(
      quote: quoteFor(),
      draft: draft,
      currentState: state,
      config: config,
      attemptId: 'attempt-1',
      now: now,
    );

    expect(outcome, isA<DemoRejected>());
    expect((outcome as DemoRejected).code, 'INSUFFICIENT_BALANCE');

    final loaded = await repository.load();
    final stored = (loaded as Ok<DemoState>).value;
    expect(stored.balanceUnits, 500);
    expect(stored.transactions, isEmpty);
  });

  test('rejects an expired quote', () async {
    final outcome = await orchestrator.commit(
      quote: quoteFor(),
      draft: draft,
      currentState: stateWith(),
      config: config,
      attemptId: 'attempt-1',
      now: now.add(const Duration(minutes: 6)),
    );

    expect((outcome as DemoRejected).code, 'QUOTE_EXPIRED');
  });

  test('forced failure changes nothing', () async {
    final outcome = await orchestrator.commit(
      quote: quoteFor(),
      draft: draft,
      currentState: stateWith(),
      config: config,
      attemptId: 'attempt-1',
      now: now,
      forceFailure: true,
    );

    expect((outcome as DemoRejected).code, 'FORCED_FAILURE');
    final loaded = await repository.load();
    final state = (loaded as Ok<DemoState>).value;
    expect(state.balanceUnits, 12500);
    expect(state.transactions, isEmpty);
  });

  test('a storage failure is reported and never looks like success', () async {
    final failing = DemoPaymentOrchestrator(_FailingRepository());
    final outcome = await failing.commit(
      quote: quoteFor(),
      draft: draft,
      currentState: stateWith(),
      config: config,
      attemptId: 'attempt-1',
      now: now,
    );

    expect((outcome as DemoRejected).code, 'STORAGE_WRITE_FAILED');
  });

  test('history is capped at 200 with the newest record first', () async {
    final existing = List<DemoTransaction>.generate(
      DemoState.maxTransactions,
      (index) => DemoTransaction(
        id: 'old-$index',
        attemptId: 'old-attempt-$index',
        createdAt: now.subtract(Duration(minutes: index + 1)),
        paymentAmountIdr: 1000,
        qrFeeIdr: 0,
        totalIdr: 1000,
        goldPriceDisplayIdrPerGram: 1500000,
        goldBuybackPriceIdrPerGram: 1470000,
        goldUnits: 7,
        goldValueIdr: 1029,
        roundingIdr: 29,
        balanceBeforeUnits: 10129 - index,
        balanceAfterUnits: 10122 - index,
        merchantName: 'Merchant $index',
        merchantCity: null,
        merchantIssuerGui: null,
        qrKind: 'static',
        crcValid: true,
        warningCodes: const [],
        source: 'paste',
        pricingConfigVersion: 'demo-2026-01',
        disclosureVersion: 'demo-2026-01',
      ),
    );
    final state = stateWith(balance: 100000, transactions: existing);

    final outcome = await orchestrator.commit(
      quote: quoteFor(id: 'quote-new'),
      draft: draft,
      currentState: state,
      config: config,
      attemptId: 'attempt-new',
      now: now,
    );

    final committed = outcome as DemoCommitted;
    expect(committed.state.transactions, hasLength(200));
    expect(committed.state.transactions.first.id, 'quote-new');
    expect(
      committed.state.transactions.any((item) => item.id == 'old-199'),
      isFalse,
    );
  });
}
