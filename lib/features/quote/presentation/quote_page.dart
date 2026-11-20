import 'dart:async';

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
import '../../checkout/application/checkout_controller.dart';

/// Quote / confirmation (docs/09 §2.4). Modern fintech styling.
class QuotePage extends ConsumerStatefulWidget {
  const QuotePage({super.key});

  @override
  ConsumerState<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends ConsumerState<QuotePage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  bool _processing = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _processing = true;
    });

    final config = ref.read(demoConfigProvider);
    await ref.read(checkoutProvider.notifier).confirm(config: config);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _processing = false;
    });
    context.pushReplacement('/result');
  }

  void _refresh() {
    final config = ref.read(demoConfigProvider);
    final balance =
        ref.read(demoStateProvider).value?.balanceUnits ??
        config.initialBalanceUnits;
    ref
        .read(checkoutProvider.notifier)
        .refreshQuote(config: config, balanceUnits: balance);
    setState(() => _now = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutProvider);
    final quote = checkout.quote;
    final draft = checkout.draft;
    final config = ref.watch(demoConfigProvider);
    final textTheme = Theme.of(context).textTheme;

    if (_processing) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: GoldPayTokens.primaryDark,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: GoldPayTokens.gold),
                  const SizedBox(height: GoldPayTokens.space24),
                  Text(
                    CopyId.statusProcessing,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (quote == null || draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(CopyId.screenQuoteTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(GoldPayTokens.pagePadding),
            child: AppButton(
              label: CopyId.navHome,
              onPressed: () => context.go('/'),
            ),
          ),
        ),
      );
    }

    final balance =
        ref.watch(demoStateProvider).value?.balanceUnits ??
        config.initialBalanceUnits;
    final expired = quote.isExpiredAt(_now);
    final insufficient = quote.goldUnits > balance;
    final canConfirm = !expired && !insufficient;

    return AppShell(
      titleText: CopyId.screenQuoteTitle,
      leading: IconButton(
        tooltip: CopyId.navBack,
        color: GoldPayTokens.ink,
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.close_rounded, size: 20),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          GoldPayTokens.pagePadding,
          GoldPayTokens.space8,
          GoldPayTokens.pagePadding,
          GoldPayTokens.space32,
        ),
        children: [
          // Total Hero Conversion Card
          Container(
            padding: const EdgeInsets.all(GoldPayTokens.space20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [GoldPayTokens.primaryDark, Color(0xFF144B3B)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: GoldPayTokens.primaryDark.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        CopyId.labelTotal.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9FC4B3),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: GoldPayTokens.space8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${formatRupiah(quote.goldBuybackPriceIdrPerGram)}/g',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GoldPayTokens.space12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRupiah(quote.totalIdr),
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CopyId.labelAmount}: ${formatRupiah(quote.paymentAmountIdr)}'
                  '${quote.qrFeeIdr > 0 ? ' (+${formatRupiah(quote.qrFeeIdr)})' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GoldPayTokens.space16),
          // Timer Countdown Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: expired
                    ? GoldPayTokens.danger.withValues(alpha: 0.1)
                    : GoldPayTokens.goldSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: expired
                      ? GoldPayTokens.danger.withValues(alpha: 0.3)
                      : GoldPayTokens.goldBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: expired
                        ? GoldPayTokens.danger
                        : GoldPayTokens.goldInk,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      expired
                          ? CopyId.quoteExpiredBody
                          : CopyId.quoteValidUntil.replaceFirst(
                              '{time}',
                              formatTimeId(quote.validUntil),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: expired
                            ? GoldPayTokens.danger
                            : GoldPayTokens.goldInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: GoldPayTokens.space16),
          // Conversion Details
          SectionCard(
            child: Column(
              children: [
                InfoRow(
                  label: CopyId.labelAmount,
                  value: formatRupiah(quote.paymentAmountIdr),
                ),
                if (quote.qrFeeIdr > 0)
                  InfoRow(
                    label: CopyId.labelQrFee,
                    value: formatRupiah(quote.qrFeeIdr),
                  ),
                InfoRow(
                  label: CopyId.labelGoldPriceUsed,
                  value: '${formatRupiah(quote.goldBuybackPriceIdrPerGram)}/g',
                ),
                InfoRow(
                  label: CopyId.labelGoldUsed,
                  value: formatGoldUnits(quote.goldUnits),
                  emphasize: true,
                ),
                InfoRow(
                  label: CopyId.labelGoldValue,
                  value: formatRupiah(quote.goldValueIdr),
                ),
                InfoRow(
                  label: CopyId.labelRounding,
                  value: formatRupiah(quote.roundingIdr),
                ),
                const Divider(height: 16),
                InfoRow(
                  label: CopyId.labelBalanceBefore,
                  value: formatGoldUnits(balance),
                ),
                InfoRow(
                  label: CopyId.labelBalanceAfter,
                  value: formatGoldUnits(balance - quote.goldUnits),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: GoldPayTokens.space12),
          Text(
            CopyId.quoteRoundingNote,
            style: textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            CopyId.disclaimerPrice,
            style: textTheme.bodySmall?.copyWith(
              color: GoldPayTokens.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GoldPayTokens.space12),
          Text(
            CopyId.quoteConfirmIntro,
            style: textTheme.bodyMedium?.copyWith(
              color: GoldPayTokens.goldInk,
              fontSize: 13,
            ),
          ),
          if (insufficient) ...[
            const SizedBox(height: GoldPayTokens.space12),
            Container(
              padding: const EdgeInsets.all(GoldPayTokens.space12),
              decoration: BoxDecoration(
                color: GoldPayTokens.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GoldPayTokens.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CopyId.statusInsufficient,
                    style: textTheme.bodyMedium?.copyWith(
                      color: GoldPayTokens.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CopyId.quoteInsufficientBody
                        .replaceFirst(
                          '{rupiah}',
                          formatRupiah(quote.shortfallIdr),
                        )
                        .replaceFirst(
                          '{gram}',
                          formatGoldUnits(quote.shortfallUnits),
                        ),
                    style: textTheme.bodySmall?.copyWith(
                      color: GoldPayTokens.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: GoldPayTokens.space20),
          if (expired)
            AppButton(
              label: CopyId.navRefreshQuote,
              variant: AppButtonVariant.gold,
              onPressed: _refresh,
            )
          else
            AppButton(
              label: CopyId.navConfirm,
              variant: AppButtonVariant.primary,
              onPressed: canConfirm ? _confirm : null,
            ),
          const SizedBox(height: GoldPayTokens.space8),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(checkoutProvider.notifier).cancel();
                context.go('/');
              },
              child: const Text(CopyId.navCancel),
            ),
          ),
          const SizedBox(height: GoldPayTokens.space12),
          const DemoBanner(),
        ],
      ),
    );
  }
}
