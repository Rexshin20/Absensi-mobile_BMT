import 'package:flutter/material.dart';

const Color brandPrimary = Color(0xFF087A45);
const Color brandDark = Color(0xFF075C35);
const Color brandLight = Color(0xFFE6F4EC);
const Color surfaceMuted = Color(0xFFF4F8F5);
const Color borderSoft = Color(0xFFDCE7E0);
const Color textStrong = Color(0xFF3A3541);
const Color textMuted = Color(0xFF6B6773);
const Color successMain = Color(0xFF2E7D32);
const Color warningMain = Color(0xFFED6C02);
const Color errorMain = Color(0xFFD32F2F);
const Color infoMain = Color(0xFF00AAFF);

ThemeData buildAppTheme() {
  return _buildAppTheme(
    brightness: Brightness.light,
    surface: Colors.white,
    scaffoldBackground: surfaceMuted,
    onSurface: textStrong,
    onSurfaceVariant: textMuted,
    outline: borderSoft,
    inputFill: Colors.white,
  );
}

ThemeData buildAppDarkTheme() {
  return _buildAppTheme(
    brightness: Brightness.dark,
    surface: const Color(0xFF18211C),
    scaffoldBackground: const Color(0xFF101713),
    onSurface: const Color(0xFFE8EFEA),
    onSurfaceVariant: const Color(0xFFB2BFB7),
    outline: const Color(0xFF35483D),
    inputFill: const Color(0xFF202B24),
    primary: const Color(0xFF63D59A),
  );
}

ThemeData _buildAppTheme({
  required Brightness brightness,
  required Color surface,
  required Color scaffoldBackground,
  required Color onSurface,
  required Color onSurfaceVariant,
  required Color outline,
  required Color inputFill,
  Color primary = brandPrimary,
}) {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: brightness,
      primary: primary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
    ),
    scaffoldBackgroundColor: scaffoldBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: brightness == Brightness.dark
            ? const Color(0xFF07371F)
            : Colors.white,
        disabledBackgroundColor: const Color(0xFFA8D4BB),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
  );
}
