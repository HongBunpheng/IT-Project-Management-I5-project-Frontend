import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../models/timetable_task_model.dart';

class IntakeProgressWidget extends StatelessWidget {
  final IntakeModel intake;

  const IntakeProgressWidget({super.key, required this.intake});

  @override
  Widget build(BuildContext context) {
    final progress = intake.total > 0 ? intake.completed / intake.total : 0.0;
    final isCompleted = intake.completed == intake.total && intake.total > 0;

    return Column(
      children: [
        Text(
          'Intakes',
          style: TextStyle(
            fontSize: AppSizes.fontSizeXXL,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        SizedBox(height: AppSizes.spacingL),
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer progress ring
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 20,
                  backgroundColor: AppColors.lightGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? AppColors.success : AppColors.cardBlue,
                  ),
                ),
              ),
              // Inner circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${intake.completed}/${intake.total}',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeXXXL,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSizes.spacingXS),
                    Text(
                      intake.dayName,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
