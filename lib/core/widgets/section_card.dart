import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';

/// White card with a 1 px border and 12 dp radius (docs/09 §1.3).
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(GoldPayTokens.space16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: GoldPayTokens.card,
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        border: Border.all(color: GoldPayTokens.border),
      ),
      child: child,
    );
  }
}
