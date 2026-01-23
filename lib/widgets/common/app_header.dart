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
  final String? fullName;
  final String? email;
  final VoidCallback? onNotificationTap;
  final String? title;
  final Widget? trailing;
  final VoidCallback? onProfileTap;

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
    this.onProfileTap,
  });

  String _capitalizeFullName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final AccountService _accountService = AccountService();
  final TokenStorage _tokenStorage = TokenStorage();

  String? _fetchedProfileImageUrl;
  String? _fetchedUsername;
  String? _fetchedUserId;
  String? _fetchedEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Local storage
      final storedUserId = await _tokenStorage.readUserId();
      final storedEmail = await _tokenStorage.readEmail();

      if (mounted) {
        setState(() {
          _fetchedUserId = storedUserId;
          _fetchedEmail = storedEmail;
        });
      }

      // Backend profile
      final profileResponse = await _accountService.getProfile();
      if (profileResponse == null || !mounted) return;

      final avatarUrl = _accountService.extractAvatarUrl(profileResponse);
      final user = _accountService.extractUserData(profileResponse);

      final userName = readString(user, const [
        'user_name',
        'username',
        'name',
        'full_name',
        'fullName',
      ]);

      final emailFromApi = readString(user, const ['email', 'user_email']);

      if (mounted) {
        setState(() {
          _fetchedProfileImageUrl = avatarUrl;
          _fetchedUsername = userName;
          _fetchedEmail = emailFromApi ?? _fetchedEmail;
        });
      }
    } catch (_) {
      // silent fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profileImageUrl = _fetchedProfileImageUrl ?? widget.profileImageUrl;
    final username = _fetchedUsername ?? widget.username;
    final fullName = widget.fullName;
    final email = _fetchedEmail;

    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.spacingM,
        right: AppSizes.spacingM,
        bottom: AppSizes.spacingM,
        top: MediaQuery.of(context).padding.top + AppSizes.spacingM,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryBlue.withOpacity(0.2)
            : AppColors.white,
        border: isDark
            ? Border(
                bottom: BorderSide(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Profile avatar
          GestureDetector(
            onTap:
                widget.onProfileTap ??
                () {
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
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person, color: appColors.textSecondary),
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

          // Name + Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ??
                      (fullName != null && fullName.isNotEmpty
                          ? widget._capitalizeFullName(fullName)
                          : (username ?? 'Student')),
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXL,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      color: appColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Notification
          widget.trailing ??
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryBlue.withOpacity(0.3)
                      : appColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryBlue.withOpacity(0.5)
                        : appColors.borderLight,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: appColors.textPrimary,
                  ),
                  onPressed:
                      widget.onNotificationTap ??
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationView(),
                          ),
                        );
                      },
                ),
              ),
        ],
      ),
    );
  }
}
