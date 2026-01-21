import 'package:flutter/material.dart';
import '../configs/app_colors.dart';
import '../configs/app_sizes.dart';
import '../widgets/common/custom_bottom_navigation_bar.dart';
import 'dashboard/dashboard_view.dart';
import '../widgets/timetable/timetable_header.dart';
import '../widgets/timetable/date_picker_widget.dart';
import '../widgets/timetable/intake_progress_widget.dart';
import '../widgets/timetable/timetable_task_card.dart';
import '../models/timetable_task_model.dart';
import 'leave_request/apply_leave_screen.dart';
import 'exam_scores_screen.dart';
import '../services/timetable_service.dart';
import '../services/token_storage.dart';
import '../utils/json_utils.dart';
// import 'settings_screen.dart';
import 'checkin_screen.dart';

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

  // Sample data - replace with API data later
  IntakeModel _currentIntake = IntakeModel(
    completed: 0,
    total: 2,
    dayName: 'Wednesday',
  );

  final List<DayModel> _days = [
    DayModel(day: 3, dayAbbreviation: 'SAT'),
    DayModel(day: 4, dayAbbreviation: 'SUN'),
    DayModel(day: 5, dayAbbreviation: 'MON'),
    DayModel(day: 6, dayAbbreviation: 'TUE'),
    DayModel(day: 7, dayAbbreviation: 'WED', isSelected: true, isToday: true),
    DayModel(day: 8, dayAbbreviation: 'THU'),
    DayModel(day: 9, dayAbbreviation: 'FRI'),
  ];

  int _selectedDayIndex = 4; // Index of the selected day (default: day 7)

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
        _tasks = _mapTasksForSelectedDay();
        _currentIntake = IntakeModel(
          completed: _tasks.where((t) => t.isCompleted).length,
          total: _tasks.length,
          dayName: _daysWithSelection[_selectedDayIndex].dayAbbreviation,
        );
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
        );

        // Update intake progress
        final completedCount = _tasks.where((t) => t.isCompleted).length;
        _currentIntake = IntakeModel(
          completed: completedCount,
          total: _currentIntake.total,
          dayName: _currentIntake.dayName,
        );
      }
    });
  }

  List<DayModel> get _daysWithSelection {
    return _days.asMap().entries.map((entry) {
      final day = entry.value;
      return DayModel(
        day: day.day,
        dayAbbreviation: day.dayAbbreviation,
        isSelected: entry.key == _selectedDayIndex,
        isToday: day.isToday,
      );
    }).toList();
  }

  void _onDaySelected(DayModel selectedDay) {
    setState(() {
      final index = _days.indexWhere((d) => d.day == selectedDay.day);
      if (index != -1) _selectedDayIndex = index;

      _tasks = _mapTasksForSelectedDay();
      _currentIntake = IntakeModel(
        completed: _tasks.where((t) => t.isCompleted).length,
        total: _tasks.length,
        dayName: selectedDay.dayAbbreviation,
      );
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusL),
            ),
            child: const ApplyLeaveScreen(),
          ),
        );
      },
    );
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
      // case 4:
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const SettingsScreen()),
      //   );
      //   break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Timetable Header
            TimetableHeader(),
            SizedBox(height: AppSizes.spacingM),
            // Date Picker
            DatePickerWidget(
              days: _daysWithSelection,
              onDaySelected: _onDaySelected,
            ),
            SizedBox(height: AppSizes.spacingXL),
            // Intake Progress
            IntakeProgressWidget(intake: _currentIntake),
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

  List<TimetableTaskModel> _mapTasksForSelectedDay() {
    final selected = _daysWithSelection[_selectedDayIndex].dayAbbreviation;

    return _rawTimetable
        .where((row) {
          final day = readString(row, const [
            'day_of_week',
            'dayOfWeek',
            'day',
          ]);
          if (day == null) return true;
          return day.toLowerCase().startsWith(selected.toLowerCase());
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
          ]);
          final buildingCode = readString(building ?? row, const [
            'name',
            'code',
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
          );
        })
        .toList();
  }
}
