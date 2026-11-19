import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/theme/theme.dart';
import 'package:goldpay_demo/core/constants/copy_id.dart';
import 'package:goldpay_demo/domain/transaction/transaction_state.dart';
import 'package:goldpay_demo/features/checkout/application/checkout_controller.dart';
import 'package:goldpay_demo/features/review/presentation/review_page.dart';
import 'package:material_ui/material_ui.dart';

const PaymentDraft _dynamic = PaymentDraft(
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

const PaymentDraft _static = PaymentDraft(
  source: 'paste',
  qrKind: 'static',
  merchantName: 'Warung Bu Tini',
  merchantCity: 'Jakarta',
  merchantIssuerGui: 'ID.CO.BANKCONTOH.WWW',
  crcValid: true,
  warningCodes: [],
  paymentAmountIdr: 0,
  qrFeeIdr: 0,
  amountReadOnly: false,
);

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  PaymentDraft draft,
) async {
  container.read(checkoutProvider.notifier).start(draft);
  addTearDown(container.dispose);

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildGoldPayTheme(), home: const ReviewPage()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('dynamic QR locks the amount and cannot be edited', (
    tester,
  ) async {
    final container = ProviderContainer();
    await _pump(tester, container, _dynamic);

    expect(tester.takeException(), isNull);
    expect(find.text('Rp150.000'), findsOneWidget);
    expect(find.text(CopyId.labelQrAmountLocked), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text(CopyId.labelSource), findsOneWidget);
    expect(find.text(CopyId.valueSourceCamera), findsOneWidget);
    expect(find.text(CopyId.valueSourcePaste), findsNothing);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('static QR validates the amount inline and gates the button', (
    tester,
  ) async {
    final container = ProviderContainer();
    await _pump(tester, container, _static);

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(CopyId.valueSourcePaste), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    expect(find.text(CopyId.validationAmountMin), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '1500');
    await tester.pump();
    expect(find.text(CopyId.validationAmountMin), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.enterText(find.byType(TextField), '2000000');
    await tester.pump();
    expect(find.text(CopyId.validationAmountMax), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
