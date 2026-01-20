import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import 'attendance_calendar_screen.dart';

class AttendanceWeeklyScreen extends StatefulWidget {
  final DateTime startDate;

  const AttendanceWeeklyScreen({
    super.key,
    required this.startDate,
  });

  @override
  State<AttendanceWeeklyScreen> createState() => _AttendanceWeeklyScreenState();
}

class _AttendanceWeeklyScreenState extends State<AttendanceWeeklyScreen> {
  DateTime _currentWeekStart = DateTime(2025, 10, 1); // Week of Oct 1-7
  bool _isWeekView = true; // true for Week, false for Month

  // Sample weekly attendance data
  final List<WeeklyAttendanceRecord> _weeklyRecords = [
    WeeklyAttendanceRecord(
      date: '01/6',
      status: AttendanceStatus.nonWorking,
      timeRange: '8:00 - 17:00',
      additionalInfo: 'HC',
    ),
    WeeklyAttendanceRecord(
      date: '02/6',
      status: AttendanceStatus.present,
      timeRange: '8:00 - 17:00',
      additionalInfo: 'HC',
    ),
    WeeklyAttendanceRecord(
      date: '03/6',
      status: AttendanceStatus.present,
      timeRange: '8:00 - 17:00',
      additionalInfo: 'HC',
    ),
    WeeklyAttendanceRecord(
      date: '04/6',
      status: AttendanceStatus.absent,
      timeRange: '8:00 - 17:00',
      additionalInfo: 'HC',
    ),
    WeeklyAttendanceRecord(
      date: '05/6',
      status: AttendanceStatus.absent,
      timeRange: '8:00 - 17:00',
      additionalInfo: 'HC',
    ),
    WeeklyAttendanceRecord(
      date: '06/6',
      status: AttendanceStatus.absent,
      timeRange: '8:00 - 17:00',
      additionalInfo: 'HC',
    ),
    WeeklyAttendanceRecord(
      date: '07/6',
      status: AttendanceStatus.nonWorking,
      timeRange: '8:00 - 17:00',
      additionalInfo: 'HC',
    ),
  ];

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return '1';
      case AttendanceStatus.absent:
        return 'x';
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

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  String _getWeekRange() {
    final endDate = _currentWeekStart.add(const Duration(days: 6));
    final startMonth = _currentWeekStart.month;
    final startDay = _currentWeekStart.day;
    final endMonth = endDate.month;
    final endDay = endDate.day;
    return 'Week of October $startDay/$startMonth - $endDay/$endMonth';
  }

  @override
  void initState() {
    super.initState();
    if (widget.startDate != null) {
      _currentWeekStart = widget.startDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AttendanceCalendarScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isWeekView
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
                            color: !_isWeekView ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isWeekView = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isWeekView
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
                            color: _isWeekView ? Colors.white : Colors.black87,
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
            // Week navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousWeek,
                  ),
                  Expanded(
                    child: Text(
                      _getWeekRange(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextWeek,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Attendance list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _weeklyRecords.length,
                itemBuilder: (context, index) {
                  final record = _weeklyRecords[index];
                  final statusText = _getStatusText(record.status);
                  final statusColor = _getStatusColor(record.status);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        // Date
                        Text(
                          record.date,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Vertical line
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 16),
                        // Status indicator
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Time range and info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.timeRange,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              if (record.additionalInfo != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  record.additionalInfo!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
}
