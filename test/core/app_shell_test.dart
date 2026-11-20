import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/app/theme/theme.dart';
import 'package:goldpay_demo/core/constants/copy_id.dart';
import 'package:goldpay_demo/core/widgets/app_shell.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('bottom bar keeps the three destinations and the centre Scan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGoldPayTheme(),
        home: AppShell(
          titleText: CopyId.appName,
          currentTab: AppShellTab.home,
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.text(CopyId.navHomeTab), findsOneWidget);
    expect(find.text(CopyId.navHistory), findsOneWidget);
    expect(find.text(CopyId.navSettingsTab), findsOneWidget);
    expect(find.text(CopyId.navScanTab), findsOneWidget);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == CopyId.navScan,
      ),
      findsOneWidget,
    );
  });
}
