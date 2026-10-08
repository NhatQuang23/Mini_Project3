import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data model for a single bar in the weekly bar chart.
class BarChartData {
  final String label; // Day label (Mon, Tue, ...)
  final double value; // Spending amount

  const BarChartData({
    required this.label,
    required this.value,
  });
}

/// Animated weekly spending bar chart drawn with [CustomPainter].
///
/// Features:
/// - Smooth grow-up animation for each bar
/// - Staggered entrance (bars animate in sequence)
/// - Auto-scaling Y-axis based on maximum value
/// - Value labels above each bar
/// - Day-of-week labels below
/// - Gridlines for readability
/// - Today's bar highlighted with a distinct color
///
/// Usage:
/// ```dart
/// WeeklyBarChart(
///   data: [
///     BarChartData(label: 'Mon', value: 50000),
///     BarChartData(label: 'Tue', value: 30000),
///     ...
///   ],
///   highlightIndex: DateTime.now().weekday - 1,
/// )
/// ```
class WeeklyBarChart extends StatefulWidget {
  final List<BarChartData> data;
  final int? highlightIndex; // Index of today's bar to highlight
  final double height;

  const WeeklyBarChart({
    super.key,
    required this.data,
    this.highlightIndex,
    this.height = 240,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: widget.height,
          child: CustomPaint(
            painter: _BarChartPainter(
              data: widget.data,
              animationValue: _animation.value,
              highlightIndex: widget.highlightIndex,
              barColor: theme.colorScheme.primary,
              highlightColor: theme.colorScheme.tertiary,
              textColor: theme.colorScheme.onSurface,
              gridColor: theme.colorScheme.outline.withOpacity(0.15),
            ),
            size: Size(double.infinity, widget.height),
          ),
        );
      },
    );
  }
}

/// CustomPainter that renders the animated bar chart.
///
/// Layout calculation:
/// - Left margin: reserved for Y-axis labels
/// - Bottom margin: reserved for X-axis labels
/// - Bars distributed evenly across remaining width
/// - Heights proportional to max value with padding
class _BarChartPainter extends CustomPainter {
  final List<BarChartData> data;
  final double animationValue;
  final int? highlightIndex;
  final Color barColor;
  final Color highlightColor;
  final Color textColor;
  final Color gridColor;

  // Layout constants
  static const double leftMargin = 50.0;
  static const double bottomMargin = 30.0;
  static const double topPadding = 30.0;
  static const double barRadiusValue = 6.0;

  _BarChartPainter({
    required this.data,
    required this.animationValue,
    required this.highlightIndex,
    required this.barColor,
    required this.highlightColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartWidth = size.width - leftMargin;
    final chartHeight = size.height - bottomMargin - topPadding;
    final maxValue = data.map((d) => d.value).reduce(math.max);
    final yScale = maxValue > 0 ? chartHeight / (maxValue * 1.15) : 1.0;
    final barWidth = (chartWidth / data.length) * 0.55;
    final barSpacing = chartWidth / data.length;

    // ─── Draw Horizontal Gridlines ───
    _drawGridlines(canvas, size, chartHeight, maxValue);

    // ─── Draw Bars ───
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x = leftMargin + (i * barSpacing) + (barSpacing - barWidth) / 2;

      // Staggered animation: each bar starts slightly after the previous
      final staggerDelay = i / (data.length + 2);
      final localAnimation = ((animationValue - staggerDelay) / (1 - staggerDelay))
          .clamp(0.0, 1.0);

      final barHeight = item.value * yScale * localAnimation;
      final y = size.height - bottomMargin - barHeight;

      // Choose color: highlighted bar gets a distinct color
      final isHighlighted = i == highlightIndex;
      final color = isHighlighted ? highlightColor : barColor;

      // Draw bar with rounded top corners
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(barRadiusValue),
        topRight: const Radius.circular(barRadiusValue),
      );

      final barPaint = Paint()
        ..color = color.withOpacity(isHighlighted ? 1.0 : 0.75)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawRRect(barRect, barPaint);

      // Draw subtle shadow/gradient effect
      if (barHeight > 4) {
        final gradientPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight))
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawRRect(barRect, gradientPaint);
      }

      // ─── Value Label Above Bar ───
      if (localAnimation > 0.7 && item.value > 0) {
        final labelOpacity = ((localAnimation - 0.7) / 0.3).clamp(0.0, 1.0);
        final valueText = _formatCompact(item.value);
        final valuePainter = TextPainter(
          text: TextSpan(
            text: valueText,
            style: TextStyle(
              color: textColor.withOpacity(labelOpacity * 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valuePainter.layout();
        valuePainter.paint(
          canvas,
          Offset(
            x + (barWidth - valuePainter.width) / 2,
            y - valuePainter.height - 4,
          ),
        );
      }

      // ─── Day Label Below Bar ───
      final dayPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            color: isHighlighted
                ? highlightColor
                : textColor.withOpacity(0.6),
            fontSize: 12,
            fontWeight:
                isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      dayPainter.layout();
      dayPainter.paint(
        canvas,
        Offset(
          x + (barWidth - dayPainter.width) / 2,
          size.height - bottomMargin + 8,
        ),
      );
    }

    // ─── Draw Baseline ───
    final baselinePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(leftMargin, size.height - bottomMargin),
      Offset(size.width, size.height - bottomMargin),
      baselinePaint,
    );
  }

  /// Draw horizontal gridlines and Y-axis labels.
  void _drawGridlines(
    Canvas canvas,
    Size size,
    double chartHeight,
    double maxValue,
  ) {
    if (maxValue <= 0) return;

    const gridlineCount = 4;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridlineCount; i++) {
      final fraction = i / gridlineCount;
      final y = size.height - bottomMargin - (chartHeight * fraction);
      final value = maxValue * fraction * 1.0;

      // Gridline
      if (i > 0) {
        canvas.drawLine(
          Offset(leftMargin, y),
          Offset(size.width, y),
          gridPaint,
        );
      }

      // Y-axis label
      if (i > 0) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: _formatCompact(value),
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
        );
        labelPainter.layout(minWidth: leftMargin - 8);
        labelPainter.paint(
          canvas,
          Offset(0, y - labelPainter.height / 2),
        );
      }
    }
  }

  /// Format number compactly: 150000 → "150K", 1500000 → "1.5M"
  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.data != data ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}
