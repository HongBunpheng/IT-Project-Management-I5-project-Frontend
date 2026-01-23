import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
import '../../utils/pull_to_refresh.dart';
import '../../services/timetable_service.dart';
import '../widget/exam_card_item.dart';
import '../widget/exam_score_summary_card.dart';
import '../widget/task_card_item.dart';
import '../model/dashboard_models.dart';
import '../../exam/service/exam_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../services/event_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ExamService _examService = ExamService();
  final TimetableService _timetableService = TimetableService();
  final EventService _eventService = EventService();
  final TokenStorage _tokenStorage = TokenStorage();

  ExamScoreSummary _scoreSummary = ExamScoreSummary(score: 0.0);

  List<ExamCard> _events = [];
  List<TaskCard> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadSubjects();
    _loadEvents();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadSummary(), _loadSubjects(), _loadEvents()]);
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

<<<<<<< HEAD
  Future<void> _loadMe() async {
    try {
      // Try to load from storage first (faster, available immediately after registration)
      final storedFullName = await _tokenStorage.readFullName();
      final storedEmail = await _tokenStorage.readEmail();
      
      if (storedFullName != null || storedEmail != null) {
        if (mounted) {
          setState(() {
            _fullName = storedFullName;
            _email = storedEmail;
          });
        }
      }
      
      // Then fetch from API to get latest data
      final me = await _authService.me();
      if (!mounted || me == null) return;
      final data = me['data'] is Map ? (me['data'] as Map) : me;
      final user = data['user'] is Map ? (data['user'] as Map) : data;
      setState(() {
        // IMPORTANT: Only use full_name, fullName, or name - NOT user_name/username
        // user_name/username are different fields (like "jkjph" from email) and should not be used as full name
        _fullName = (user['full_name'] ?? user['fullName'] ?? user['name'] ?? data['full_name'] ?? data['fullName'] ?? data['name'] ?? _fullName)
            ?.toString();
        _email = (user['email'] ?? data['email'] ?? _email)?.toString();
        _userId = (user['id'] ?? user['user_id'] ?? data['id'] ?? data['user_id'])?.toString();
        
        // Store updated values back to storage (async, don't await to avoid blocking UI)
        if (_fullName != null && _fullName!.isNotEmpty) {
          _tokenStorage.writeFullName(_fullName!);
        }
        if (_email != null && _email!.isNotEmpty) {
          _tokenStorage.writeEmail(_email!);
        }
      });
    } catch (_) {
      // If API fails, use stored values if available
      if (mounted) {
        final storedFullName = await _tokenStorage.readFullName();
        final storedEmail = await _tokenStorage.readEmail();
        setState(() {
          _fullName = storedFullName;
          _email = storedEmail;
        });
      }
    }
  }

=======
>>>>>>> 31ed3ad0eb176462ae8a9c44e9fb5995c76fb5a0
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
      final raw = await _eventService.list();
      final events = raw
          .map(_mapEventToEventCard)
          .whereType<ExamCard>()
          .toList();

      if (!mounted) return;
      setState(() => _events = events);
    } catch (_) {
      // ignore
    }
  }

  ExamCard? _mapEventToEventCard(Map<String, dynamic> json) {
    final type =
        readString(json, const ['type', 'category', 'title']) ?? 'Event';
    final title =
        readString(json, const ['title', 'name', 'description']) ?? 'New event';
    final isExam =
        type.toLowerCase().contains('exam') ||
        title.toLowerCase().contains('exam');

    return ExamCard(
      id: readString(json, const ['id']),
      category: type,
      title: title,
      progress: 0.65,
      iconCategory: isExam ? 'blue' : 'pink',
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

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      body: AppPullToRefresh(
        onRefresh: _refresh,
        alwaysScrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.spacingM),
            ExamScoreSummaryCard(scoreSummary: _scoreSummary),
            SizedBox(height: AppSizes.spacingL),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    decoration: const BoxDecoration(
                      color: AppColors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_events.length}',
                      style: const TextStyle(
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
            if (_events.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const Text('No events yet'),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    decoration: const BoxDecoration(
                      color: AppColors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_subjects.length}',
                      style: const TextStyle(
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
            if (_subjects.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const Text('No subjects yet'),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children:
                      _subjects.map((task) => TaskCardItem(task: task)).toList(),
                ),
              ),
            SizedBox(height: AppSizes.spacingM),
          ],
        ),
      ),
    );
  }
}
