import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/localization_helper.dart';
import '../widget/date_selector.dart';
import '../widget/stat_card.dart';
import '../widget/activity_item.dart';
import '../../app_header.dart';
import 'attendance_history_screen.dart';
import '../../leave_request/screen/leave_request_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedDateIndex = 3; // "04 Wed" selected in screenshot
  
  final List<Map<String, String>> _days = [
    {"day": "01", "weekday": "Sun"},
    {"day": "02", "weekday": "Mon"},
    {"day": "03", "weekday": "Tue"},
    {"day": "04", "weekday": "Wed"},
    {"day": "05", "weekday": "Th6"}, // Screenshot says Th6? probably Thu
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            
          ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title: Attendance Sheet
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AttendanceHistoryScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              safeLocaleString(context, 'attendance_sheet', fallback: "Attendance sheet"),
                              style: const TextStyle(
                                fontSize: 16, // Adjusted to fit both
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF154888), // Dark Blue
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Color(0xFF154888),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Title: Leave Request
                   Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LeaveRequestScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              safeLocaleString(context, 'leave_request', fallback: "Leave Request"),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date Selector
              DateSelector(
                days: _days,
                selectedIndex: _selectedDateIndex,
                onSelect: (index) {
                  setState(() => _selectedDateIndex = index);
                },
              ),
                    const SizedBox(height: 30),

                    Text(
                      safeLocaleString(context, 'check_in_today', fallback: "Check in today"),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),

                    // Check In / Check Out Cards
                    Row(
                      children: [
                        // Check In
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.login, size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(safeLocaleString(context, 'check_in', fallback: "Check In"), style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "10:20 AM",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "2hours ago",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        // Check Out
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.logout, size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(safeLocaleString(context, 'check_out', fallback: "Check Out"), style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "5:30 PM",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                safeLocaleString(context, 'on_time', fallback: "On time"),
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Stats Row
                    Row(
                      children: [
                        StatCard(
                          title: safeLocaleString(context, 'attendance', fallback: "Attendance"),
                          value: "28",
                          subtitle: safeLocaleString(context, 'day_of_month', fallback: "day of month"),
                          icon: Icons.calendar_today,
                          iconColor: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        StatCard(
                          title: safeLocaleString(context, 'total_number_day_of_month', fallback: "Total number day\nof month"),
                          value: "22",
                          subtitle: safeLocaleString(context, 'day_of_month', fallback: "day of month"),
                          icon: Icons.calendar_month,
                          iconColor: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Your Activity Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          safeLocaleString(context, 'your_activity', fallback: "Your activity"),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen()),
                            );
                          },
                          child: Text(safeLocaleString(context, 'see_all', fallback: "See All")),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Activity List
                    const ActivityItemWidget(
                      type: "checkin",
                      date: "26/6/2025",
                      time: "8:20 AM",
                      statusMessage: "late 1:20 min",
                    ),
                    const ActivityItemWidget(
                      type: "checkout",
                      date: "26/6/2025",
                      time: "5:20 PM",
                      statusMessage: "on time",
                    ),
                     Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                                  ),
                                ),
                                child: Text(
                                  safeLocaleString(context, 'back', fallback: 'Back'),
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSizeM,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
