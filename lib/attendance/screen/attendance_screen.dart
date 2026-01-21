import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../widget/date_selector.dart';
import '../widget/stat_card.dart';
import '../widget/activity_item.dart';
import '../../app_header.dart';
import '../../services/attendance_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import 'attendance_history_screen.dart';
import '../../leave_request/screen/leave_request_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedDateIndex = 3; // "04 Wed" selected in screenshot
  final AttendanceService _attendanceService = AttendanceService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendanceRows = [];

  final List<Map<String, String>> _days = [
    {"day": "01", "weekday": "Sun"},
    {"day": "02", "weekday": "Mon"},
    {"day": "03", "weekday": "Tue"},
    {"day": "04", "weekday": "Wed"},
    {"day": "05", "weekday": "Th6"}, // Screenshot says Th6? probably Thu
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = await _tokenStorage.readUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Missing user id. Please login again.');
      }
      final rows = await _attendanceService.myAttendance(userId);
      if (!mounted) return;
      setState(() {
        _attendanceRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _attendanceRows.length;
    final presentDays = _attendanceRows
        .where(
          (row) => (readString(row, const ['status']) ?? '')
              .toLowerCase()
              .contains('present'),
        )
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
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
                                  builder: (context) =>
                                      const AttendanceHistoryScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 8.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "Attendance sheet",
                                    style: TextStyle(
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
                                  builder: (context) =>
                                      const LeaveRequestScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 8.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "Leave Request",
                                    style: TextStyle(
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

                    const Text(
                      "Check in today",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.login,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Check In",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "10:20 AM",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "2hours ago",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.logout,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Check Out",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "5:30 PM",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "On time",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
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
                          title: "Attendance",
                          value: "$presentDays",
                          subtitle: "day of month",
                          icon: Icons.calendar_today,
                          iconColor: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        StatCard(
                          title: "Total number day\nof month",
                          value: "$totalDays",
                          subtitle: "day of month",
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
                        const Text(
                          "Your activity",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AttendanceHistoryScreen(),
                              ),
                            );
                          },
                          child: const Text("See All"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Activity List
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadAttendance,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_attendanceRows.isEmpty)
                      const Text('No attendance records')
                    else
                      ..._attendanceRows.take(2).expand((row) {
                        final date =
                            readString(row, const ['date', 'created_at']) ??
                            '-';
                        final checkIn =
                            readString(row, const ['check_in_time']) ?? '';
                        final checkOut =
                            readString(row, const ['check_out_time']) ?? '';
                        final status =
                            readString(row, const ['status', 'remark']) ??
                            'on time';

                        return [
                          if (checkIn.isNotEmpty)
                            ActivityItemWidget(
                              type: "checkin",
                              date: date,
                              time: checkIn,
                              statusMessage: status,
                            ),
                          if (checkOut.isNotEmpty)
                            ActivityItemWidget(
                              type: "checkout",
                              date: date,
                              time: checkOut,
                              statusMessage: status,
                            ),
                        ];
                      }),
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
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusM,
                              ),
                            ),
                          ),
                          child: Text(
                            'Back',
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
      ),
    );
  }
}
