import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../../models/timetable_task_model.dart';
import 'task_completion_dialog.dart';

class TimetableTaskCard extends StatelessWidget {
  final TimetableTaskModel task;
  final Function(bool)? onCompletionChanged;

  const TimetableTaskCard({
    super.key,
    required this.task,
    this.onCompletionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (!task.isCompleted) {
          final result = await TaskCompletionDialog.show(context, task);
          if (result == true && onCompletionChanged != null) {
            onCompletionChanged!(true);
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSizes.spacingM,
          left: Responsive.getPadding(context),
          right: Responsive.getPadding(context),
        ),
        padding: EdgeInsets.all(AppSizes.spacingM),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.success
                    : AppColors.iconOrange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                task.isCompleted ? Icons.check : Icons.info,
                color: AppColors.white,
                size: AppSizes.iconSizeM,
              ),
            ),
            SizedBox(width: AppSizes.spacingM),
            // Title and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSizes.spacingXS),
                  Text(
                    task.details,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Time Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.spacingM,
                vertical: AppSizes.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Text(
                task.time,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
