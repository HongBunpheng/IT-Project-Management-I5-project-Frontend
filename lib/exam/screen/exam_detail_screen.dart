import 'package:flutter/material.dart';

import '../model/exam_model.dart';
import '../service/exam_service.dart';
import '../widget/single_score_donut_chart.dart';

import '../../widgets/common/app_header.dart';
import '../../utils/snackbar.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';

class ExamDetailScreen extends StatefulWidget {
  final String examId;
  final String subjectName;

  const ExamDetailScreen({
    super.key,
    required this.examId,
    required this.subjectName,
  });

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final ExamService _examService = ExamService();

  ExamResult? _examResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamDetail();
  }

  Future<void> _loadExamDetail() async {
    try {
      final exam = await _examService.getExamDetail(widget.examId);
      if (!mounted) return;
      setState(() {
        _examResult = exam;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackBar.error(
        title: 'Error',
        message: 'Failed to load exam detail',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _examResult == null
            ? Center(
                child: Text(
                  'No exam data available',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    /// HEADER
                    AppHeader(title: widget.subjectName),

                    const SizedBox(height: 35),

                    /// DONUT SCORE
                    Center(
                      child: SingleScoreDonutChart(
                        score: _examResult!.score.toDouble(),
                        scoreColor: AppColors.primaryBlue,
                        remainingColor: isDark
                            ? Colors.white24
                            : const Color(0xFFEEEEEE),
                        size: 180,
                        strokeWidth: 20,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _ScoreDetailsCard(result: _examResult!),
                          const SizedBox(height: 16),
                          _ExamDateCard(date: _examResult!.examDate ?? 'N/A'),
                          const SizedBox(height: 16),
                          _LecturersCard(
                            lecturers: _examResult!.lecturers ?? [],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// BACK BUTTON
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusM,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeM,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

/// =======================
/// SCORE DETAILS CARD
/// =======================
class _ScoreDetailsCard extends StatelessWidget {
  final ExamResult result;

  const _ScoreDetailsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CardContainer(
      child: Column(
        children: [
          _cardHeader(Icons.verified, 'Score Details'),
          const SizedBox(height: 20),
          _row('Total Mark', '${result.totalMark ?? 100}', isDark),
          _divider(),
          _row('Max Score', '${result.maxScore ?? 100}', isDark),
          _divider(),
          _row(
            'Midterm Exam',
            result.midtermScore != null
                ? '${result.midtermScore} (${result.midtermScore}%)'
                : 'N/A',
            isDark,
            highlight: true,
          ),
          _divider(),
          _row(
            'Final Exam',
            result.finalScore != null
                ? '${result.finalScore} (${result.finalScore}%)'
                : 'N/A',
            isDark,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    bool isDark, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.success : AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(),
  );
}

/// =======================
/// EXAM DATE CARD
/// =======================
class _ExamDateCard extends StatelessWidget {
  final String date;

  const _ExamDateCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CardContainer(
      child: Row(
        children: [
          _iconCircle(Icons.calendar_today, AppColors.primaryBlue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exam Date',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// =======================
/// LECTURERS CARD
/// =======================
class _LecturersCard extends StatelessWidget {
  final List<String> lecturers;

  const _LecturersCard({required this.lecturers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.people, 'Lecturers'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lecturers
                .map(
                  (l) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white12
                          : AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.replaceAll('(TP)', '').trim(),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// SHARED CARD CONTAINER
/// =======================
class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceVariant
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: child,
    );
  }
}

Widget _cardHeader(IconData icon, String title) {
  return Row(
    children: [
      _iconCircle(icon, AppColors.primaryBlue),
      const SizedBox(width: 12),
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  );
}

Widget _iconCircle(IconData icon, Color color) {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(icon, color: Colors.white, size: 20),
  );
}
