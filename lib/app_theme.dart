import 'package:flutter/material.dart';

const Color brandPrimary = Color(0xFF9155FD);
const Color surfaceMuted = Color(0xFFF4F5FA);
const Color borderSoft = Color(0xFFE7E7F0);
const Color textStrong = Color(0xFF3A3541);
const Color textMuted = Color(0xFF6B6773);
const Color successMain = Color(0xFF2E7D32);
const Color warningMain = Color(0xFFED6C02);
const Color errorMain = Color(0xFFD32F2F);
const Color infoMain = Color(0xFF00AAFF);

ThemeData buildAppTheme() {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: borderSoft),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: brandPrimary),
    scaffoldBackgroundColor: surfaceMuted,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textStrong,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textStrong,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: brandPrimary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandPrimary,
        disabledBackgroundColor: const Color(0xFFD9CDF8),
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
