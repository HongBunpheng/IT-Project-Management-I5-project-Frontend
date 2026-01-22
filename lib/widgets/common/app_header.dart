import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../account/service/account_service.dart';
import '../../account/screen/profile_screen.dart';
import '../../notification/screen/notification_screen.dart';

class AppHeader extends StatefulWidget {
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
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final AccountService _accountService = AccountService();
  final TokenStorage _tokenStorage = TokenStorage();
  
  String? _fetchedProfileImageUrl;
  String? _fetchedUsername;
  String? _fetchedUserId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // First try to get from stored data
      final storedUserId = await _tokenStorage.readUserId();
      if (mounted) {
        setState(() {
          _fetchedUserId = storedUserId;
        });
      }

      // Fetch user profile from API using AccountService
      final profileResponse = await _accountService.getProfile();
      if (profileResponse == null || !mounted) return;

      // Extract avatar URL using service method
      final avatarUrl = _accountService.extractAvatarUrl(profileResponse);
      
      // Extract user data
      final user = _accountService.extractUserData(profileResponse);
      
      final userName = readString(user, const ['user_name', 'name', 'full_name', 'fullName', 'username']);
      final userId = readString(user, const ['id', 'user_id', 'userId']);
      
      if (mounted) {
        setState(() {
          _fetchedProfileImageUrl = avatarUrl;
          _fetchedUsername = userName;
          _fetchedUserId = userId ?? _fetchedUserId;
        });
      }
    } catch (e) {
      // Ignore errors, use fallback values
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use fetched data or fallback to widget parameters
    final profileImageUrl = _fetchedProfileImageUrl ?? widget.profileImageUrl;
    final username = _fetchedUsername ?? widget.username;
    final userId = _fetchedUserId ?? widget.userId;
    
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.spacingM,
        right: AppSizes.spacingM,
        bottom: AppSizes.spacingM,
        top: MediaQuery.of(context).padding.top + AppSizes.spacingM,
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
          // Profile Picture (Clickable)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColors.lightGrey,
              ),
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: appColors.primaryBlue,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading network image in header: $error');
                          print('Failed URL: $profileImageUrl');
                          // Clear invalid URL
                          if (mounted) {
                            Future.microtask(() {
                              if (mounted) {
                                setState(() {
                                  _fetchedProfileImageUrl = null;
                                });
                              }
                            });
                          }
                          return Icon(
                            Icons.person,
                            size: 30,
                            color: appColors.textSecondary,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 30,
                      color: appColors.textSecondary,
                    ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          // Username and ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? username ?? 'Student Name',
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
          widget.trailing ??
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
                  onPressed: widget.onNotificationTap ??
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
