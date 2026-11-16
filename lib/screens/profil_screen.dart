import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../formatters.dart';
import '../store.dart';
import '../widgets/ui.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({
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
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _loggingOut = false;

  Future<void> _logout(BuildContext context) async {
    if (_loggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar akun?'),
        content: const Text(
          'Kamu akan keluar dari akun di perangkat ini. '
          'Login kembali diperlukan untuk menggunakan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _loggingOut = true);
    try {
      await widget.store.logout();
      if (!context.mounted) return;
      widget.onLoggedOut();
    } catch (error, stackTrace) {
      debugPrint('Failed to log out: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat keluar. Silakan coba lagi.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final info = widget.store.info;
        if (info == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: widget.store.error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorBanner(
                      message: widget.store.error!,
                      onRetry: widget.store.refresh,
                    ),
                  )
                : Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          );
        }

        final user = info.user;
        final employee = user.employee;
        final office = employee?.office;
        final radius = office == null
            ? 'Radius kantor'
            : 'Radius ${office.radiusM} m';

        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ResponsivePage(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
              children: [
                _identityCard(
                  name: employee?.name ?? user.name,
                  email: user.email,
                  themeMode: widget.themeMode,
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardTitle(title: 'Data karyawan'),
                      const SizedBox(height: 14),
                      _dataRow(
                        'Jabatan',
                        employee?.position ?? 'Belum tersedia',
                      ),
                      _dataRow(
                        'Divisi',
                        employee?.division ?? 'Belum tersedia',
                      ),
                      _dataRow(
                        'Kantor',
                        office == null ? 'Belum tersedia' : office.name,
                      ),
                      _dataRow(
                        'Radius absen',
                        office == null ? '-' : '${office.radiusM} meter',
                      ),
                      _dataRow('Jam masuk', '${info.workStart} WIB'),
                      _dataRow(
                        'Hari kerja',
                        workDayNames(info.workDays),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardTitle(
                        title: 'Ketentuan absen',
                        subtitle: 'Berlaku untuk setiap absen masuk.',
                      ),
                      const SizedBox(height: 14),
                      const _RuleRow(
                        label: 'Foto selfie',
                        description: 'Setiap absen wajib menyertakan foto.',
                      ),
                      Divider(height: 20, color: Theme.of(context).colorScheme.outline),
                      _RuleRow(
                        label: radius,
                        description: office == null
                            ? 'Admin belum mengatur radius kantor untuk akun ini.'
                            : 'Absen di luar radius kantor ditolak.',
                      ),
                      Divider(height: 20, color: Theme.of(context).colorScheme.outline),
                      _RuleRow(
                        label: 'Jam masuk ${info.workStart} WIB',
                        description:
                            'Lewat dari jam ini absen tercatat terlambat.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _loggingOut ? null : () => _logout(context),
                  icon: _loggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout, size: 20),
                  label: Text(_loggingOut ? 'Sedang keluar...' : 'Keluar akun'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dataRow(String label, String value, {bool isLast = false}) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 11),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 108,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 11),
            Divider(height: 1, color: colors.outline),
          ],
        ],
      ),
    );
  }

  Widget _identityCard({
    required String name,
    required String email,
    required ThemeMode themeMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brandDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<ThemeMode>(
            tooltip: 'Pilih tampilan',
            initialValue: themeMode,
            icon: Icon(_themeModeIcon(themeMode), color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: _changeThemeMode,
            itemBuilder: (context) => [
              _themeMenuItem(
                ThemeMode.light,
                'Terang',
                Icons.light_mode_outlined,
                themeMode,
              ),
              _themeMenuItem(
                ThemeMode.dark,
                'Gelap',
                Icons.dark_mode_outlined,
                themeMode,
              ),
              _themeMenuItem(
                ThemeMode.system,
                'Sistem',
                Icons.settings_brightness_outlined,
                themeMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _themeModeIcon(ThemeMode themeMode) => switch (themeMode) {
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
    ThemeMode.system => Icons.settings_brightness_rounded,
  };

  PopupMenuItem<ThemeMode> _themeMenuItem(
    ThemeMode value,
    String label,
    IconData icon,
    ThemeMode selectedMode,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (selectedMode == value) const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }

  Future<void> _changeThemeMode(ThemeMode themeMode) async {
    try {
      await widget.onThemeModeChanged(themeMode);
    } catch (error, stackTrace) {
      debugPrint('Failed to save theme preference: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pengaturan tampilan gagal disimpan. Coba lagi.'),
          ),
        );
    }
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
