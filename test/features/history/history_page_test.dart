import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/providers.dart';
import 'package:goldpay_demo/app/router.dart';
import 'package:goldpay_demo/app/theme/theme.dart';
import 'package:goldpay_demo/core/constants/copy_id.dart';
import 'package:goldpay_demo/core/constants/demo_config.dart';
import 'package:goldpay_demo/data/demo_state_codec.dart';
import 'package:goldpay_demo/data/prefs_demo_repository.dart';
import 'package:goldpay_demo/domain/entities/demo_transaction.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const DemoPricingConfig _config = DemoPricingConfig.standard;

const String _transactionId = 'tx-0001';

DemoTransaction _transaction() => DemoTransaction(
  id: _transactionId,
  attemptId: 'attempt-0001',
  createdAt: DateTime.utc(2026, 11, 19, 12, 24),
  paymentAmountIdr: 150000,
  qrFeeIdr: 0,
  totalIdr: 150000,
  goldPriceDisplayIdrPerGram: 1500000,
  goldBuybackPriceIdrPerGram: 1470000,
  goldUnits: 1021,
  goldValueIdr: 150087,
  roundingIdr: 87,
  balanceBeforeUnits: 12500,
  balanceAfterUnits: 11479,
  merchantName: 'Warung Bu Tini',
  merchantCity: 'Jakarta',
  merchantIssuerGui: 'ID.CO.BANKCONTOH.WWW',
  qrKind: 'dynamic',
  crcValid: true,
  warningCodes: const [],
  source: 'paste',
  pricingConfigVersion: _config.version,
  disclosureVersion: 'demo-1',
);

Future<ProviderContainer> _containerWithOneTransaction() async {
  final base = buildInitialDemoState(
    config: _config,
    appVersion: '0.1.0+1',
    now: DateTime.utc(2026, 11, 19, 12),
  );
  final state = base.copyWith(
    balanceUnits: 11479,
    transactions: [_transaction()],
  );
  final encoded = jsonEncode(demoStateToJson(state));

  SharedPreferences.setMockInitialValues({
    PrefsDemoRepository.mainKey: encoded,
    PrefsDemoRepository.prevKey: encoded,
  });
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  await container.read(demoStateProvider.future);
  return container;
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('tapping a transaction opens its receipt detail', (tester) async {
    final container = await _containerWithOneTransaction();
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    goldPayRouter.go('/history');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildGoldPayTheme(),
          routerConfig: goldPayRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Title in the header plus the Riwayat tab in the bottom bar.
    expect(find.text(CopyId.screenHistoryTitle), findsNWidgets(2));

    await tester.tap(find.text('Warung Bu Tini'));
    await tester.pumpAndSettle();

    // The detail route needs the transaction id; an empty id would fall back to
    // the "receipt not found" state with a single Riwayat button.
    expect(find.text(CopyId.screenReceiptTitle), findsOneWidget);
    expect(find.text(CopyId.statusCompleted), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(CopyId.labelTransactionId),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_transactionId), findsOneWidget);
    expect(find.text(CopyId.valueSourcePaste), findsOneWidget);
    expect(find.text(CopyId.disclaimerReceipt), findsOneWidget);

    goldPayRouter.go('/');
    await tester.pumpWidget(const SizedBox());
  });
}
