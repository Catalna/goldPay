import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/formatters/datetime.dart';
import '../../../core/formatters/gold.dart';
import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_card.dart';
import '../../checkout/application/checkout_controller.dart';
import '../../shared/presentation/qris_copy.dart';

/// Result / receipt (docs/09 §2.6). Values come from the stored record.
class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutProvider);
    final transaction = checkout.transaction;
    final failed = checkout.failureCode != null;
    final config = ref.watch(demoConfigProvider);
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
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              GoldPayTokens.pagePadding,
              GoldPayTokens.space24,
              GoldPayTokens.pagePadding,
              GoldPayTokens.space32,
            ),
            children: [
              Icon(
                failed ? Icons.error_outline : Icons.check_circle_outline,
                size: 48,
                color: failed ? GoldPayTokens.danger : GoldPayTokens.success,
              ),
              const SizedBox(height: GoldPayTokens.space12),
              Text(
                failed ? CopyId.statusFailed : CopyId.statusCompleted,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: GoldPayTokens.space8),
              Text(
                failed ? CopyId.resultFailedBody : CopyId.resultCompletedBody,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: GoldPayTokens.space16),
              const DemoBanner(),
              if (transaction != null) ...[
                const SizedBox(height: GoldPayTokens.space16),
                SectionCard(
                  child: Column(
                    children: [
                      InfoRow(
                        label: CopyId.labelAmount,
                        value: formatRupiah(transaction.paymentAmountIdr),
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
                        label: CopyId.labelMerchant,
                        value: merchantNameCopy(transaction.merchantName),
                      ),
                      InfoRow(
                        label: CopyId.labelTransactionId,
                        value: transaction.id,
                      ),
                      InfoRow(
                        label: CopyId.labelTime,
                        value: formatDateTimeId(transaction.createdAt),
                      ),
                      InfoRow(
                        label: CopyId.labelSource,
                        value: sourceCopy(transaction.source),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: GoldPayTokens.space24),
              if (failed) ...[
                AppButton(
                  label: CopyId.navRetry,
                  onPressed: () {
                    final balance =
                        ref.read(demoStateProvider).value?.balanceUnits ??
                        config.initialBalanceUnits;
                    ref
                        .read(checkoutProvider.notifier)
                        .refreshQuote(config: config, balanceUnits: balance);
                    context.pushReplacement('/quote');
                  },
                ),
                const SizedBox(height: GoldPayTokens.space8),
                AppButton(
                  label: CopyId.navCancel,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    ref.read(checkoutProvider.notifier).cancel();
                    context.go('/');
                  },
                ),
              ] else ...[
                AppButton(
                  label: CopyId.navHome,
                  onPressed: () {
                    ref.read(checkoutProvider.notifier).cancel();
                    context.go('/');
                  },
                ),
                const SizedBox(height: GoldPayTokens.space8),
                AppButton(
                  label: CopyId.navViewHistory,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    ref.read(checkoutProvider.notifier).cancel();
                    context.go('/history');
                  },
                ),
              ],
              if (transaction != null) ...[
                const SizedBox(height: GoldPayTokens.space24),
                Text(CopyId.disclaimerReceipt, style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
