import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../widgets/common/custom_bottom_navigation_bar.dart';
import '../../dashboard/screen/dashboard_screen.dart';
import '../widget/calendar_table_widget.dart';
import '../widget/timetable_task_card.dart';
import '../model/timetable_task_model.dart';
import '../../exam/screen/exam_scores_screen.dart';
import '../../checkin/screen/checkin_screen.dart';
import '../../services/timetable_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../account/screen/profile_screen.dart';

class TimetableView extends StatefulWidget {
  const TimetableView({super.key});

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> {
  int _currentBottomNavIndex = 3; // Schedule icon is index 3
  final TimetableService _timetableService = TimetableService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _rawTimetable = [];

  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  Map<DateTime, int> _tasksCountByDate = {}; // Map of date to task count

  List<TimetableTaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await _tokenStorage.readUserId();
      final groupId = await _tokenStorage.readGroupId();

      if (userId == null || userId.isEmpty) {
        throw Exception('Missing user id. Please login again.');
      }

      final raw = groupId != null && groupId.isNotEmpty
          ? await _timetableService.listByGroup(groupId)
          : await _timetableService.listByUser(userId);

      if (!mounted) return;
      setState(() {
        _rawTimetable = raw;
        // Rebuild tasks count whenever data is loaded
        _tasksCountByDate = _buildTasksCountByDate();
        _tasks = _mapTasksForSelectedDay();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _tasks = [];
      });
    }
  }

  void _onTaskCompleted(int index, bool completed) {
    setState(() {
      if (completed) {
        // Mark task as completed
        _tasks[index] = TimetableTaskModel(
          id: _tasks[index].id,
          title: _tasks[index].title,
          details: _tasks[index].details,
          time: _tasks[index].time,
          isCompleted: true,
          iconType: 'check',
          building: _tasks[index].building,
          room: _tasks[index].room,
          instructor: _tasks[index].instructor,
          dayOfWeek: _tasks[index].dayOfWeek,
        );
      }
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      // If the date is in a different month, update the current month view
      if (date.year != _currentMonth.year || date.month != _currentMonth.month) {
        _currentMonth = DateTime(date.year, date.month);
      }
      _selectedDate = DateTime(date.year, date.month, date.day);
      _tasks = _mapTasksForSelectedDay();
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _currentMonth = DateTime(newMonth.year, newMonth.month);
      // Rebuild tasks count for the new month
      _tasksCountByDate = _buildTasksCountByDate();
      // Keep selected date if it's still in the new month, otherwise select first day
      if (_selectedDate.year != _currentMonth.year || 
          _selectedDate.month != _currentMonth.month) {
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
        _tasks = _mapTasksForSelectedDay();
      } else {
        // Update tasks for the selected date in the new month
        _tasks = _mapTasksForSelectedDay();
      }
    });
  }

  void _onBottomNavTap(int index) {
    // Only update local index when staying on this tab
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
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExamScoresScreen()),
        );
        break;
      case 3:
        // Already on timetable
        setState(() => _currentBottomNavIndex = 3);
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Timetable Header
            SizedBox(height: AppSizes.spacingM),
            // Calendar Table
            CalendarTableWidget(
              selectedDate: _selectedDate,
              currentMonth: _currentMonth,
              onDateSelected: _onDateSelected,
              onMonthChanged: _onMonthChanged,
              tasksCount: _tasksCountByDate,
            ),
            SizedBox(height: AppSizes.spacingXL),
            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadTimetable,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTimetable,
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: AppSizes.spacingM),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return TimetableTaskCard(
                            task: _tasks[index],
                            onCompletionChanged: (completed) =>
                                _onTaskCompleted(index, completed),
                          );
                        },
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

  Map<DateTime, int> _buildTasksCountByDate() {
    final Map<DateTime, int> countMap = {};
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    for (final row in _rawTimetable) {
      // Try to get date from various fields (specific date)
      final dateStr = readString(row, const ['date', 'schedule_date', 'scheduleDate', 'scheduled_date']);
      if (dateStr != null) {
        try {
          final taskDate = DateTime.parse(dateStr);
          final dateKey = DateTime(taskDate.year, taskDate.month, taskDate.day);
          
          // Only include if it's in the current month view
          if (dateKey.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
              dateKey.isBefore(lastDayOfMonth.add(const Duration(days: 1)))) {
            countMap[dateKey] = (countMap[dateKey] ?? 0) + 1;
          }
          continue; // Skip day_of_week processing for specific dates
        } catch (_) {
          // If parsing fails, fall through to day of week processing
        }
      }
      
      // Handle weekly recurring schedules (day_of_week)
      final dayOfWeek = readString(row, const [
        'day_of_week',
        'dayOfWeek',
        'day',
      ]);
      
      if (dayOfWeek != null) {
        final weekdayNumber = _getWeekdayNumber(dayOfWeek);
        if (weekdayNumber != null) {
          // Find all occurrences of this weekday in the current month
          final occurrences = _getAllWeekdayOccurrencesInMonth(
            weekdayNumber,
            firstDayOfMonth,
            lastDayOfMonth,
          );
          
          for (final date in occurrences) {
            final dateKey = DateTime(date.year, date.month, date.day);
            countMap[dateKey] = (countMap[dateKey] ?? 0) + 1;
          }
        }
      }
    }

    return countMap;
  }

  int? _getWeekdayNumber(String dayOfWeek) {
    final dayNames = {
      'monday': 1, 'mon': 1, '1': 1,
      'tuesday': 2, 'tue': 2, '2': 2,
      'wednesday': 3, 'wed': 3, '3': 3,
      'thursday': 4, 'thu': 4, 'thurs': 4, '4': 4,
      'friday': 5, 'fri': 5, '5': 5,
      'saturday': 6, 'sat': 6, '6': 6,
      'sunday': 7, 'sun': 7, '0': 7, '7': 7,
    };
    
    return dayNames[dayOfWeek.toLowerCase().trim()];
  }

  List<DateTime> _getAllWeekdayOccurrencesInMonth(
    int weekday,
    DateTime firstDay,
    DateTime lastDay,
  ) {
    final List<DateTime> occurrences = [];
    
    // Find first occurrence of this weekday in the month
    int firstDayWeekday = firstDay.weekday;
    int daysToAdd = weekday - firstDayWeekday;
    if (daysToAdd < 0) daysToAdd += 7;
    
    DateTime currentDate = firstDay.add(Duration(days: daysToAdd));
    
    // Add all occurrences in the month
    while (currentDate.isBefore(lastDay.add(const Duration(days: 1)))) {
      occurrences.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 7));
    }
    
    return occurrences;
  }


  List<TimetableTaskModel> _mapTasksForSelectedDay() {
    final selectedDateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final selectedWeekday = _selectedDate.weekday;

    return _rawTimetable
        .where((row) {
          // Try to match by actual date first (specific date schedules)
          final dateStr = readString(row, const [
            'date',
            'schedule_date',
            'scheduleDate',
            'scheduled_date',
            'scheduledDate',
          ]);
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              final taskDate = DateTime.parse(dateStr);
              final taskDateKey = DateTime(taskDate.year, taskDate.month, taskDate.day);
              return taskDateKey == selectedDateKey;
            } catch (_) {
              // If parsing fails, fall through to day of week matching
            }
          }
          
          // Fall back to day of week matching (weekly recurring schedules)
          final day = readString(row, const [
            'day_of_week',
            'dayOfWeek',
            'day',
            'weekday',
          ]);
          if (day == null || day.isEmpty) return false;
          
          final weekdayNumber = _getWeekdayNumber(day);
          return weekdayNumber != null && weekdayNumber == selectedWeekday;
        })
        .map((row) {
          final subject = asMap(row['subject']);
          final classroom = asMap(row['class']) ?? asMap(row['class_room']);
          final building =
              asMap(classroom?['building']) ?? asMap(row['building']);

          final title =
              readString(subject ?? row, const [
                'name',
                'title',
                'subject_name',
                'subjectName',
              ]) ??
              'Class';

          final start =
              readString(row, const ['start_time', 'startTime']) ?? '';
          final end = readString(row, const ['end_time', 'endTime']) ?? '';
          final time = [start, end].where((s) => s.isNotEmpty).join(' - ');

          final roomCode = readString(classroom ?? row, const [
            'name',
            'code',
            'room',
            'room_name',
            'roomName',
          ]);
          final buildingCode = readString(building ?? row, const [
            'name',
            'code',
            'building_name',
            'buildingName',
          ]);
          
          final instructor = readString(row, const [
            'instructor',
            'teacher',
            'instructor_name',
            'instructorName',
            'teacher_name',
            'teacherName',
          ]);
          
          final dayOfWeek = readString(row, const [
            'day_of_week',
            'dayOfWeek',
            'day',
            'weekday',
          ]);

          final details = [
            if (buildingCode != null && buildingCode.isNotEmpty) buildingCode,
            if (roomCode != null && roomCode.isNotEmpty) roomCode,
          ].join(' • ');

          return TimetableTaskModel(
            id: readString(row, const ['id']),
            title: title,
            details: details.isEmpty ? 'Timetable' : details,
            time: time.isEmpty ? '-' : time,
            isCompleted: false,
            iconType: 'info',
            building: buildingCode,
            room: roomCode,
            instructor: instructor,
            dayOfWeek: dayOfWeek,
          );
        })
        .toList();
  }
}
