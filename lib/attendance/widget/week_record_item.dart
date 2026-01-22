import 'package:flutter/material.dart';
import '../model/attendance_model.dart';

class WeekRecordItem extends StatelessWidget {
  final WeeklyAttendanceRecord record;

  const WeekRecordItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Column
          SizedBox(
            width: 50,
            child: Text(
              record.date,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Vertical Divider Line
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Status
          SizedBox(
            width: 30,
            child: Text(
              _getStatusText(record.status),
              style: TextStyle(
                color: _getStatusColor(record.status),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),
          // Time and Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.timeRange,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              if (record.additionalInfo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    record.additionalInfo!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return "1";
      case AttendanceStatus.absent:
        return "x";
      case AttendanceStatus.nonWorking:
        return "N"; // Ensure 'N' is handled if it appears in week view
      case AttendanceStatus.noData:
        return "";
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
        return Colors.transparent;
    }
  }
}
