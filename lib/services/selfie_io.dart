import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import 'selfie_image.dart';
import 'selfie_types.dart';

class _CameraPackageSelfie implements SelfieCamera {
  _CameraPackageSelfie(this._controller, {required this.mirrorCapture});

  final CameraController _controller;
  final bool mirrorCapture;

  @override
  Widget buildPreview() => CameraPreview(_controller);

  @override
  Future<SelfieShot> capture() async {
    final file = await _controller.takePicture();
    final bytes = await file.readAsBytes();
    return SelfieShot(
      bytes: mirrorCapture ? mirrorSelfieImage(bytes) : bytes,
    );
  }

  @override
  Future<void> dispose() => _controller.dispose();
}

Future<SelfieCamera> openSelfieCamera() async {
  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    throw SelfieCameraException('Tidak ada kamera di perangkat ini.');
  }

  final front = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  final controller = CameraController(
    front,
    ResolutionPreset.medium,
    enableAudio: false,
  );
  try {
    await controller.initialize();
  } on CameraException catch (error) {
    debugPrint('Failed to initialize selfie camera: $error');
    await _disposeAfterFailedInitialization(controller);
    throw SelfieCameraException(
      error.code == 'permissionDenied' || error.code == 'cameraPermission'
          ? 'Izin kamera belum diberikan. Absen butuh foto selfie.'
          : 'Kamera tidak bisa dibuka (${error.code}).',
    );
  } catch (error, stackTrace) {
    debugPrint('Unexpected selfie camera initialization failure: $error');
    debugPrintStack(stackTrace: stackTrace);
    await _disposeAfterFailedInitialization(controller);
    throw SelfieCameraException(
      'Kamera gagal dibuka. Tutup aplikasi lain yang memakai kamera, lalu coba lagi.',
    );
  }

  return _CameraPackageSelfie(
    controller,
    mirrorCapture: front.lensDirection == CameraLensDirection.front,
  );
}

Future<void> _disposeAfterFailedInitialization(
  CameraController controller,
) async {
  try {
    await controller.dispose();
  } catch (error, stackTrace) {
    debugPrint(
      'Failed to dispose selfie camera after initialization error: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}
