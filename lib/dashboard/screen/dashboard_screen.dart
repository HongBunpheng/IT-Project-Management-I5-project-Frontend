import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
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
      body: SingleChildScrollView(
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
