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
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F8FA),
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
                  _HeroScoreCard(summary: _examSummary!),
                  const SizedBox(height: 20),

                  _StatsRow(summary: _examSummary!),
                  const SizedBox(height: 28),

                  Text(
                    safeLocaleString(
                      context,
                      'quick_actions',
                      fallback: 'Quick Actions',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                    ],
                  ),

                  const SizedBox(height: 28),

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
   UI COMPONENTS
========================= */

class _HeroScoreCard extends StatelessWidget {
  final ExamSummary summary;
  const _HeroScoreCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final passed = summary.examResults.where((e) => e.score >= 50).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          _ScoreCircle(score: summary.averageScore.toInt()),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeLocaleString(
                    context,
                    'exam_scores',
                    fallback: 'Exam Scores',
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Keep pushing ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Passed $passed / ${summary.examResults.length} subjects',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int score;
  const _ScoreCircle({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          '$score%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ExamSummary summary;
  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final passed = summary.examResults.where((e) => e.score >= 50).length;
    final failed = summary.examResults.length - passed;

    return Row(
      children: [
        _StatCard(
          label: 'Subjects',
          value: summary.examResults.length.toString(),
        ),
        const SizedBox(width: 12),
        _StatCard(label: 'Passed', value: passed.toString()),
        const SizedBox(width: 12),
        _StatCard(label: 'Failed', value: failed.toString()),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 11)),
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

class _ExamResultCard extends StatelessWidget {
  final ExamResult exam;
  final VoidCallback onPreview;

  const _ExamResultCard({required this.exam, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final isPass = exam.score >= 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exam.subjectName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPass ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${exam.score}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPass ? Colors.green : Colors.red,
              ),
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
