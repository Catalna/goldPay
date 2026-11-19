import 'package:material_ui/material_ui.dart';

import '../app/router.dart';
import '../core/constants/copy_id.dart';
import '../app/theme/theme.dart';

class GoldPayApp extends StatelessWidget {
  const GoldPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: CopyId.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildGoldPayTheme(),
      routerConfig: goldPayRouter,
    );
  }
}
