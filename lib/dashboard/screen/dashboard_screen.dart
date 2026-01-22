import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/custom_bottom_navigation_bar.dart';
import '../../timetable/screen/timetable_screen.dart';
import '../../services/timetable_service.dart';
import '../widget/exam_card_item.dart';
import '../widget/exam_score_summary_card.dart';
import '../widget/task_card_item.dart';
import '../model/dashboard_models.dart';
import '../../notification/screen/notification_screen.dart';
import '../../services/notification_service.dart';
import '../../exam/screen/exam_scores_screen.dart';
import '../../checkin/screen/checkin_screen.dart';
import '../../auth/service/auth_service.dart';
import '../../exam/service/exam_service.dart';
import '../../account/screen/profile_screen.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentBottomNavIndex = 0;

  final AuthService _authService = AuthService();
  final ExamService _examService = ExamService();
  final TimetableService _timetableService = TimetableService();
  final NotificationService _notificationService = NotificationService();
  final TokenStorage _tokenStorage = TokenStorage();

  ExamScoreSummary _scoreSummary = ExamScoreSummary(score: 0.0);
  String? _username;
  String? _userId;

  List<ExamCard> _events = [];
  List<TaskCard> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadMe();
    _loadSubjects();
    _loadEvents();
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

  Future<void> _loadSubjects() async {
    try {
      final userId = await _tokenStorage.readUserId();
      if (userId == null || userId.isEmpty) return;
      final groupId = await _tokenStorage.readGroupId();

      final raw = groupId != null && groupId.isNotEmpty
          ? await _timetableService.listByGroup(groupId)
          : await _timetableService.listByUser(userId);

      final nowWeekday = DateTime.now().weekday; // Mon=1..Sun=7
      final stats = <String, ({int total, int completed})>{};

      for (final row in raw) {
        final subject = asMap(row['subject']);
        final title =
            readString(subject ?? row, const [
              'name',
              'title',
              'subject_name',
              'subjectName',
            ]) ??
            'Class';

        final day = readString(row, const ['day_of_week', 'dayOfWeek', 'day']);
        final dayIndex = _weekdayIndex(day);
        final isCompleted = dayIndex != null && dayIndex <= nowWeekday;

        final existing = stats[title] ?? (total: 0, completed: 0);
        stats[title] = (
          total: existing.total + 1,
          completed: existing.completed + (isCompleted ? 1 : 0),
        );
      }

      final subjects =
          stats.entries.map((entry) {
            final total = entry.value.total;
            final completed = entry.value.completed;
            final progress = total == 0 ? 0.0 : (completed / total);
            return TaskCard(
              title: entry.key,
              taskCount: total,
              progress: progress.clamp(0.0, 1.0),
              iconCategory: _subjectIconCategory(entry.key),
            );
          }).toList()
            ..sort((a, b) => (b.taskCount ?? 0).compareTo(a.taskCount ?? 0));

      if (!mounted) return;
      setState(() => _subjects = subjects);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadEvents() async {
    try {
      final raw = await _notificationService.list();
      final events = raw
          .map(_mapNotificationToEventCard)
          .whereType<ExamCard>()
          .toList();

      if (!mounted) return;
      setState(() => _events = events.take(2).toList());
    } catch (_) {
      // ignore
    }
  }

  ExamCard? _mapNotificationToEventCard(Map<String, dynamic> json) {
    final type = readString(json, const ['title', 'type']) ?? 'Event';
    final message = readString(json, const ['message', 'body']) ?? '';
    final isRead =
        (json['is_read'] == true) ||
        (json['isRead'] == true) ||
        (readInt(json, const ['is_read']) ?? 0) == 1;

    return ExamCard(
      category: type,
      title: message.isEmpty ? 'New event' : message,
      progress: isRead ? 1.0 : 0.35,
      iconCategory: isRead ? 'blue' : 'pink',
    );
  }

  int? _weekdayIndex(String? raw) {
    if (raw == null) return null;
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.startsWith('mon')) return DateTime.monday;
    if (v.startsWith('tue')) return DateTime.tuesday;
    if (v.startsWith('wed')) return DateTime.wednesday;
    if (v.startsWith('thu')) return DateTime.thursday;
    if (v.startsWith('fri')) return DateTime.friday;
    if (v.startsWith('sat')) return DateTime.saturday;
    if (v.startsWith('sun')) return DateTime.sunday;
    return null;
  }

  String _subjectIconCategory(String title) {
    final index = title.hashCode.abs() % 3;
    switch (index) {
      case 0:
        return 'office';
      case 1:
        return 'personal';
      default:
        return 'study';
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
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ).then((_) {
          if (mounted) setState(() => _currentBottomNavIndex = 0);
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
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
                            'Event',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeXL,
                              fontWeight: FontWeight.bold,
                              color: appColors.textPrimary,
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
                              '${_events.length}',
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
                    // Event Cards
                    if (_events.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: const Text('No events yet'),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Row(
                          children: [
                            ExamCardItem(exam: _events[0]),
                            if (_events.length > 1) ...[
                              SizedBox(width: AppSizes.spacingM),
                              ExamCardItem(exam: _events[1]),
                            ],
                          ],
                        ),
                      ),
                    SizedBox(height: AppSizes.spacingL),
                    // Subject Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Subject',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeXL,
                              fontWeight: FontWeight.bold,
                              color: appColors.textPrimary,
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
                              '${_subjects.length}',
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
                    // Subject Cards (same design as tasks)
                    if (_subjects.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: const Text('No subjects yet'),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          children: _subjects
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
