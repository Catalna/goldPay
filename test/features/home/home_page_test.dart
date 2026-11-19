import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/theme/theme.dart';
import 'package:goldpay_demo/core/constants/copy_id.dart';
import 'package:goldpay_demo/features/home/presentation/home_page.dart';
import 'package:material_ui/material_ui.dart';

Widget _app() {
  return ProviderScope(
    child: MaterialApp(theme: buildGoldPayTheme(), home: const HomePage()),
  );
}

void main() {
  testWidgets('home renders demo disclosure, balance and prices at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());

    expect(tester.takeException(), isNull);
    expect(find.text(CopyId.disclaimerShort), findsOneWidget);
    expect(find.text(CopyId.navScan), findsOneWidget);
    expect(find.text('1,2500 g'), findsOneWidget);
    expect(find.text('Rp1.470.000/g'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(CopyId.disclaimerBanner),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(CopyId.disclaimerBanner), findsOneWidget);
    expect(find.text(CopyId.historyEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home does not overflow at text scale 1.3 on a 320dp screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1920);
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Walk the whole list so lazily built rows are laid out too.
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
