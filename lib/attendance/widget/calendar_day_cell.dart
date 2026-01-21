import 'package:flutter/material.dart';
import '../model/attendance_model.dart';

class CalendarDayCell extends StatelessWidget {
  final CalendarDay day;

  const CalendarDayCell({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day.date.day.toString(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStatusText(day.status),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(day.status),
          ),
        ),
      ],
    );
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return "1";
      case AttendanceStatus.absent:
        return "X"; // Orange 'x' from image
      case AttendanceStatus.nonWorking:
        return "N";
      case AttendanceStatus.noData:
        return "0";
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF4CAF50); // Green
      case AttendanceStatus.absent:
        return const Color(0xFFFF9800); // Orange
      case AttendanceStatus.nonWorking:
        return const Color(0xFF4CAF50); // Green
      case AttendanceStatus.noData:
        return Colors.grey;
    }
  }
}
