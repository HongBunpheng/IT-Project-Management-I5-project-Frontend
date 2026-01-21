import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../model/exam_model.dart';
import '../service/exam_service.dart';
import '../../app_header.dart';
import '../../custom_bottom_navigation_bar.dart';
import '../../attendance/screen/attendance_screen.dart';
import 'scores_summary_screen.dart';
import 'exam_detail_screen.dart';
import '../../dashboard/screen/dashboard_screen.dart';
import '../../timetable/screen/timetable_screen.dart';
import '../../checkin/screen/checkin_screen.dart';
import '../../account/screen/profile_screen.dart'; // SettingsScreen is defined here

class ExamScoresScreen extends StatefulWidget {
  const ExamScoresScreen({super.key});

  @override
  State<ExamScoresScreen> createState() => _ExamScoresScreenState();
}

class _ExamScoresScreenState extends State<ExamScoresScreen> {
  final ExamService _examService = ExamService();
  ExamSummary? _examSummary;
  int _currentBottomNavIndex = 2; // menu_book tab for exam scores

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  Future<void> _loadExamData() async {
    // Load instantly without delay
    final summary = await _examService.getExamResults();
    if (mounted) {
      setState(() {
        _examSummary = summary;
      });
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
        break;
      case 1:
 Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CheckInScreen()),
        );        break;
      case 2:
        // Already on exam scores
        setState(() => _currentBottomNavIndex = 2);
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TimetableView()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _examSummary == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const AppHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text( 'Exam Scores', style: TextStyle(
                            fontSize: AppSizes.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),),
                        Text( 'Average Score: ${_examSummary!.averageScore.toInt()}%', style: const TextStyle(
                            fontSize: AppSizes.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            title: 'Attendance and Leave Request',
                            icon: Icons.bar_chart,
                            color: const Color(0xFF42A5F5),
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
                            color: const Color(0xFF66BB6A),
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: const [
                          Icon(
                            Icons.workspace_premium,
                            color: Color(0xFF5C6BC0),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Exam Results',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
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
