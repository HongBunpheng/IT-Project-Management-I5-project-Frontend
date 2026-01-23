import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../model/dashboard_models.dart';

class ExamCardItem extends StatelessWidget {
  final ExamCard exam;

  const ExamCardItem({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final date = exam.date;
    final startTime = exam.startTime;
    final endTime = exam.endTime;
    final timeLabel =
        (startTime != null && startTime.isNotEmpty) ||
            (endTime != null && endTime.isNotEmpty)
        ? '${startTime ?? '--:--'} - ${endTime ?? '--:--'}'
        : null;
    final metaLabel = (date != null && date.isNotEmpty) && timeLabel != null
        ? '$date • $timeLabel'
        : (date != null && date.isNotEmpty)
        ? date
        : timeLabel;

    final Color cardColor = exam.iconCategory == 'blue'
        ? (isDark
              ? AppColors.primaryBlue.withValues(alpha: 0.2)
              : AppColors.cardBlue)
        : (isDark
              ? AppColors.primaryBlueLight.withValues(alpha: 0.2)
              : AppColors.primaryBlueLight.withValues(alpha: 0.3));
    final Color iconColor = exam.iconCategory == 'blue'
        ? AppColors.iconPink
        : AppColors.iconOrange;
    final IconData iconData = Icons.work_outline;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppSizes.spacingM),
        decoration: BoxDecoration(
          color: isDark
              ? (exam.iconCategory == 'blue'
                    ? AppColors.primaryBlue.withValues(alpha: 0.2)
                    : AppColors.primaryBlueLight.withValues(alpha: 0.2))
              : cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: isDark
              ? Border.all(
                  color: exam.iconCategory == 'blue'
                      ? AppColors.primaryBlue.withValues(alpha: 0.4)
                      : AppColors.primaryBlueLight.withValues(alpha: 0.4),
                  width: 1,
                )
              : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                    color: appColors.textSecondary,
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
                color: appColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (metaLabel != null) ...[
              SizedBox(height: AppSizes.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: appColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      metaLabel,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeS,
                        color: appColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: AppSizes.spacingM),
          ],
        ),
      ),
    );
  }
}
