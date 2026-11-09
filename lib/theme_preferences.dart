import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

Future<ThemeMode> loadThemeMode() async {
  final preferences = await SharedPreferences.getInstance();
  return switch (preferences.getString(_themeModeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

Future<void> saveThemeMode(ThemeMode themeMode) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(_themeModeKey, themeMode.name);
}
