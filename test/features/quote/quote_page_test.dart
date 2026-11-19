import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/providers.dart';
import 'package:goldpay_demo/app/theme/theme.dart';
import 'package:goldpay_demo/core/constants/copy_id.dart';
import 'package:goldpay_demo/core/constants/demo_config.dart';
import 'package:goldpay_demo/data/demo_state_codec.dart';
import 'package:goldpay_demo/data/prefs_demo_repository.dart';
import 'package:goldpay_demo/domain/transaction/transaction_state.dart';
import 'package:goldpay_demo/features/checkout/application/checkout_controller.dart';
import 'package:goldpay_demo/features/quote/presentation/quote_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const DemoPricingConfig _config = DemoPricingConfig.standard;

const PaymentDraft _draft = PaymentDraft(
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

Future<ProviderContainer> _containerWithBalance(int balanceUnits) async {
  final state = buildInitialDemoState(
    config: _config,
    appVersion: '0.1.0+1',
    now: DateTime.utc(2026, 1, 19, 14),
  ).copyWith(balanceUnits: balanceUnits);
  final encoded = jsonEncode(demoStateToJson(state));

  SharedPreferences.setMockInitialValues({
    PrefsDemoRepository.mainKey: encoded,
    PrefsDemoRepository.prevKey: encoded,
  });
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      checkoutDelayProvider.overrideWithValue(Duration.zero),
    ],
  );
  await container.read(demoStateProvider.future);
  return container;
}

Future<void> _pumpQuote(
  WidgetTester tester,
  ProviderContainer container,
  int balanceUnits,
) async {
  final checkout = container.read(checkoutProvider.notifier);
  checkout.start(_draft);
  checkout.createQuote(config: _config, balanceUnits: balanceUnits);
  addTearDown(container.dispose);

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildGoldPayTheme(), home: const QuotePage()),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> scrollToConfirm(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(CopyId.navConfirm),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  testWidgets('insufficient balance disables confirmation', (tester) async {
    final container = await _containerWithBalance(500);
    await _pumpQuote(tester, container, 500);

    expect(tester.takeException(), isNull);
    expect(find.text(CopyId.statusInsufficient), findsOneWidget);
    await scrollToConfirm(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text(CopyId.navRefreshQuote), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a covered quote shows the exact units and allows confirmation', (
    tester,
  ) async {
    final container = await _containerWithBalance(12500);
    await _pumpQuote(tester, container, 12500);

    expect(tester.takeException(), isNull);
    expect(find.text(CopyId.statusInsufficient), findsNothing);
    expect(find.text('0,1021 g'), findsOneWidget);
    await scrollToConfirm(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.pumpWidget(const SizedBox());
  });
}
