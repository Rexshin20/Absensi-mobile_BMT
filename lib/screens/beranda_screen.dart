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
            child: ResponsivePage(
              child: RefreshIndicator(
                onRefresh: store.refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (info == null)
                      _loadingOrError(store)
                    else ...[
                      _topBar(store),
                      SizedBox(height: info.today == null ? 8 : 14),
                      if (info.today != null) ...[
                        _checkInCard(store),
                        const SizedBox(height: 12),
                      ],
                      _quickActions(store),
                      const SizedBox(height: 12),
                      _mapCard(store),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(AppStore store) {
    final user = store.user!;
    final employee = user.employee;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF159957), brandDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: brandDark.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/images/logo_bmt.png',
                    fit: BoxFit.cover,
                    semanticLabel: 'Logo BMT Cinde Barokah',
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: const Text(
                  'BMT CINDE BAROKAH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: store.loading ? null : store.refresh,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Assalamu’alaikum,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            employee?.name ?? user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        longDate(_now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                clockTime(_now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
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
    final colors = Theme.of(context).colorScheme;

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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
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
          _timeSlot(
            label: 'Absen Masuk',
            value: alreadyIn ? '${today.checkInTime} WIB' : '--:-- WIB',
            caption: 'Batas ${store.info!.workStart} WIB',
            highlight: alreadyIn,
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: highlight ? colors.onSurface : colors.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(caption, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
      ],
    );
  }

  Widget _photoStrip(TodayAttendance today) {
    final colors = Theme.of(context).colorScheme;
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
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Foto absen tersimpan${today.office == null ? '.' : ' di ${today.office}.'}',
              style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCard(AppStore store) {
    final office = store.user?.employee?.office;
    final colors = Theme.of(context).colorScheme;

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
                Icon(Icons.straighten, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${office.name} · radius ${office.radiusM} m',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(AppStore store) {
    return SectionCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(title: 'Menu Utama'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _menuTile(
                leading: Image.asset(
                  'assets/images/menu_izin.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  semanticLabel: 'Ilustrasi pengajuan izin',
                ),
                label: 'Izin',
                onTap: widget.onOpenIzin,
              ),
              const SizedBox(width: 8),
              _menuTile(
                leading: Image.asset(
                  'assets/images/menu_riwayat.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  semanticLabel: 'Ilustrasi riwayat absensi',
                ),
                label: 'Riwayat\nAbsen',
                onTap: widget.onOpenRiwayat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      height: 88,
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
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
