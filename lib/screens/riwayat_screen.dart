import 'package:flutter/material.dart';

import '../api.dart';
import '../app_theme.dart';
import '../formatters.dart';
import '../store.dart';
import '../widgets/ui.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key, required this.store});

  final AppStore store;

  String _shiftMonth(String month, int delta) {
    final parts = month.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final history = store.history;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Absen'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: store.loading ? null : store.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: store.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Bulan sebelumnya',
                        onPressed: () => store.loadMonth(_shiftMonth(store.month, -1)),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          monthLabel(store.month),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textStrong,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bulan berikutnya',
                        onPressed: () => store.loadMonth(_shiftMonth(store.month, 1)),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (history == null)
                  store.error != null
                      ? ErrorBanner(message: store.error!, onRetry: store.refresh)
                      : const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: CircularProgressIndicator(color: brandPrimary)),
                        )
                else ...[
                  SectionCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: StatBox(
                            value: '${history.summary.present}',
                            label: 'Tepat Waktu',
                            color: successMain,
                          ),
                        ),
                        Expanded(
                          child: StatBox(
                            value: '${history.summary.late}',
                            label: 'Terlambat',
                            color: errorMain,
                          ),
                        ),
                        Expanded(
                          child: StatBox(
                            value: '${history.summary.leave}',
                            label: 'Hari Izin',
                            color: warningMain,
                          ),
                        ),
                        Expanded(
                          child: StatBox(
                            value: '${history.summary.workDays}',
                            label: 'Hari Kerja',
                            color: brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (history.records.isEmpty)
                    const SectionCard(
                      child: EmptyState(
                        icon: Icons.event_busy_outlined,
                        message: 'Belum ada absen pada bulan ini.',
                      ),
                    )
                  else
                    ...history.records.map(_recordTile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _recordTile(AttendanceRecord record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _thumbnail(record.photoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prettyDate(record.date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.checkInTime} WIB · ${record.office ?? 'tanpa lokasi'} · '
                    '${record.distanceM == null ? '-' : '${record.distanceM} m'}',
                    style: const TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Sumber: ${record.source ?? '-'}',
                    style: const TextStyle(fontSize: 11.5, color: textMuted),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: record.status,
              color: StatusChip.forStatus(record.status),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(String? url) {
    if (url == null) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderSoft),
        ),
        child: const Icon(Icons.no_photography_outlined, size: 18, color: textMuted),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : Container(width: 46, height: 46, color: surfaceMuted),
        errorBuilder: (context, error, stack) => Container(
          width: 46,
          height: 46,
          color: surfaceMuted,
          child: const Icon(Icons.broken_image_outlined, size: 18, color: textMuted),
        ),
      ),
    );
  }
}
