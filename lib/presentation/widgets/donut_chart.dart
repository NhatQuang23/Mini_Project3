import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Data model for a single slice of the donut chart.
class DonutChartData {
  final String category;
  final double amount;
  final Color color;

  const DonutChartData({
    required this.category,
    required this.amount,
    required this.color,
  });
}

/// Animated donut/pie chart widget drawn entirely with [CustomPainter].
///
/// Features:
/// - Smooth sweep animation on data change
/// - Category color coding from [AppConstants]
/// - Center text showing total amount
/// - Interactive legend beneath the chart
/// - Anti-aliased rendering with rounded stroke caps
///
/// Usage:
/// ```dart
/// DonutChart(
///   data: [
///     DonutChartData(category: 'Food', amount: 50000, color: Colors.red),
///     DonutChartData(category: 'Travel', amount: 30000, color: Colors.orange),
///   ],
///   totalAmount: 80000,
/// )
/// ```
class DonutChart extends StatefulWidget {
  final List<DonutChartData> data;
  final double totalAmount;
  final double size;

  const DonutChart({
    super.key,
    required this.data,
    required this.totalAmount,
    this.size = 220,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Start the entrance animation
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animate when data changes
    if (oldWidget.data != widget.data) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── Chart ───
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  data: widget.data,
                  totalAmount: widget.totalAmount,
                  animationValue: _animation.value,
                  centerTextColor: theme.colorScheme.onSurface,
                ),
                size: Size(widget.size, widget.size),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // ─── Legend ───
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.data.map((item) {
            final percentage = widget.totalAmount > 0
                ? (item.amount / widget.totalAmount * 100)
                : 0.0;
            return _LegendItem(
              color: item.color,
              label: item.category,
              percentage: percentage,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// CustomPainter that draws the animated donut chart.
///
/// Drawing strategy:
/// 1. Calculate sweep angles proportional to each category's share
/// 2. Draw arcs from the current start angle, multiplied by animation value
/// 3. Draw center circle to create the "donut hole"
/// 4. Render total amount text in the center
class _DonutChartPainter extends CustomPainter {
  final List<DonutChartData> data;
  final double totalAmount;
  final double animationValue;
  final Color centerTextColor;

  _DonutChartPainter({
    required this.data,
    required this.totalAmount,
    required this.animationValue,
    required this.centerTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Donut dimensions
    final outerRadius = radius - 4; // Small padding from edges
    final innerRadius = outerRadius * 0.55; // 55% inner hole for donut look
    final strokeWidth = outerRadius - innerRadius;
    final drawRadius = innerRadius + strokeWidth / 2;

    // Bounding rect for arc drawing
    final rect = Rect.fromCircle(center: center, radius: drawRadius);

    if (data.isEmpty || totalAmount <= 0) {
      // Draw an empty placeholder ring
      final emptyPaint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;
      canvas.drawCircle(center, drawRadius, emptyPaint);
      _drawCenterText(canvas, center, '0');
      return;
    }

    // ─── Draw Donut Slices ───
    double startAngle = -math.pi / 2; // Start from top (12 o'clock)

    for (final item in data) {
      final sweepAngle =
          (item.amount / totalAmount) * 2 * math.pi * animationValue;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }

    // ─── Draw thin separator lines between slices ───
    if (data.length > 1) {
      double separatorAngle = -math.pi / 2;
      final separatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..isAntiAlias = true;

      for (final item in data) {
        final sweepAngle =
            (item.amount / totalAmount) * 2 * math.pi * animationValue;

        // Draw a small line at the start of each slice
        final lineStartX =
            center.dx + innerRadius * math.cos(separatorAngle);
        final lineStartY =
            center.dy + innerRadius * math.sin(separatorAngle);
        final lineEndX =
            center.dx + outerRadius * math.cos(separatorAngle);
        final lineEndY =
            center.dy + outerRadius * math.sin(separatorAngle);

        canvas.drawLine(
          Offset(lineStartX, lineStartY),
          Offset(lineEndX, lineEndY),
          separatorPaint,
        );

        separatorAngle += sweepAngle;
      }
    }

    // ─── Center Text (Total Amount) ───
    if (animationValue > 0.5) {
      // Fade in the text during the second half of animation
      final textOpacity = ((animationValue - 0.5) * 2).clamp(0.0, 1.0);
      _drawCenterText(
        canvas,
        center,
        _formatAmount(totalAmount),
        opacity: textOpacity,
      );
    }
  }

  /// Draw the total amount text centered in the donut hole.
  void _drawCenterText(
    Canvas canvas,
    Offset center,
    String amount, {
    double opacity = 1.0,
  }) {
    // "Total" label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Total',
        style: TextStyle(
          color: centerTextColor.withOpacity(0.6 * opacity),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy - labelPainter.height - 2,
      ),
    );

    // Amount value
    final amountPainter = TextPainter(
      text: TextSpan(
        text: amount,
        style: TextStyle(
          color: centerTextColor.withOpacity(opacity),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    amountPainter.layout();
    amountPainter.paint(
      canvas,
      Offset(
        center.dx - amountPainter.width / 2,
        center.dy + 2,
      ),
    );
  }

  /// Format a number with thousand separators for display.
  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.data != data ||
        oldDelegate.totalAmount != totalAmount;
  }
}

/// Individual legend item showing category color, name, and percentage.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ${percentage.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
