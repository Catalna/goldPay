import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/formatters/datetime.dart';
import '../../../../core/formatters/gold.dart';
import '../../../../core/formatters/money.dart';
import '../../../../core/widgets/demo_badge.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../domain/entities/demo_transaction.dart';
import '../../../shared/presentation/qris_copy.dart';

/// Compact history row used on Home and in the history list.
class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  final DemoTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(GoldPayTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      merchantNameCopy(transaction.merchantName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: GoldPayTokens.space8),
                  const DemoBadge(),
                ],
              ),
              const SizedBox(height: GoldPayTokens.space4),
              Text(
                formatDateTimeId(transaction.createdAt),
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: GoldPayTokens.space8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatRupiah(transaction.totalIdr),
                      style: textTheme.titleLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      formatGoldUnits(transaction.goldUnits),
                      textAlign: TextAlign.right,
                      style: textTheme.bodySmall,
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
