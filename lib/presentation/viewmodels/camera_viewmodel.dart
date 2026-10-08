import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';

/// ViewModel for the Camera screen.
///
/// Manages the camera lifecycle, photo capture, and OCR processing.
class CameraViewModel extends ChangeNotifier {
  final OcrService _ocrService = OcrService();
  final ReceiptParser _receiptParser = ReceiptParser();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  String? _errorMessage;
  String? _capturedImagePath;
  ParsedReceipt? _parsedReceipt;
  String? _rawOcrText;

  // ─── Getters ───
  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  bool get isFlashOn => _isFlashOn;
  String? get errorMessage => _errorMessage;
  String? get capturedImagePath => _capturedImagePath;
  ParsedReceipt? get parsedReceipt => _parsedReceipt;
  String? get rawOcrText => _rawOcrText;

  /// Initialize the camera. Call this when the screen mounts.
  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _errorMessage = 'No cameras available on this device.';
        notifyListeners();
        return;
      }

      // Use the back camera
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _isInitialized = false;
    }
    notifyListeners();
  }

  /// Toggle the camera flash between on and off.
  Future<void> toggleFlash() async {
    if (_cameraController == null) return;

    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to toggle flash: $e';
      notifyListeners();
    }
  }

  /// Handle tap-to-focus on the camera preview.
  Future<void> setFocusPoint(Offset point) async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusPoint(point);
      await _cameraController!.setFocusMode(FocusMode.auto);
    } catch (e) {
      // Focus point may not be supported on all devices
      debugPrint('Focus point not supported: $e');
    }
  }

  /// Capture a photo, save it as a receipt thumbnail, then run OCR.
  Future<void> captureAndProcess() async {
    if (_cameraController == null || _isProcessing) return;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Capture the image
      final XFile photo = await _cameraController!.takePicture();

      // Save to app's receipt thumbnail directory
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory(
        path.join(appDir.path, AppConstants.thumbnailDir),
      );
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = path.join(
        thumbnailDir.path,
        'receipt_$timestamp.jpg',
      );

      // Copy the captured image to our storage directory
      await File(photo.path).copy(savedPath);
      _capturedImagePath = savedPath;

      // Run OCR on the captured image
      final ocrResult = await _ocrService.recognizeText(savedPath);
      _rawOcrText = ocrResult.fullText;

      // Parse the recognized text
      _parsedReceipt = _receiptParser.parse(ocrResult.fullText);

      debugPrint(
        'OCR completed in ${ocrResult.processingTimeMs}ms. '
        'Parsed: $_parsedReceipt',
      );
    } catch (e) {
      _errorMessage = 'Failed to capture/process image: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Release camera and OCR resources.
  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}
