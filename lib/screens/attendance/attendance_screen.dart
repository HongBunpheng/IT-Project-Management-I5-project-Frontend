import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../widgets/user_profile_section.dart';
import '../widgets/attendance_day_selector.dart';
import '../widgets/check_in_out_section.dart';
import '../widgets/summary_statistics.dart';
import '../widgets/activity_list.dart';
import 'attendance_calendar_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int selectedDay = 4; // Default to day 04 Wed

  final List<DayInfo> days = [
    DayInfo(day: 1, dayName: 'Sun'),
    DayInfo(day: 2, dayName: 'Mon'),
    DayInfo(day: 3, dayName: 'Tue'),
    DayInfo(day: 4, dayName: 'Wed', isSelected: true),
    DayInfo(day: 5, dayName: 'Thu'),
  ];

  final List<AttendanceRecord> activities = [
    AttendanceRecord(
      date: '26/6/2025',
      checkInTime: '8:20 AM',
      checkOutTime: '5:20 PM',
      checkInStatus: 'late 1:20 min',
      checkOutStatus: 'on time',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // User Profile Section
                const UserProfileSection(
                  name: 'Kadorukuriki',
                  id: 'e20211399',
                  hasNotification: true,
                ),
                const SizedBox(height: 24),
                // Attendance Sheet Section
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceCalendarScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Attendance sheet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Day Selector
                AttendanceDaySelector(
                  days: days,
                  selectedDay: selectedDay,
                  onDaySelected: (day) {
                    setState(() {
                      selectedDay = day;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Check In Today Section
                const Text(
                  'Check in today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const CheckInOutSection(
                  checkInTime: '10:20 AM',
                  checkInStatus: '2hours ago',
                  checkOutTime: '5:30 PM',
                  checkOutStatus: 'On time',
                ),
                const SizedBox(height: 24),
                // Summary Statistics
                const SummaryStatistics(
                  attendance: 28,
                  totalDays: 22,
                ),
                const SizedBox(height: 24),
                // Your Activity Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ActivityList(activities: activities),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
