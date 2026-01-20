import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import 'attendance_weekly_screen.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() => _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  DateTime _currentMonth = DateTime(2025, 10, 1); // October 2025
  bool _isMonthView = true; // true for Month, false for Week

  // Sample attendance data for October 2025
  final Map<int, AttendanceStatus> _attendanceData = {
    1: AttendanceStatus.nonWorking, // Sunday
    2: AttendanceStatus.present,
    3: AttendanceStatus.present,
    4: AttendanceStatus.present,
    5: AttendanceStatus.present,
    6: AttendanceStatus.present,
    7: AttendanceStatus.present,
    8: AttendanceStatus.nonWorking, // Sunday
    9: AttendanceStatus.present,
    10: AttendanceStatus.present,
    11: AttendanceStatus.present,
    12: AttendanceStatus.present,
    13: AttendanceStatus.present,
    14: AttendanceStatus.present,
    15: AttendanceStatus.nonWorking, // Sunday
    16: AttendanceStatus.absent,
    17: AttendanceStatus.absent,
    18: AttendanceStatus.absent,
    19: AttendanceStatus.absent,
    20: AttendanceStatus.absent,
    21: AttendanceStatus.absent,
    22: AttendanceStatus.nonWorking, // Sunday
    23: AttendanceStatus.present,
    24: AttendanceStatus.absent,
    25: AttendanceStatus.present,
    26: AttendanceStatus.present,
    27: AttendanceStatus.present,
    28: AttendanceStatus.present,
    29: AttendanceStatus.nonWorking, // Sunday
    30: AttendanceStatus.noData,
    31: AttendanceStatus.noData,
  };

  List<String> _getWeekDays() {
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  }

  List<CalendarDay> _getCalendarDays() {
    final List<CalendarDay> days = [];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Add days from previous month to fill first week
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    final daysToAdd = firstWeekday == 7 ? 0 : firstWeekday;
    
    for (int i = daysToAdd - 1; i >= 0; i--) {
      final date = firstDay.subtract(Duration(days: i + 1));
      days.add(CalendarDay(date: date, status: AttendanceStatus.noData));
    }
    
    // Add days of current month
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final status = _attendanceData[day] ?? AttendanceStatus.noData;
      days.add(CalendarDay(date: date, status: status));
    }
    
    // Fill remaining days to complete last week
    final totalDays = days.length;
    final remainingDays = 42 - totalDays; // 6 weeks * 7 days
    for (int day = 1; day <= remainingDays; day++) {
      final date = lastDay.add(Duration(days: day));
      days.add(CalendarDay(date: date, status: AttendanceStatus.noData));
    }
    
    return days;
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '1';
      case AttendanceStatus.absent:
        return 'X';
      case AttendanceStatus.nonWorking:
        return 'N';
      case AttendanceStatus.noData:
        return '0';
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.orange;
      case AttendanceStatus.nonWorking:
        return Colors.green;
      case AttendanceStatus.noData:
        return Colors.grey;
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _switchView() {
    // Switch to week view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceWeeklyScreen(
          startDate: _currentMonth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _getMonthName(_currentMonth.month);
    final year = _currentMonth.year;
    final calendarDays = _getCalendarDays();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Attendance sheet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            // Month/Week selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isMonthView = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isMonthView
                              ? const Color(0xFF1976D2)
                              : Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Month',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isMonthView ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _switchView,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isMonthView
                              ? const Color(0xFF1976D2)
                              : Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Week',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isMonthView ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Month navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    '$monthName $year',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Calendar grid
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Week day headers
                    Row(
                      children: _getWeekDays().map((day) {
                        return Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Calendar days grid
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: calendarDays.length,
                        itemBuilder: (context, index) {
                          final day = calendarDays[index];
                          final isCurrentMonth =
                              day.date.month == _currentMonth.month;
                          final statusText = _getStatusText(day.status);
                          final statusColor = _getStatusColor(day.status);

                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.date.day}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentMonth
                                        ? Colors.black87
                                        : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
