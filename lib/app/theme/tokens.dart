import 'package:material_ui/material_ui.dart';

/// Design tokens inspired by modern fintech aesthetics.
/// Do not invent arbitrary colors, sizes, or radii in widgets.
abstract final class GoldPayTokens {
  // Color Palette
  static const Color primary = Color(0xFF0F6B4F); // Rich forest emerald
  static const Color primaryDark = Color(
    0xFF0D3B2E,
  ); // Deep forest green from hero card
  static const Color primarySoft = Color(0xFFDCECE4); // Soft sage green
  static const Color primaryContainer = Color(
    0xFF144B3B,
  ); // Dark green container
  static const Color gold = Color(
    0xFFEAA93B,
  ); // Warm golden amber from action buttons
  static const Color goldSoft = Color(0xFFFBF4E6); // Light soft cream-gold
  static const Color goldBorder = Color(0x33EAA93B);
  static const Color goldInk = Color(0xFF6B4A12);
  static const Color ink = Color(0xFF131A16); // High contrast dark charcoal
  static const Color inkMuted = Color(0xFF6A7971); // Clean slate grey
  static const Color border = Color(0xFFE8E4DA); // Subtle warm border
  static const Color surface = Color(0xFFF6F4EE); // Warm linen/cream background
  static const Color card = Color(0xFFFFFFFF); // Pure crisp white card
  static const Color success = Color(0xFF177A4C);
  static const Color warning = Color(0xFFB4690E);
  static const Color danger = Color(0xFFB3261E);
  static const Color info = Color(0xFF1F5FA8);

  // Spacing (multiples of 4)
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Layout
  static const double pagePadding = 20;
  static const double cardRadius = 20;
  static const double sheetRadius = 24;
  static const double buttonHeight = 52;
  static const double minTouchTarget = 48;
  static const double navBarHeight = 84;
  static const double navScanButtonSize = 52;
  static const double headerOverlap = 24;

  // Motion
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
}
