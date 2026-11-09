import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'selfie_types.dart';

Uint8List mirrorSelfieImage(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw SelfieCameraException('Foto selfie tidak dapat diproses.');
    }

    final oriented = img.bakeOrientation(decoded);
    return Uint8List.fromList(
      img.encodeJpg(img.flipHorizontal(oriented), quality: 90),
    );
  } on SelfieCameraException {
    rethrow;
  } catch (error, stackTrace) {
    debugPrint('Failed to mirror selfie image: $error');
    debugPrintStack(stackTrace: stackTrace);
    throw SelfieCameraException(
      'Foto selfie gagal diproses. Silakan ambil ulang.',
    );
  }
}
