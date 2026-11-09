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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 12),
                  _locationCard(office?.name, distance, inside, alreadyIn),
                  const SizedBox(height: 12),
                  Expanded(child: _previewCard()),
                  const SizedBox(height: 12),
                  _actionPanel(
                    canCheckIn: office != null && _position != null && inside,
                    alreadyIn: alreadyIn,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.outline),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Absen masuk',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ambil foto selfie sebagai bukti kehadiran',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewCard() {
    final photo = _captured;
    final camera = _camera;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF18221C),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image.memory(
                photo.bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => _cameraPlaceholder(
                  icon: Icons.broken_image_outlined,
                  title: 'Foto tidak dapat ditampilkan',
                  message: 'Ambil ulang foto untuk melanjutkan.',
                ),
              )
            else if (_cameraLoading)
              _cameraPlaceholder(
                icon: Icons.camera_alt_outlined,
                title: 'Menyiapkan kamera',
                message: 'Mohon tunggu sebentar.',
                loading: true,
              )
            else if (_cameraError != null)
              _cameraPlaceholder(
                icon: Icons.no_photography_outlined,
                title: 'Kamera belum tersedia',
                message: _cameraError!,
              )
            else if (camera != null)
              camera.buildPreview()
            else
              _cameraPlaceholder(
                icon: Icons.camera_alt_outlined,
                title: 'Kamera belum siap',
                message: 'Coba buka kamera kembali.',
              ),
            if (!_cameraLoading && _cameraError == null && photo == null)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.face_retouching_natural,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Posisikan wajah di tengah',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (photo != null)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: brandDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Foto siap diperiksa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cameraPlaceholder({
    required IconData icon,
    required String title,
    required String message,
    bool loading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(color: Colors.white)
            else
              Icon(icon, size: 42, color: Colors.white70),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard(
    String? officeName,
    double? distance,
    bool inside,
    bool alreadyIn,
  ) {
    final colors = Theme.of(context).colorScheme;
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (alreadyIn) {
      statusColor = warningMain;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Absensi hari ini sudah tercatat';
    } else if (_locating) {
      statusColor = brandPrimary;
      statusIcon = Icons.gps_fixed;
      statusText = 'Sedang mencari lokasi perangkat...';
    } else if (_locationError != null) {
      statusColor = errorMain;
      statusIcon = Icons.gps_off;
      statusText = _locationError!;
    } else if (distance == null) {
      statusColor = warningMain;
      statusIcon = Icons.location_searching;
      statusText = 'Lokasi kantor belum tersedia';
    } else if (inside) {
      statusColor = successMain;
      statusIcon = Icons.check_circle;
      statusText = 'Kamu berada dalam radius absen';
    } else {
      statusColor = errorMain;
      statusIcon = Icons.location_off;
      statusText = 'Kamu berada di luar radius absen';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on_outlined, color: statusColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  officeName ?? 'Kantor belum diatur',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 15, color: statusColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        statusText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (distance != null && !alreadyIn) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Jarak ke kantor ${formatDistance(distance)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Perbarui lokasi',
            onPressed: _locating ? null : _locate,
            style: IconButton.styleFrom(foregroundColor: brandPrimary),
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _actionPanel({
    required bool canCheckIn,
    required bool alreadyIn,
  }) {
    final colors = Theme.of(context).colorScheme;
    final submitting = widget.store.submitting;
    final photoTaken = _captured != null;
    final cameraReady = _camera != null && !_cameraLoading;
    final canTakePhoto = cameraReady && !alreadyIn && !submitting;
    final canSubmit = photoTaken &&
        canCheckIn &&
        !alreadyIn &&
        !submitting;

    final String helperText;
    if (alreadyIn) {
      helperText = 'Absensi untuk hari ini sudah tercatat.';
    } else if (_cameraError != null) {
      helperText = 'Izinkan akses kamera, lalu coba buka kembali.';
    } else if (!photoTaken) {
      helperText = 'Pastikan wajah terlihat jelas sebelum mengambil foto.';
    } else if (!canCheckIn) {
      helperText = 'Kirim absen aktif setelah lokasi berada dalam radius kantor.';
    } else {
      helperText = 'Periksa foto, lalu tekan Kirim Absen.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            helperText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (photoTaken)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: submitting
                        ? null
                        : () => setState(() => _captured = null),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Ambil Ulang'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: brandPrimary,
                      side: const BorderSide(color: brandPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(submitting ? 'Mengirim...' : 'Kirim Absen'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: _cameraError != null
                  ? _openCamera
                  : canTakePhoto
                  ? _capture
                  : null,
              icon: _cameraLoading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _cameraError != null
                          ? Icons.refresh_rounded
                          : Icons.camera_alt_rounded,
                    ),
              label: Text(_cameraError != null ? 'Buka Kamera Lagi' : 'Ambil Foto'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationFailure implements Exception {
  _LocationFailure(this.text);

  final String text;
}
