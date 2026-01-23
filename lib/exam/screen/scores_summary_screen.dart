import 'package:flutter/material.dart';

import '../model/exam_model.dart';
import '../service/exam_service.dart';
import '../widget/rounded_donut_chart.dart';
import '../widget/subject_score_row.dart';
import '../widget/scores_table_header.dart';

import '../../widgets/common/app_header.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/snackbar.dart';

class ScoresSummaryScreen extends StatefulWidget {
  const ScoresSummaryScreen({super.key});

  @override
  State<ScoresSummaryScreen> createState() => _ScoresSummaryScreenState();
}

class _ScoresSummaryScreenState extends State<ScoresSummaryScreen> {
  final ExamService _examService = ExamService();

  List<SubjectScore> _subjectScores = [];
  double _averageScore = 0.0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  Future<void> _loadSummaryData() async {
    try {
      final summary = await _examService.getScoresSummary();
      final examSummary = await _examService.getExamResults();

      if (!mounted) return;

      setState(() {
        _subjectScores = summary;
        _averageScore = examSummary.averageScore;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      CustomSnackBar.error(
        title: 'Error loading summary',
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _errorView(context)
            : Column(
                children: [
                  const AppHeader(),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 35),

                          /// 🔵 DONUT CHART
                          RoundedDonutChart(
                            subjects: _subjectScores,
                            averageScore: _averageScore,
                          ),

                          const SizedBox(height: 60),

                          /// 📊 TABLE HEADER
                          const ScoresTableHeader(),

                          const SizedBox(height: 12),

                          /// 📋 SUBJECT LIST
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 32, right: 16),
                            itemCount: _subjectScores.length,
                            itemBuilder: (context, index) {
                              return SubjectScoreRow(
                                subject: _subjectScores[index],
                              );
                            },
                          ),

                          /// ⬅️ BACK BUTTON
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusM,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSizeM,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// ❌ ERROR VIEW — DARK MODE FRIENDLY
  Widget _errorView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: AppSizes.fontSizeM,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadSummaryData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
