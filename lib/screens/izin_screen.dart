import 'package:flutter/material.dart';

import '../api.dart';
import '../app_theme.dart';
import '../formatters.dart';
import '../store.dart';
import '../widgets/ui.dart';

class IzinScreen extends StatelessWidget {
  const IzinScreen({super.key, required this.store});

  final AppStore store;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
            title: const Text('Izin & Cuti'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: store.loading ? null : store.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'ajukan-izin',
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajukan Izin'),
          ),
          body: ResponsivePage(
            child: RefreshIndicator(
              onRefresh: store.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  if (store.error != null) ...[
                    ErrorBanner(message: store.error!, onRetry: store.refresh),
                    const SizedBox(height: 12),
                  ],
                  if (leaves.isEmpty)
                    const SectionCard(
                      child: EmptyState(
                        icon: Icons.event_note_outlined,
                        message: 'Belum ada pengajuan izin. Tekan tombol Ajukan Izin di bawah.',
                      ),
                    )
                  else
                    ...leaves.map((leave) => _leaveTile(context, leave)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _leaveTile(BuildContext context, LeaveRecord leave) {
    final colors = Theme.of(context).colorScheme;
    final range = leave.startDate == leave.endDate
        ? prettyDate(leave.startDate)
        : '${prettyDate(leave.startDate)} - ${prettyDate(leave.endDate)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    leave.type ?? 'Izin',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                StatusChip(
                  label: leave.status,
                  color: StatusChip.forStatus(leave.status),
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$range · ${leave.days} hari kerja',
              style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
            ),
            if (leave.note != null && leave.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                leave.note!,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface,
                  height: 1.35,
                ),
              ),
            ],
            if (leave.reason != null && leave.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: errorMain.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Alasan ditolak: ${leave.reason}',
                  style: const TextStyle(fontSize: 12.5, color: errorMain),
                ),
              ),
            ],
          ],
        ),
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
                title: 'Ajukan Izin',
                subtitle: 'Pengajuan diperiksa oleh admin sebelum disetujui.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LeaveTypeOption>(
                initialValue: _type,
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
                hint: const Text('Pilih jenis izin'),
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
                  hintText: 'Keterangan izin',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12.5, color: errorMain),
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
                          : const Text('Kirim Pengajuan'),
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
