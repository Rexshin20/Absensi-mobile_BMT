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
          body: ResponsivePage(
            child: RefreshIndicator(
              onRefresh: store.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  SectionCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Bulan sebelumnya',
                          onPressed: () =>
                              store.loadMonth(_shiftMonth(store.month, -1)),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            monthLabel(store.month),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Bulan berikutnya',
                          onPressed: () =>
                              store.loadMonth(_shiftMonth(store.month, 1)),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (history == null)
                    store.error != null
                        ? ErrorBanner(
                            message: store.error!,
                            onRetry: store.refresh,
                          )
                        : const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: brandPrimary,
                              ),
                            ),
                          )
                  else ...[
                    SectionCard(
                      child: StatGrid(
                        items: [
                          StatGridItem(
                            value: '${history.summary.present}',
                            label: 'Tepat Waktu',
                            color: successMain,
                          ),
                          StatGridItem(
                            value: '${history.summary.late}',
                            label: 'Terlambat',
                            color: errorMain,
                          ),
                          StatGridItem(
                            value: '${history.summary.leave}',
                            label: 'Hari Izin',
                            color: warningMain,
                          ),
                          StatGridItem(
                            value: '${history.summary.workDays}',
                            label: 'Hari Kerja',
                            color: brandPrimary,
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
                      ...history.records.map(
                        (record) => _recordTile(context, record),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _recordTile(BuildContext context, AttendanceRecord record) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prettyDate(record.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.checkInTime} WIB · ${record.office ?? 'tanpa lokasi'} · '
                    '${record.distanceM == null ? '-' : '${record.distanceM} m'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Sumber: ${record.source ?? '-'}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
            final thumbnail = _thumbnail(context, record.photoUrl);
            final status = StatusChip(
              label: record.status,
              color: StatusChip.forStatus(record.status),
              dense: true,
            );

            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [thumbnail, const SizedBox(width: 12), details],
                  ),
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: status),
                ],
              );
            }

            return Row(
              children: [
                thumbnail,
                const SizedBox(width: 12),
                details,
                const SizedBox(width: 8),
                status,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _thumbnail(BuildContext context, String? url) {
    final colors = Theme.of(context).colorScheme;
    if (url == null) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outline),
        ),
        child: Icon(
          Icons.no_photography_outlined,
          size: 18,
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                width: 46,
                height: 46,
                color: colors.surfaceContainerHighest,
              ),
        errorBuilder: (context, error, stack) => Container(
          width: 46,
          height: 46,
          color: colors.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
