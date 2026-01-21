import 'package:flutter/material.dart';
import '../configs/app_colors.dart';
import '../configs/app_sizes.dart';
import '../widgets/common/custom_bottom_navigation_bar.dart';
import '../widgets/timetable/timetable_header.dart';
import '../widgets/timetable/date_picker_widget.dart';
import '../widgets/timetable/intake_progress_widget.dart';
import '../widgets/timetable/timetable_task_card.dart';
import '../models/timetable_task_model.dart';

class TimetableView extends StatefulWidget {
  const TimetableView({super.key});

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> {
  int _currentBottomNavIndex = 2; // Schedule is index 2
  
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
      // Update selected day index
      final index = _days.indexWhere((d) => d.day == selectedDay.day);
      if (index != -1) {
        _selectedDayIndex = index;
      }
      
      // Update intake based on selected day
      // This is sample data - replace with actual data from API
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
        // Sample data for other days
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
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    
    // Navigate based on index
    switch (index) {
      case 0:
        // Navigate to dashboard
        Navigator.pop(context); // Assuming we came from Dashboard
        break;
      case 1:
        // Check in
        break;
      case 2:
        // Already on timetable
        break;
      case 3:
        // Notifications
        break;
      case 4:
        // Navigate to settings (if needed)
        break;
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
