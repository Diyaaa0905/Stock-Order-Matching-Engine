import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chart_point_model.dart';

class StockChartWidget extends StatefulWidget {
  final List<ChartPointModel> points;
  final String activeTimeframe;
  final Function(String) onTimeframeChanged;
  final bool isPositive;

  const StockChartWidget({
    super.key,
    required this.points,
    required this.activeTimeframe,
    required this.onTimeframeChanged,
    this.isPositive = true,
  });

  @override
  State<StockChartWidget> createState() => _StockChartWidgetState();
}

class _StockChartWidgetState extends State<StockChartWidget> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final primaryColor = widget.isPositive ? const Color(0xFF00C087) : const Color(0xFFF6465D);

    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (final p in points) {
      if (p.price < minPrice) minPrice = p.price;
      if (p.price > maxPrice) maxPrice = p.price;
    }
    if (minPrice == double.infinity) minPrice = 0.0;
    if (maxPrice == double.negativeInfinity) maxPrice = 100.0;
    if (minPrice == maxPrice) {
      minPrice *= 0.95;
      maxPrice *= 1.05;
    }

    ChartPointModel? hoveredPoint;
    if (_hoveredIndex != null && _hoveredIndex! >= 0 && _hoveredIndex! < points.length) {
      hoveredPoint = points[_hoveredIndex!];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Timeframe Selector Buttons
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF131722),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2E39)),
          ),
          child: Row(
            children: ['1D', '1M', '1Y', 'ALL'].map((tf) {
              final isSelected = widget.activeTimeframe == tf;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTimeframeChanged(tf),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withValues(alpha: 0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: primaryColor, width: 1) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tf,
                      style: TextStyle(
                        color: isSelected ? primaryColor : const Color(0xFF848E9C),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Hover tooltip display
        if (hoveredPoint != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(hoveredPoint.timestamp, widget.activeTimeframe),
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                ),
                Text(
                  '₹${hoveredPoint.price.toStringAsFixed(2)}',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'High: ₹${maxPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                ),
                Text(
                  'Low: ₹${minPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                ),
              ],
            ),
          ),

        // Interactive Canvas Chart
        SizedBox(
          height: 200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (details) => _updateHover(details.localPosition.dx, constraints.maxWidth, points.length),
                onPanUpdate: (details) => _updateHover(details.localPosition.dx, constraints.maxWidth, points.length),
                onPanEnd: (_) => setState(() => _hoveredIndex = null),
                onPanCancel: () => setState(() => _hoveredIndex = null),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 200),
                  painter: _ChartPainter(
                    points: points,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    color: primaryColor,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateHover(double dx, double width, int count) {
    if (count <= 1 || width <= 0) return;
    final index = (dx / width * (count - 1)).round().clamp(0, count - 1);
    setState(() {
      _hoveredIndex = index;
    });
  }

  String _formatTimestamp(int ts, String tf) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    if (tf == '1D') {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (tf == '1M') {
      return '${dt.day}/${dt.month}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

class _ChartPainter extends CustomPainter {
  final List<ChartPointModel> points;
  final double minPrice;
  final double maxPrice;
  final Color color;
  final int? hoveredIndex;

  _ChartPainter({
    required this.points,
    required this.minPrice,
    required this.maxPrice,
    required this.color,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double priceRange = max(maxPrice - minPrice, 0.001);
    final double stepX = size.width / (points.length - 1);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E222D)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalizedY = (points[i].price - minPrice) / priceRange;
      final y = size.height - (normalizedY * (size.height - 20) + 10);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((points.length - 1) * stepX, size.height);
    fillPath.close();

    // Gradient fill under curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Price stroke curve
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Draw hover crosshair and marker
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < points.length) {
      final hx = hoveredIndex! * stepX;
      final normY = (points[hoveredIndex!].price - minPrice) / priceRange;
      final hy = size.height - (normY * (size.height - 20) + 10);

      final crosshairPaint = Paint()
        ..color = Colors.white38
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(hx, 0), Offset(hx, size.height), crosshairPaint);

      // Outer halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(hx, hy), 7, haloPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(hx, hy), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.activeTimeframe != activeTimeframe;
  }

  String get activeTimeframe => '';
}
