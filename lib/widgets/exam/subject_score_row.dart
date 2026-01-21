import 'package:flutter/material.dart';
import '../../models/exam_model.dart';

class SubjectScoreRow extends StatelessWidget {
  final SubjectScore subject;

  const SubjectScoreRow({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Determine status color based on score
    final bool isPassed = subject.score >= 50;
    final Color statusColor = isPassed
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);
    final Color statusBgColor = isPassed
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 16.0,
      ), // Reduced vertical padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(subject.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              subject.subjectName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14, // Reduced from 16
                color: Color(0xFF1A1F36),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${subject.score}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, // Reduced from 18
                color: Color(0xFF1A1F36),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 32, // Reduced from 40
                height: 32, // Reduced from 40
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // Reduced radius slightly
                ),
                child: Text(
                  _calculateGrade(subject.score),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 14, // Reduced from 16
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }
}
