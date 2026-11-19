import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/formatters/gold.dart';
import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/demo_badge.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../history/presentation/widgets/transaction_summary_card.dart';
import 'widgets/balance_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(demoConfigProvider);
    final demoState = ref.watch(demoStateProvider);
    final textTheme = Theme.of(context).textTheme;

    final balanceUnits =
        demoState.value?.balanceUnits ?? config.initialBalanceUnits;
    final balanceValueIdr =
        balanceUnits * config.goldBuybackPriceIdrPerGram ~/ 10000;
    final transactions = demoState.value?.transactions ?? const [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: GoldPayTokens.pagePadding,
        title: Row(
          children: [
            Flexible(
              child: Text(
                CopyId.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: GoldPayTokens.space8),
            const DemoBadge(),
          ],
        ),
        actions: [
          IconButton(
            tooltip: CopyId.navSettings,
            onPressed: () => context.push('/demo-settings'),
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: GoldPayTokens.space4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          GoldPayTokens.pagePadding,
          GoldPayTokens.space4,
          GoldPayTokens.pagePadding,
          GoldPayTokens.space32,
        ),
        children: [
          Text(CopyId.disclaimerShort, style: textTheme.bodySmall),
          const SizedBox(height: GoldPayTokens.space16),
          BalanceCard(
            grams: formatGoldUnits(balanceUnits),
            valueRupiah: formatRupiah(balanceValueIdr),
            buybackPriceRupiah:
                '${formatRupiah(config.goldBuybackPriceIdrPerGram)}/g',
          ),
          const SizedBox(height: GoldPayTokens.space24),
          AppButton(
            label: CopyId.navScan,
            icon: Icons.qr_code_scanner,
            onPressed: () => context.push('/scan'),
          ),
          const SizedBox(height: GoldPayTokens.space24),
          Row(
            children: [
              Expanded(
                child: Text(
                  CopyId.labelHistorySection,
                  style: textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text(
                    CopyId.navViewHistory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (transactions.isEmpty)
            _EmptyHistoryCard(textTheme: textTheme)
          else
            for (final transaction in transactions.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: GoldPayTokens.space12),
                child: TransactionSummaryCard(
                  transaction: transaction,
                  onTap: () => context.push('/history/${transaction.id}'),
                ),
              ),
          const SizedBox(height: GoldPayTokens.space24),
          const DemoBanner(),
          const SizedBox(height: GoldPayTokens.space12),
          Text(CopyId.disclaimerConcept, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GoldPayTokens.space16,
        vertical: GoldPayTokens.space32,
      ),
      decoration: BoxDecoration(
        color: GoldPayTokens.card,
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        border: Border.all(color: GoldPayTokens.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 28,
            color: GoldPayTokens.inkMuted,
          ),
          const SizedBox(height: GoldPayTokens.space8),
          Text(
            CopyId.historyEmpty,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
