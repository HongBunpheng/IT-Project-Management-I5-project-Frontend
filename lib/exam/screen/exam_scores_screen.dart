import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/localization_helper.dart';
import '../model/exam_model.dart';
import '../service/exam_service.dart';
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
                  : Text(_errorMessage!),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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

                  /// ✅ ONLY SCORE SUMMARY (ATTENDANCE REMOVED)
                  _ActionTile(
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

                  const SizedBox(height: 24),

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
                              builder: (_) => ExamDetailScreen(
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
    );
  }
}

/* =========================
   UI COMPONENTS BELOW
========================= */

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(averageLabel, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
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
            label: 'Subjects: $subjectsCount',
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
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exam.subjectName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(onPressed: onPreview, child: const Text('Preview')),
        ],
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
