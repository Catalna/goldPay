import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/formatters/money.dart';
import '../../../core/formatters/rupiah_input_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_card.dart';
import '../../checkout/application/checkout_controller.dart';
import '../../shared/presentation/qris_copy.dart';

/// Review / nominal entry (docs/09 §2.3). Modern fintech styling.
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  late final TextEditingController _amountController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(checkoutProvider).draft;
    final initial = draft == null || draft.paymentAmountIdr <= 0
        ? ''
        : formatRupiah(draft.paymentAmountIdr).replaceFirst('Rp', '');
    _amountController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validate(String text, int configMin, int configMax) {
    final amount = parseRupiahDigits(text);
    final String? error;
    if (text.trim().isEmpty || amount == 0) {
      error = CopyId.validationAmountRequired;
    } else if (amount < configMin) {
      error = CopyId.validationAmountMin;
    } else if (amount > configMax) {
      error = CopyId.validationAmountMax;
    } else {
      error = null;
    }
    if (error != _error) setState(() => _error = error);
  }

  void _setPresetAmount(int amount) {
    _amountController.text = formatRupiah(amount).replaceFirst('Rp', '');
    final config = ref.read(demoConfigProvider);
    _validate(
      _amountController.text,
      config.minPaymentIdr,
      config.maxPaymentIdr,
    );
  }

  void _continue() {
    final config = ref.read(demoConfigProvider);
    final draft = ref.read(checkoutProvider).draft;
    if (draft == null) return;

    final amount = draft.amountReadOnly
        ? draft.paymentAmountIdr
        : parseRupiahDigits(_amountController.text);
    if (amount < config.minPaymentIdr || amount > config.maxPaymentIdr) {
      setState(
        () => _error = amount < config.minPaymentIdr
            ? CopyId.validationAmountMin
            : CopyId.validationAmountMax,
      );
      return;
    }

    final controller = ref.read(checkoutProvider.notifier);
    controller.setAmount(amount);

    final balance =
        ref.read(demoStateProvider).value?.balanceUnits ??
        config.initialBalanceUnits;
    final quote = controller.createQuote(config: config, balanceUnits: balance);
    if (quote == null) return;
    context.push('/quote');
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutProvider);
    final draft = checkout.draft;
    final config = ref.watch(demoConfigProvider);
    final textTheme = Theme.of(context).textTheme;

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(CopyId.screenReviewTitle)),
        body: const _MissingDraft(),
      );
    }

    final amount = draft.amountReadOnly
        ? draft.paymentAmountIdr
        : parseRupiahDigits(_amountController.text);
    final canContinue = draft.amountReadOnly
        ? amount >= config.minPaymentIdr && amount <= config.maxPaymentIdr
        : _error == null &&
              amount >= config.minPaymentIdr &&
              amount <= config.maxPaymentIdr;

    return AppShell(
      titleText: CopyId.screenReviewTitle,
      leading: IconButton(
        tooltip: CopyId.navBack,
        color: GoldPayTokens.ink,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          GoldPayTokens.pagePadding,
          GoldPayTokens.space8,
          GoldPayTokens.pagePadding,
          GoldPayTokens.space32,
        ),
        children: [
          const DemoBanner(),
          const SizedBox(height: GoldPayTokens.space16),
          // Merchant Card
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: GoldPayTokens.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          color: GoldPayTokens.primaryDark,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: GoldPayTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchantNameCopy(draft.merchantName),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${merchantCityCopy(draft.merchantCity)} · '
                            '${issuerCopy(draft.merchantIssuerGui)}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GoldPayTokens.space16),
                const Divider(height: 1),
                const SizedBox(height: GoldPayTokens.space12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Chip(label: qrKindCopy(draft.qrKind)),
                ),
                const SizedBox(height: GoldPayTokens.space8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      draft.crcValid
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: draft.crcValid
                          ? GoldPayTokens.success
                          : GoldPayTokens.warning,
                    ),
                    const SizedBox(width: GoldPayTokens.space8),
                    Expanded(
                      child: Text(
                        draft.crcValid
                            ? CopyId.valueCrcValid
                            : CopyId.valueCrcInvalid,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GoldPayTokens.space8),
                InfoRow(
                  label: CopyId.labelSource,
                  value: sourceCopy(draft.source),
                ),
              ],
            ),
          ),
          if (draft.warningCodes.isNotEmpty) ...[
            const SizedBox(height: GoldPayTokens.space12),
            _WarningsCard(codes: draft.warningCodes),
          ],
          const SizedBox(height: GoldPayTokens.space20),
          // Amount Section
          if (draft.amountReadOnly) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(CopyId.labelAmount, style: textTheme.bodySmall),
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: GoldPayTokens.inkMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: GoldPayTokens.space8),
                  Text(
                    formatRupiah(amount),
                    style: textTheme.displaySmall?.copyWith(
                      color: GoldPayTokens.ink,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: GoldPayTokens.space4),
                  Text(
                    CopyId.labelQrAmountLocked,
                    style: textTheme.bodySmall?.copyWith(
                      color: GoldPayTokens.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CopyId.labelAmount,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: GoldPayTokens.space12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [RupiahInputFormatter()],
                    onChanged: (value) => _validate(
                      value,
                      config.minPaymentIdr,
                      config.maxPaymentIdr,
                    ),
                    decoration: InputDecoration(
                      labelText: CopyId.labelAmount,
                      prefixText: 'Rp',
                      errorText: _error,
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: GoldPayTokens.space12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [10000, 25000, 50000, 100000].map((preset) {
                      return ActionChip(
                        label: Text(
                          formatRupiah(preset),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: GoldPayTokens.surface,
                        side: const BorderSide(color: GoldPayTokens.border),
                        shape: const StadiumBorder(),
                        onPressed: () => _setPresetAmount(preset),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: GoldPayTokens.space24),
          AppButton(
            label: CopyId.navContinue,
            onPressed: canContinue ? _continue : null,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GoldPayTokens.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: GoldPayTokens.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      backgroundColor: GoldPayTokens.goldSoft,
      borderColor: GoldPayTokens.goldBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final code in codes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: GoldPayTokens.warning,
                  ),
                  const SizedBox(width: GoldPayTokens.space8),
                  Expanded(
                    child: Text(
                      qrisWarningCopy(code),
                      style: textTheme.bodySmall?.copyWith(
                        color: GoldPayTokens.goldInk,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MissingDraft extends StatelessWidget {
  const _MissingDraft();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GoldPayTokens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CopyId.errorEmptyPayload,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: GoldPayTokens.space16),
            AppButton(label: CopyId.navHome, onPressed: () => context.go('/')),
          ],
        ),
      ),
    );
  }
}
