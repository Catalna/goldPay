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
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_card.dart';
import '../../shared/presentation/qris_copy.dart';

/// Receipt detail (docs/09 §2.8).
class HistoryDetailPage extends ConsumerWidget {
  const HistoryDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoStateProvider);
    final textTheme = Theme.of(context).textTheme;
    final transaction = demoState.value?.transactions
        .where((item) => item.id == transactionId)
        .firstOrNull;

    return AppShell(
      titleText: CopyId.screenReceiptTitle,
      leading: IconButton(
        tooltip: CopyId.navBack,
        color: GoldPayTokens.ink,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
      child: transaction == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(GoldPayTokens.pagePadding),
                child: AppButton(
                  label: CopyId.navHistory,
                  onPressed: () => context.go('/history'),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                GoldPayTokens.pagePadding,
                GoldPayTokens.space8,
                GoldPayTokens.pagePadding,
                GoldPayTokens.space32,
              ),
              children: [
                const DemoBanner(),
                const SizedBox(height: GoldPayTokens.space16),
                SectionCard(
                  child: Column(
                    children: [
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
                              merchantNameCopy(transaction.merchantName),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
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
                      const SizedBox(height: GoldPayTokens.space12),
                      InfoRow(
                        label: CopyId.labelStatus,
                        value: CopyId.statusCompleted,
                      ),
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
                        label: CopyId.labelTotal,
                        value: formatRupiah(transaction.totalIdr),
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GoldPayTokens.space12),
                SectionCard(
                  child: Column(
                    children: [
                      InfoRow(
                        label: CopyId.labelPriceDisplay,
                        value:
                            '${formatRupiah(transaction.goldPriceDisplayIdrPerGram)}/g',
                      ),
                      InfoRow(
                        label: CopyId.labelGoldPriceUsed,
                        value:
                            '${formatRupiah(transaction.goldBuybackPriceIdrPerGram)}/g',
                      ),
                      InfoRow(
                        label: CopyId.labelGoldUsed,
                        value: formatGoldUnits(transaction.goldUnits),
                        emphasize: true,
                      ),
                      InfoRow(
                        label: CopyId.labelGoldValue,
                        value: formatRupiah(transaction.goldValueIdr),
                      ),
                      InfoRow(
                        label: CopyId.labelRounding,
                        value: formatRupiah(transaction.roundingIdr),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GoldPayTokens.space12),
                SectionCard(
                  child: Column(
                    children: [
                      InfoRow(
                        label: CopyId.labelBalanceBefore,
                        value: formatGoldUnits(transaction.balanceBeforeUnits),
                      ),
                      InfoRow(
                        label: CopyId.labelBalanceAfter,
                        value: formatGoldUnits(transaction.balanceAfterUnits),
                        emphasize: true,
                      ),
                      InfoRow(
                        label: CopyId.labelMerchant,
                        value: merchantNameCopy(transaction.merchantName),
                      ),
                      InfoRow(
                        label: CopyId.labelCity,
                        value: merchantCityCopy(transaction.merchantCity),
                      ),
                      InfoRow(
                        label: CopyId.labelMerchantIssuer,
                        value: issuerCopy(transaction.merchantIssuerGui),
                      ),
                      InfoRow(
                        label: CopyId.labelQrType,
                        value: qrKindCopy(transaction.qrKind),
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
                if (transaction.warningCodes.isNotEmpty) ...[
                  const SizedBox(height: GoldPayTokens.space12),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final code in transaction.warningCodes)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              qrisWarningCopy(code),
                              style: textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: GoldPayTokens.space12),
                SectionCard(
                  child: Column(
                    children: [
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
                      InfoRow(
                        label: CopyId.labelConfigVersion,
                        value: transaction.pricingConfigVersion,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GoldPayTokens.space24),
                Text(
                  CopyId.disclaimerReceipt,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
    );
  }
}
