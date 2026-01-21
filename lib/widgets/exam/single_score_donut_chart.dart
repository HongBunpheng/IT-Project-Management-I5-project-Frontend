import 'package:flutter/material.dart';
import 'dart:math';

class SingleScoreDonutChart extends StatelessWidget {
  final double score;
  final Color scoreColor;
  final Color remainingColor;
  final double size;
  final double strokeWidth;

  const SingleScoreDonutChart({
    super.key,
    required this.score,
    required this.scoreColor,
    required this.remainingColor,
    this.size = 200,
    this.strokeWidth = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DonutChartPainter(
        score: score,
        scoreColor: scoreColor,
        remainingColor: remainingColor,
        strokeWidth: strokeWidth,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${score.toInt()}',
              style: TextStyle(
                fontSize: 36, // Reduced from 48
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'out of 100',
              style: TextStyle(
                fontSize: 12, // Reduced from 14
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double score;
  final Color scoreColor;
  final Color remainingColor;
  final double strokeWidth;

  _DonutChartPainter({
    required this.score,
    required this.scoreColor,
    required this.remainingColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = remainingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final scorePaint = Paint()
      ..color = scoreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final scoreAngle = (score / 100) * 2 * pi;
    // -pi/2 to start from top
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      scoreAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
