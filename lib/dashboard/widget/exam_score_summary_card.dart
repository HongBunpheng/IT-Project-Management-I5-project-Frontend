import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../model/dashboard_models.dart';

class ExamScoreSummaryCard extends StatelessWidget {
  final ExamScoreSummary scoreSummary;

  const ExamScoreSummaryCard({super.key, required this.scoreSummary});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryBlue.withValues(alpha: 0.85),
                  AppColors.primaryBlueLight.withValues(alpha: 0.75),
                ]
              : [AppColors.primaryBlue, AppColors.primaryBlueLight],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// LEFT SIDE — TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam Overview',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  'Average Score',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeS,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  '${scoreSummary.score.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeXXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),

          /// RIGHT SIDE — ICON ONLY (NO ATTENDANCE)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: AppColors.white, size: 40),
          ),
        ],
      ),
    );
  }
}
