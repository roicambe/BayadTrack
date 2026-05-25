import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// OcrService processes an image file using on-device ML Kit text recognition.
///
/// - No image data is ever uploaded to the internet.
/// - The temp image file is deleted from app cache immediately after OCR.
/// - The caller's original gallery file is never touched.
class OcrService {
  /// Recognises all text in [imageFile] and returns a single raw string.
  ///
  /// Throws [OcrException] if the image cannot be processed.
  /// Always cleans up the temp file before returning or throwing.
  static Future<String> extractText(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);
      return result.text;
    } catch (e) {
      throw OcrException('Could not read text from image: $e');
    } finally {
      // Clean up: close the recognizer and delete any temp cache copy
      await recognizer.close();
      _deleteTempFile(imageFile.path);
    }
  }

  /// Deletes the temp file silently — original gallery files are NOT affected.
  static void _deleteTempFile(String path) {
    try {
      // Only delete if the path lives inside a cache-like directory
      // (image_picker copies to a temp dir, not the user's gallery)
      if (path.contains('cache') ||
          path.contains('tmp') ||
          path.contains('temp')) {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      }
    } catch (_) {
      // Silently ignore — the OS will clear caches on its own schedule
    }
  }
}

/// Thrown when OCR fails to process an image.
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
