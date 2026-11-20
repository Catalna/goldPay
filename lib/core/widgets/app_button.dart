import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';

enum AppButtonVariant { primary, secondary, danger, gold }

/// Action button: 52 dp tall, pill-shaped stadium border, full width.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge;

    final ButtonStyle style = switch (variant) {
      AppButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: GoldPayTokens.primaryDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: GoldPayTokens.border,
        disabledForegroundColor: GoldPayTokens.inkMuted,
        textStyle: textStyle,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      AppButtonVariant.gold => FilledButton.styleFrom(
        backgroundColor: GoldPayTokens.gold,
        foregroundColor: GoldPayTokens.ink,
        disabledBackgroundColor: GoldPayTokens.border,
        disabledForegroundColor: GoldPayTokens.inkMuted,
        textStyle: textStyle?.copyWith(color: GoldPayTokens.ink),
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      AppButtonVariant.danger => FilledButton.styleFrom(
        backgroundColor: GoldPayTokens.danger,
        foregroundColor: Colors.white,
        textStyle: textStyle,
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      AppButtonVariant.secondary => OutlinedButton.styleFrom(
        foregroundColor: GoldPayTokens.ink,
        backgroundColor: GoldPayTokens.card,
        textStyle: textStyle?.copyWith(color: GoldPayTokens.ink),
        side: const BorderSide(color: GoldPayTokens.border),
        elevation: 0,
        shape: const StadiumBorder(),
      ),
    };

    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: GoldPayTokens.space8),
              Text(label),
            ],
          );

    return SizedBox(
      height: GoldPayTokens.buttonHeight,
      width: double.infinity,
      child: variant == AppButtonVariant.secondary
          ? OutlinedButton(onPressed: onPressed, style: style, child: child)
          : FilledButton(onPressed: onPressed, style: style, child: child),
    );
  }
}
