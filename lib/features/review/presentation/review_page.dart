import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/formatters/money.dart';
import '../../../core/formatters/rupiah_input_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../core/widgets/section_card.dart';
import '../../checkout/application/checkout_controller.dart';
import '../../shared/presentation/qris_copy.dart';

/// Review / nominal entry (docs/09 §2.3). Dynamic QRs lock the amount.
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: CopyId.navBack,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(CopyId.screenReviewTitle),
      ),
      body: ListView(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantNameCopy(draft.merchantName),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: GoldPayTokens.space4),
                Text(
                  '${merchantCityCopy(draft.merchantCity)} · '
                  '${issuerCopy(draft.merchantIssuerGui)}',
                  style: textTheme.bodySmall,
                ),
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
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 18,
                      color: draft.crcValid
                          ? GoldPayTokens.info
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
              ],
            ),
          ),
          if (draft.warningCodes.isNotEmpty) ...[
            const SizedBox(height: GoldPayTokens.space12),
            _WarningsCard(codes: draft.warningCodes),
          ],
          const SizedBox(height: GoldPayTokens.space24),
          if (draft.amountReadOnly) ...[
            Text(CopyId.labelAmount, style: textTheme.bodySmall),
            const SizedBox(height: GoldPayTokens.space4),
            Text(
              formatRupiah(amount),
              style: textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: GoldPayTokens.space4),
            Text(CopyId.labelQrAmountLocked, style: textTheme.bodySmall),
          ] else ...[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              onChanged: (value) =>
                  _validate(value, config.minPaymentIdr, config.maxPaymentIdr),
              decoration: InputDecoration(
                labelText: CopyId.labelAmount,
                prefixText: 'Rp',
                errorText: _error,
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
      padding: const EdgeInsets.symmetric(
        horizontal: GoldPayTokens.space12,
        vertical: GoldPayTokens.space4,
      ),
      decoration: BoxDecoration(
        color: GoldPayTokens.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: GoldPayTokens.primaryDark,
          fontWeight: FontWeight.w600,
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
                    Icons.info_outline,
                    size: 18,
                    color: GoldPayTokens.warning,
                  ),
                  const SizedBox(width: GoldPayTokens.space8),
                  Expanded(
                    child: Text(
                      qrisWarningCopy(code),
                      style: textTheme.bodySmall,
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
