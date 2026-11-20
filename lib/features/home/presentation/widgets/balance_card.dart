import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/constants/copy_id.dart';

/// Hero balance card modeled directly from the user's reference design:
/// Deep forest green card with subtle curved contour watermark, large balance,
/// rate pill, and dual action pill buttons (+ Top Up and Scan).
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.grams,
    required this.valueRupiah,
    required this.buybackPriceRupiah,
    this.onTopUp,
    this.onScan,
    super.key,
  });

  final String grams;
  final String valueRupiah;
  final String buybackPriceRupiah;
  final VoidCallback? onTopUp;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label:
          '${CopyId.labelBalance}, $grams, '
          '${CopyId.labelBalanceRupiah} $valueRupiah',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GoldPayTokens.primaryDark, Color(0xFF124738)],
          ),
          boxShadow: [
            BoxShadow(
              color: GoldPayTokens.primaryDark.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CardCurvesPainter())),
            Padding(
              padding: const EdgeInsets.all(GoldPayTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          CopyId.labelBalance.toUpperCase(),
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
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  size: 14,
                                  color: GoldPayTokens.gold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  buybackPriceRupiah,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
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
                      grams,
                      style: textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '•••• 4221 · ${CopyId.labelBalanceRupiah} $valueRupiah',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'IDR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GoldPayTokens.space20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: onTopUp,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: GoldPayTokens.gold,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: GoldPayTokens.ink,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      CopyId.navAddGold,
                                      style: TextStyle(
                                        color: GoldPayTokens.ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: GoldPayTokens.space12),
                      Expanded(
                        child: InkWell(
                          onTap: onScan,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      CopyId.navScan,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for subtle geometric wave lines in the background.
class _CardCurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path1 = Path();
    path1.moveTo(size.width * 0.45, 0);
    path1.cubicTo(
      size.width * 0.65,
      size.height * 0.35,
      size.width * 0.75,
      size.height * 0.8,
      size.width * 1.1,
      size.height * 0.95,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width * 0.6, 0);
    path2.cubicTo(
      size.width * 0.78,
      size.height * 0.3,
      size.width * 0.85,
      size.height * 0.7,
      size.width * 1.15,
      size.height * 0.85,
    );
    canvas.drawPath(path2, paint);

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.35),
      size.width * 0.32,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
