import 'package:flutter/material.dart';
import '../model/attendance_model.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
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
  bool _isMonthView = true;
  DateTime _focusedDate = DateTime(2025, 10, 1); // Mock start date as Oct 2025

  // Mock Data for Month View
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<CalendarDay> _monthData = [];

  // Mock Data for Week View
  final List<WeeklyAttendanceRecord> _weekData = [
    WeeklyAttendanceRecord(
      date: "01/6",
      status: AttendanceStatus.present,
      timeRange: "8:00 - 17:00",
    ),
    WeeklyAttendanceRecord(
      date: "02/6",
      status: AttendanceStatus.present,
      timeRange: "8:00 - 17:00",
      additionalInfo: "HC",
    ),
    WeeklyAttendanceRecord(
      date: "03/6",
      status: AttendanceStatus.present,
      timeRange: "8:00 - 17:00",
      additionalInfo: "HC",
    ),
    WeeklyAttendanceRecord(
      date: "04/6",
      status: AttendanceStatus.absent,
      timeRange: "8:00 - 17:00",
      additionalInfo: "HC",
    ),
    WeeklyAttendanceRecord(
      date: "05/6",
      status: AttendanceStatus.absent,
      timeRange: "8:00 - 17:00",
      additionalInfo: "HC",
    ),
    WeeklyAttendanceRecord(
      date: "06/6",
      status: AttendanceStatus.absent,
      timeRange: "8:00 - 17:00",
      additionalInfo: "HC",
    ),
    WeeklyAttendanceRecord(
      date: "07/6",
      status: AttendanceStatus.nonWorking,
      timeRange: "8:00 - 17:00",
      additionalInfo: "HC",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _generateMockMonthData();
  }

  void _generateMockMonthData() {
    // Generate some mock data similar to the screenshot
    // Starting with empty cells for offset
    for (int i = 0; i < 2; i++) {
      // Placeholder for offset
      _monthData.add(
        CalendarDay(
          date: DateTime(2025, 10, 0),
          status: AttendanceStatus.noData,
        ),
      );
    }

    // Days 1-31
    for (int i = 1; i <= 31; i++) {
      AttendanceStatus status = AttendanceStatus.present;
      if (i % 7 == 0 || i % 7 == 6) {
        status = AttendanceStatus.nonWorking; // Weekend
      }
      if (i == 16 || i == 17 || i == 18 || i == 24) {
        status = AttendanceStatus.absent;
      }

      _monthData.add(CalendarDay(date: DateTime(2025, 10, i), status: status));
    }
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
        _focusedDate = picked;
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
                child: _isMonthView ? _buildMonthView() : _buildWeekView(),
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
              if (day.status == AttendanceStatus.noData) {
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
