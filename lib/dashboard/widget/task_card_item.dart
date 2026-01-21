import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../model/dashboard_models.dart';

class TaskCardItem extends StatelessWidget {
  final TaskCard task;

  const TaskCardItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color progressColor;
    IconData iconData;

    switch (task.iconCategory) {
      case 'office':
        iconColor = AppColors.iconPink;
        progressColor = AppColors.progressRed;
        iconData = Icons.work_outline;
        break;
      case 'personal':
        iconColor = AppColors.purple;
        progressColor = AppColors.purple;
        iconData = Icons.category_outlined;
        break;
      case 'study':
        iconColor = AppColors.progressOrange;
        progressColor = AppColors.progressOrange;
        iconData = Icons.book_outlined;
        break;
      default:
        iconColor = AppColors.grey;
        progressColor = AppColors.grey;
        iconData = Icons.work_outline;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.spacingM),
      padding: EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.borderLight, width: 1),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSizes.spacingXS),
                Text(
                  '${task.taskCount ?? 0} Tasks',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: task.progress ?? 0.0,
                  strokeWidth: 4,
                  backgroundColor: AppColors.lightGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              Text(
                '${((task.progress ?? 0.0) * 100).toInt()}%',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXS,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
