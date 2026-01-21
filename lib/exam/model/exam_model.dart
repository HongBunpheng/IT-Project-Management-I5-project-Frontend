class ExamResult {
  final String subjectName;
  final int score;
  final bool isCompleted;
  final String examId;
  final int? totalMark;
  final int? maxScore;
  final int? midtermScore;
  final int? finalScore;
  final String? examDate;
  final List<String>? lecturers;

  ExamResult({
    required this.subjectName,
    required this.score,
    required this.isCompleted,
    required this.examId,
    this.totalMark,
    this.maxScore,
    this.midtermScore,
    this.finalScore,
    this.examDate,
    this.lecturers,
  });

  String get statusText => isCompleted ? 'Completed $score%' : 'Not Completed';

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      subjectName: json['subjectName'] as String,
      score: json['score'] as int,
      isCompleted: json['isCompleted'] as bool,
      examId: json['examId'] as String,
      totalMark: json['totalMark'] as int?,
      maxScore: json['maxScore'] as int?,
      midtermScore: json['midtermScore'] as int?,
      finalScore: json['finalScore'] as int?,
      examDate: json['examDate'] as String?,
      lecturers: json['lecturers'] != null
          ? List<String>.from(json['lecturers'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectName': subjectName,
      'score': score,
      'isCompleted': isCompleted,
      'examId': examId,
      'totalMark': totalMark,
      'maxScore': maxScore,
      'midtermScore': midtermScore,
      'finalScore': finalScore,
      'examDate': examDate,
      'lecturers': lecturers,
    };
  }
}

class ExamSummary {
  final double averageScore;
  final List<ExamResult> examResults;

  ExamSummary({
    required this.averageScore,
    required this.examResults,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> json) {
    return ExamSummary(
      averageScore: (json['averageScore'] as num).toDouble(),
      examResults: (json['examResults'] as List)
          .map((e) => ExamResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageScore': averageScore,
      'examResults': examResults.map((e) => e.toJson()).toList(),
    };
  }
}

class SubjectScore {
  final String subjectName;
  final int score;
  final int colorValue; // Store as int to avoid Flutter dependency in model
  final double percentage; // Percentage of total

  SubjectScore({
    required this.subjectName,
    required this.score,
    required this.colorValue,
    required this.percentage,
  });
}
