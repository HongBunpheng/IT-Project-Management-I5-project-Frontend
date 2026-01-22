import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../../utils/localization_helper.dart';
import '../model/timetable_task_model.dart';

class TaskCompletionDialog extends StatelessWidget {
  final TimetableTaskModel task;

  const TaskCompletionDialog({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSizes.spacingXL,
      ),
      child: Container(
        padding: EdgeInsets.all(AppSizes.spacingL),
        decoration: BoxDecoration(
          color: AppColors.cardBlue,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.iconOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info,
                    color: AppColors.white,
                    size: AppSizes.iconSizeM,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: AppSizes.iconSizeL,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacingL),
            // Question
            Center(
              child: Text(
                safeLocaleString(context, 'did_you_complete_schedule', fallback: 'Did you complete your schedule?'),
                style: TextStyle(
                  fontSize: AppSizes.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: AppSizes.spacingXL),
            // Task Title
            Center(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: AppSizes.spacingXL),
            // Schedule details
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: AppSizes.iconSizeM,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: AppSizes.spacingS),
                Expanded(
                  child: Text(
                    '${safeLocaleString(context, 'scheduled_for', fallback: 'Scheduled for')} ${task.time}, Wednesday',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacingM),
            // Task details
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: AppSizes.iconSizeM,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: AppSizes.spacingS),
                Expanded(
                  child: Text(
                    task.details,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacingXL),
            // Yes/No Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: AppSizes.spacingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                    child: Text(
                      safeLocaleString(context, 'yes', fallback: 'Yes'),
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlueLight,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: AppSizes.spacingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                    child: Text(
                      safeLocaleString(context, 'no', fallback: 'No'),
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context,
    TimetableTaskModel task,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TaskCompletionDialog(task: task),
    );
  }
}
