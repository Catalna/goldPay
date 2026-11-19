import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

const String _fontFamily = 'PlusJakartaSans';

/// Theme built only from docs/09 tokens. Do not add ad-hoc styling in widgets.
ThemeData buildGoldPayTheme() {
  final ColorScheme scheme =
      ColorScheme.fromSeed(
        seedColor: GoldPayTokens.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: GoldPayTokens.primary,
        onPrimary: Colors.white,
        surface: GoldPayTokens.surface,
        onSurface: GoldPayTokens.ink,
        error: GoldPayTokens.danger,
        outline: GoldPayTokens.border,
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: GoldPayTokens.surface,
    dividerColor: GoldPayTokens.border,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: GoldPayTokens.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: GoldPayTokens.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        color: GoldPayTokens.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: GoldPayTokens.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: GoldPayTokens.ink,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: GoldPayTokens.inkMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 20 / 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GoldPayTokens.surface,
      foregroundColor: GoldPayTokens.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GoldPayTokens.card,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GoldPayTokens.space16,
        vertical: GoldPayTokens.space16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        borderSide: const BorderSide(color: GoldPayTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        borderSide: const BorderSide(color: GoldPayTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GoldPayTokens.cardRadius),
        borderSide: const BorderSide(color: GoldPayTokens.primary, width: 1.5),
      ),
    ),
  );
}
