class TimetableTaskModel {
  final String? id;
  final String title;
  final String details;
  final String time;
  final bool isCompleted;
  final String? iconType; // 'info' or 'check'
  final String? building;
  final String? room;
  final String? instructor;
  final String? dayOfWeek;

  TimetableTaskModel({
    this.id,
    required this.title,
    required this.details,
    required this.time,
    this.isCompleted = false,
    this.iconType = 'info',
    this.building,
    this.room,
    this.instructor,
    this.dayOfWeek,
  });
}

class IntakeModel {
  final int completed;
  final int total;
  final String dayName;

  IntakeModel({
    required this.completed,
    required this.total,
    required this.dayName,
  });
}

class DayModel {
  final int day;
  final String dayAbbreviation;
  bool isSelected;
  bool isToday;

  DayModel({
    required this.day,
    required this.dayAbbreviation,
    this.isSelected = false,
    this.isToday = false,
  });
}
