import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/formatters/datetime.dart';
import '../../../../core/formatters/gold.dart';
import '../../../../core/formatters/money.dart';
import '../../../../core/widgets/demo_badge.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../domain/entities/demo_transaction.dart';
import '../../../shared/presentation/qris_copy.dart';

/// Modern transaction card matching the reference design:
/// Left rounded avatar icon, merchant title, category/date, and trailing amount.
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
          padding: const EdgeInsets.symmetric(
            horizontal: GoldPayTokens.space16,
            vertical: GoldPayTokens.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GoldPayTokens.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    color: GoldPayTokens.primaryDark,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: GoldPayTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            merchantNameCopy(transaction.merchantName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: GoldPayTokens.space8),
                        const DemoBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTimeId(transaction.createdAt),
                      style: textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GoldPayTokens.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatRupiah(transaction.totalIdr),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatGoldUnits(transaction.goldUnits),
                    textAlign: TextAlign.right,
                    style: textTheme.bodySmall?.copyWith(fontSize: 12),
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
