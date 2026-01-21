import '../models/exam_model.dart';

/// Service class for handling exam score API calls
/// This is structured to work with backend API when available
class ExamService {
  // TODO: Replace with actual API base URL when backend is ready
  static const String baseUrl = 'https://api.example.com'; // Placeholder

  /// Fetch all exam results
  /// When API is ready, replace with actual HTTP call
  Future<ExamSummary> getExamResults() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    // Example:
    // final response = await http.get(Uri.parse('$baseUrl/api/exams'));
    // if (response.statusCode == 200) {
    //   return ExamSummary.fromJson(json.decode(response.body));
    // } else {
    //   throw Exception('Failed to load exam results');
    // }

    // Mock data for now
    return ExamSummary(
      averageScore: 85.0,
      examResults: [
        ExamResult(
          subjectName: 'Network Security',
          score: 70,
          isCompleted: true,
          examId: '1',
          totalMark: 100,
          maxScore: 100,
          midtermScore: 100,
          finalScore: 100,
          examDate: '02/11/2025',
          lecturers: ['Kim Jongun', 'Christopher', 'Olivia (TP)'],
        ),
        ExamResult(
          subjectName: 'Data Mining',
          score: 60,
          isCompleted: true,
          examId: '2',
          totalMark: 100,
          maxScore: 100,
          midtermScore: 60,
          finalScore: 60,
          examDate: '15/10/2025',
          lecturers: ['Dr. Smith'],
        ),
        ExamResult(
          subjectName: 'Natural Language Processing',
          score: 45,
          isCompleted: true,
          examId: '3',
          totalMark: 100,
          maxScore: 100,
          midtermScore: 40,
          finalScore: 50,
          examDate: '20/10/2025',
          lecturers: ['Prof. Johnson'],
        ),
        ExamResult(
          subjectName: 'Information Security',
          score: 80,
          isCompleted: true,
          examId: '4',
          totalMark: 100,
          maxScore: 100,
          midtermScore: 85,
          finalScore: 75,
          examDate: '10/11/2025',
          lecturers: ['Dr. Williams'],
        ),
      ],
    );
  }

  /// Fetch detailed exam result for a specific subject
  /// When API is ready, replace with actual HTTP call
  Future<ExamResult> getExamDetail(String examId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    // Example:
    // final response = await http.get(Uri.parse('$baseUrl/api/exams/$examId'));
    // if (response.statusCode == 200) {
    //   return ExamResult.fromJson(json.decode(response.body));
    // } else {
    //   throw Exception('Failed to load exam detail');
    // }

    // Mock data for now - return based on examId with detailed info
    final allExams = await getExamResults();
    final exam = allExams.examResults.firstWhere(
      (exam) => exam.examId == examId,
      orElse: () => ExamResult(
        subjectName: 'Unknown',
        score: 0,
        isCompleted: false,
        examId: examId,
      ),
    );
    
    // Return with all details
    return exam;
  }

  /// Get scores summary with color mapping
  Future<List<SubjectScore>> getScoresSummary() async {
    final examSummary = await getExamResults();
    
    // Color mapping for subjects (matching the design)
    final colorMap = {
      'Network Security': 0xFF00BCD4, // Teal/Cyan
      'Data Mining': 0xFF9C27B0, // Purple
      'Natural Language Processing': 0xFF2196F3, // Blue
      'Information Security': 0xFFFF5252, // Red
      'French': 0xFFFF9800, // Orange
    };

    // Based on design, use the scores shown in the summary table
    // These appear to be weighted or normalized scores, not raw percentages
    final summaryData = [
      {'name': 'Network Security', 'score': 28, 'percentage': 62.5},
      {'name': 'Natural Language Processing', 'score': 12, 'percentage': 25.0},
      {'name': 'Data Mining', 'score': 6, 'percentage': 12.5},
      {'name': 'Information Security', 'score': 6, 'percentage': 12.5},
      {'name': 'French', 'score': 6, 'percentage': 12.5},
      {'name': 'French', 'score': 6, 'percentage': 12.5},
    ];

    // Create list matching the design
    final allSubjects = <SubjectScore>[];
    
    for (final data in summaryData) {
      final subjectName = data['name'] as String;
      final score = data['score'] as int;
      final percentage = data['percentage'] as double;
      
      // Get color from map, or use default
      int colorValue = colorMap[subjectName] ?? 0xFF9E9E9E;
      
      // Special handling for duplicate French entries
      if (subjectName == 'French' && allSubjects.any((s) => s.subjectName == 'French')) {
        colorValue = 0xFFFFEB3B; // Yellow for second French entry
      }
      
      allSubjects.add(SubjectScore(
        subjectName: subjectName,
        score: score,
        colorValue: colorValue,
        percentage: percentage,
      ));
    }

    return allSubjects;
  }
}
