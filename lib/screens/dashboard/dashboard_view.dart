import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/custom_bottom_navigation_bar.dart';
import '../timetable_view.dart';
import '../../widgets/dashboard/checkin_card.dart';
import '../../widgets/dashboard/exam_card_item.dart';
import '../../widgets/dashboard/task_card_item.dart';
import '../../models/dashboard_models.dart';
import '../../services/auth_service.dart';
import '../../services/exam_service.dart';
import '../notification_screen.dart';
import '../exam_scores_screen.dart';
// import '../settings_screen.dart';
import '../checkin_screen.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentBottomNavIndex = 0;

  final AuthService _authService = AuthService();
  final ExamService _examService = ExamService();
  ExamScoreSummary _scoreSummary = ExamScoreSummary(score: 0.0);
  String? _username;
  String? _userId;

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

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadMe();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _examService.getExamResults();
      if (!mounted) return;
      setState(
        () => _scoreSummary = ExamScoreSummary(score: summary.averageScore),
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadMe() async {
    try {
      final me = await _authService.me();
      if (!mounted || me == null) return;
      final data = me['data'] is Map ? (me['data'] as Map) : me;
      setState(() {
        _username = (data['name'] ?? data['full_name'] ?? data['email'])
            ?.toString();
        _userId = (data['id'] ?? data['user_id'])?.toString();
      });
    } catch (_) {
      // ignore
    }
  }

  void _onBottomNavTap(int index) {
    // Only update local index when staying on this tab
    switch (index) {
      case 0:
        setState(() => _currentBottomNavIndex = 0);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckInScreen()),
        ).then((_) {
          if (mounted) setState(() => _currentBottomNavIndex = 0);
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamScoresScreen()),
        ).then((_) {
          if (mounted) setState(() => _currentBottomNavIndex = 0);
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimetableView()),
        ).then((_) {
          if (mounted) setState(() => _currentBottomNavIndex = 0);
        });
        break;
      // case 4:
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (_) => const SettingsScreen()),
      //   ).then((_) {
      //     if (mounted) setState(() => _currentBottomNavIndex = 0);
      //   });
      //   break;
      default:
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
              username: _username,
              userId: _userId,
              trailing: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationView()),
                ),
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
