import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Thin wrapper over ML Kit's on-device (offline) text recognizer.
///
/// Runs entirely on the device — no network/server is used. Call [dispose]
/// when the owning widget is disposed to release native resources.
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Recognizes text in the image at [imagePath] and returns every recognized
  /// line as a plain string. Lines (rather than the whole blob) keep the
  /// downstream brand matcher from joining unrelated text across the shelf.
  Future<List<String>> recognizeLines(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);

    final lines = <String>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        lines.add(line.text);
      }
    }
    return lines;
  }

  void dispose() {
    _recognizer.close();
  }
}
