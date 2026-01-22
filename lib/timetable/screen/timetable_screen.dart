import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../custom_bottom_navigation_bar.dart';
import '../../dashboard/screen/dashboard_screen.dart';
import '../widget/date_picker_widget.dart';
import '../widget/intake_progress_widget.dart';
import '../widget/timetable_task_card.dart';
import '../model/timetable_task_model.dart';
import '../../leave_request/screen/apply_leave_screen.dart';
import '../../exam/screen/exam_scores_screen.dart';
import '../../checkin/screen/checkin_screen.dart';
import '../../account/screen/profile_screen.dart'; // SettingsScreen is defined here

class TimetableView extends StatefulWidget {
  const TimetableView({super.key});

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> {
  int _currentBottomNavIndex = 3; // Schedule icon is index 3
  
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
  
  List<TimetableTaskModel> _tasks = [
    TimetableTaskModel(
      id: '1',
      title: 'Databaae',
      details: '1 TP, 2 Quiz',
      time: '09:41',
      isCompleted: false,
      iconType: 'info',
    ),
    TimetableTaskModel(
      id: '2',
      title: 'Programming Language',
      details: '5 quiz, 1 Course',
      time: '06:13',
      isCompleted: false,
      iconType: 'info',
    ),
  ];

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

      // Sample data update
      if (selectedDay.day == 7) {
        _currentIntake = IntakeModel(
          completed: 0,
          total: 2,
          dayName: 'Wednesday',
        );
        _tasks = [
          TimetableTaskModel(
            title: 'Databaae',
            details: '1 TP, 2 Quiz',
            time: '09:41',
            isCompleted: false,
          ),
          TimetableTaskModel(
            title: 'Programming Language',
            details: '5 quiz, 1 Course',
            time: '06:13',
            isCompleted: false,
          ),
        ];
      } else {
        _currentIntake = IntakeModel(
          completed: 2,
          total: 2,
          dayName: selectedDay.dayAbbreviation,
        );
        _tasks = [
          TimetableTaskModel(
            title: 'Databaae',
            details: '1 TP, 2 Quiz',
            time: '09:41',
            isCompleted: true,
          ),
          TimetableTaskModel(
            title: 'Programming Language',
            details: '5 quiz, 1 Course',
            time: '06:13',
            isCompleted: true,
          ),
        ];
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
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
        );        break;
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
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: AppSizes.spacingM),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return TimetableTaskCard(
                    task: _tasks[index],
                    onCompletionChanged: (completed) => _onTaskCompleted(index, completed),
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
