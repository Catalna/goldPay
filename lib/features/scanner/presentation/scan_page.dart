import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/constants/copy_id.dart';
import '../../../core/constants/payment_source.dart';
import '../../../core/platform/app_settings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/demo_banner.dart';
import '../../checkout/application/checkout_controller.dart';
import '../../checkout/application/draft_builder.dart';
import '../../shared/presentation/qris_copy.dart';

/// Camera scanner (docs/09 §2.2). One decode stops the camera immediately and
/// the payload is never stored, only parsed into a draft.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late final MobileScannerController _controller;
  bool _handling = false;
  bool _processing = false;
  bool _permissionDenied = false;
  String? _errorCopy;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    try {
      await _controller.start();
      if (!mounted) return;
      setState(() {
        _permissionDenied = false;
        _errorCopy = null;
      });
    } on MobileScannerException catch (error) {
      if (!mounted) return;
      final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
      setState(() {
        _permissionDenied = denied;
        _errorCopy = denied
            ? CopyId.scannerDeniedBody
            : CopyId.scannerErrorBody;
      });
    }
  }

  Future<void> _resume() async {
    setState(() {
      _handling = false;
      _errorCopy = null;
    });
    await _start();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    String? payload;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        payload = value;
        break;
      }
    }
    if (payload == null) return;

    _handling = true;
    await _controller.stop();
    if (!mounted) return;

    setState(() => _processing = true);
    final result = buildDraft(payload, source: PaymentSource.camera);
    if (!mounted) return;

    if (result is DraftInvalid) {
      setState(() {
        _processing = false;
        _errorCopy = qrisErrorCopy(result.code);
      });
      return;
    }

    final draft = (result as DraftReady).draft;
    ref.read(checkoutProvider.notifier).start(draft);
    setState(() => _processing = false);

    await context.push('/review');
    if (!mounted) return;
    await _resume();
  }

  Future<void> _openPasteSheet() async {
    final controller = TextEditingController();
    String? error;
    final payload = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                GoldPayTokens.pagePadding,
                GoldPayTokens.space24,
                GoldPayTokens.pagePadding,
                MediaQuery.of(sheetContext).viewInsets.bottom +
                    GoldPayTokens.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CopyId.settingsPasteLabel,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: GoldPayTokens.space8),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: CopyId.settingsPasteHint,
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: GoldPayTokens.space16),
                  AppButton(
                    label: CopyId.settingsPasteAction,
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isEmpty) {
                        setSheetState(() => error = CopyId.errorEmptyPayload);
                        return;
                      }
                      Navigator.of(sheetContext).pop(value);
                    },
                  ),
                  const SizedBox(height: GoldPayTokens.space8),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text(CopyId.navCancel),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (payload == null || !mounted) return;

    final result = buildDraft(payload, source: PaymentSource.paste);
    if (result is DraftInvalid) {
      setState(() => _errorCopy = qrisErrorCopy(result.code));
      return;
    }
    final draft = (result as DraftReady).draft;
    ref.read(checkoutProvider.notifier).start(draft);
    await context.push('/review');
    if (!mounted) return;
    await _resume();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: CopyId.navCancel,
                  color: Colors.white,
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Text(
                    CopyId.scannerTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: GoldPayTokens.minTouchTarget),
              ],
            ),
            Expanded(
              child: _errorCopy != null
                  ? _ScannerError(
                      message: _errorCopy!,
                      showSettings: _permissionDenied,
                      onRetry: _resume,
                      onPaste: _openPasteSheet,
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error) => _ScannerError(
                            message:
                                error.errorCode ==
                                    MobileScannerErrorCode.permissionDenied
                                ? CopyId.scannerDeniedBody
                                : CopyId.scannerErrorBody,
                            showSettings:
                                error.errorCode ==
                                MobileScannerErrorCode.permissionDenied,
                            onRetry: _resume,
                            onPaste: _openPasteSheet,
                          ),
                        ),
                        const IgnorePointer(child: _ScannerFrame()),
                        if (_processing)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: GoldPayTokens.space16),
                                  Text(
                                    CopyId.scannerProcessing,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(GoldPayTokens.pagePadding),
              child: Column(
                children: [
                  Text(
                    CopyId.scannerHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: GoldPayTokens.space16),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      if (state.torchState == TorchState.unavailable) {
                        return const SizedBox.shrink();
                      }
                      final on = state.torchState == TorchState.on;
                      return OutlinedButton.icon(
                        onPressed: () => _controller.toggleTorch(),
                        icon: Icon(on ? Icons.flash_on : Icons.flash_off),
                        label: const Text(CopyId.scannerTorch),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: GoldPayTokens.space8),
                  TextButton(
                    onPressed: _openPasteSheet,
                    child: Text(
                      CopyId.scannerPasteFallback,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: GoldPayTokens.space8),
                  const DemoBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({
    required this.message,
    required this.showSettings,
    required this.onRetry,
    required this.onPaste,
  });

  final String message;
  final bool showSettings;
  final VoidCallback onRetry;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GoldPayTokens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 40,
              color: Colors.white70,
            ),
            const SizedBox(height: GoldPayTokens.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: GoldPayTokens.space24),
            AppButton(label: CopyId.navRetry, onPressed: onRetry),
            if (showSettings) ...[
              const SizedBox(height: GoldPayTokens.space8),
              AppButton(
                label: CopyId.dialogPermissionSettings,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  openAppSettings();
                },
              ),
            ],
            const SizedBox(height: GoldPayTokens.space8),
            AppButton(
              label: CopyId.scannerPasteFallback,
              variant: AppButtonVariant.secondary,
              onPressed: onPaste,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(painter: _FramePainter()),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const corner = 28.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, corner)
      ..lineTo(0, 0)
      ..lineTo(corner, 0)
      ..moveTo(size.width - corner, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, corner)
      ..moveTo(size.width, size.height - corner)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - corner, size.height)
      ..moveTo(corner, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - corner);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
