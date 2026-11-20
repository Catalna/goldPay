import 'package:material_ui/material_ui.dart';

import '../../app/theme/tokens.dart';

/// Label/value pair used in quote, settings, and receipt rows.
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: GoldPayTokens.inkMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: GoldPayTokens.space16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: emphasize
                  ? textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GoldPayTokens.ink,
                      fontSize: 15,
                    )
                  : textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: GoldPayTokens.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
