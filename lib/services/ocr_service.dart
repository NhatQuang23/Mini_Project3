import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result container for OCR text recognition.
class OcrResult {
  /// The full concatenated text from all recognized blocks.
  final String fullText;

  /// Individual text blocks with their bounding rectangles.
  final List<OcrTextBlock> blocks;

  /// Processing time in milliseconds.
  final int processingTimeMs;

  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.processingTimeMs,
  });

  /// Returns true if no text was recognized.
  bool get isEmpty => fullText.trim().isEmpty;
}

/// Represents a single recognized text block with position data.
class OcrTextBlock {
  final String text;
  final List<String> lines;

  const OcrTextBlock({
    required this.text,
    required this.lines,
  });
}

/// Service wrapper around Google ML Kit's on-device text recognition.
///
/// Key features:
/// - Fully offline, zero cloud cost
/// - Sub-100ms processing for typical receipt images
/// - Supports Latin script (Vietnamese included)
/// - Proper resource cleanup via [dispose]
///
/// Usage:
/// ```dart
/// final ocrService = OcrService();
/// final result = await ocrService.recognizeText('/path/to/image.jpg');
/// print(result.fullText);
/// ocrService.dispose();
/// ```
class OcrService {
  /// ML Kit text recognizer instance.
  /// Uses Latin script recognizer which covers English and Vietnamese.
  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  OcrService() {
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    _isInitialized = true;
  }

  /// Recognize text from an image file path.
  ///
  /// [imagePath] must point to a valid image file (JPEG/PNG).
  /// Returns an [OcrResult] containing the extracted text and metadata.
  ///
  /// Throws [OcrException] if recognition fails.
  Future<OcrResult> recognizeText(String imagePath) async {
    if (!_isInitialized) {
      throw OcrException('OcrService has been disposed.');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw OcrException('Image file not found: $imagePath');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Create an InputImage from the file path
      final inputImage = InputImage.fromFilePath(imagePath);

      // Run on-device text recognition
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      stopwatch.stop();

      // Convert ML Kit blocks to our domain model
      final blocks = recognizedText.blocks.map((block) {
        return OcrTextBlock(
          text: block.text,
          lines: block.lines.map((line) => line.text).toList(),
        );
      }).toList();

      // Build full text by joining all blocks with newlines
      final fullText = recognizedText.blocks
          .map((block) => block.text)
          .join('\n');

      return OcrResult(
        fullText: fullText,
        blocks: blocks,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      throw OcrException('Text recognition failed: $e');
    }
  }

  /// Release ML Kit resources.
  /// After calling this, the service cannot be used again.
  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}

/// Custom exception for OCR-related errors.
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}
