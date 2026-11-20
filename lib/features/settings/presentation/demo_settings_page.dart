import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/constants/payment_source.dart';
import '../../../core/formatters/gold.dart';
import '../../../core/formatters/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/section_card.dart';
import '../../checkout/application/checkout_controller.dart';
import '../../checkout/application/draft_builder.dart';
import '../../shared/presentation/qris_copy.dart';

/// Demo Settings (docs/09 §2.9): fallbacks, balance, data, info. Modern styling.
class DemoSettingsPage extends ConsumerStatefulWidget {
  const DemoSettingsPage({super.key});

  @override
  ConsumerState<DemoSettingsPage> createState() => _DemoSettingsPageState();
}

class _DemoSettingsPageState extends ConsumerState<DemoSettingsPage> {
  final TextEditingController _pasteController = TextEditingController();
  String? _pasteError;
  bool _busy = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _usePastedPayload() async {
    final payload = _pasteController.text.trim();
    if (payload.isEmpty) {
      setState(() => _pasteError = CopyId.errorEmptyPayload);
      return;
    }
    await _openDraft(payload, PaymentSource.paste);
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _pasteError = null;
    });
    final controller = MobileScannerController(autoStart: false);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final capture = await controller.analyzeImage(
        picked.path,
        formats: const [BarcodeFormat.qrCode],
      );
      final payload = capture?.barcodes
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .firstOrNull;
      if (payload == null) {
        if (mounted) setState(() => _pasteError = CopyId.settingsGalleryError);
        return;
      }
      await _openDraft(payload, PaymentSource.gallery);
    } catch (_) {
      if (mounted) setState(() => _pasteError = CopyId.settingsGalleryError);
    } finally {
      await controller.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDraft(String payload, String source) async {
    final result = buildDraft(payload, source: source);
    if (result is DraftInvalid) {
      setState(() => _pasteError = qrisErrorCopy(result.code));
      return;
    }
    setState(() => _pasteError = null);
    ref.read(checkoutProvider.notifier).start((result as DraftReady).draft);
    await context.push('/review');
  }

  Future<void> _addGold() async {
    final controller = TextEditingController();
    String? error;
    final units = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: GoldPayTokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GoldPayTokens.sheetRadius),
              ),
              title: const Text(
                CopyId.dialogAddGoldTitle,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(CopyId.dialogAddGoldBody),
                  const SizedBox(height: GoldPayTokens.space16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: CopyId.dialogAddGoldField,
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(CopyId.navCancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: GoldPayTokens.primaryDark,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    final parsed = parseGoldGramsToUnits(controller.text);
                    if (parsed == null || parsed <= 0) {
                      setDialogState(
                        () => error = CopyId.validationGoldInvalid,
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(parsed);
                  },
                  child: const Text(CopyId.dialogAddGoldConfirm),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (units == null || !mounted) return;

    try {
      await ref.read(demoStateProvider.notifier).addGold(units);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(CopyId.resultFailedBody)));
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: GoldPayTokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldPayTokens.sheetRadius),
        ),
        title: const Text(
          CopyId.dialogResetTitle,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(CopyId.dialogResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(CopyId.navCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GoldPayTokens.danger,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(CopyId.dialogResetConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(demoStateProvider.notifier).reset();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(CopyId.resultFailedBody)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final forceFailure = ref.watch(forceFailureProvider);
    final demoState = ref.watch(demoStateProvider);
    final config = ref.watch(demoConfigProvider);
    final appVersion = ref.watch(appVersionProvider);
    final balanceUnits = demoState.value?.balanceUnits;
    final txCount = demoState.value?.transactions.length;

    return AppShell(
      currentTab: AppShellTab.settings,
      titleText: CopyId.screenSettingsTitle,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GoldPayTokens.goldSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GoldPayTokens.goldBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.handyman_rounded,
                  size: 16,
                  color: GoldPayTokens.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CopyId.settingsDevOnly,
                    style: textTheme.bodySmall?.copyWith(
                      color: GoldPayTokens.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GoldPayTokens.space20),
          Text(
            CopyId.settingsSectionFallback,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: GoldPayTokens.space8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _pasteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: CopyId.settingsPasteLabel,
                    hintText: CopyId.settingsPasteHint,
                    errorText: _pasteError,
                  ),
                ),
                const SizedBox(height: GoldPayTokens.space12),
                AppButton(
                  label: CopyId.settingsPasteAction,
                  variant: AppButtonVariant.primary,
                  onPressed: _busy ? null : _usePastedPayload,
                ),
                const SizedBox(height: GoldPayTokens.space8),
                AppButton(
                  label: CopyId.settingsGalleryAction,
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _pickFromGallery,
                ),
                const Divider(height: GoldPayTokens.space24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: GoldPayTokens.primaryDark,
                  title: Text(
                    CopyId.settingsFailureToggle,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(CopyId.settingsFailureHint),
                  value: forceFailure,
                  onChanged: (value) =>
                      ref.read(forceFailureProvider.notifier).set(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: GoldPayTokens.space24),
          Text(
            CopyId.settingsSectionBalance,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: GoldPayTokens.space8),
          SectionCard(
            child: Column(
              children: [
                InfoRow(
                  label: CopyId.labelBalance,
                  value: balanceUnits == null
                      ? '—'
                      : formatGoldUnits(balanceUnits),
                  emphasize: true,
                ),
                InfoRow(
                  label: CopyId.labelBalanceRupiah,
                  value: balanceUnits == null
                      ? '—'
                      : formatRupiah(
                          balanceUnits *
                              config.goldBuybackPriceIdrPerGram ~/
                              10000,
                        ),
                ),
                const SizedBox(height: GoldPayTokens.space12),
                AppButton(
                  label: CopyId.navAddGold,
                  variant: AppButtonVariant.gold,
                  onPressed: _addGold,
                ),
              ],
            ),
          ),
          const SizedBox(height: GoldPayTokens.space24),
          Text(
            CopyId.settingsSectionData,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: GoldPayTokens.space8),
          AppButton(
            label: CopyId.navReset,
            variant: AppButtonVariant.danger,
            onPressed: _reset,
          ),
          const SizedBox(height: GoldPayTokens.space24),
          Text(
            CopyId.settingsSectionInfo,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: GoldPayTokens.space8),
          SectionCard(
            child: Column(
              children: [
                InfoRow(label: CopyId.settingsAppVersion, value: appVersion),
                InfoRow(
                  label: CopyId.labelConfigVersion,
                  value: config.version,
                ),
                InfoRow(
                  label: CopyId.settingsTxCount,
                  value: '${txCount ?? 0}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
