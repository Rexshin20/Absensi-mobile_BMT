import 'package:flutter/material.dart';

import '../api.dart';
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
            title: const Text('Riwayat absen'),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                children: [
                  _monthBar(context),
                  const SizedBox(height: 8),
                  if (store.error != null) ...[
                    ErrorBanner(message: store.error!, onRetry: store.refresh),
                    const SizedBox(height: 12),
                  ],
                  if (history == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else ...[
                    SectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 14,
                      ),
                      child: MonthLedger(
                        items: [
                          LedgerMetric(
                            value: history.summary.present,
                            label: 'Tepat waktu',
                          ),
                          LedgerMetric(
                            value: history.summary.late,
                            label: 'Terlambat',
                            alert: history.summary.late > 0,
                          ),
                          LedgerMetric(
                            value: history.summary.leave,
                            label: 'Hari izin',
                          ),
                          LedgerMetric(
                            value: history.summary.workDays,
                            label: 'Hari kerja',
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
                      _recordsCard(context, history.records),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _monthBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Bulan berikutnya',
          onPressed: () => store.loadMonth(_shiftMonth(store.month, 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _recordsCard(BuildContext context, List<AttendanceRecord> records) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];

    for (var i = 0; i < records.length; i++) {
      children.add(_recordRow(context, records[i]));
      if (i < records.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(height: 1, color: colors.outline),
          ),
        );
      }
    }

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _recordRow(BuildContext context, AttendanceRecord record) {
    final colors = Theme.of(context).colorScheme;
    final meta =
        '${record.checkInTime} WIB · ${record.office ?? 'tanpa lokasi'} · '
        '${record.distanceM == null ? '-' : '${record.distanceM} m'} · '
        '${record.source ?? '-'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumbnail(context, record.photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        prettyDate(record.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusLabel(status: record.status, dense: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(BuildContext context, String? url) {
    final colors = Theme.of(context).colorScheme;
    if (url == null) {
      return Container(
        width: 44,
        height: 44,
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
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        semanticLabel: 'Foto absen',
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                width: 44,
                height: 44,
                color: colors.surfaceContainerHighest,
              ),
        errorBuilder: (context, error, stack) => Container(
          width: 44,
          height: 44,
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
