import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/formatters/gold.dart';
import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_shell.dart';
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

    return AppShell(
      currentTab: AppShellTab.home,
      showDemoBadge: true,
      title: Text(
        CopyId.appName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleLarge?.copyWith(
          color: GoldPayTokens.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      subtitle: CopyId.disclaimerShort,
      actions: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GoldPayTokens.card,
            shape: BoxShape.circle,
            border: Border.all(color: GoldPayTokens.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: CopyId.navSettings,
            padding: EdgeInsets.zero,
            color: GoldPayTokens.ink,
            onPressed: () => context.push('/demo-settings'),
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          GoldPayTokens.pagePadding,
          GoldPayTokens.space12,
          GoldPayTokens.pagePadding,
          GoldPayTokens.space32,
        ),
        children: [
          BalanceCard(
            grams: formatGoldUnits(balanceUnits),
            valueRupiah: formatRupiah(balanceValueIdr),
            buybackPriceRupiah:
                '${formatRupiah(config.goldBuybackPriceIdrPerGram)}/g',
            onTopUp: () => context.push('/demo-settings'),
            onScan: () => context.push('/scan'),
          ),
          const SizedBox(height: GoldPayTokens.space20),
          Row(
            children: [
              Expanded(
                child: _QuickActionCircle(
                  icon: Icons.north_east_rounded,
                  label: CopyId.navHistory,
                  onTap: () => context.go('/history'),
                ),
              ),
              Expanded(
                child: _QuickActionCircle(
                  icon: Icons.south_west_rounded,
                  label: CopyId.labelPriceDisplay,
                  onTap: () => context.go('/demo-settings'),
                ),
              ),
              Expanded(
                child: _QuickActionCircle(
                  icon: Icons.qr_code_scanner_rounded,
                  label: CopyId.navScanTab,
                  isHighlighted: true,
                  onTap: () => context.push('/scan'),
                ),
              ),
              Expanded(
                child: _QuickActionCircle(
                  icon: Icons.add_rounded,
                  label: CopyId.navAddGold,
                  onTap: () => context.push('/demo-settings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: GoldPayTokens.space24),
          Row(
            children: [
              Expanded(
                child: Text(
                  CopyId.labelHistorySection,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () => context.go('/history'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          CopyId.navViewHistory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: GoldPayTokens.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: GoldPayTokens.primaryDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GoldPayTokens.space12),
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
          const SizedBox(height: GoldPayTokens.space16),
          const DemoBanner(),
          const SizedBox(height: GoldPayTokens.space12),
          Text(
            CopyId.disclaimerConcept,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCircle extends StatelessWidget {
  const _QuickActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? GoldPayTokens.gold
                      : GoldPayTokens.card,
                  borderRadius: BorderRadius.circular(18),
                  border: isHighlighted
                      ? null
                      : Border.all(color: GoldPayTokens.border),
                  boxShadow: [
                    BoxShadow(
                      color: isHighlighted
                          ? GoldPayTokens.gold.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: 24, color: GoldPayTokens.ink),
                ),
              ),
              const SizedBox(height: GoldPayTokens.space8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GoldPayTokens.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        vertical: GoldPayTokens.space24,
      ),
      decoration: BoxDecoration(
        color: GoldPayTokens.card,
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        border: Border.all(color: GoldPayTokens.border),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: GoldPayTokens.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: GoldPayTokens.primaryDark,
            ),
          ),
          const SizedBox(height: GoldPayTokens.space12),
          Text(
            CopyId.historyEmpty,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
