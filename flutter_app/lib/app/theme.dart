import 'package:flutter/material.dart';

/// Design tokens taken from the supplied Tawasul screens.
class TawasulColors {
  static const forest = Color(0xFF1E3D2B);
  static const forestDeep = Color(0xFF14291D);
  static const cream = Color(0xFFF6F1E7);
  static const card = Color(0xFFFFFDF8);
  static const red = Color(0xFFD9503F);
  static const gold = Color(0xFFD9A94B);
  static const mint = Color(0xFFD6E7DC);
  static const sage = Color(0xFFD5E0C0);
  static const green = Color(0xFF5B9268);
  static const muted = Color(0xFF6E7B71);
}

ThemeData buildTawasulTheme() {
  const scheme = ColorScheme.light(
    primary: TawasulColors.forest,
    onPrimary: TawasulColors.cream,
    secondary: TawasulColors.gold,
    onSecondary: TawasulColors.forestDeep,
    tertiary: TawasulColors.green,
    error: TawasulColors.red,
    onError: Colors.white,
    surface: TawasulColors.card,
    onSurface: TawasulColors.forestDeep,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TawasulColors.cream,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: TawasulColors.forestDeep,
      displayColor: TawasulColors.forest,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TawasulColors.cream,
      foregroundColor: TawasulColors.forest,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: TawasulColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x141E3D2B)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x221E3D2B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x221E3D2B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide:
            const BorderSide(color: TawasulColors.forest, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TawasulColors.forest,
        foregroundColor: TawasulColors.cream,
        minimumSize: const Size.fromHeight(56),
        textStyle:
            const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: TawasulColors.card,
      indicatorColor: TawasulColors.gold,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0x141E3D2B)),
  );
}
