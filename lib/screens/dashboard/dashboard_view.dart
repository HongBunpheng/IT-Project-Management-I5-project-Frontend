import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/custom_bottom_navigation_bar.dart';
import '../timetable_view.dart';
import '../../widgets/dashboard/exam_score_summary_card.dart';
import '../../widgets/dashboard/exam_card_item.dart';
import '../../widgets/dashboard/task_card_item.dart';
import '../../models/dashboard_models.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentBottomNavIndex = 0;

  final ExamScoreSummary _scoreSummary = ExamScoreSummary(score: 85.0);
  
  final List<ExamCard> _exams = [
    ExamCard(
      category: 'HTML',
      title: 'Grocery shopping app design',
      progress: 0.75,
      iconCategory: 'blue',
    ),
    ExamCard(
      category: 'Personal Project',
      title: 'Uber Eats redesign challenge',
      progress: 0.45,
      iconCategory: 'pink',
    ),
  ];

  final List<TaskCard> _tasks = [
    TaskCard(
      title: 'Office Project',
      taskCount: 23,
      progress: 0.70,
      iconCategory: 'office',
    ),
    TaskCard(
      title: 'Personal Project',
      taskCount: 30,
      progress: 0.52,
      iconCategory: 'personal',
    ),
    TaskCard(
      title: 'Daily Study',
      taskCount: 30,
      progress: 0.87,
      iconCategory: 'study',
    ),
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    
    // Navigate based on index
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        // Check-in
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimetableView()),
        );
        break;
      case 3:
        // Notifications
        break;
      case 4:
        // Settings
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(
              trailing: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TimetableView()),
                  );
                },
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSizes.spacingM),
                    // Exam Score Summary Card
                    ExamScoreSummaryCard(scoreSummary: _scoreSummary),
                    SizedBox(height: AppSizes.spacingL),
                    // Exam Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Exam',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeXL,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: AppSizes.spacingS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.spacingS,
                              vertical: AppSizes.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_exams.length}',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: AppSizes.fontSizeS,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingM),
                    // Exam Cards
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        children: [
                          ExamCardItem(exam: _exams[0]),
                          SizedBox(width: AppSizes.spacingM),
                          ExamCardItem(exam: _exams[1]),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingL),
                    // Task Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Task',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeXL,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: AppSizes.spacingS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.spacingS,
                              vertical: AppSizes.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_tasks.length}',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: AppSizes.fontSizeS,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingM),
                    // Task Cards
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: _tasks
                            .map((task) => TaskCardItem(task: task))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingM),
                  ],
                ),
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