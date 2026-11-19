import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/constants/copy_id.dart';

/// Balance card. Shows grams and illustrative rupiah value.
///
/// The grams string is produced from the same integer units that will be
/// deducted, so display and storage never diverge.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.grams,
    required this.valueRupiah,
    required this.buybackPriceRupiah,
    super.key,
  });

  final String grams;
  final String valueRupiah;
  final String buybackPriceRupiah;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label:
          '${CopyId.labelBalance}, $grams, '
          '${CopyId.labelBalanceRupiah} $valueRupiah',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GoldPayTokens.space16),
          decoration: BoxDecoration(
            color: GoldPayTokens.goldSoft,
            borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
            border: Border.all(color: const Color(0x33C9973A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CopyId.labelBalance,
                style: textTheme.bodySmall?.copyWith(
                  color: GoldPayTokens.goldInk,
                ),
              ),
              const SizedBox(height: GoldPayTokens.space8),
              Text(
                grams,
                style: textTheme.displaySmall?.copyWith(
                  color: GoldPayTokens.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: GoldPayTokens.space4),
              Text(
                '${CopyId.labelBalanceRupiah} $valueRupiah',
                style: textTheme.bodyLarge?.copyWith(
                  color: GoldPayTokens.goldInk,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: GoldPayTokens.space12),
              Divider(height: 1, color: const Color(0x33C9973A)),
              const SizedBox(height: GoldPayTokens.space12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CopyId.labelPriceBuyback,
                      style: textTheme.bodySmall?.copyWith(
                        color: GoldPayTokens.goldInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: GoldPayTokens.space8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        buybackPriceRupiah,
                        style: textTheme.bodyMedium?.copyWith(
                          color: GoldPayTokens.goldInk,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
