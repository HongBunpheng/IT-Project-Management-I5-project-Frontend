import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import '../widgets/exam/single_score_donut_chart.dart';
import '../widgets/common/app_header.dart';
import '../widgets/common/primary_button.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exam detail: $e')),
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
                : Column(
                    children: [
                      // Header
                       AppHeader(
                        title: widget.subjectName,
                      ),
                      const SizedBox(height: 65),
                      // Donut Chart with rounded segments - centered
                      Center(
                        child: SingleScoreDonutChart(
                          score: _examResult!.score.toDouble(),
                          scoreColor: Colors.blue,
                          remainingColor: Colors.grey[300]!,
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Detailed Exam Information with padding like scores summary
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(left: 30.0, right: 35.0),
                          children: [
                            _DetailRow(
                              label: 'Total Mark:',
                              value: '${_examResult!.totalMark ?? 100}',
                              isBlue: true,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Max Score:',
                              value: '${_examResult!.maxScore ?? 100}',
                              isBlue: true,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Midterm Exam:',
                              value: _examResult!.midtermScore != null
                                  ? '${_examResult!.midtermScore} (${_examResult!.midtermScore}%)'
                                  : 'N/A',
                              isBlue: true,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Final Exam:',
                              value: _examResult!.finalScore != null
                                  ? '${_examResult!.finalScore} (${_examResult!.finalScore}%)'
                                  : 'N/A',
                              isBlue: true,
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              label: 'Exam Date:',
                              value: _examResult!.examDate ?? 'N/A',
                              isBlue: false,
                            ),
                            const SizedBox(height: 12),
                            _LecturerRow(
                              lecturers: _examResult!.lecturers,
                            ),
                          ],
                        ),
                      ),
                      // Back Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PrimaryButton(
                          text: 'Back',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBlue;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: isBlue ? Colors.blue : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _LecturerRow extends StatelessWidget {
  final List<String>? lecturers;

  const _LecturerRow({
    required this.lecturers,
  });

  @override
  Widget build(BuildContext context) {
    if (lecturers == null || lecturers!.isEmpty) {
      return _DetailRow(
        label: 'Lecturer:',
        value: 'N/A',
        isBlue: true,
      );
    }

    // Display each lecturer name on its own row
    final List<String> names = lecturers!;
    final int totalNames = names.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 8,
            child: Text(
              'Lecturer:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < names.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i > 0 ? 4.0 : 0.0),
                    child: Text(
                      i == totalNames - 1
                          ? '${names[i].replaceAll(' (TP)', '').trim()} (TP)'
                          : '${names[i].replaceAll(' (TP)', '').trim()},',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
