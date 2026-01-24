import '../dashboard/model/dashboard_models.dart';
import '../services/timetable_service.dart';
import '../services/token_storage.dart';
import '../utils/json_utils.dart';

class SubjectService {
  final TimetableService _timetableService;
  final TokenStorage _tokenStorage;

  SubjectService({TimetableService? timetableService, TokenStorage? tokenStorage})
    : _timetableService = timetableService ?? TimetableService(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<List<TaskCard>> listSubjects() async {
    final userId = await _tokenStorage.readUserId();
    if (userId == null || userId.isEmpty) return const [];
    final groupId = await _tokenStorage.readGroupId();

    final raw = groupId != null && groupId.isNotEmpty
        ? await _timetableService.listByGroup(groupId)
        : await _timetableService.listByUser(userId);

    return buildSubjectCards(raw);
  }

  static List<TaskCard> buildSubjectCards(List<Map<String, dynamic>> raw) {
    final titles = <String>{};

    for (final row in raw) {
      final subject = asMap(row['subject']);
      final title =
          readString(subject ?? row, const [
            'name',
            'title',
            'subject_name',
            'subjectName',
          ]) ??
          'Class';

      titles.add(title);
    }

    final subjects =
        titles
            .map(
              (title) => TaskCard(
                title: title,
                iconCategory: _subjectIconCategory(title),
              ),
            )
            .toList()
          ..sort(
            (a, b) => (a.title ?? '').toLowerCase().compareTo(
              (b.title ?? '').toLowerCase(),
            ),
          );

    return subjects;
  }

  static String _subjectIconCategory(String title) {
    final index = title.hashCode.abs() % 3;
    switch (index) {
      case 0:
        return 'office';
      case 1:
        return 'personal';
      default:
        return 'study';
    }
  }
}

