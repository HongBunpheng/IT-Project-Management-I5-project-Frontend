import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../model/dashboard_models.dart';

class TaskCardItem extends StatelessWidget {
  final TaskCard task;

  const TaskCardItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    IconData iconData;

    switch (task.iconCategory) {
      case 'office':
        iconColor = AppColors.iconPink;
        iconData = Icons.work_outline;
        break;
      case 'personal':
        iconColor = AppColors.purple;
        iconData = Icons.category_outlined;
        break;
      case 'study':
        iconColor = AppColors.progressOrange;
        iconData = Icons.book_outlined;
        break;
      default:
        iconColor = AppColors.grey;
        iconData = Icons.work_outline;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spacingM),
      padding: EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryBlue.withValues(alpha: 0.15)
            : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: isDark
              ? AppColors.primaryBlue.withValues(alpha: 0.3)
              : AppColors.primaryBlue.withValues(alpha: 0.1),
          width: 1,
        ),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                (iconColor.r * 255).round().clamp(0, 255).toInt(),
                (iconColor.g * 255).round().clamp(0, 255).toInt(),
                (iconColor.b * 255).round().clamp(0, 255).toInt(),
                0.2,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Icon(iconData, color: iconColor, size: AppSizes.iconSizeM),
          ),
          SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title ?? 'Project',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: appColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSizes.spacingXS),
              ],
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}
