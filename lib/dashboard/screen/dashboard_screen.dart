import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
import '../../utils/pull_to_refresh.dart';
import '../../checkin/screen/checkin_screen.dart';
import '../../event/screen/events_screen.dart';
import '../../services/attendance_service.dart';
import '../../services/timetable_service.dart';
import '../../timetable/screen/timetable_screen.dart';
import '../widget/exam_card_item.dart';
import '../widget/task_card_item.dart';
import '../model/dashboard_models.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../services/event_service.dart';
import '../../services/subject_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TimetableService _timetableService = TimetableService();
  final EventService _eventService = EventService();
  final AttendanceService _attendanceService = AttendanceService();
  final TokenStorage _tokenStorage = TokenStorage();
  final SubjectService _subjectService = SubjectService();

  List<ExamCard> _events = [];
  List<TaskCard> _subjects = [];
  int _todayClasses = 0;
  int _todayChecked = 0;

  @override
  void initState() {
    super.initState();
    _loadTodayCheckin();
    _loadSubjects();
    _loadEvents();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadTodayCheckin(), _loadSubjects(), _loadEvents()]);
  }

  Future<void> _loadTodayCheckin() async {
    try {
      final userId = await _tokenStorage.readUserId();
      final groupId = await _tokenStorage.readGroupId();
      if ((userId == null || userId.isEmpty) &&
          (groupId == null || groupId.isEmpty)) {
        return;
      }

      final raw = userId != null && userId.isNotEmpty
          ? await _timetableService.listByUser(userId)
          : await _timetableService.listByGroup(groupId!);

      final todayIndex = DateTime.now().weekday;
      final todayTimetables = raw.where((row) {
        final day = readString(row, const ['day_of_week', 'dayOfWeek', 'day']);
        final idx = _weekdayIndex(day);
        return idx == todayIndex;
      }).toList();

      int checked = 0;
      if (userId != null && userId.isNotEmpty) {
        final attendance = await _attendanceService.myAttendance(userId);
        final today = DateTime.now();
        checked = attendance
            .where((row) => _isSameDay(_parseDate(row), today))
            .length;
      }

      if (!mounted) return;
      setState(() {
        _todayClasses = todayTimetables.length;
        _todayChecked = checked.clamp(0, todayTimetables.length);
      });
    } catch (_) {
      // ignore
    }
  }

  DateTime? _parseDate(Map<String, dynamic> row) {
    final raw = readString(row, const ['date', 'created_at', 'createdAt']);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      if (raw.length >= 10) {
        try {
          return DateTime.parse(raw.substring(0, 10));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _subjectService.listSubjects();

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
    final title = readString(json, const ['title', 'name']) ?? 'New event';
    final isExam =
        type.toLowerCase().contains('exam') ||
        title.toLowerCase().contains('exam');

    return ExamCard(
      id: readString(json, const ['id']),
      category: type,
      title: title,
      date: readString(json, const ['date']),
      startTime: readString(json, const ['start_time', 'startTime']),
      endTime: readString(json, const ['end_time', 'endTime']),
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

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checkinProgress = _todayClasses == 0
        ? 0.0
        : (_todayChecked / _todayClasses);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      body: AppPullToRefresh(
        onRefresh: _refresh,
        alwaysScrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.spacingS),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _SmartCheckinCard(
                todayClasses: _todayClasses,
                todayChecked: _todayChecked,
                progress: checkinProgress.clamp(0.0, 1.0),
                onOpen: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckInScreen()),
                  );
                },
              ),
            ),
            SizedBox(height: AppSizes.spacingM),
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
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EventsScreen()),
                      );
                    },
                    child: const Text('See all'),
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
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TimetableView(),
                        ),
                      );
                    },
                    child: const Text('See all'),
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
                  children: _subjects
                      .take(5)
                      .map((task) => TaskCardItem(task: task))
                      .toList(),
                ),
              ),
            SizedBox(height: AppSizes.spacingM),
          ],
        ),
      ),
    );
  }
}

class _SmartCheckinCard extends StatelessWidget {
  final int todayClasses;
  final int todayChecked;
  final double progress;
  final VoidCallback onOpen;

  const _SmartCheckinCard({
    required this.todayClasses,
    required this.todayChecked,
    required this.progress,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = todayClasses > 0 && todayChecked >= todayClasses;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.success.withValues(alpha: 0.35),
                  AppColors.primaryBlue.withValues(alpha: 0.25),
                ]
              : [
                  AppColors.success.withValues(alpha: 0.22),
                  AppColors.primaryBlueLight.withValues(alpha: 0.35),
                ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone ? 'All check-ins complete' : 'Today check-in',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  todayClasses == 0
                      ? 'No timetable today'
                      : '$todayChecked / $todayClasses checked',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeS,
                    color: appColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF2E2E2E)
                        : AppColors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? AppColors.success : AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: Text(isDone ? 'View' : 'Scan now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingM,
                        vertical: AppSizes.spacingS,
                      ),
                      backgroundColor: isDone
                          ? AppColors.primaryBlue
                          : AppColors.success,
                      foregroundColor: AppColors.white,
                      textStyle: const TextStyle(
                        fontSize: AppSizes.fontSizeS,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: isDark ? 0.10 : 0.24),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.verified_rounded : Icons.qr_code_2,
              color: isDone ? AppColors.success : AppColors.primaryBlue,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
