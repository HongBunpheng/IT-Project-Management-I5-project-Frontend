import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/exam_model.dart';

class RoundedDonutChart extends StatelessWidget {
  final List<SubjectScore> subjects;
  final double averageScore;

  const RoundedDonutChart({
    super.key,
    required this.subjects,
    required this.averageScore,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(250, 250),
            painter: _DonutChartPainter(subjects),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Average',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                averageScore.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<SubjectScore> subjects;

  _DonutChartPainter(this.subjects);

  @override
  void paint(Canvas canvas, Size size) {
    if (subjects.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 40) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (var subject in subjects) {
      final double sweepAngle = (subject.percentage / 100) * 2 * pi;
      
      final paint = Paint()
        ..color = Color(subject.colorValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 35
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
