import 'package:flutter/material.dart';

import '../api.dart';
import '../formatters.dart';
import '../store.dart';
import '../widgets/ui.dart';

class IzinScreen extends StatelessWidget {
  const IzinScreen({super.key, required this.store, this.bottomBarHeight = 76});

  final AppStore store;
  final double bottomBarHeight;

  Future<void> _openForm(BuildContext context) async {
    if (store.leaveTypes.isEmpty) {
      await store.refresh();
      if (!context.mounted) return;
    }

    if (store.leaveTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada jenis izin aktif. Hubungi admin.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _LeaveForm(store: store),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final leaves = store.leaves;
        final colors = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Izin & cuti'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: store.loading ? null : store.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Stack(
            children: [
              ResponsivePage(
                child: RefreshIndicator(
                  onRefresh: store.refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      bottomBarHeight + 80,
                    ),
                    children: [
                      if (store.error != null) ...[
                        ErrorBanner(
                          message: store.error!,
                          onRetry: store.refresh,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (store.loading && leaves.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          ),
                        )
                      else if (leaves.isEmpty)
                        const SectionCard(
                          child: EmptyState(
                            icon: Icons.event_note_outlined,
                            message:
                                'Belum ada pengajuan izin. Mulai dari tombol Ajukan izin.',
                          ),
                        )
                      else
                        _leavesCard(context, leaves),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: bottomBarHeight + 12,
                child: FloatingActionButton.extended(
                  heroTag: 'ajukan-izin',
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajukan izin'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _leavesCard(BuildContext context, List<LeaveRecord> leaves) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];

    for (var i = 0; i < leaves.length; i++) {
      children.add(_leaveRow(context, leaves[i]));
      if (i < leaves.length - 1) {
        children.add(Divider(height: 1, color: colors.outline));
      }
    }

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _leaveRow(BuildContext context, LeaveRecord leave) {
    final colors = Theme.of(context).colorScheme;
    final range = leave.startDate == leave.endDate
        ? prettyDate(leave.startDate)
        : '${prettyDate(leave.startDate)} - ${prettyDate(leave.endDate)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leave.type ?? 'Izin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusLabel(status: leave.status, dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$range · ${leave.days} hari kerja',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          if (leave.note != null && leave.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              leave.note!,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.onSurface,
                height: 1.4,
              ),
            ),
          ],
          if (leave.reason != null && leave.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Alasan ditolak: ${leave.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.error,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveForm extends StatefulWidget {
  const _LeaveForm({required this.store});

  final AppStore store;

  @override
  State<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<_LeaveForm> {
  final _note = TextEditingController();
  LeaveTypeOption? _type;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isStart ? 'Tanggal mulai izin' : 'Tanggal selesai izin',
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked.isBefore(_start) ? _start : picked;
      }
    });
  }

  String _iso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final note = _note.text.trim();

    if (_type == null || note.length < 5) {
      setState(
        () => _error =
            'Pilih jenis izin dan tulis keterangan minimal 5 karakter.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final message = await widget.store.submitLeave(
        leaveTypeId: _type!.id,
        startDate: _iso(_start),
        endDate: _iso(_end),
        note: note,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _error = exception.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                title: 'Ajukan izin',
                subtitle: 'Pengajuan diperiksa admin sebelum disetujui.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LeaveTypeOption>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Jenis izin'),
                items: widget.store.leaveTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      'Mulai',
                      _start,
                      () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateField(
                      'Selesai',
                      _end,
                      () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Contoh: sakit demam, surat dokter menyusul.',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kirim pengajuan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          longDate(value).split(', ').last,
          style: TextStyle(fontSize: 14, color: colors.onSurface),
        ),
      ),
    );
  }
}
