import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';

class AssessmentMediaService {
  AssessmentMediaService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickCompressedImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (file == null) return null;
    return compressToDataUrl(await file.readAsBytes());
  }

  static Future<String?> recoverLostImage() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files?.isEmpty != false) return null;
    return compressToDataUrl(await response.files!.first.readAsBytes());
  }

  static String compressToDataUrl(Uint8List bytes) {
    final decoded = image_lib.decodeImage(bytes);
    if (decoded == null) {
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    final resized = decoded.width > 1080
        ? image_lib.copyResize(decoded, width: 1080)
        : decoded;
    final compressed = image_lib.encodeJpg(resized, quality: 72);
    return 'data:image/jpeg;base64,${base64Encode(compressed)}';
  }
}
