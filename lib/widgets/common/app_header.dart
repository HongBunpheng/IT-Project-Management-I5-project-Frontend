import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../notification/screen/notification_screen.dart';

class AppHeader extends StatelessWidget {
  final String? profileImageUrl;
  final String? username;
  final String? userId;
  final String? fullName;
  final String? email;
  final VoidCallback? onNotificationTap;
  final String? title;
  final Widget? trailing;

  const AppHeader({
    super.key,
    this.profileImageUrl,
    this.username,
    this.userId,
    this.fullName,
    this.email,
    this.onNotificationTap,
    this.title,
    this.trailing,
  });
  
  String _capitalizeFullName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

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
                ? Icon(Icons.person, size: 30, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: AppSizes.spacingM),
          // Full Name and Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Name (first line) - only show if available
                if (fullName != null && fullName!.isNotEmpty)
                  Text(
                    _capitalizeFullName(fullName),
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                // Email (second line) - always show if available
                if (email != null && email!.isNotEmpty) ...[
                  if (fullName != null && fullName!.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    email!,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
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
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed:
                      onNotificationTap ??
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationView(),
                        ),
                      ),
                  padding: EdgeInsets.zero,
                ),
              ),
        ],
      ),
    );
  }
}
