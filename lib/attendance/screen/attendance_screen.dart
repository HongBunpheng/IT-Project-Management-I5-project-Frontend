import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/localization_helper.dart';
import '../widget/date_selector.dart';
import '../widget/stat_card.dart';
import '../widget/activity_item.dart';
import '../../services/attendance_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../utils/pull_to_refresh.dart';
import 'attendance_history_screen.dart';
import '../../leave_request/screen/leave_request_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendanceRows = [];

  List<DateTime> _availableDates = const [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  DateTime? _parseDate(Map<String, dynamic> row) {
    final raw = readString(row, const [
      'date',
      'created_at',
      'createdAt',
      'check_in_date',
      'checkInDate',
    ]);
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

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
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

        final dateSet = <DateTime>{};
        for (final row in rows) {
          final dt = _parseDate(row);
          if (dt == null) continue;
          dateSet.add(DateUtils.dateOnly(dt));
        }

        var dates = dateSet.toList()..sort();
        if (dates.length > 5) {
          dates = dates.sublist(dates.length - 5);
        }

        if (dates.isEmpty) {
          final today = DateUtils.dateOnly(DateTime.now());
          dates = List.generate(
            5,
            (i) => today.subtract(Duration(days: 4 - i)),
          );
        }

        final current = _selectedDate;
        final nextSelected =
            current != null && dates.any((d) => _isSameDay(d, current))
            ? current
            : dates.last;

        _availableDates = dates;
        _selectedDate = nextSelected;
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
    final totalDays = _availableDates.length;

    final presentDaySet = <DateTime>{};
    for (final row in _attendanceRows) {
      final dt = _parseDate(row);
      if (dt == null) continue;

      final checkIn = readString(row, const ['check_in_time']) ?? '';
      final status = (readString(row, const ['status', 'remark']) ?? '')
          .toLowerCase();

      final isPresent =
          checkIn.isNotEmpty ||
          status.contains('present') ||
          status.contains('on time') ||
          status.contains('late');

      if (isPresent) {
        presentDaySet.add(DateUtils.dateOnly(dt));
      }
    }

    final presentDays = presentDaySet.length;

    final selectedDate = _selectedDate ?? DateUtils.dateOnly(DateTime.now());
    final selectedIndex = _availableDates.indexWhere(
      (d) => _isSameDay(d, selectedDate),
    );

    final selectedRows = _attendanceRows
        .where((row) => _isSameDay(_parseDate(row), selectedDate))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppPullToRefresh(
                onRefresh: _loadAttendance,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                        days: _availableDates
                            .map(
                              (d) => {
                                'day': d.day.toString().padLeft(2, '0'),
                                'weekday': _weekdayLabel(d.weekday),
                              },
                            )
                            .toList(growable: false),
                        selectedIndex: selectedIndex == -1
                            ? _availableDates.length - 1
                            : selectedIndex,
                        onSelect: (index) {
                          if (index < 0 || index >= _availableDates.length) {
                            return;
                          }
                          setState(
                            () => _selectedDate = _availableDates[index],
                          );
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
                            subtitle: '$presentDays / $totalDays days',
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
                      else if (selectedRows.isEmpty)
                        Text(
                          'No activity for ${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.grey),
                        )
                      else
                        ...selectedRows.expand((row) {
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
            ),
          ],
        ),
      ),
    );
  }
}
