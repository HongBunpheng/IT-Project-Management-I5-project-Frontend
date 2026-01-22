import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';

class LeaveRequestDetailScreen extends StatelessWidget {
  final String startDate;
  final String endDate;
  final String reason;
  final bool isHalfDay;

  const LeaveRequestDetailScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.isHalfDay,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark 
            ? AppColors.primaryBlue.withValues(alpha: 0.2)
            : AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: isDark
            ? Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              )
            : null,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: AppSizes.iconSizeM,
            color: appColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leave Request',
          style: TextStyle(
            color: appColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSizes.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.spacingS),
              const Text(
                'October 2025',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Leave Request',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeL,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF154888), // Dark Blue
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingS,
                      vertical: AppSizes.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFCC80,
                      ).withValues(alpha: 0.5), // Light Orange
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontSizeS,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingXL),

              _buildLabelValue('Start Date', startDate),
              const SizedBox(height: AppSizes.spacingM),
              _buildLabelValue('End Date', endDate),
              const SizedBox(height: AppSizes.spacingM),
              _buildLabelValue('Half day', isHalfDay ? 'Yes' : 'No'),
              const SizedBox(height: AppSizes.spacingL),

              const Text(
                'Reason:',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                reason,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeM,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                'Apply on Tue 20, July 2025', // Mock submission date
                style: TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  color: Colors.grey.shade400,
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeS,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
