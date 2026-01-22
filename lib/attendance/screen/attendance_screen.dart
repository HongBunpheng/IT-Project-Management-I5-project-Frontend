import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/localization_helper.dart';
import '../widget/date_selector.dart';
import '../widget/stat_card.dart';
import '../widget/activity_item.dart';
import '../../widgets/common/app_header.dart';
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
  int _selectedDateIndex = 3;
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
    {"day": "05", "weekday": "Thu"},
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
                                children: [
                                  Text(
                                    safeLocaleString(
                                      context,
                                      'attendance_sheet',
                                      fallback: 'Attendance sheet',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF154888),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Color(0xFF154888),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                                children: [
                                  Text(
                                    safeLocaleString(
                                      context,
                                      'leave_request',
                                      fallback: 'Leave Request',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
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
                    DateSelector(
                      days: _days,
                      selectedIndex: _selectedDateIndex,
                      onSelect: (index) {
                        setState(() => _selectedDateIndex = index);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        StatCard(
                          title: safeLocaleString(
                            context,
                            'present_days',
                            fallback: 'Present Days',
                          ),
                          value: '$presentDays',
                          subtitle: safeLocaleString(
                            context,
                            'out_of_total_days',
                            fallback: 'Out of $totalDays',
                          ),
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: safeLocaleString(
                            context,
                            'total_days',
                            fallback: 'Total Days',
                          ),
                          value: '$totalDays',
                          subtitle: safeLocaleString(
                            context,
                            'attendance_records',
                            fallback: 'Attendance records',
                          ),
                          icon: Icons.calendar_today_outlined,
                          iconColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      safeLocaleString(
                        context,
                        'recent_activity',
                        fallback: 'Recent activity',
                      ),
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeM,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A74DA),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    SizedBox(
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
                          safeLocaleString(context, 'back', fallback: 'Back'),
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeM,
                            fontWeight: FontWeight.w600,
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

