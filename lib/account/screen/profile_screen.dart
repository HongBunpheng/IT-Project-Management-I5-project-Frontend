import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_locales/flutter_locales.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/localization_helper.dart';
import '../../widgets/common/custom_bottom_navigation_bar.dart';
import '../../dashboard/screen/dashboard_screen.dart';
import '../../checkin/screen/checkin_screen.dart';
import '../../exam/screen/exam_scores_screen.dart';
import '../../timetable/screen/timetable_screen.dart';
import '../../auth/screen/login_screen.dart';
import '../../auth/service/auth_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../utils/snackbar.dart';
import '../service/account_service.dart';
import 'personal_information_screen.dart';
import 'academic_records_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentBottomNavIndex = 4; // Profile is index 4
  bool _notificationsEnabled = true;
  File? _profileImage;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isLoadingMe = true;
  bool _isLoggingOut = false;
  bool _isUploadingImage = false;

  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();
  final AccountService _accountService = AccountService();

  String? _name;
  String? _email;
  String? _userId;
  String? _groupId;
  String? _major;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isScrolled = _scrollController.offset > 50;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    try {
      final storedUserId = await _tokenStorage.readUserId();
      final storedGroupId = await _tokenStorage.readGroupId();
      if (mounted) {
        setState(() {
          _userId = storedUserId;
          _groupId = storedGroupId;
        });
      }

      // Use AccountService to get profile
      final profileResponse = await _accountService.getProfile();
      if (profileResponse == null || !mounted) {
        if (mounted) setState(() => _isLoadingMe = false);
        return;
      }

      // Extract avatar URL using service method
      final avatarUrl = _accountService.extractAvatarUrl(profileResponse);
      
      // Extract user data
      final user = _accountService.extractUserData(profileResponse);

      if (mounted) {
        setState(() {
          _name = readString(user, const ['user_name', 'name', 'full_name', 'fullName']);
          _email = readString(user, const ['email']);
          _userId = readString(user, const ['id', 'user_id', 'userId']) ?? _userId;
          _groupId = readString(user, const ['group_id', 'groupId']) ?? _groupId;
          _major = readString(user, const ['major', 'department', 'faculty', 'course', 'program']);
          // Only update if we got a valid full URL (starts with http)
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            _profileImageUrl = avatarUrl;
          }
          // Don't overwrite existing valid URL with null or invalid URL
        });
        
        print('Loaded profile image URL: $_profileImageUrl');
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMe = false);
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _authService.logout();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickImage() async {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (builderContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (textContext) => Text(
                  safeLocaleString(textContext, 'select_profile_photo', fallback: 'Select Profile Photo'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (rowContext) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: safeLocaleString(rowContext, 'gallery', fallback: 'Gallery'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _selectAndUploadImage(ImageSource.gallery);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: safeLocaleString(rowContext, 'camera', fallback: 'Camera'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _selectAndUploadImage(ImageSource.camera);
                      },
                    ),
                    if (_profileImage != null || (_profileImageUrl != null && _profileImageUrl!.isNotEmpty))
                      _buildImageSourceOption(
                        icon: Icons.delete_outline,
                        label: safeLocaleString(rowContext, 'remove', fallback: 'Remove'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _profileImage = null;
                            _profileImageUrl = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        // Show local image immediately for better UX
        setState(() {
          _profileImage = file;
        });

        // Upload to backend
        await _uploadProfileImage(file);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(
          title: 'Error',
          message: 'Failed to select image. Please try again.',
        );
        print('Error selecting image: $e');
      }
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    if (!mounted) return;
    
    setState(() => _isUploadingImage = true);
    
    try {
      // Use AccountService to upload avatar
      final response = await _accountService.uploadAvatar(imageFile);
      
      if (response != null) {
        final statusCode = response['statusCode'] as int? ?? 0;
        
        if (statusCode == 200) {
          final body = response['body'];
          if (body != null && body is Map<String, dynamic>) {
            // Debug: Print the response to see what we're getting
            print('Upload response: ${jsonEncode(body)}');
            
            // Extract avatar URL using service method
            final avatarUrl = _accountService.extractAvatarUrl(body);
            print('Extracted avatar URL: $avatarUrl');
            
            if (mounted) {
              // Only update if we got a valid URL
              if (avatarUrl != null && avatarUrl.isNotEmpty) {
                setState(() {
                  _profileImageUrl = avatarUrl;
                  // Clear local image so it uses the URL from backend
                  _profileImage = null;
                  _isUploadingImage = false;
                });
                
                CustomSnackBar.success(
                  title: 'Success',
                  message: 'Profile photo uploaded successfully',
                );
                
                // Reload profile after a short delay to ensure backend has processed
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _loadProfile();
                  }
                });
              } else {
                // No URL found, but upload was successful - reload profile
                setState(() {
                  _isUploadingImage = false;
                });
                
                CustomSnackBar.success(
                  title: 'Success',
                  message: 'Profile photo uploaded successfully',
                );
                
                // Reload profile to get the URL
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _loadProfile();
                  }
                });
              }
            }
          } else {
            if (mounted) {
              setState(() => _isUploadingImage = false);
              CustomSnackBar.error(
                title: 'Error',
                message: 'Invalid response from server',
              );
            }
          }
        } else {
          // Handle error
          if (mounted) {
            final body = response['body'];
            final errorMessage = body is Map<String, dynamic>
                ? (readString(body, const ['message', 'error']) ?? 'Failed to upload image')
                : 'Failed to upload image';
            setState(() => _isUploadingImage = false);
            CustomSnackBar.error(
              title: 'Upload Failed',
              message: errorMessage,
            );
            print('Failed to upload image: $statusCode - $errorMessage');
          }
        }
      } else {
        if (mounted) {
          setState(() => _isUploadingImage = false);
          CustomSnackBar.error(
            title: 'Error',
            message: 'Failed to upload image. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        CustomSnackBar.error(
          title: 'Error',
          message: 'Failed to upload image. Please try again.',
        );
        print('Error uploading image: $e');
      }
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: context.appColors.primaryBlueLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: context.appColors.primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CheckInScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ExamScoresScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TimetableView()),
        );
        break;
      case 4:
        // Already on settings
        setState(() => _currentBottomNavIndex = 4);
        break;
      default:
        break;
    }
  }

  void _showPersonalInformation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: const PersonalInformationScreen(),
        );
      },
    );
  }

  void _showAcademicRecords() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: const AcademicRecordsScreen(),
        );
      },
    );
  }

  String _getCurrentLanguageName(BuildContext context) {
    final currentLocale = Locales.currentLocale(context);
    if (currentLocale?.languageCode == 'km') {
      return safeLocaleString(context, 'khmer', fallback: 'Khmer');
    }
    return safeLocaleString(context, 'english', fallback: 'English');
  }

  void _showLanguagePicker() {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Store the widget's context for locale changes
    final widgetContext = context;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final currentLocale = Locales.currentLocale(sheetContext);
        final currentLangCode = currentLocale?.languageCode ?? 'en';
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: appColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  safeLocaleString(sheetContext, 'language', fallback: 'Language'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                // English option
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(
                    safeLocaleString(sheetContext, 'english', fallback: 'English'),
                    style: TextStyle(
                      fontSize: 16,
                      color: appColors.textPrimary,
                    ),
                  ),
                  trailing: currentLangCode == 'en'
                      ? Icon(Icons.check, color: appColors.primaryBlue)
                      : null,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    // Change locale using the widget's context
                    await Locales.change(widgetContext, 'en');
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                // Khmer option
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(
                    safeLocaleString(sheetContext, 'khmer', fallback: 'Khmer'),
                    style: TextStyle(
                      fontSize: 16,
                      color: appColors.textPrimary,
                    ),
                  ),
                  trailing: currentLangCode == 'km'
                      ? Icon(Icons.check, color: appColors.primaryBlue)
                      : null,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    // Change locale using the widget's context
                    await Locales.change(widgetContext, 'km');
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark 
            ? AppColors.primaryBlue.withValues(alpha: 0.2)
            : AppColors.white,
        elevation: _isScrolled ? 4 : 0,
        shadowColor: _isScrolled 
            ? (isDark 
                ? AppColors.primaryBlue.withValues(alpha: 0.3)
                : AppColors.grey.withValues(alpha: 0.3)) 
            : Colors.transparent,
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
            color: appColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          safeLocaleString(context, 'my_profile', fallback: 'My Profile'),
          style: TextStyle(
            color: appColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Profile Picture with Camera Icon
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _pickImage,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appColors.lightGrey,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Image layer
                                _profileImage != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                        ),
                                      )
                                    : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              _profileImageUrl!,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
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
                                                print('Error loading network image: $error');
                                                print('Failed URL: $_profileImageUrl');
                                                // Clear invalid URL
                                                if (mounted) {
                                                  Future.microtask(() {
                                                    if (mounted) {
                                                      setState(() {
                                                        _profileImageUrl = null;
                                                      });
                                                    }
                                                  });
                                                }
                                                return Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: appColors.textSecondary,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: appColors.textSecondary,
                                          ),
                                // Loading overlay
                                if (_isUploadingImage)
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.3),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: appColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Text(
                      _name ?? (_isLoadingMe ? 'Loading...' : 'Student'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ID and Major
                    Text(
                      'ID: ${_userId ?? '-'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _major ?? _email ?? (_groupId != null ? 'Group: $_groupId' : '-'),
                      style: TextStyle(
                        fontSize: 14,
                        color: appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Divider
                    const Divider(height: 1),
                    // Account Section
                    _buildSectionHeader(safeLocaleString(context, 'account', fallback: 'Account'), context),
                    _buildAccountItem(
                      context: context,
                      icon: Icons.person_outline,
                      iconColor: appColors.primaryBlueLight,
                      label: safeLocaleString(context, 'personal_information', fallback: 'Personal Information'),
                      onTap: _showPersonalInformation,
                    ),
                    _buildAccountItem(
                      context: context,
                      icon: Icons.school_outlined,
                      iconColor: appColors.primaryBlueLight,
                      label: safeLocaleString(context, 'academic_records', fallback: 'Academic Records'),
                      onTap: _showAcademicRecords,
                    ),
                    const Divider(height: 1),
                    // Settings Section
                    _buildSectionHeader(safeLocaleString(context, 'settings', fallback: 'Settings'), context),
                    _buildSettingsItemWithToggle(
                      context: context,
                      icon: Icons.notifications_outlined,
                      iconColor: appColors.primaryBlueLight,
                      label: safeLocaleString(context, 'notifications', fallback: 'Notifications'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    _buildSettingsItemWithToggle(
                      context: context,
                      icon: Icons.dark_mode_outlined,
                      iconColor: appColors.primaryBlueLight,
                      label: safeLocaleString(context, 'dark_mode', fallback: 'Dark Mode'),
                      value: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark,
                      onChanged: (value) {
                        AdaptiveTheme.of(context).setThemeMode(
                          value ? AdaptiveThemeMode.dark : AdaptiveThemeMode.light,
                        );
                      },
                    ),
                    _buildSettingsItemWithSubtitle(
                      context: context,
                      icon: Icons.language_outlined,
                      iconColor: appColors.primaryBlueLight,
                      label: safeLocaleString(context, 'language', fallback: 'Language'),
                      subtitle: _getCurrentLanguageName(context),
                      onTap: _showLanguagePicker,
                    ),
                    const Divider(height: 1),
                    // Logout
                    _buildLogoutItem(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    final appColors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: appColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final appColors = context.appColors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: appColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: appColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSettingsItemWithToggle({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final appColors = context.appColors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: appColors.textPrimary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: appColors.primaryBlue,
      ),
    );
  }

  Widget _buildSettingsItemWithSubtitle({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final appColors = context.appColors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: appColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: appColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: appColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutItem() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.logout, color: AppColors.error, size: 22),
      ),
      title: Text(
        safeLocaleString(context, 'logout', fallback: 'Logout'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.error,
        size: 20,
      ),
      onTap: () {
        // Handle logout
        final dialogColors = context.appColors;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (context) => Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    safeLocaleString(context, 'logout', fallback: 'Logout'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: dialogColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    safeLocaleString(context, 'logout_confirmation', fallback: 'Are you sure you want to logout?'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: dialogColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: dialogColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            safeLocaleString(context, 'cancel', fallback: 'Cancel'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: dialogColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoggingOut
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _handleLogout();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isLoggingOut
                                ? 'Logging out...'
                                : safeLocaleString(
                                    context,
                                    'logout',
                                    fallback: 'Logout',
                                  ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
