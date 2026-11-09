import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'selfie_types.dart';

int _viewCounter = 0;

class _UserMediaSelfie implements SelfieCamera {
  _UserMediaSelfie(this._video, this._stream, this._viewId);

  final web.HTMLVideoElement _video;
  final web.MediaStream _stream;
  final String _viewId;

  @override
  Widget buildPreview() => HtmlElementView(viewType: _viewId);

  @override
  Future<SelfieShot> capture() async {
    for (var attempt = 0; attempt < 40 && _video.videoWidth == 0; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    final width = _video.videoWidth;
    final height = _video.videoHeight;
    if (width == 0 || height == 0) {
      throw SelfieCameraException('Kamera browser belum siap. Tekan ulang tombolnya.');
    }

    final canvas = web.HTMLCanvasElement()
      ..width = width
      ..height = height;
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (context == null) {
      throw SelfieCameraException('Browser ini tidak mendukung pengambilan gambar.');
    }
    context.drawImage(_video, 0, 0, width, height);

    final dataUrl = canvas.toDataURL('image/jpeg', 0.8.toJS);
    final comma = dataUrl.indexOf(',');
    if (comma < 0) throw SelfieCameraException('Gagal membaca gambar dari browser.');

    return SelfieShot(bytes: base64Decode(dataUrl.substring(comma + 1)));
  }

  @override
  Future<void> dispose() async {
    for (final track in _stream.getTracks().toDart) {
      track.stop();
    }
    _video.srcObject = null;
  }
}

Future<SelfieCamera> openSelfieCamera() async {
  final web.MediaStream stream;
  try {
    final result = await web.window.navigator.mediaDevices
        .getUserMedia(
          web.MediaStreamConstraints(
            video: web.MediaTrackConstraints(
              facingMode: web.ConstrainDOMStringParameters(
                ideal: 'user'.toJS,
              ),
            ),
          ),
        )
        .toDart;
    stream = result;
  } catch (error) {
    throw SelfieCameraException(_cameraMessage(error.toString()));
  }

  final video = web.HTMLVideoElement()
    ..autoplay = true
    ..muted = true
    ..playsInline = true
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover'
    ..style.display = 'block'
    ..srcObject = stream;

  final viewId = 'selfie-camera-${_viewCounter++}';
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) => video);

  return _UserMediaSelfie(video, stream, viewId);
}

String _cameraMessage(String error) {
  if (error.contains('NotAllowed')) {
    return 'Izin kamera ditolak browser. Izinkan akses kamera di address bar, lalu muat ulang.';
  }
  if (error.contains('NotFound') || error.contains('Overconstrained')) {
    return 'Tidak ada kamera yang terdeteksi di perangkat ini.';
  }
  if (error.contains('InUse') || error.contains('NotReadable')) {
    return 'Kamera sedang dipakai aplikasi lain. Tutup aplikasi itu lalu coba lagi.';
  }
  return 'Kamera browser tidak bisa dibuka.';
}
