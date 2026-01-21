import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';

class TimetableHeader extends StatelessWidget {
  const TimetableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSizes.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Calendar Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.error,
              size: AppSizes.iconSizeM,
            ),
          ),
          // Profile and Settings Icons
          Row(
            children: [
              // Profile Icon (Yellow emoji with halo)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.iconOrange,
                  size: AppSizes.iconSizeM,
                ),
              ),
              SizedBox(width: AppSizes.spacingS),
              // Settings Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Icon(
                  Icons.settings,
                  color: AppColors.grey,
                  size: AppSizes.iconSizeM,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
