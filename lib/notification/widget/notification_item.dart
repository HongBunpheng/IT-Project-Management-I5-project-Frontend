import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../model/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onDelete;
  final VoidCallback? onDecline;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onDelete,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSizes.spacingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!notification.isRead)
            Padding(
              padding: EdgeInsets.only(
                top: AppSizes.spacingM + 4,
                right: AppSizes.spacingS,
              ),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.lightGrey,
            child: Icon(
              Icons.person,
              color: AppColors.textSecondary,
              size: AppSizes.iconSizeL,
            ),
          ),
          SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.senderName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (notification.hasActions) ...[
                  const SizedBox(height: AppSizes.spacingS),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingM,
                            vertical: AppSizes.spacingXS,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusS,
                            ),
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontSize: AppSizes.fontSizeS),
                        ),
                      ),
                      SizedBox(width: AppSizes.spacingS),
                      OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                            color: AppColors.borderLight,
                            width: 1,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingM,
                            vertical: AppSizes.spacingXS,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusS,
                            ),
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(fontSize: AppSizes.fontSizeS),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  notification.timestamp,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
