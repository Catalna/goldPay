import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/formatters/datetime.dart';
import '../../../core/formatters/gold.dart';
import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_card.dart';
import '../../checkout/application/checkout_controller.dart';
import '../../shared/presentation/qris_copy.dart';

/// Result / receipt (docs/09 §2.6). Styled like a modern digital receipt.
class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutProvider);
    final transaction = checkout.transaction;
    final failed = checkout.failureCode != null;
    final textTheme = Theme.of(context).textTheme;

    if (transaction == null && !failed) {
      return Scaffold(
        body: Center(
          child: AppButton(
            label: CopyId.navHome,
            onPressed: () => context.go('/'),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: AppShell(
        titleText: CopyId.screenResultTitle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            GoldPayTokens.pagePadding,
            GoldPayTokens.space16,
            GoldPayTokens.pagePadding,
            GoldPayTokens.space32,
          ),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: failed
                      ? GoldPayTokens.danger.withValues(alpha: 0.12)
                      : GoldPayTokens.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  failed
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_rounded,
                  size: 38,
                  color: failed
                      ? GoldPayTokens.danger
                      : GoldPayTokens.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: GoldPayTokens.space12),
            Text(
              failed ? CopyId.statusFailed : CopyId.statusCompleted,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: GoldPayTokens.space4),
            Text(
              failed ? CopyId.resultFailedBody : CopyId.resultCompletedBody,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: GoldPayTokens.space16),
            const DemoBanner(),
            if (transaction != null) ...[
              const SizedBox(height: GoldPayTokens.space16),
              // Modern Receipt Card
              SectionCard(
                child: Column(
                  children: [
                    Text(
                      merchantNameCopy(transaction.merchantName),
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTimeId(transaction.createdAt),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: GoldPayTokens.space16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: GoldPayTokens.space12,
                        horizontal: GoldPayTokens.space16,
                      ),
                      decoration: BoxDecoration(
                        color: GoldPayTokens.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            formatRupiah(transaction.totalIdr),
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '≈ ${formatGoldUnits(transaction.goldUnits)} emas',
                            style: textTheme.bodySmall?.copyWith(
                              color: GoldPayTokens.goldInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GoldPayTokens.space16),
                    InfoRow(
                      label: CopyId.labelAmount,
                      value: formatRupiah(transaction.paymentAmountIdr),
                    ),
                    if (transaction.qrFeeIdr > 0)
                      InfoRow(
                        label: CopyId.labelQrFee,
                        value: formatRupiah(transaction.qrFeeIdr),
                      ),
                    InfoRow(
                      label: CopyId.labelGoldUsed,
                      value: formatGoldUnits(transaction.goldUnits),
                      emphasize: true,
                    ),
                    InfoRow(
                      label: CopyId.labelBalanceAfter,
                      value: formatGoldUnits(transaction.balanceAfterUnits),
                    ),
                    InfoRow(
                      label: CopyId.labelTransactionId,
                      value: transaction.id,
                    ),
                    InfoRow(
                      label: CopyId.labelCrc,
                      value: transaction.crcValid
                          ? CopyId.valueCrcValid
                          : CopyId.valueCrcInvalid,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: GoldPayTokens.space24),
            AppButton(label: CopyId.navHome, onPressed: () => context.go('/')),
            const SizedBox(height: GoldPayTokens.space8),
            AppButton(
              label: CopyId.navViewHistory,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go('/history'),
            ),
          ],
        ),
      ),
    );
  }
}
