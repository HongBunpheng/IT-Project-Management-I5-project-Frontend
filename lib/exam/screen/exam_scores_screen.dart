import 'package:flutter/material.dart';

import '../../configs/app_colors.dart';
import '../../configs/app_theme_extension.dart';
import '../../dashboard/model/dashboard_models.dart';
import '../../dashboard/widget/exam_score_summary_card.dart';
import '../../utils/json_utils.dart';
import '../../utils/localization_helper.dart';
import '../../utils/pull_to_refresh.dart';
import '../model/exam_model.dart';
import '../service/exam_service.dart';
import 'exam_detail_screen.dart';
import 'scores_summary_screen.dart';

enum _ExamFilter { all, graded, pending }

enum _ExamItemSource { groupExam, myScore }

class ExamScoresScreen extends StatefulWidget {
  const ExamScoresScreen({super.key});

  @override
  State<ExamScoresScreen> createState() => _ExamScoresScreenState();
}

class _ExamScoresScreenState extends State<ExamScoresScreen> {
  final ExamService _examService = ExamService();

  ExamSummary? _summary;
  List<_ExamListItem> _items = const [];
  _ExamFilter _filter = _ExamFilter.all;

  bool _isLoading = true;
  String? _errorMessage;

  final GlobalKey _examListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  Future<void> _loadExamData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryFuture = _examService.getExamResults();
      final groupExamsFuture = _examService.listMyGroupExams();

      final summary = await summaryFuture;
      final groupExams = await groupExamsFuture;

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _items = _mergeExamsAndScores(
          groupExams: groupExams,
          scoreSummary: summary,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _items = const [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<_ExamListItem> _mergeExamsAndScores({
    required List<Map<String, dynamic>> groupExams,
    required ExamSummary scoreSummary,
  }) {
    final scoreByExamId = <String, ExamResult>{};
    for (final result in scoreSummary.examResults) {
      final id = result.examId.trim();
      if (id.isEmpty) continue;
      scoreByExamId[id] = result;
    }

    final groupExamIds = <String>{};
    final merged = <_ExamListItem>[];

    for (final exam in groupExams) {
      final examId =
          readString(exam, const ['id', 'exam_id', 'examId'])?.trim() ?? '';
      if (examId.isNotEmpty) groupExamIds.add(examId);

      final subject = asMap(exam['subject']);
      final subjectName =
          readString(subject ?? exam, const [
            'name',
            'subject_name',
            'subjectName',
            'title',
          ]) ??
          'Exam';

      final dateRaw = readString(exam, const [
        'exam_date',
        'date',
        'examDate',
        'start_date',
        'startDate',
        'created_at',
      ]);

      final totalMark = readInt(exam, const [
        'total_mark',
        'totalMark',
        'max_score',
        'maxScore',
      ]);

      final score = examId.isEmpty ? null : scoreByExamId[examId]?.score;
      final scoreDate = examId.isEmpty ? null : scoreByExamId[examId]?.examDate;

      final parsedDate = _parseDate(dateRaw) ?? _parseDate(scoreDate);
      final dateLabel = parsedDate != null
          ? _formatDate(parsedDate)
          : (dateRaw ?? scoreDate);

      merged.add(
        _ExamListItem(
          examId: examId,
          subjectName: subjectName,
          date: parsedDate,
          dateLabel: dateLabel,
          score: score,
          totalMark: totalMark,
          source: _ExamItemSource.groupExam,
        ),
      );
    }

    // Add scores that didn't appear in the group exams list (API data mismatch).
    for (final result in scoreSummary.examResults) {
      final examId = result.examId.trim();
      if (examId.isEmpty) continue;
      if (groupExamIds.contains(examId)) continue;

      merged.add(
        _ExamListItem(
          examId: examId,
          subjectName: result.subjectName,
          date: _parseDate(result.examDate),
          dateLabel: result.examDate,
          score: result.score,
          totalMark: result.totalMark ?? result.maxScore,
          source: _ExamItemSource.myScore,
        ),
      );
    }

    merged.sort((a, b) {
      final ad = a.date;
      final bd = b.date;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return merged;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    try {
      return DateTime.parse(value);
    } catch (_) {
      if (value.length >= 10) {
        try {
          return DateTime.parse(value.substring(0, 10));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _scrollToExamList() {
    final ctx = _examListKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = _filter == _ExamFilter.all
        ? _items
        : _items
              .where(
                (e) => _filter == _ExamFilter.graded ? e.isGraded : !e.isGraded,
              )
              .toList(growable: false);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F8FA),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _summary == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage ??
                            safeLocaleString(
                              context,
                              'failed_to_load_exam_data',
                              fallback: 'Failed to load exam data.',
                            ),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: appColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadExamData,
                        child: Text(
                          safeLocaleString(context, 'retry', fallback: 'Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : AppPullToRefresh(
                onRefresh: _loadExamData,
                alwaysScrollable: true,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExamScoreSummaryCard(
                        scoreSummary: ExamScoreSummary(
                          score: _summary!.averageScore,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _StatsRow(items: _items),
                      const SizedBox(height: 28),
                      Text(
                        safeLocaleString(
                          context,
                          'quick_actions',
                          fallback: 'Quick Actions',
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _ActionCard(
                            title: safeLocaleString(
                              context,
                              'score_summary',
                              fallback: 'Score Summary',
                            ),
                            subtitle: safeLocaleString(
                              context,
                              'detailed_analytics',
                              fallback: 'Detailed analytics',
                            ),
                            icon: Icons.pie_chart_outline,
                            color: appColors.success,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScoresSummaryScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionCard(
                            title: safeLocaleString(
                              context,
                              'browse_exams',
                              fallback: 'Browse Exams',
                            ),
                            subtitle: safeLocaleString(
                              context,
                              'group_exams',
                              fallback: 'From your group',
                            ),
                            icon: Icons.list_alt_rounded,
                            color: appColors.primaryBlue,
                            onTap: _scrollToExamList,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _SectionHeader(
                              icon: Icons.workspace_premium,
                              title: safeLocaleString(
                                context,
                                'exam_results',
                                fallback: 'Exam Results',
                              ),
                            ),
                          ),
                          _FilterChipRow(
                            value: _filter,
                            onChanged: (v) => setState(() => _filter = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(key: _examListKey),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            safeLocaleString(
                              context,
                              'no_exam_data',
                              fallback: 'No exams found.',
                            ),
                            style: TextStyle(color: appColors.textSecondary),
                          ),
                        )
                      else
                        ListView.builder(
                          itemCount: items.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _ExamListCard(
                              item: item,
                              onPreview: item.examId.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ExamDetailScreen(
                                            examId: item.examId,
                                            subjectName: item.subjectName,
                                          ),
                                        ),
                                      );
                                    },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ExamListItem {
  final String examId;
  final String subjectName;
  final DateTime? date;
  final String? dateLabel;
  final int? score;
  final int? totalMark;
  final _ExamItemSource source;

  const _ExamListItem({
    required this.examId,
    required this.subjectName,
    required this.date,
    required this.dateLabel,
    required this.score,
    required this.totalMark,
    required this.source,
  });

  bool get isGraded => score != null;
}

class _StatsRow extends StatelessWidget {
  final List<_ExamListItem> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final graded = items.where((e) => e.isGraded).toList(growable: false);
    final passed = graded.where((e) => (e.score ?? 0) >= 50).length;
    final pending = items.length - graded.length;

    return Row(
      children: [
        _StatCard(label: 'Exams', value: items.length.toString()),
        const SizedBox(width: 12),
        _StatCard(label: 'Pending', value: pending.toString()),
        const SizedBox(width: 12),
        _StatCard(label: 'Passed', value: passed.toString()),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : appColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: appColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : appColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: appColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ExamListCard extends StatelessWidget {
  final _ExamListItem item;
  final VoidCallback? onPreview;

  const _ExamListCard({required this.item, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isPass = (item.score ?? 0) >= 50;
    final isGraded = item.isGraded;
    final statusColor = !isGraded
        ? appColors.textSecondary
        : (isPass ? appColors.success : appColors.error);

    final statusLabel = !isGraded ? 'Pending' : '${item.score}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : appColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.source == _ExamItemSource.myScore)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: appColors.primaryBlue.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: appColors.primaryBlue.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Text(
                            'Score',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: appColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.dateLabel != null || item.totalMark != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.dateLabel != null) ...[
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: appColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.dateLabel!,
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                          ),
                        ),
                      ],
                      if (item.dateLabel != null && item.totalMark != null)
                        const SizedBox(width: 14),
                      if (item.totalMark != null) ...[
                        Icon(
                          Icons.stacked_bar_chart_rounded,
                          size: 14,
                          color: appColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total: ${item.totalMark}',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onPreview,
          ),
        ],
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  final _ExamFilter value;
  final ValueChanged<_ExamFilter> onChanged;

  const _FilterChipRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Row(
      children: [
        _chip(
          context: context,
          label: 'All',
          selected: value == _ExamFilter.all,
          onTap: () => onChanged(_ExamFilter.all),
          color: appColors.primaryBlue,
        ),
        const SizedBox(width: 8),
        _chip(
          context: context,
          label: 'Graded',
          selected: value == _ExamFilter.graded,
          onTap: () => onChanged(_ExamFilter.graded),
          color: appColors.success,
        ),
        const SizedBox(width: 8),
        _chip(
          context: context,
          label: 'Pending',
          selected: value == _ExamFilter.pending,
          onTap: () => onChanged(_ExamFilter.pending),
          color: appColors.textSecondary,
        ),
      ],
    );
  }

  Widget _chip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.24 : 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.45 : 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
