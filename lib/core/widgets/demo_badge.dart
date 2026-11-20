import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../constants/copy_id.dart';

/// Small "DEMO" pill used next to the concept name.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GoldPayTokens.goldSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GoldPayTokens.goldBorder),
      ),
      child: const Text(
        CopyId.badgeDemo,
        style: TextStyle(
          fontSize: 10,
          height: 13 / 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: GoldPayTokens.goldInk,
        ),
      ),
    );
  }
}
