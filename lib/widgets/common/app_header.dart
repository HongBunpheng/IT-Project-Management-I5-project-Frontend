import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';

class AppHeader extends StatelessWidget {
  final String? profileImageUrl;
  final String? username;
  final String? userId;
  final VoidCallback? onNotificationTap;
  final String? title;
  final Widget? trailing;

  const AppHeader({
    super.key,
    this.profileImageUrl,
    this.username,
    this.userId,
    this.onNotificationTap,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingM,
      ),
      color: AppColors.white,
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightGrey,
              image: profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: AppSizes.spacingM),
          // Username and ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? username ?? 'Student Name',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${userId ?? 'e20211580'}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Notification Icon
          trailing ??
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: onNotificationTap ?? () {},
                  padding: EdgeInsets.zero,
                ),
              ),
        ],
      ),
    );
  }
}