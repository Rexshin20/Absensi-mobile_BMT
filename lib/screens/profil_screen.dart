import 'package:flutter/material.dart';

import '../api.dart';
import '../app_theme.dart';
import '../formatters.dart';
import '../store.dart';
import '../widgets/ui.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key, required this.store, required this.onLoggedOut});

  final AppStore store;
  final VoidCallback onLoggedOut;

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar akun?'),
        content: const Text('Kamu perlu login lagi untuk absen.'),
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

    await store.logout();
    if (!context.mounted) return;
    onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final info = store.info;
        if (info == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: store.error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorBanner(message: store.error!, onRetry: store.refresh),
                  )
                : const Center(child: CircularProgressIndicator(color: brandPrimary)),
          );
        }

        final user = info.user;
        final employee = user.employee;
        final office = employee?.office;

        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: brandPrimary.withValues(alpha: 0.12),
                      child: Text(
                        initials(employee?.name ?? user.name),
                        style: const TextStyle(
                          color: brandPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee?.name ?? user.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textStrong,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 12.5, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitle(title: 'Data Kerja'),
                    const SizedBox(height: 10),
                    InfoRow(label: 'Jabatan', value: employee?.position ?? 'Belum diatur'),
                    InfoRow(label: 'Divisi', value: employee?.division ?? 'Belum diatur'),
                    InfoRow(
                      label: 'Kantor',
                      value: office == null ? 'Belum diatur' : office.name,
                    ),
                    InfoRow(
                      label: 'Radius absen',
                      value: office == null ? '-' : '${office.radiusM} meter',
                    ),
                    InfoRow(label: 'Jam masuk', value: '${info.workStart} WIB'),
                    InfoRow(label: 'Hari kerja', value: workDayNames(info.workDays)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitle(
                      title: 'Cara Absen',
                      subtitle: 'Tekan tombol sidik jari di bawah, ambil foto selfie, lalu kirim.',
                    ),
                    const SizedBox(height: 10),
                    const InfoRow(
                      label: '1. Kamera',
                      value: 'Foto tersimpan sebagai bukti absen dan bisa dilihat admin.',
                      labelWidth: 96,
                    ),
                    const InfoRow(
                      label: '2. Lokasi',
                      value: 'GPS perangkat dibandingkan dengan titik kantor.',
                      labelWidth: 96,
                    ),
                    const InfoRow(
                      label: '3. Batas waktu',
                      value: 'Absen setelah jam masuk tercatat Terlambat.',
                      labelWidth: 96,
                    ),
                  ],
              ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorMain,
                  side: const BorderSide(color: errorMain),
                ),
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Keluar'),
              ),
              const SizedBox(height: 14),
              Text(
                apiBase,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}
