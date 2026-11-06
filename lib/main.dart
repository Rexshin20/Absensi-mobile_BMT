import 'package:flutter/material.dart';

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

void main() {
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi BMT Cinde Barokah',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

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
      } on ApiException {
        await api.forgetSession();
      }
    }

    if (!mounted) return;
    setState(() {
      _signedIn = signedIn;
      _restoring = false;
    });
  }

  Future<void> _signIn() async {
    await _store.refresh();
    if (!mounted) return;
    setState(() => _signedIn = true);
  }

  void _signOut() {
    setState(() => _signedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: brandPrimary)),
      );
    }

    if (!_signedIn) {
      return LoginScreen(onLoggedIn: _signIn);
    }

    return RootShell(store: _store, onLoggedOut: _signOut);
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.store, required this.onLoggedOut});

  final AppStore store;
  final VoidCallback onLoggedOut;

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
          ProfilScreen(store: widget.store, onLoggedOut: widget.onLoggedOut),
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
