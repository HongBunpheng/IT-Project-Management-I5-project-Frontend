import 'package:flutter/material.dart';
import '../model/exam_model.dart';
import '../service/exam_service.dart';
import '../widget/single_score_donut_chart.dart';
import '../../widgets/common/app_header.dart';
import '../../utils/snackbar.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/pull_to_refresh.dart';

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
      setState(() {
        _examResult = exam;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.error(
          title: 'Error loading exam detail',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _examResult == null
            ? const Center(child: Text('No data available'))
            : AppPullToRefresh(
                onRefresh: _loadExamDetail,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                    const SizedBox(height: 20),
                    // Header
                    AppHeader(title: widget.subjectName),
                    const SizedBox(height: 35),
                    // Donut Chart
                    Center(
                      child: SingleScoreDonutChart(
                        score: _examResult!.score.toDouble(),
                        scoreColor: const Color(0xFF2196F3), // Blue
                        remainingColor: const Color(0xFFEEEEEE),
                        size: 180,
                        strokeWidth: 20,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          // Score Details Card
                          _ScoreDetailsCard(result: _examResult!),
                          const SizedBox(height: 16),

                          // Exam Date Card
                          _ExamDateCard(date: _examResult!.examDate ?? 'N/A'),
                          const SizedBox(height: 16),

                          // Lecturers Card
                          _LecturersCard(
                            lecturers: _examResult!.lecturers ?? [],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Back Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
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
      ),
    );
  }
}

class _ScoreDetailsCard extends StatelessWidget {
  final ExamResult result;

  const _ScoreDetailsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF2979FF), // Blue icon bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Score Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRow(
            'Total Mark:',
            '${result.totalMark ?? 100}',
            const Color(0xFF2979FF),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _buildRow(
            'Max Score:',
            '${result.maxScore ?? 100}',
            const Color(0xFF2979FF),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _buildRow(
            'Midterm Exam:',
            result.midtermScore != null
                ? '${result.midtermScore} (${result.midtermScore}%)'
                : 'N/A',
            const Color(0xFF00C853), // Green for exam scores
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          _buildRow(
            'Final Exam:',
            result.finalScore != null
                ? '${result.finalScore} (${result.finalScore}%)'
                : 'N/A',
            const Color(0xFF00C853), // Green
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ExamDateCard extends StatelessWidget {
  final String date;

  const _ExamDateCard({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC).withValues(alpha: 0.5), // Light pinkish
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEC407A), // Pink icon bg
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exam Date',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LecturersCard extends StatelessWidget {
  final List<String> lecturers;

  const _LecturersCard({required this.lecturers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withValues(alpha: 0.5), // Light blue bg
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF2196F3), // Blue icon bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lecturers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: lecturers.map((lecturer) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lecturer.replaceAll('(TP)', '').trim(),
                  style: const TextStyle(
                    color: Color(0xFF1565C0), // Darker blue text
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
