import 'package:flutter/material.dart';
import 'configs/app_colors.dart';
import 'configs/app_sizes.dart';
import 'configs/app_theme_extension.dart';
import 'utils/localization_helper.dart';
import 'notification/screen/notification_screen.dart';

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
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.spacingM,
        right: AppSizes.spacingM,
        bottom: AppSizes.spacingM,
        top: statusBarHeight + AppSizes.spacingM,
      ),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.primaryBlue.withValues(alpha: 0.2)
            : AppColors.white,
        border: isDark
            ? Border(
                bottom: BorderSide(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appColors.lightGrey,
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
                    color: appColors.textSecondary,
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
                  title ?? username ?? safeLocaleString(context, 'student_name', fallback: 'Student Name'),
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXL,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${userId ?? 'e20211580'}',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    color: appColors.textSecondary,
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
                  color: isDark
                      ? AppColors.primaryBlue.withValues(alpha: 0.3)
                      : appColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryBlue.withValues(alpha: 0.5)
                        : appColors.borderLight,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: appColors.textPrimary,
                  ),
                  onPressed: onNotificationTap ??
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationView()),
                          ),
                  padding: EdgeInsets.zero,
                ),
              ),
        ],
      ),
    );
  }
}
