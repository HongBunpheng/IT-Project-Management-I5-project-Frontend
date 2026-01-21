import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../models/timetable_model.dart';

class TimetableCard extends StatelessWidget {
  final TimetableModel timetable;
  final VoidCallback? onTap;

  const TimetableCard({super.key, required this.timetable, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      timetable.subject ?? 'Subject',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingS,
                      vertical: AppSizes.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Text(
                      timetable.dayOfWeek ?? 'Day',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: AppSizes.fontSizeXS,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingS),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.spacingXS),
                  Text(
                    '${timetable.startTime ?? '00:00'} - ${timetable.endTime ?? '00:00'}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (timetable.location != null) ...[
                const SizedBox(height: AppSizes.spacingXS),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Text(
                      timetable.location!,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              if (timetable.instructor != null) ...[
                const SizedBox(height: AppSizes.spacingXS),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Text(
                      timetable.instructor!,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
