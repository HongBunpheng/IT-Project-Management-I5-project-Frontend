import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../model/timetable_task_model.dart';

class DatePickerWidget extends StatelessWidget {
  final List<DayModel> days;
  final Function(DayModel) onDaySelected;

  const DatePickerWidget({
    super.key,
    required this.days,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.getPadding(context),
          ),
          child: Text(
            'Today',
            style: TextStyle(
              fontSize: AppSizes.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        SizedBox(height: AppSizes.spacingM),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getPadding(context),
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return GestureDetector(
                onTap: () => onDaySelected(day),
                child: Container(
                  width: 60,
                  margin: EdgeInsets.only(right: AppSizes.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(
                      color: day.isSelected
                          ? AppColors.primaryBlue
                          : AppColors.borderLight,
                      width: day.isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeL,
                          fontWeight: FontWeight.bold,
                          color: day.isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSizes.spacingXS),
                      Text(
                        day.dayAbbreviation,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          color: day.isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
