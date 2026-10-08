import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../widgets/crop_overlay.dart';
import 'review_screen.dart';
import '../viewmodels/camera_viewmodel.dart';

/// Camera screen for capturing receipt images.
///
/// Features:
/// - Live camera preview
/// - Flash toggle button
/// - Tap-to-focus with animated focus indicator
/// - Crop overlay guide for receipt framing
/// - Automatic OCR processing on capture
/// - Loading indicator during processing
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraViewModel _viewModel;
  Offset? _focusPoint;
  bool _showFocusIndicator = false;

  @override
  void initState() {
    super.initState();
    _viewModel = CameraViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initializeCamera();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    setState(() {});

    // When processing is complete and we have a parsed receipt,
    // navigate to the review screen
    if (!_viewModel.isProcessing && _viewModel.parsedReceipt != null) {
      _navigateToReview();
    }
  }

  void _navigateToReview() {
    final receipt = _viewModel.parsedReceipt;
    if (receipt == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          parsedReceipt: receipt,
          imagePath: _viewModel.capturedImagePath,
          rawOcrText: _viewModel.rawOcrText,
        ),
      ),
    );

    // Reset the parsed receipt so navigating back doesn't re-trigger
    // (We don't clear _viewModel since it still has the camera open)
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Receipt'),
        actions: [
          // Flash toggle
          IconButton(
            icon: Icon(
              _viewModel.isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _viewModel.isFlashOn ? Colors.amber : Colors.white,
            ),
            onPressed: _viewModel.toggleFlash,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                _viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _viewModel.initializeCamera,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_viewModel.isInitialized ||
        _viewModel.cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // ─── Camera Preview ───
        Positioned.fill(
          child: GestureDetector(
            onTapDown: _handleTapToFocus,
            child: CameraPreview(_viewModel.cameraController!),
          ),
        ),

        // ─── Crop Overlay ───
        const Positioned.fill(
          child: CropOverlay(),
        ),

        // ─── Focus Indicator ───
        if (_showFocusIndicator && _focusPoint != null)
          Positioned(
            left: _focusPoint!.dx - 30,
            top: _focusPoint!.dy - 30,
            child: _FocusIndicator(),
          ),

        // ─── Processing Overlay ───
        if (_viewModel.isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing receipt...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ─── Capture Button ───
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _viewModel.isProcessing
                  ? null
                  : _viewModel.captureAndProcess,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white.withOpacity(0.3),
                ),
                child: const Icon(
                  Icons.camera,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),

        // ─── Help Text ───
        const Positioned(
          bottom: 130,
          left: 0,
          right: 0,
          child: Text(
            'Align receipt within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Handle tap-to-focus gesture on the camera preview.
  void _handleTapToFocus(TapDownDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final point = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );

    _viewModel.setFocusPoint(point);

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusIndicator = true;
    });

    // Hide the focus indicator after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _showFocusIndicator = false);
      }
    });
  }
}

/// Animated focus indicator shown at the tap point.
class _FocusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.amber, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
