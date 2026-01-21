// Exam Score Summary Model
class ExamScoreSummary {
  final double score;
  final String? title;

  ExamScoreSummary({
    required this.score,
    this.title,
  });
}

// Exam Card Model
class ExamCard {
  final String? id;
  final String? category;
  final String? title;
  final double? progress;
  final String? iconCategory;

  ExamCard({
    this.id,
    this.category,
    this.title,
    this.progress,
    this.iconCategory,
  });
}

// Task Card Model
class TaskCard {
  final String? id;
  final String? title;
  final int? taskCount;
  final double? progress;
  final String? iconCategory;

  TaskCard({
    this.id,
    this.title,
    this.taskCount,
    this.progress,
    this.iconCategory,
  });
}