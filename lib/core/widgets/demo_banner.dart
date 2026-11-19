import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';
import '../constants/copy_id.dart';

/// Persistent disclosure. Must appear on every transaction screen (docs/09 §3).
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GoldPayTokens.space12,
        vertical: GoldPayTokens.space12,
      ),
      decoration: BoxDecoration(
        color: GoldPayTokens.goldSoft,
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        border: Border.all(color: GoldPayTokens.goldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: GoldPayTokens.goldInk,
          ),
          const SizedBox(width: GoldPayTokens.space8),
          const Expanded(
            child: Text(
              CopyId.disclaimerBanner,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: GoldPayTokens.goldInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
