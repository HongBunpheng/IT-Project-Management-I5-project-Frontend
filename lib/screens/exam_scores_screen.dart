import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import 'attendance/attendance_screen.dart';
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
                            const SizedBox(height: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Exam Scores',
                                    style: TextStyle(
                                      fontSize: 15,
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
                                title: 'Attendance and Leave Request',
                                icon: Icons.bar_chart,
                                color: const Color(0xFF42A5F5), // Brighter blue
                                gradient: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AttendanceScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                title: 'Score Summary',
                                icon: Icons.description_outlined,
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
                          child: Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium, // Ribbon/Medal icon
                                  color: const Color(0xFF5C6BC0), // Purple/Indigo color
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Exam Results',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1F36), // Dark text
                                  ),
                                ),
                              ],
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
            cardColor.withValues(alpha: 0.7), // Lighter blue for left page
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
    if (baseColor.toARGB32() == 0xFF42A5F5) {
      // Blue card gradient
      return [
        const Color(0xFF448AFF), // Darker Blue
        const Color(0xFF40C4FF), // Lighter Blue
      ];
    } else if (baseColor.toARGB32() == 0xFF66BB6A) {
      // Green card gradient
      return [
        const Color(0xFF00BFA5), // Teal/Green
        const Color(0xFF1DE9B6), // Lighter Teal
      ];
    }
    return [
      baseColor.withValues(alpha: 0.6),
      baseColor,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: _getGradientColors(color),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle top-right
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: _buildIcon(icon, color)),
                  ),
                  
                  // Texts
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title.startsWith("Attendance") ? "View complete history" : "Detailed analytics",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exam.statusText,
                  style: TextStyle(
                    fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              minimumSize: const Size(70, 32),
            ),
            child: const Text(
              'Preview',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
