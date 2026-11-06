import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../api.dart';
import '../app_theme.dart';
import '../formatters.dart';
import '../services/selfie.dart';
import '../store.dart';

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> with WidgetsBindingObserver {
  SelfieCamera? _camera;
  bool _cameraLoading = true;
  String? _cameraError;

  Position? _position;
  bool _locating = true;
  String? _locationError;

  SelfieShot? _captured;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
    _locate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  Future<void> _openCamera() async {
    setState(() {
      _cameraLoading = true;
      _cameraError = null;
    });

    try {
      final camera = await openSelfieCamera();
      if (!mounted) {
        await camera.dispose();
        return;
      }
      setState(() {
        _camera = camera;
        _cameraLoading = false;
      });
    } on SelfieCameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _cameraError = error.message;
      });
    }
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw _LocationFailure('Lokasi HP belum aktif. Nyalakan GPS lalu coba lagi.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw _LocationFailure('Izin lokasi ditolak. Absen membutuhkan lokasi kamu.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw _LocationFailure(
          'Izin lokasi diblokir permanen. Buka Pengaturan > Aplikasi > Absensi BMT > Izin > Lokasi.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = position;
        _locating = false;
      });
    } on _LocationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = failure.text;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = 'Sinyal GPS lambat. Coba di area terbuka lalu tekan perbarui.';
      });
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null) {
      _snack('Kamera belum siap.');
      return;
    }

    try {
      final shot = await camera.capture();
      if (!mounted) return;
      setState(() => _captured = shot);
    } on SelfieCameraException catch (error) {
      _snack(error.message);
    }
  }

  Future<void> _submit() async {
    final photo = _captured;
    final position = _position;
    final office = widget.store.user?.employee?.office;

    if (photo == null || position == null || office == null) return;

    widget.store.markSubmitting(true);
    try {
      final message = await widget.store.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
        photoBytes: photo.bytes,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (error) {
      if (!mounted) return;
      _snack(error.message);
    } finally {
      if (mounted) widget.store.markSubmitting(false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final office = widget.store.user?.employee?.office;
    final alreadyIn = widget.store.info?.today != null;
    final distance = office == null || _position == null
        ? null
        : distanceMeters(
            _position!.latitude,
            _position!.longitude,
            office.latitude,
            office.longitude,
          );
    final inside = distance != null && office != null && distance <= office.radiusM;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _preview(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _infoCard(office?.name, distance, inside, alreadyIn),
                ),
                const Spacer(),
                _bottomBar(photoTaken: _captured != null, disabled: alreadyIn),
              ],
            ),
          ),
          Positioned(
            top: 6,
            left: 4,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final photo = _captured;
    if (photo != null) {
      return Image.memory(photo.bytes, fit: BoxFit.cover, errorBuilder: (context, _, _) => const SizedBox.shrink());
    }

    if (_cameraLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: brandPrimary),
            SizedBox(height: 12),
            Text('Membuka kamera...', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    }

    if (_cameraError != null) {
      return _retryPanel(
        icon: Icons.no_photography_outlined,
        message: _cameraError!,
        actionLabel: 'Coba lagi',
        onAction: _openCamera,
      );
    }

    final camera = _camera;
    if (camera == null) {
      return const Center(child: CircularProgressIndicator(color: brandPrimary));
    }
    return camera.buildPreview();
  }

  Widget _retryPanel({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      color: const Color(0xFF15131A),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Colors.white54),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(160, 46)),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String? officeName, double? distance, bool inside, bool alreadyIn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  officeName == null ? 'Kantor belum diatur' : 'Target: $officeName',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Perbarui lokasi',
                visualDensity: VisualDensity.compact,
                onPressed: _locating ? null : _locate,
                icon: Icon(Icons.refresh, size: 18, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (alreadyIn)
            const _Pill(
              label: 'Kamu sudah absen hari ini',
              color: warningMain,
              icon: Icons.lock_outline,
            )
          else if (_locating)
            const _Pill(label: 'Mengambil lokasi GPS...', color: Colors.white, icon: Icons.gps_fixed)
          else if (_locationError != null)
            _Pill(label: _locationError!, color: errorMain, icon: Icons.gps_off)
          else if (distance == null)
            const _Pill(label: 'Koordinat kantor belum tersedia', color: Colors.white, icon: Icons.warning_amber)
          else
            _Pill(
              label: '${formatDistance(distance)} dari kantor · ${inside ? 'dalam radius' : 'di luar radius'}',
              color: inside ? const Color(0xFF66D275) : errorMain,
              icon: inside ? Icons.gps_fixed : Icons.report_gmailerrorred,
            ),
        ],
      ),
    );
  }

  Widget _bottomBar({required bool photoTaken, required bool disabled}) {
    final submitting = widget.store.submitting;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (photoTaken)
            _circleAction(
              icon: Icons.refresh,
              label: 'Ambil Ulang',
              onTap: submitting ? null : () => setState(() => _captured = null),
            )
          else
            const SizedBox(width: 74),
          _circleAction(
            icon: photoTaken ? Icons.check : Icons.camera_alt,
            label: photoTaken ? 'Kirim Absen' : 'Ambil Foto',
            big: true,
            onTap: disabled || submitting
                ? null
                : photoTaken
                    ? _submit
                    : _capture,
            busy: submitting,
          ),
          _circleAction(
            icon: Icons.my_location,
            label: 'Cek Lokasi',
            onTap: _locating ? null : _locate,
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool big = false,
    bool busy = false,
  }) {
    final size = big ? 74.0 : 58.0;
    final enabled = onTap != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? Colors.white.withValues(alpha: big ? 0.95 : 0.2) : Colors.white24,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: brandPrimary),
                    )
                  : Icon(icon, size: big ? 30 : 22, color: enabled ? brandPrimary : Colors.white54),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: enabled ? Colors.white : Colors.white54),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _LocationFailure implements Exception {
  _LocationFailure(this.text);

  final String text;
}
