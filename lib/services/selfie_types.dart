import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class SelfieShot {
  const SelfieShot({required this.bytes});

  final Uint8List bytes;
}

class SelfieCameraException implements Exception {
  SelfieCameraException(this.message);

  final String message;
}

abstract class SelfieCamera {
  Widget buildPreview();

  Future<SelfieShot> capture();

  Future<void> dispose();
}
