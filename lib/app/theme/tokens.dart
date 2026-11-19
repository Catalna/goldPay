import 'package:material_ui/material_ui.dart';

/// Design tokens from docs/09_UI_UX_SCREEN_SPEC.md.
/// Do not invent colors, sizes, or radii in widgets.
abstract final class GoldPayTokens {
  // Color
  static const Color primary = Color(0xFF0F6B4F);
  static const Color primaryDark = Color(0xFF0A4B38);
  static const Color primarySoft = Color(0xFFD7F0E6);
  static const Color gold = Color(0xFFC9973A);
  static const Color goldSoft = Color(0xFFF6E7C8);
  static const Color goldBorder = Color(0x33C9973A);
  static const Color goldInk = Color(0xFF6B4A12);
  static const Color ink = Color(0xFF0E1512);
  static const Color inkMuted = Color(0xFF46524C);
  static const Color border = Color(0xFFE1E8E5);
  static const Color surface = Color(0xFFF6F8F7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF177A4C);
  static const Color warning = Color(0xFFB4690E);
  static const Color danger = Color(0xFFB3261E);
  static const Color info = Color(0xFF1F5FA8);

  // Spacing (multiples of 4)
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  // Layout
  static const double pagePadding = 20;
  static const double cardRadius = 12;
  static const double sheetRadius = 16;
  static const double buttonHeight = 52;
  static const double minTouchTarget = 48;

  // Motion
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
}
