import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/demo_banner.dart';
import 'widgets/transaction_summary_card.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoStateProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: CopyId.navBack,
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(CopyId.screenHistoryTitle),
      ),
      body: demoState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(GoldPayTokens.pagePadding),
            child: AppButton(
              label: CopyId.navRetry,
              onPressed: () => ref.invalidate(demoStateProvider),
            ),
          ),
        ),
        data: (state) {
          if (state.transactions.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                GoldPayTokens.pagePadding,
                GoldPayTokens.space8,
                GoldPayTokens.pagePadding,
                GoldPayTokens.space32,
              ),
              children: [
                const DemoBanner(),
                const SizedBox(height: GoldPayTokens.space32),
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: GoldPayTokens.inkMuted,
                ),
                const SizedBox(height: GoldPayTokens.space8),
                Text(
                  CopyId.historyEmpty,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: GoldPayTokens.space24),
                AppButton(
                  label: CopyId.navScan,
                  onPressed: () => context.go('/scan'),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              GoldPayTokens.pagePadding,
              GoldPayTokens.space8,
              GoldPayTokens.pagePadding,
              GoldPayTokens.space32,
            ),
            itemCount: state.transactions.length + 1,
            separatorBuilder: (_, index) => SizedBox(
              height: index == 0
                  ? GoldPayTokens.space16
                  : GoldPayTokens.space12,
            ),
            itemBuilder: (context, index) {
              if (index == 0) return const DemoBanner();
              final transaction = state.transactions[index - 1];
              return TransactionSummaryCard(
                transaction: transaction,
                onTap: () => context.push('/history/'),
              );
            },
          );
        },
      ),
    );
  }
}
