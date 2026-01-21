class AttendanceRecord {
  final String date;
  final String checkInTime;
  final String checkOutTime;
  final String checkInStatus; // "on time", "late X min"
  final String checkOutStatus; // "on time", "early X min"

  AttendanceRecord({
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.checkInStatus,
    required this.checkOutStatus,
  });
}

class DayInfo {
  final int day;
  final String dayName;
  final bool isSelected;

  DayInfo({required this.day, required this.dayName, this.isSelected = false});
}

enum AttendanceStatus {
  present, // "1" - green
  absent, // "X" - orange/red
  nonWorking, // "N" - green (Sunday/holiday)
  noData, // "0" - grey
}

class CalendarDay {
  final DateTime date;
  final AttendanceStatus status;

  CalendarDay({required this.date, required this.status});
}

class WeeklyAttendanceRecord {
  final String date; // "01/6" format
  final AttendanceStatus status;
  final String timeRange; // "8:00 - 17:00"
  final String? additionalInfo; // "HC" or other info

  WeeklyAttendanceRecord({
    required this.date,
    required this.status,
    required this.timeRange,
    this.additionalInfo,
  });
}
