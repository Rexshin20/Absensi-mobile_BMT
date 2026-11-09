import 'package:flutter/material.dart';

import 'theme_preferences.dart';
import 'api.dart';
import 'app_theme.dart';
import 'screens/absen_screen.dart';
import 'screens/beranda_screen.dart';
import 'screens/izin_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/riwayat_screen.dart';
import 'store.dart';
import 'widgets/absen_bottom_bar.dart';
import 'widgets/app_splash_screen.dart';

void main() {
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatefulWidget {
  const AbsensiApp({super.key});

  @override
  State<AbsensiApp> createState() => _AbsensiAppState();
}

class _AbsensiAppState extends State<AbsensiApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final themeMode = await loadThemeMode();
      if (mounted) setState(() => _themeMode = themeMode);
    } catch (error, stackTrace) {
      debugPrint('Failed to load theme preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    await saveThemeMode(themeMode);
    if (mounted) setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi BMT',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: _themeMode,
      home: AuthGate(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode) onThemeModeChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AppStore _store = AppStore(api);
  bool _restoring = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    var signedIn = false;

    if (await api.restoreSession()) {
      try {
        await _store.refresh();
        signedIn = true;
      } on ApiException catch (error) {
        if (error.isUnauthorized) {
          await api.forgetSession();
        } else {
          signedIn = true;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _signedIn = signedIn;
      _restoring = false;
    });
  }

  Future<void> _signIn() async {
    try {
      await _store.refresh();
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await api.forgetSession();
        rethrow;
      }
    }
    if (!mounted) return;
    setState(() => _signedIn = true);
  }

  void _signOut() {
    setState(() => _signedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const AppSplashScreen();
    }

    if (!_signedIn) {
      return LoginScreen(onLoggedIn: _signIn);
    }

    return RootShell(
      store: _store,
      onLoggedOut: _signOut,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    required this.store,
    required this.onLoggedOut,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final AppStore store;
  final VoidCallback onLoggedOut;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode) onThemeModeChanged;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  Future<void> openAbsen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AbsenScreen(store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          BerandaScreen(
            store: widget.store,
            onAbsen: openAbsen,
            onOpenIzin: () => setState(() => _index = 2),
            onOpenRiwayat: () => setState(() => _index = 1),
          ),
          RiwayatScreen(store: widget.store),
          IzinScreen(store: widget.store),
          ProfilScreen(
            store: widget.store,
            onLoggedOut: widget.onLoggedOut,
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          ),
        ],
      ),
      bottomNavigationBar: AbsenBottomBar(
        index: _index,
        onSelect: (index) => setState(() => _index = index),
        onAbsen: openAbsen,
      ),
    );
  }
}
