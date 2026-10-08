import 'package:flutter/material.dart';

/// Camera crop overlay that draws a semi-transparent frame
/// to guide the user in positioning their receipt.
///
/// Draws:
/// - Darkened area outside the crop rectangle
/// - Rounded corner brackets at each corner
/// - Dashed border along the crop edges
class CropOverlay extends StatelessWidget {
  const CropOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CropOverlayPainter(),
      size: Size.infinite,
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define the crop rectangle (80% width, 60% height, centered)
    final cropWidth = size.width * 0.85;
    final cropHeight = size.height * 0.55;
    final left = (size.width - cropWidth) / 2;
    final top = (size.height - cropHeight) / 2.5; // Slightly above center

    final cropRect = Rect.fromLTWH(left, top, cropWidth, cropHeight);
    final cornerRadius = 16.0;
    final cornerLength = 30.0;
    final cornerStrokeWidth = 3.0;

    // ─── Draw Darkened Overlay ───
    // Create a path that covers the entire screen with a hole for the crop area
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(cropRect, Radius.circular(cornerRadius)),
      );
    overlayPath.fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // ─── Draw Corner Brackets ───
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStrokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top + cornerRadius),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(left, top, cornerRadius * 2, cornerRadius * 2),
      3.14159, // pi (180°)
      1.5708,  // pi/2 (90°)
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cornerRadius, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + cropWidth - cornerLength, top),
      Offset(left + cropWidth - cornerRadius, top),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        left + cropWidth - cornerRadius * 2, top,
        cornerRadius * 2, cornerRadius * 2,
      ),
      -1.5708, // -pi/2 (-90°)
      1.5708,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cropWidth, top + cornerRadius),
      Offset(left + cropWidth, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + cropHeight - cornerLength),
      Offset(left, top + cropHeight - cornerRadius),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        left, top + cropHeight - cornerRadius * 2,
        cornerRadius * 2, cornerRadius * 2,
      ),
      1.5708, // pi/2 (90°)
      1.5708,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cornerRadius, top + cropHeight),
      Offset(left + cornerLength, top + cropHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + cropWidth - cornerLength, top + cropHeight),
      Offset(left + cropWidth - cornerRadius, top + cropHeight),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        left + cropWidth - cornerRadius * 2,
        top + cropHeight - cornerRadius * 2,
        cornerRadius * 2, cornerRadius * 2,
      ),
      0, // 0° (3 o'clock)
      1.5708,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cropWidth, top + cropHeight - cornerRadius),
      Offset(left + cropWidth, top + cropHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
