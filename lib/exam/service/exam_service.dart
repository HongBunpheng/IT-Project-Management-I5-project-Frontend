import 'dart:convert';

import '../model/exam_model.dart';
import '../../utils/json_utils.dart';
import '../../services/api_client.dart';
import '../../services/score_service.dart';
import '../../services/token_storage.dart';

class ExamService {
  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final ScoreService _scores;

  ExamService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    ScoreService? scoreService,
  }) : _api = apiClient ?? ApiClient(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _scores = scoreService ?? ScoreService();

  Future<ExamSummary> getExamResults() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Missing user id. Please login again.');
    }

    final scores = await _scores.byStudent(userId);

    final results = scores.map(_mapScoreToExamResult).toList();
    final average = results.isEmpty
        ? 0.0
        : results.map((e) => e.score).reduce((a, b) => a + b) / results.length;

    return ExamSummary(averageScore: average, examResults: results);
  }

  Future<ExamResult> getExamDetail(String examId) async {
    final res = await _api.getJson('/exams/$examId');
    final decoded = _safeDecode(res.body);

    final data = decoded is Map<String, dynamic>
        ? (asMap(decoded['data']) ?? asMap(decoded['exam']) ?? decoded)
        : null;

    if (data == null) {
      throw Exception('Invalid response');
    }

    return _mapExamToExamResult(data, fallbackId: examId);
  }

  Future<List<Map<String, dynamic>>> listByGroup(String groupId) async {
    final res = await _api.getJson('/exams/group/$groupId');
    final decoded = _safeDecode(res.body);

    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['exams']) ??
              asList(decoded))
        : asList(decoded);

    return (data ?? const [])
        .map((e) => asMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> listMyGroupExams() async {
    final groupId = await _tokenStorage.readGroupId();
    if (groupId == null || groupId.isEmpty) {
      throw Exception('Missing group id. Please login again.');
    }
    return listByGroup(groupId);
  }

  Future<List<SubjectScore>> getScoresSummary() async {
    final summary = await getExamResults();
    final exams = summary.examResults;
    final total = exams.fold<int>(0, (acc, e) => acc + e.score);

    final subjectScores = <SubjectScore>[];
    for (final exam in exams) {
      final percentage = total == 0 ? 0.0 : (exam.score / total) * 100;
      subjectScores.add(
        SubjectScore(
          subjectName: exam.subjectName,
          score: exam.score,
          colorValue: _colorForSubject(exam.subjectName),
          percentage: percentage,
        ),
      );
    }

    return subjectScores;
  }

  ExamResult _mapScoreToExamResult(Map<String, dynamic> score) {
    final exam = asMap(score['exam']);
    final subject = asMap(exam?['subject']) ?? asMap(score['subject']);

    final subjectName =
        readString(subject ?? score, const [
          'name',
          'subject_name',
          'subjectName',
          'title',
        ]) ??
        'Unknown';

    final examId =
        readString(exam ?? score, const ['id', 'exam_id', 'examId']) ?? '';

    final percentage =
        readDouble(score, const [
          'percentage',
          'percentages',
          'score',
          'mark',
        ]) ??
        0.0;

    final maxScore = readInt(score, const [
      'max_score',
      'maxScore',
      'total_mark',
      'totalMark',
    ]);

    final totalMark = readInt(score, const [
      'total_mark',
      'totalMark',
      'max_score',
      'maxScore',
    ]);

    final examDate = readString(exam ?? score, const [
      'exam_date',
      'date',
      'examDate',
    ]);

    return ExamResult(
      subjectName: subjectName,
      score: percentage.round(),
      isCompleted: true,
      examId: examId,
      totalMark: totalMark,
      maxScore: maxScore,
      examDate: examDate,
      lecturers: _extractLecturers(exam),
    );
  }

  ExamResult _mapExamToExamResult(
    Map<String, dynamic> exam, {
    String? fallbackId,
  }) {
    final subject = asMap(exam['subject']);
    final subjectName =
        readString(subject ?? exam, const [
          'name',
          'subject_name',
          'subjectName',
          'title',
        ]) ??
        'Unknown';

    final examId =
        readString(exam, const ['id', 'exam_id', 'examId']) ??
        (fallbackId ?? '');

    final totalMark = readInt(exam, const ['total_mark', 'totalMark']);
    final duration = readString(exam, const ['duration']);

    final scoreValue = readDouble(exam, const [
      'percentage',
      'percentages',
      'score',
    ]);

    return ExamResult(
      subjectName: subjectName,
      score: (scoreValue ?? 0.0).round(),
      isCompleted: true,
      examId: examId,
      totalMark: totalMark,
      maxScore: totalMark,
      midtermScore: null,
      finalScore: null,
      examDate:
          readString(exam, const ['exam_date', 'date', 'examDate']) ?? duration,
      lecturers: _extractLecturers(exam),
    );
  }

  List<String>? _extractLecturers(Map<String, dynamic>? exam) {
    if (exam == null) return null;
    final lecturersValue =
        exam['lecturers'] ?? exam['teachers'] ?? exam['users'];
    final list = asList(lecturersValue);
    if (list == null) return null;

    final names = <String>[];
    for (final item in list) {
      final map = asMap(item);
      final name = map == null
          ? item?.toString()
          : (readString(map, const ['name', 'full_name', 'email']) ??
                map.toString());
      if (name != null && name.isNotEmpty) names.add(name);
    }
    return names.isEmpty ? null : names;
  }

  int _colorForSubject(String subjectName) {
    final hash = subjectName.hashCode & 0xFFFFFF;
    return 0xFF000000 | hash;
  }

  dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
