import 'package:flutter/material.dart';
import '../model/attendance_model.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../services/attendance_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../widget/attendance_toggle_button.dart';
import '../widget/calendar_day_cell.dart';
import '../widget/week_record_item.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isMonthView = true;
  DateTime _focusedDate = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendanceRows = [];

  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<CalendarDay> _monthData = [];

  final List<WeeklyAttendanceRecord> _weekData = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (!mounted) return;
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
        _rebuildViewData();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _attendanceRows = [];
        _monthData.clear();
        _weekData.clear();
      });
    }
  }

  void _rebuildViewData() {
    _monthData
      ..clear()
      ..addAll(_buildMonthData());
    _weekData
      ..clear()
      ..addAll(_buildWeekData());
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

  bool _isPresentRow(Map<String, dynamic> row) {
    final checkIn = readString(row, const [
          'check_in_time',
          'checkInTime',
          'time_in',
        ]) ??
        '';
    final status = (readString(row, const ['status', 'remark']) ?? '')
        .trim()
        .toLowerCase();

    return checkIn.isNotEmpty ||
        status.contains('present') ||
        status.contains('on time') ||
        status.contains('late') ||
        status == '1' ||
        status == 'true';
  }

  bool _isExplicitAbsentRow(Map<String, dynamic> row) {
    final checkIn = readString(row, const [
          'check_in_time',
          'checkInTime',
          'time_in',
        ]) ??
        '';
    if (checkIn.isNotEmpty) return false;
    final status = (readString(row, const ['status', 'remark']) ?? '')
        .trim()
        .toLowerCase();
    return status.contains('absent') || status.contains('miss');
  }

  Map<DateTime, AttendanceStatus> _statusByDay() {
    final map = <DateTime, AttendanceStatus>{};
    for (final row in _attendanceRows) {
      final dt = _parseDate(row);
      if (dt == null) continue;
      final day = DateUtils.dateOnly(dt);

      final current = map[day];
      if (_isPresentRow(row)) {
        map[day] = AttendanceStatus.present;
        continue;
      }
      if (_isExplicitAbsentRow(row) && current != AttendanceStatus.present) {
        map[day] = AttendanceStatus.absent;
      }
    }
    return map;
  }

  List<CalendarDay> _buildMonthData() {
    final statusByDay = _statusByDay();

    final year = _focusedDate.year;
    final month = _focusedDate.month;
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);

    // Monday=1..Sunday=7. We want Monday as first column.
    final leadingEmpty = (first.weekday - DateTime.monday) % 7;

    final out = <CalendarDay>[];
    for (var i = 0; i < leadingEmpty; i++) {
      out.add(
        CalendarDay(date: DateTime(0), status: AttendanceStatus.noData),
      );
    }

    for (var day = 1; day <= last.day; day++) {
      final dt = DateTime(year, month, day);
      final weekday = dt.weekday;
      final isWeekend =
          weekday == DateTime.saturday || weekday == DateTime.sunday;

      final status =
          isWeekend
              ? AttendanceStatus.nonWorking
              : (statusByDay[DateUtils.dateOnly(dt)] ??
                  AttendanceStatus.noData);

      out.add(CalendarDay(date: dt, status: status));
    }

    return out;
  }

  List<WeeklyAttendanceRecord> _buildWeekData() {
    final statusByDay = _statusByDay();
    final weekStart = _focusedDate.subtract(
      Duration(days: _focusedDate.weekday - DateTime.monday),
    );

    final out = <WeeklyAttendanceRecord>[];
    for (var i = 0; i < 7; i++) {
      final dt = DateUtils.dateOnly(weekStart.add(Duration(days: i)));
      final weekday = dt.weekday;
      final isWeekend =
          weekday == DateTime.saturday || weekday == DateTime.sunday;

      final dayStatus =
          isWeekend
              ? AttendanceStatus.nonWorking
              : (statusByDay[dt] ?? AttendanceStatus.noData);

      final rowsForDay = _attendanceRows
          .where((row) {
            final d = _parseDate(row);
            if (d == null) return false;
            return DateUtils.isSameDay(d, dt);
          })
          .toList(growable: false);

      String timeRange = '--';
      if (rowsForDay.isNotEmpty) {
        final row = rowsForDay.first;
        final checkIn = readString(row, const [
              'check_in_time',
              'checkInTime',
              'time_in',
            ]) ??
            '';
        final checkOut = readString(row, const [
              'check_out_time',
              'checkOutTime',
              'time_out',
            ]) ??
            '';
        if (checkIn.isNotEmpty || checkOut.isNotEmpty) {
          timeRange =
              '${checkIn.isEmpty ? '--:--' : checkIn} - ${checkOut.isEmpty ? '--:--' : checkOut}';
        }
      }

      out.add(
        WeeklyAttendanceRecord(
          date: '${dt.day.toString().padLeft(2, '0')}/${dt.month}',
          status: dayStatus,
          timeRange: timeRange,
        ),
      );
    }

    return out;
  }

  void _changeDate({required bool navBack}) {
    setState(() {
      if (_isMonthView) {
        // Change month
        _focusedDate = DateTime(
          _focusedDate.year,
          navBack ? _focusedDate.month - 1 : _focusedDate.month + 1,
          1,
        );
      } else {
        // Change week
        _focusedDate = _focusedDate.add(Duration(days: navBack ? -7 : 7));
      }
      _rebuildViewData();
    });
  }

  Future<void> _handleDateSelection() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: _isMonthView
          ? DatePickerMode.year
          : DatePickerMode.day,
    );

    if (picked != null && picked != _focusedDate) {
      setState(() {
        _focusedDate = DateTime(picked.year, picked.month, picked.day);
        _rebuildViewData();
      });
    }
  }

  String _getDateRangeText() {
    if (_isMonthView) {
      // Format: "October 2025"
      final months = [
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
      return '${months[_focusedDate.month - 1]}    ${_focusedDate.year}';
    } else {
      // Format: "Week of Oct 1/6 - 7/6"
      // Calculate week start (Monday) and end (Sunday)
      // For simplicity just using focusedDate as mock "start of week" logic or just static string with date
      final start = _focusedDate.subtract(
        Duration(days: _focusedDate.weekday - 1),
      );
      final end = start.add(const Duration(days: 6));
      return 'Week of ${_getMonthShort(start.month)} ${start.day}/${start.month} - ${end.day}/${end.month}';
    }
  }

  String _getMonthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark 
            ? AppColors.primaryBlue.withValues(alpha: 0.2)
            : AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: isDark
            ? Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              )
            : null,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: appColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Attendance sheet',
          style: TextStyle(
            color: appColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Toggle Button
              AttendanceToggleButton(
                isMonthView: _isMonthView,
                onToggle: () {
                  setState(() {
                    _isMonthView = !_isMonthView;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Date Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                    ), // Smaller icon
                    onPressed: () => _changeDate(navBack: true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  Flexible(
                    child: GestureDetector(
                      onTap: _handleDateSelection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getDateRangeText(),
                          style: const TextStyle(
                            fontSize: 14, // Smaller font
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                    ), // Smaller icon
                    onPressed: () => _changeDate(navBack: false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
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
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadAttendance,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (_isMonthView ? _buildMonthView() : _buildWeekView()),
              ),

              // Back Button (Bottom)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
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
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays
              .map(
                (day) => Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        // Divider
        Divider(color: Colors.grey[200]),
        const SizedBox(height: 16),
        // Grid
        Expanded(
          child: GridView.builder(
            itemCount: _monthData.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final day = _monthData[index];
              if (day.date.year == 0) {
                return const SizedBox.shrink();
              }
              return CalendarDayCell(day: day);
            },
          ),
        ),
        const SizedBox(height: 10),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Frame",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    return ListView.builder(
      itemCount: _weekData.length,
      itemBuilder: (context, index) {
        return WeekRecordItem(record: _weekData[index]);
      },
    );
  }
}
