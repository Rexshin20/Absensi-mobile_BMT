import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../app_theme.dart';
import '../formatters.dart';
import '../store.dart';
import '../widgets/office_map.dart';
import '../widgets/ui.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({
    super.key,
    required this.store,
    required this.onAbsen,
    required this.onOpenIzin,
    required this.onOpenRiwayat,
  });

  final AppStore store;
  final VoidCallback onAbsen;
  final VoidCallback onOpenIzin;
  final VoidCallback onOpenRiwayat;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final info = store.info;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: store.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (info == null)
                    _loadingOrError(store)
                  else ...[
                    _topBar(store),
                    const SizedBox(height: 14),
                    _identityCard(store),
                    const SizedBox(height: 12),
                    _checkInCard(store),
                    const SizedBox(height: 12),
                    _mapCard(store),
                    const SizedBox(height: 12),
                    _summaryCard(store),
                    const SizedBox(height: 12),
                    _quickActions(store),
                    const SizedBox(height: 12),
                    _rulesCard(store),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(AppStore store) {
    final office = store.user?.employee?.office;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderSoft),
          ),
          child: const Icon(Icons.account_balance, size: 22, color: brandPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                office?.name ?? 'Belum ada kantor',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textStrong,
                ),
              ),
              Text(
                office == null
                    ? 'Lokasi kantor belum diatur admin'
                    : 'Radius absen ${office.radiusM} m',
                style: const TextStyle(fontSize: 12, color: textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: store.loading ? null : store.refresh,
          icon: const Icon(Icons.refresh, color: textMuted),
        ),
      ],
    );
  }

  Widget _identityCard(AppStore store) {
    final user = store.user!;
    final employee = user.employee;

    return SectionCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: brandPrimary.withValues(alpha: 0.12),
            child: Text(
              initials(employee?.name ?? user.name),
              style: const TextStyle(
                color: brandPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee?.name ?? user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (employee?.position != null) employee!.position!,
                    if (employee?.division != null) employee!.division!,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                clockTime(_now),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: brandPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                longDate(_now),
                style: const TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkInCard(AppStore store) {
    final today = store.info?.today;
    final alreadyIn = today != null;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alreadyIn ? Icons.check_circle : Icons.schedule,
                size: 20,
                color: alreadyIn ? successMain : warningMain,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alreadyIn ? 'Sudah absen hari ini' : 'Belum absen hari ini',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textStrong,
                  ),
                ),
              ),
              if (alreadyIn)
                StatusChip(
                  label: today.status,
                  color: StatusChip.forStatus(today.status),
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _timeSlot(
                  label: 'Absen Masuk',
                  value: alreadyIn ? '${today.checkInTime} WIB' : '--:-- WIB',
                  caption: 'Batas ${store.info!.workStart} WIB',
                  highlight: alreadyIn,
                ),
              ),
              Container(width: 1, height: 54, color: borderSoft),
              const SizedBox(width: 12),
              Expanded(
                child: _timeSlot(
                  label: 'Absen Pulang',
                  value: '--:-- WIB',
                  caption: 'Belum tersedia di BMT',
                  highlight: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (alreadyIn && today.photoUrl != null) _photoStrip(today),
          FilledButton.icon(
            onPressed: alreadyIn || store.submitting ? null : widget.onAbsen,
            icon: alreadyIn
                ? const Icon(Icons.lock_outline, size: 20)
                : const Icon(Icons.camera_alt_rounded, size: 20),
            label: Text(
              alreadyIn
                  ? 'Absen tercatat ${today.checkInTime} WIB'
                  : store.submitting
                      ? 'Mengirim absen...'
                      : 'Absen dengan Foto & Lokasi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeSlot({
    required String label,
    required String value,
    required String caption,
    required bool highlight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: highlight ? textStrong : const Color(0xFFB9B4C4),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(caption, style: const TextStyle(fontSize: 11, color: textMuted)),
      ],
    );
  }

  Widget _photoStrip(TodayAttendance today) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              today.photoUrl!,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 46,
                height: 46,
                color: surfaceMuted,
                child: const Icon(Icons.broken_image, size: 20, color: textMuted),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Foto absen tersimpan${today.office == null ? '.' : ' di ${today.office}.'}',
              style: const TextStyle(fontSize: 12.5, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCard(AppStore store) {
    final office = store.user?.employee?.office;

    if (office == null) {
      return const SectionCard(
        child: CardTitle(
          title: 'Lokasi Kantor',
          subtitle: 'Admin belum mengatur koordinat kantor untuk akun ini.',
        ),
      );
    }

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            title: 'Lokasi Kantor',
            subtitle: 'Absen hanya diterima di dalam lingkaran radius.',
          ),
          const SizedBox(height: 12),
          OfficeMap(
            latitude: office.latitude,
            longitude: office.longitude,
            radiusMeters: office.radiusM,
            height: 190,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  '${office.name} · radius ${office.radiusM} m',
                  style: const TextStyle(fontSize: 12.5, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(AppStore store) {
    final summary = store.history?.summary;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            title: 'Rekap ${monthLabel(store.month)}',
            subtitle: summary == null
                ? 'Memuat rekap...'
                : '${summary.total} dari ${summary.workDays} hari kerja sudah absen',
          ),
          const SizedBox(height: 14),
          if (summary == null)
            const LinearProgressIndicator(minHeight: 4)
          else
            Row(
              children: [
                Expanded(
                  child: StatBox(
                    value: '${summary.present}',
                    label: 'Tepat Waktu',
                    color: successMain,
                  ),
                ),
                Expanded(
                  child: StatBox(
                    value: '${summary.late}',
                    label: 'Terlambat',
                    color: errorMain,
                  ),
                ),
                Expanded(
                  child: StatBox(
                    value: '${summary.leave}',
                    label: 'Hari Izin',
                    color: warningMain,
                  ),
                ),
                Expanded(
                  child: StatBox(
                    value: '${summary.workDays}',
                    label: 'Hari Kerja',
                    color: brandPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _quickActions(AppStore store) {
    final pending = store.leaves.where((leave) => leave.isPending).length;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onOpenIzin,
            icon: const Icon(Icons.event_available, size: 20),
            label: Text(pending > 0 ? 'Izin ($pending)' : 'Ajukan Izin'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onOpenRiwayat,
            icon: const Icon(Icons.history, size: 20),
            label: const Text('Riwayat Absen'),
          ),
        ),
      ],
    );
  }

  Widget _rulesCard(AppStore store) {
    final info = store.info!;
    final office = store.user?.employee?.office;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(title: 'Ketentuan Absen'),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Kantor',
            value: office == null
                ? 'Belum diatur admin'
                : '${office.name} (radius ${office.radiusM} m)',
          ),
          InfoRow(label: 'Jam masuk', value: '${info.workStart} WIB'),
          InfoRow(label: 'Hari kerja', value: workDayNames(info.workDays)),
          const InfoRow(
            label: 'Cara absen',
            value: 'Foto selfie + lokasi GPS, satu kali per hari.',
            labelWidth: 96,
          ),
        ],
      ),
    );
  }

  Widget _loadingOrError(AppStore store) {
    if (store.error != null) {
      return Column(
        children: [
          const SizedBox(height: 40),
          ErrorBanner(message: store.error!, onRetry: store.refresh),
        ],
      );
    }

    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(child: CircularProgressIndicator(color: brandPrimary)),
    );
  }
}
