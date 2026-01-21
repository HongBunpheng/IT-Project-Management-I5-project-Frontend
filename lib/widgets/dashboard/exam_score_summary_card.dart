import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../core/responsive/responsive.dart';
import '../../models/dashboard_models.dart';
import '../../screens/exam_scores_screen.dart';

class ExamScoreSummaryCard extends StatelessWidget {
  final ExamScoreSummary scoreSummary;

  const ExamScoreSummaryCard({
    super.key,
    required this.scoreSummary,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scoreSummary.title ?? 'Exam Score Summary',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: AppSizes.spacingM),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExamScoresScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                  ),
                  child: Text(
                    'View Scores',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeS,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: scoreSummary.score / 100,
                  strokeWidth: 8,
                  backgroundColor: Color.fromRGBO(255, 255, 255, 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
              Text(
                '${scoreSummary.score.toInt()}%',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}