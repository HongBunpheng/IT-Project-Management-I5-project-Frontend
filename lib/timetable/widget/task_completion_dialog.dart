import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../model/timetable_task_model.dart';

class TaskCompletionDialog extends StatelessWidget {
  final TimetableTaskModel task;

  const TaskCompletionDialog({super.key, required this.task});

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
            // Task Title
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: AppSizes.spacingXL),
            // Subject Name
            if (task.subjectName != null && task.subjectName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.book,
                      size: AppSizes.iconSizeM,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        task.subjectName!,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Time
            if (task.time.isNotEmpty && task.time != '-')
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: AppSizes.iconSizeM,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        task.time,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Building
            if (task.building != null && task.building!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: AppSizes.iconSizeM,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        task.building!,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Room
            if (task.room != null && task.room!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.room,
                      size: AppSizes.iconSizeM,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        task.room!,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Instructor/Teacher
            if (task.instructor != null && task.instructor!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: AppSizes.iconSizeM,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        task.instructor!,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Day of Week
            if (task.dayOfWeek != null && task.dayOfWeek!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: AppSizes.iconSizeM,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        task.dayOfWeek!,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Group Name
            if (task.groupName != null && task.groupName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: AppSizes.iconSizeM,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Text(
                        task.groupName!,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeM,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, TimetableTaskModel task) {
    return showDialog(
      context: context,
      builder: (context) => TaskCompletionDialog(task: task),
    );
  }
}
