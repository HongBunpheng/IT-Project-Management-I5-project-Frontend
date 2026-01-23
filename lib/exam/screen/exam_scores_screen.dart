import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/localization_helper.dart';
import '../../utils/pull_to_refresh.dart';
import '../model/exam_model.dart';
import '../service/exam_service.dart';
import '../../attendance/screen/attendance_screen.dart';
import 'scores_summary_screen.dart';
import 'exam_detail_screen.dart';

class ExamScoresScreen extends StatefulWidget {
  const ExamScoresScreen({super.key});

  @override
  State<ExamScoresScreen> createState() => _ExamScoresScreenState();
}

class _ExamScoresScreenState extends State<ExamScoresScreen> {
  final ExamService _examService = ExamService();
  ExamSummary? _examSummary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  Future<void> _loadExamData() async {
    try {
      final summary = await _examService.getExamResults();
      if (!mounted) return;
      setState(() {
        _examSummary = summary;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _examSummary = null;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      body: _examSummary == null
            ? Center(
                child: _errorMessage == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadExamData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
              )
            : AppPullToRefresh(
                onRefresh: _loadExamData,
                alwaysScrollable: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OverviewCard(
                        title: safeLocaleString(
                          context,
                          'exam_scores',
                          fallback: 'Exam Scores',
                        ),
                        averageLabel: safeLocaleString(
                          context,
                          'average_score',
                          fallback: 'Average Score',
                        ),
                        averageScore: _examSummary!.averageScore,
                        subjectsCount: _examSummary!.examResults.length,
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        icon: Icons.grid_view,
                        title: safeLocaleString(
                          context,
                          'quick_actions',
                          fallback: 'Quick actions',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              title: safeLocaleString(
                                context,
                                'attendance',
                                fallback: 'Attendance',
                              ),
                              subtitle: safeLocaleString(
                                context,
                                'view_complete_history',
                                fallback: 'View complete history',
                              ),
                              icon: Icons.fact_check_outlined,
                              color: appColors.primaryBlue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AttendanceScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionTile(
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
                                    builder: (_) =>
                                        const ScoresSummaryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.workspace_premium,
                        title: safeLocaleString(
                          context,
                          'exam_results',
                          fallback: 'Exam Results',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _examSummary!.examResults.length,
                        itemBuilder: (context, index) {
                          final exam = _examSummary!.examResults[index];
                          return _ExamResultCard(
                            exam: exam,
                            onPreview: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExamDetailScreen(
                                    examId: exam.examId,
                                    subjectName: exam.subjectName,
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
    );
  }
}

class _ExamResultCard extends StatelessWidget {
  final ExamResult exam;
  final VoidCallback onPreview;

  const _ExamResultCard({required this.exam, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = exam.examDate?.trim();
    final total = exam.totalMark;
    final max = exam.maxScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.borderLight, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon - circular container
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), // Light green background
              shape: BoxShape.circle, // Circular shape
            ),
            child: const Center(
              child: Icon(
                Icons.school,
                color: Color(0xFF4CAF50), // Green icon
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Exam Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.subjectName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Pill(
                      label: '${exam.score}%',
                      background: appColors.primaryBlue.withValues(alpha: 0.12),
                      foreground: appColors.primaryBlue,
                    ),
                    if (total != null)
                      _Pill(
                        label:
                            '${safeLocaleString(context, 'total_mark', fallback: 'Total')}: $total',
                        background: appColors.lightGrey.withValues(alpha: 0.6),
                        foreground: appColors.textPrimary,
                      ),
                    if (max != null && max != total)
                      _Pill(
                        label:
                            '${safeLocaleString(context, 'max_score', fallback: 'Max')}: $max',
                        background: appColors.lightGrey.withValues(alpha: 0.6),
                        foreground: appColors.textPrimary,
                      ),
                    if (date != null && date.isNotEmpty)
                      _Pill(
                        label:
                            '${safeLocaleString(context, 'date', fallback: 'Date')}: $date',
                        background: appColors.lightGrey.withValues(alpha: 0.6),
                        foreground: appColors.textPrimary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  exam.isCompleted
                      ? safeLocaleString(
                          context,
                          'completed',
                          fallback: 'Completed',
                        )
                      : safeLocaleString(
                          context,
                          'not_completed',
                          fallback: 'Not completed',
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    color: exam.isCompleted
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Preview Button
          ElevatedButton(
            onPressed: onPreview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3), // Blue button
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              minimumSize: const Size(70, 32),
            ),
            child: Text(
              safeLocaleString(context, 'preview', fallback: 'Preview'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String averageLabel;
  final double averageScore;
  final int subjectsCount;

  const _OverviewCard({
    required this.title,
    required this.averageLabel,
    required this.averageScore,
    required this.subjectsCount,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  averageLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${averageScore.toInt()}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          _Pill(
            label:
                '${safeLocaleString(context, 'subjects', fallback: 'Subjects')}: $subjectsCount',
            background: AppColors.primaryBlue.withValues(alpha: 0.12),
            foreground: AppColors.primaryBlue,
          ),
        ],
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
        Icon(icon, color: appColors.primaryBlueLight, size: 20),
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

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: appColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
