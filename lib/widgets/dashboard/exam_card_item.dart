import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../models/dashboard_models.dart';

class ExamCardItem extends StatelessWidget {
  final ExamCard exam;

  const ExamCardItem({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = exam.iconCategory == 'blue'
        ? AppColors.cardBlue
        : AppColors.primaryBlueLight;
    final Color iconColor = exam.iconCategory == 'blue'
        ? AppColors.iconPink
        : AppColors.iconOrange;
    final Color progressColor = exam.iconCategory == 'blue'
        ? AppColors.primaryBlueLight
        : AppColors.progressOrange;
    final IconData iconData = Icons.work_outline;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppSizes.spacingM),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  exam.category ?? 'Category',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeS,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconData,
                    color: AppColors.white,
                    size: AppSizes.iconSizeS,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacingS),
            Text(
              exam.title ?? 'Project Title',
              style: TextStyle(
                fontSize: AppSizes.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSizes.spacingM),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: exam.progress ?? 0.0,
                minHeight: 6,
                backgroundColor: AppColors.white,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
