import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

/// Camera scanner (docs/09 §2.2). Redesigned to be exceptionally user-friendly
/// with modern corner markers, quick gallery picker, flashlight toggle,
/// and paste fallback.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _animController.dispose();
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

  Future<void> _pickFromGallery() async {
    if (_processing) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _processing = true);
      final capture = await _controller.analyzeImage(
        picked.path,
        formats: const [BarcodeFormat.qrCode],
      );
      final payload = capture?.barcodes
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .firstOrNull;

      if (payload == null) {
        if (!mounted) return;
        setState(() {
          _processing = false;
          _errorCopy = CopyId.settingsGalleryError;
        });
        return;
      }

      final result = buildDraft(payload, source: PaymentSource.gallery);
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorCopy = CopyId.settingsGalleryError;
      });
    }
  }

  Future<void> _openPasteSheet() async {
    final controller = TextEditingController();
    String? error;
    final payload = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GoldPayTokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: GoldPayTokens.goldSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.content_paste_rounded,
                          size: 18,
                          color: GoldPayTokens.goldInk,
                        ),
                      ),
                      const SizedBox(width: GoldPayTokens.space12),
                      Expanded(
                        child: Text(
                          CopyId.settingsPasteLabel,
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: GoldPayTokens.space16),
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
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text(CopyId.navCancel),
                    ),
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
            // Modern Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GoldPayTokens.pagePadding,
                vertical: GoldPayTokens.space8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: CopyId.navCancel,
                      color: Colors.white,
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      CopyId.scannerTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      final on = state.torchState == TorchState.on;
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: on
                              ? GoldPayTokens.gold
                              : Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: CopyId.scannerTorch,
                          color: on ? GoldPayTokens.ink : Colors.white,
                          onPressed: () => _controller.toggleTorch(),
                          icon: Icon(
                            on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Scanner Viewport
            Expanded(
              child: _errorCopy != null
                  ? _ScannerError(
                      message: _errorCopy!,
                      showSettings: _permissionDenied,
                      onRetry: _resume,
                      onPaste: _openPasteSheet,
                      onPickGallery: _pickFromGallery,
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
                            onPickGallery: _pickFromGallery,
                          ),
                        ),
                        // Darkened overlay with rounded cutout
                        const _ScannerOverlay(),
                        // Reticle with laser animation
                        _ScannerFrame(animation: _animController),
                        // Top floating instruction hint
                        Positioned(
                          top: 24,
                          left: 24,
                          right: 24,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 16,
                                    color: GoldPayTokens.gold,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      CopyId.scannerHint,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_processing)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: GoldPayTokens.gold,
                                    ),
                                    const SizedBox(
                                      height: GoldPayTokens.space16,
                                    ),
                                    Text(
                                      CopyId.scannerProcessing,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            // Bottom Action Deck
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141916),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                GoldPayTokens.pagePadding,
                GoldPayTokens.space16,
                GoldPayTokens.pagePadding,
                GoldPayTokens.space16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(
                            Icons.photo_library_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            CopyId.settingsGalleryAction,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: GoldPayTokens.space12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openPasteSheet,
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            CopyId.scannerPasteFallback,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GoldPayTokens.space12),
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

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final boxSize = (width * 0.72).clamp(240.0, 300.0);

        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = (constraints.maxWidth * 0.72).clamp(240.0, 300.0);

        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(boxSize, boxSize),
                  painter: _FramePainter(),
                ),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    return Positioned(
                      top: 16 + (boxSize - 32) * animation.value,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              GoldPayTokens.gold.withValues(alpha: 0.0),
                              GoldPayTokens.gold,
                              GoldPayTokens.gold.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GoldPayTokens.gold.withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const corner = 32.0;
    const strokeWidth = 3.5;

    final paint = Paint()
      ..color = GoldPayTokens.gold
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Top Left
    path.moveTo(0, corner);
    path.arcToPoint(const Offset(corner, 0), radius: const Radius.circular(24));

    // Top Right
    path.moveTo(size.width - corner, 0);
    path.arcToPoint(
      Offset(size.width, corner),
      radius: const Radius.circular(24),
    );

    // Bottom Right
    path.moveTo(size.width, size.height - corner);
    path.arcToPoint(
      Offset(size.width - corner, size.height),
      radius: const Radius.circular(24),
    );

    // Bottom Left
    path.moveTo(corner, size.height);
    path.arcToPoint(
      Offset(0, size.height - corner),
      radius: const Radius.circular(24),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({
    required this.message,
    required this.showSettings,
    required this.onRetry,
    required this.onPaste,
    required this.onPickGallery,
  });

  final String message;
  final bool showSettings;
  final VoidCallback onRetry;
  final VoidCallback onPaste;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GoldPayTokens.pagePadding),
        child: Container(
          padding: const EdgeInsets.all(GoldPayTokens.space24),
          decoration: BoxDecoration(
            color: const Color(0xFF19201C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: GoldPayTokens.danger.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_photography_rounded,
                  size: 28,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: GoldPayTokens.space16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: GoldPayTokens.space24),
              AppButton(label: CopyId.navRetry, onPressed: onRetry),
              if (showSettings) ...[
                const SizedBox(height: GoldPayTokens.space12),
                AppButton(
                  label: CopyId.dialogPermissionSettings,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => openAppSettings(),
                ),
              ],
              const SizedBox(height: GoldPayTokens.space12),
              AppButton(
                label: CopyId.settingsGalleryAction,
                variant: AppButtonVariant.secondary,
                onPressed: onPickGallery,
              ),
              const SizedBox(height: GoldPayTokens.space12),
              AppButton(
                label: CopyId.scannerPasteFallback,
                variant: AppButtonVariant.secondary,
                onPressed: onPaste,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
