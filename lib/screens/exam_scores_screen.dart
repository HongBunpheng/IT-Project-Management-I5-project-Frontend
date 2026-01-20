import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import 'scores_summary_screen.dart';
import 'exam_detail_screen.dart';

class ExamScoresScreen extends StatefulWidget {
  const ExamScoresScreen({super.key});

  @override
  State<ExamScoresScreen> createState() => _ExamScoresScreenState();
}

class _ExamScoresScreenState extends State<ExamScoresScreen> {
  final ExamService _examService = ExamService();
  ExamSummary? _examSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  Future<void> _loadExamData() async {
    try {
      final summary = await _examService.getExamResults();
      setState(() {
        _examSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exam data: $e')),
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
            : _examSummary == null
                ? const Center(child: Text('No data available'))
                : Column(
                    children: [
                      // Header with Title and Average Score on same row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Exam Scores',
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Average Score: ${_examSummary!.averageScore.toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                title: 'All Exams',
                                icon: Icons.menu_book,
                                color: const Color(0xFF42A5F5), // Brighter blue
                                gradient: true,
                                onTap: () {
                                  // Already on this screen, could show all exams
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                title: 'Score Summary',
                                icon: Icons.show_chart,
                                color: const Color(0xFF66BB6A), // Brighter green
                                gradient: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ScoresSummaryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Exam Results Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Exam Results',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Exam Results List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _examSummary!.examResults.length,
                          itemBuilder: (context, index) {
                            final exam = _examSummary!.examResults[index];
                            return _ExamResultCard(
                              exam: exam,
                              onPreview: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExamDetailScreen(
                                      examId: exam.examId,
                                      subjectName: exam.subjectName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    this.gradient = false,
    required this.onTap,
  });

  // Build icon based on type - book icon directly, chart icon with gradient square
  Widget _buildIcon(IconData iconData, Color cardColor) {
    // For book icon (menu_book), show directly with gradient effect
    if (iconData == Icons.menu_book) {
      return ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            cardColor.withOpacity(0.7), // Lighter blue for left page
            cardColor, // Darker blue for right page
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        child: Icon(
          iconData,
          color: Colors.white,
          size: 32,
        ),
      );
    }

    else {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(cardColor),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            iconData,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }
  }

  // Helper method to get gradient colors based on card type
  List<Color> _getGradientColors(Color baseColor) {
    if (baseColor.value == 0xFF42A5F5) {
      // Blue card gradient: bright cyan to darker blue (from image)
      return [
        const Color(0xFF00C6FF), // Bright cyan/sky blue at top (#00C6FF)
        const Color(0xFF3790FF), // Darker blue at bottom (#3790FF)
      ];
    } else if (baseColor.value == 0xFF66BB6A) {
      // Green card gradient: light green to teal (from image)
      return [
        const Color(0xFF9CF993), // Light green at top (#9CF993)
        const Color(0xFF099F9A), // Teal at bottom (#099F9A)
      ];
    }
    return [
      baseColor.withOpacity(0.6),
      baseColor,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: gradient ? null : color,
          gradient: gradient
              ? LinearGradient(
                  colors: _getGradientColors(color),
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon in a white circle - top left
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _buildIcon(icon, color),
              ),
            ),
            const SizedBox(height: 12),
            // Text below icon - aligned left
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamResultCard extends StatelessWidget {
  final ExamResult exam;
  final VoidCallback onPreview;

  const _ExamResultCard({
    required this.exam,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          // Icon - circular container
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), // Light green background
              shape: BoxShape.circle, // Circular shape
            ),
            child: const Center(
              child: Icon(
                Icons.school,
                color: Color(0xFF4CAF50), // Green icon
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Exam Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.subjectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exam.statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: exam.score < 50 
                        ? Colors.red 
                        : const Color(0xFF4CAF50), // Green color for completed
                    fontWeight: exam.score < 50 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Preview Button
          ElevatedButton(
            onPressed: onPreview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3), // Blue button
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              minimumSize: const Size(80, 40),
            ),
            child: const Text(
              'Preview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
