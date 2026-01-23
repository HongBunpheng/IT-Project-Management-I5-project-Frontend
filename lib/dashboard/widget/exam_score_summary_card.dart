import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../../utils/localization_helper.dart';
import '../model/dashboard_models.dart';
import '../../main_shell.dart';

class ExamScoreSummaryCard extends StatelessWidget {
  final ExamScoreSummary scoreSummary;

  const ExamScoreSummaryCard({super.key, required this.scoreSummary});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryBlue.withValues(alpha: 0.8),
                  AppColors.primaryBlueLight.withValues(alpha: 0.7),
                ]
              : [
                  AppColors.primaryBlue,
                  AppColors.primaryBlueLight,
                ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeLocaleString(context, 'please_checkin_checkout', fallback: 'Checkin/Checkout here'),
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSizes.spacingM),
                ElevatedButton(
                  onPressed: () {
                    goToMainTab(context, 1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                  ),
                  child: Text(
                    safeLocaleString(context, 'scan_attendance', fallback: 'Scan Attendance'),
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              goToMainTab(context, 1);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppColors.white,
                size: 60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
