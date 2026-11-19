import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/providers.dart';
import 'package:goldpay_demo/core/constants/demo_config.dart';
import 'package:goldpay_demo/core/errors/result.dart';
import 'package:goldpay_demo/data/demo_state_codec.dart';
import 'package:goldpay_demo/data/prefs_demo_repository.dart';
import 'package:goldpay_demo/domain/entities/demo_state.dart';
import 'package:goldpay_demo/domain/entities/demo_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DemoPricingConfig config = DemoPricingConfig.standard;
final DateTime now = DateTime.utc(2026, 1, 19, 14, 5);

DemoState initialState() =>
    buildInitialDemoState(config: config, appVersion: '0.1.0+1', now: now);

DemoTransaction transaction({
  required String id,
  required String attemptId,
  int goldUnits = 1021,
  DateTime? createdAt,
}) {
  return DemoTransaction(
    id: id,
    attemptId: attemptId,
    createdAt: createdAt ?? now,
    paymentAmountIdr: 150000,
    qrFeeIdr: 0,
    totalIdr: 150000,
    goldPriceDisplayIdrPerGram: 1500000,
    goldBuybackPriceIdrPerGram: 1470000,
    goldUnits: goldUnits,
    goldValueIdr: 150087,
    roundingIdr: 87,
    balanceBeforeUnits: 12500,
    balanceAfterUnits: 12500 - goldUnits,
    merchantName: 'Warung Bu Tini',
    merchantCity: 'Jakarta',
    merchantIssuerGui: 'ID.CO.BANKCONTOH.WWW',
    qrKind: 'dynamic',
    crcValid: true,
    warningCodes: const [],
    source: 'camera',
    pricingConfigVersion: 'demo-2026-01',
    disclosureVersion: 'demo-2026-01',
  );
}

Future<SharedPreferences> freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('codec', () {
    test('round-trips a state without losing any field', () {
      final state = initialState().copyWith(
        balanceUnits: 11479,
        transactions: [transaction(id: 'tx-1', attemptId: 'attempt-1')],
      );

      final encoded = jsonEncode(demoStateToJson(state));
      final decoded = demoStateFromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      );

      expect(demoStateToJson(decoded), demoStateToJson(state));
      expect(decoded.transactions.single.status, 'completed_demo');
      expect(decoded.lastUpdatedAt.isUtc, isTrue);
    });

    test('rejects a schema version from the future', () {
      final json = demoStateToJson(initialState());
      json['schemaVersion'] = DemoState.currentSchemaVersion + 1;
      expect(
        () => demoStateFromJson(json),
        throwsA(isA<SchemaTooNewException>()),
      );
    });

    test('rejects any status other than completed_demo', () {
      final json = demoStateToJson(
        initialState().copyWith(
          transactions: [transaction(id: 'tx-1', attemptId: 'a-1')],
        ),
      );
      final transactions = json['transactions']! as List<Object?>;
      final first = transactions.first! as Map<String, Object?>;
      first['status'] = 'processing_demo';

      expect(() => demoStateFromJson(json), throwsA(isA<FormatException>()));
    });

    test('rejects more than 200 stored transactions', () {
      final json = demoStateToJson(initialState());
      json['transactions'] = <Object?>[];
      expect(demoStateFromJson(json).transactions, isEmpty);

      final tooMany = List<Object?>.generate(
        DemoState.maxTransactions + 1,
        (index) => demoTransactionToJson(
          transaction(id: 'tx-$index', attemptId: 'attempt-$index'),
        ),
      );
      json['transactions'] = tooMany;
      expect(() => demoStateFromJson(json), throwsA(isA<FormatException>()));
    });
  });

  group('PrefsDemoRepository', () {
    test('first load seeds the initial state into both keys', () async {
      final prefs = await freshPrefs();
      final repository = PrefsDemoRepository(prefs, initialState);

      final result = await repository.load();
      expect(result, isA<Ok<DemoState>>());
      expect(prefs.getString(PrefsDemoRepository.mainKey), isNotNull);
      expect(prefs.getString(PrefsDemoRepository.prevKey), isNotNull);
    });

    test(
      'atomic write stores previous and next, and load returns next',
      () async {
        final prefs = await freshPrefs();
        final repository = PrefsDemoRepository(prefs, initialState);
        final previous = initialState();
        final next = previous.copyWith(
          balanceUnits: 11479,
          transactions: [transaction(id: 'tx-1', attemptId: 'attempt-1')],
        );

        final write = await repository.writeAtomic(
          previous: previous,
          next: next,
        );
        expect(write, isA<Ok<DemoState>>());

        final loaded = await repository.load();
        final state = (loaded as Ok<DemoState>).value;
        expect(state.balanceUnits, 11479);
        expect(state.transactions.single.id, 'tx-1');
      },
    );

    test(
      'recovers the previous snapshot when the main blob is corrupt',
      () async {
        final prefs = await freshPrefs();
        final repository = PrefsDemoRepository(prefs, initialState);
        final previous = initialState();
        final next = previous.copyWith(balanceUnits: 9000);

        await repository.writeAtomic(previous: previous, next: next);
        // Corrupt the main blob only; `_prev` still holds `previous`.
        await prefs.setString(PrefsDemoRepository.mainKey, '{not json');

        final loaded = await repository.load();
        final state = (loaded as Ok<DemoState>).value;
        expect(state.balanceUnits, config.initialBalanceUnits);
        expect(
          prefs.getString(PrefsDemoRepository.mainKey),
          isNot('{not json'),
        );
      },
    );

    test('reports corrupt storage instead of inventing a balance', () async {
      final prefs = await freshPrefs();
      final repository = PrefsDemoRepository(prefs, initialState);
      await prefs.setString(PrefsDemoRepository.mainKey, '{not json');
      await prefs.setString(PrefsDemoRepository.prevKey, '{not json either');

      final result = await repository.load();
      expect(result, isA<Err<DemoState>>());
      expect((result as Err<DemoState>).failure.code, 'STORAGE_CORRUPT');
    });

    test('resetTo writes the same blob to both keys', () async {
      final prefs = await freshPrefs();
      final repository = PrefsDemoRepository(prefs, initialState);

      final result = await repository.resetTo(initialState());
      expect(result, isA<Ok<DemoState>>());
      expect(
        prefs.getString(PrefsDemoRepository.mainKey),
        prefs.getString(PrefsDemoRepository.prevKey),
      );
    });
  });
}
