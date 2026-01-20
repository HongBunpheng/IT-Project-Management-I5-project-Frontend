import 'dart:io';
import 'package:gate_khmer_ai/main.dart';
import 'package:gate_khmer_ai/core/widgets/mixed_text.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gate_khmer_ai/core/config/buttons/buttons_widget.dart';
import 'package:gate_khmer_ai/core/config/snack_bar.dart';
import 'package:gate_khmer_ai/core/constants/base_url.dart';
import 'package:gate_khmer_ai/core/constants/controllers.dart';
import 'package:gate_khmer_ai/core/db/message_cache_db_helper.dart';
import 'package:gate_khmer_ai/core/theme/colors.dart';
import 'package:gate_khmer_ai/core/utils/image_compressor.dart';

import 'package:gate_khmer_ai/core/utils/permission_manager.dart';
import 'package:gate_khmer_ai/core/services/file_validation_service.dart';
import 'package:gate_khmer_ai/features/components/user_profile/models/update_user_model.dart';
import 'package:gate_khmer_ai/features/components/user_profile/models/user_model.dart';
import 'package:gate_khmer_ai/features/screens/chat/models/message_model.dart';
import 'package:gate_khmer_ai/features/screens/setting/api_call/privacy_security_api.dart'
    as privacyApi;
import 'package:gate_khmer_ai/services/audio/audio_output_service.dart';
import 'package:gate_khmer_ai/services/version_check_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'package:file_picker/file_picker.dart';

// List of available social media platforms
final List<Map<String, String>> socialMediaOptions = [
  {
    'name': 'Facebook',
    'icon': 'assets/images/social_media/facebook.png',
    'domain': 'facebook.com'
  },
  {'name': 'X', 'icon': 'assets/images/social_media/x.png', 'domain': 'x.com'},
  {
    'name': 'Instagram',
    'icon': 'assets/images/social_media/instagram.png',
    'domain': 'instagram.com'
  },
  {
    'name': 'LinkedIn',
    'icon': 'assets/images/social_media/linkedin.png',
    'domain': 'linkedin.com'
  },
  {
    'name': 'YouTube',
    'icon': 'assets/images/social_media/youtube.png',
    'domain': 'youtube.com'
  },
  {
    'name': 'TikTok',
    'icon': 'assets/images/social_media/tiktok.png',
    'domain': 'tiktok.com'
  },
  {
    'name': 'Snapchat',
    'icon': 'assets/images/social_media/snapchat.jpeg',
    'domain': 'snapchat.com'
  },
  {
    'name': 'Pinterest',
    'icon': 'assets/images/social_media/pinterest.png',
    'domain': 'pinterest.com'
  },
];

class SettingsController extends GetxController {
  // Scroll control
  final RxBool canScrollLeft = false.obs;
  final RxBool canScrollRight = true.obs;
  final RxBool isLoading = false.obs;

  // Loading state for audio output changes
  final RxBool isChangingAudioOutput = false.obs;

  void updateScrollState(ScrollPosition position) {
    canScrollLeft.value = position.pixels > 0;
    canScrollRight.value = position.pixels < position.maxScrollExtent;
  }

  // Tab selection
  final RxInt selectedTab = 0.obs;
  final RxInt selectedTabContent = 0.obs;
  final RxBool isEditMode = false.obs;

  // Settings states
  final RxMap<String, bool> settingsPreference = <String, bool>{}.obs;
  final RxMap<String, bool> privacySettings = <String, bool>{}.obs;
  final Rx<Color> accentColor = AppColors.primary.obs;

  // New settings properties
  final RxString selectedAudioOutput = 'speaker'.obs;
  final RxString selectedMediaQuality = 'auto'.obs;
  final RxString selectedMessageTone = 'default'.obs;
  final RxString selectedCallRingtone = 'default'.obs;

  // Data usage settings
  final RxString selectedPhotoDownload = 'wifi_only'.obs;
  final RxString selectedAudioDownload = 'wifi_only'.obs;
  final RxString selectedVideoDownload = 'wifi_only'.obs;
  final RxString selectedDocumentDownload = 'wifi_only'.obs;

  // Form controllers
  final Rx<TextEditingController> fullNameController =
      TextEditingController().obs;
  final Rx<TextEditingController> usernameController =
      TextEditingController().obs;
  final Rx<TextEditingController> emailController = TextEditingController().obs;
  final Rx<TextEditingController> bioController = TextEditingController().obs;
  final Rx<TextEditingController> interestsController =
      TextEditingController().obs;
  final Rx<TextEditingController> newSocialMediaController =
      TextEditingController().obs;
  final Rx<TextEditingController> phoneController = TextEditingController().obs;

  // Reactive text length counters
  final RxInt fullNameTextLength = 0.obs;
  final RxInt usernameTextLength = 0.obs;
  final RxInt emailTextLength = 0.obs;
  final RxInt bioTextLength = 0.obs;

  // Dropdown values
  final RxString selectedLanguage = 'English'.obs;
  final RxString selectedTheme = 'light'.obs;
  final RxString selectedFontSize = 'medium'.obs;
  final RxString selectedLoginHistory = 'view_all'.obs;
  final RxString selectedBlockedUsers = 'manage'.obs;

  // Profile visibility and online status
  final RxString profileVisibility = 'everyone'.obs;
  final RxString onlineStatus = 'everyone'.obs;

  // Add profile image
  final Rx<File?> profileImage = Rx<File?>(null);
  final Rx<File?> coverImage = Rx<File?>(null);
  final RxString selectedProfileImage = ''.obs;
  final RxString selectedCoverImage = ''.obs;

  // Add reactive variables for image URLs to trigger UI updates
  final RxString currentCoverImageUrl = ''.obs;
  final RxString currentAvatarImageUrl = ''.obs;

  // Default images
  final List<String> defaultProfileImages = [
    'assets/images/default_avatars/avatar1.jpg',
    'assets/images/default_avatars/avatar2.jpg',
    'assets/images/default_avatars/avatar3.jpg',
    'assets/images/default_avatars/avatar4.jpg',
    'assets/images/default_avatars/avatar5.jpg',
  ];

  final List<String> defaultCoverImages = [
    'assets/images/default_covers/cover1.jpg',
    'assets/images/default_covers/cover2.jpg',
    'assets/images/default_covers/cover3.jpg',
    'assets/images/default_covers/cover4.jpg',
    'assets/images/default_covers/cover5.jpg',
  ];

  GetStorage storage = GetStorage();

  // Add these new variables at the top of the class with other variables
  final RxString currentLanguage = 'English'.obs;
  final Map<String, String> languageCodes = {
    'English': 'en_US',
    'Khmer': 'km_KH',
    'Chinese': 'zh_CN',
  };
  final Map<String, String> _shortCodeToLanguage = const {
    'en': 'English',
    'en_us': 'English',
    'english': 'English',
    'km': 'Khmer',
    'km_kh': 'Khmer',
    'khmer': 'Khmer',
    'zh': 'Chinese',
    'zh_cn': 'Chinese',
    'chinese': 'Chinese',
  };

  // Add these new variables at the top of the class with other variables
  final RxList<TextEditingController> socialMediaControllers =
      <TextEditingController>[].obs;
  final RxList<String> socialMediaPlatforms = <String>[].obs;
  final RxBool showNewTextField = false.obs;
  final RxString newPlatform = ''.obs;
  final RxBool isSelected = false.obs;

  // Add this with other Rx variables at the top of the class
  final RxList<Map<String, String>> blockedUsers = <Map<String, String>>[
    {'id': '1', 'name': 'User 1', 'username': '@user1'},
    {'id': '2', 'name': 'User 2', 'username': '@user2'},
    {'id': '3', 'name': 'User 3', 'username': '@user3'},
  ].obs;

  // Cache management
  final RxString cacheSize = '0 MB'.obs;
  final RxBool isClearingCache = false.obs;
  final RxBool isCalculatingStorage = false.obs;
  final RxMap<String, String> mediaCacheSizes = <String, String>{
    'Images': '0 MB',
    'Videos': '0 MB',
    'Audio': '0 MB',
    'Documents': '0 MB',
  }.obs;

  // Add this constant at the top of the class with other constants
  static const int maxGalleryPhotos = 10;

  // Add these new variables at the top of the class with other variables
  final RxList<String> displayGallery = <String>[].obs;
  final RxList<String> uploadGallery = <String>[].obs;

  final RxList<String> getCurrentPhotosGallery = <String>[].obs;

  RxBool isUserUpdateImage = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize default values

    // Initialize default values
    _initializeDefaultValues();

    // Load saved language preference
    _loadLanguagePreference();

    // Load settings from storage
    _loadSettings();

    // Initialize reactive image URLs with current user data
    _initializeReactiveImageUrls();

    // Calculate initial cache sizes
    calculateCacheSizes();

    // Listen to user model changes for real-time UI updates
    ever(authController.user, (UserModel user) {
      // Clear reactive image URLs first to prevent showing old cached images
      clearReactiveImageUrls();

      // Then reinitialize with new user's image URLs
      _initializeReactiveImageUrls();

      _updateControllersFromProfile(user);

      // Force refresh all reactive variables
      fullNameController.refresh();
      usernameController.refresh();
      emailController.refresh();
      bioController.refresh();
      interestsController.refresh();

      // Force update the UI
      update();
    });

    // Optional: Check for updates when settings screen is opened
    _checkForUpdates();
  }

  /// Check for app updates when settings screen is opened
  void _checkForUpdates() async {
    try {
      // Only check if the service is available and user is authenticated
      if (Get.isRegistered<VersionCheckService>() &&
          authController.acessToken != null) {
        final versionService = Get.find<VersionCheckService>();
        // Use a delayed check to avoid blocking the UI
        Future.delayed(const Duration(seconds: 2), () async {
          await versionService.manualVersionCheck();
        });
      }
    } catch (e) {
    }
  }



  void _initializeDefaultValues() {
    // Initialize notification settings
    settingsPreference.value = {
      'push_notifications': true,
      'sound': true,
    };

    // Initialize privacy settings
    privacySettings.value = {
      'two_factor_authentication': false,
      'profile_visibility': true,
    };
  }

  // Tab management
  void changeTab(int index) {
    selectedTab.value = index;
  }

  void changeTabContent(int index) {
    selectedTabContent.value = index;
  }

  // Settings updates
  void updateNotificationSetting(String key, bool value) {
    settingsPreference[key] = value;
  }

  void updatePrivacySetting(String key, bool value) {
    privacySettings[key] = value;
  }

  void updateAccentColor(Color color) {
    accentColor.value = color;
  }

  // Dropdown updates
  void updateLanguage(String value) {
    try {
      final normalizedValue = _normalizeLanguageKey(value);
      currentLanguage.value = normalizedValue;
      selectedLanguage.value = normalizedValue;
      storage.write('language', normalizedValue);

      final localeString = languageCodes[normalizedValue] ?? 'en_US';
      final localeParts = localeString.split('_');
      final locale = localeParts.length > 1
          ? Locale(localeParts[0], localeParts[1])
          : Locale(localeParts[0]);
      Get.updateLocale(locale);

      snackBar(
        title: 'language_updated'.tr,
        message: '${'language_preference_updated'.tr} $normalizedValue',
      );
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_save_settings'.tr,
        isWarning: true,
      );
    }
  }

  String _normalizeLanguageKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'English';
    }

    if (languageCodes.containsKey(trimmed)) {
      return trimmed;
    }

    final caseInsensitiveMatch = languageCodes.keys.firstWhere(
      (key) => key.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => '',
    );
    if (caseInsensitiveMatch.isNotEmpty) {
      return caseInsensitiveMatch;
    }

    final localeMatch = languageCodes.entries.firstWhere(
      (entry) => entry.value.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => const MapEntry('', ''),
    );
    if (localeMatch.key.isNotEmpty) {
      return localeMatch.key;
    }

    final normalizedCode = trimmed.toLowerCase().replaceAll('-', '_');
    final shortCodeMatch = _shortCodeToLanguage[normalizedCode];
    if (shortCodeMatch != null) {
      return shortCodeMatch;
    }

    return 'English';
  }

  void updateTheme(String value) {
    selectedTheme.value = value;
  }

  void updateFontSize(String value) {
    selectedFontSize.value = value;
  }

  // Login history and blocked users management
  void updateLoginHistory(String value) {
    selectedLoginHistory.value = value;
    // TODO: Implement login history view logic
    snackBar(title: 'login_history'.tr, message: 'viewing_login_history'.tr);
  }

  void updateBlockedUsers(String value) {
    selectedBlockedUsers.value = value;
    // TODO: Implement blocked users management logic
    snackBar(title: 'blocked_users'.tr, message: 'managing_blocked_users'.tr);
  }

  // Profile visibility and online status
  void updateProfileVisibility(String? value) {
    if (value != null) {
      profileVisibility.value = value;
      snackBar(
        title: 'profile_visibility'.tr,
        message: 'your_profile_visibility_has_been_updated_to_${value.tr}',
      );
    }
  }

  void updateOnlineStatus(String? value) {
    if (value != null) {
      onlineStatus.value = value;
      snackBar(
        title: 'online_status'.tr,
        message:
            'your_online_status_visibility_has_been_updated_to_${value.tr}',
      );
    }
  }

  // Validation: Check if all social media URLs are valid
  bool get hasSocialMediaError {
    for (int i = 0; i < socialMediaControllers.length; i++) {
      final platform = socialMediaPlatforms[i];
      final url = socialMediaControllers[i].text.trim();

      // Check if platform is selected but URL is empty
      if (platform.isNotEmpty && url.isEmpty) {
        return true; // Incomplete entry: platform selected but no URL
      }

      // If URL is provided, validate it matches the platform
      if (url.isNotEmpty) {
        // Get the domain for the selected platform
        final platformDomain = socialMediaOptions.firstWhere(
          (option) => option['name'] == platform,
          orElse: () => {'domain': ''},
        )['domain'];
        if (platformDomain == null ||
            platformDomain.isEmpty ||
            !url.toLowerCase().contains(platformDomain)) {
          return true; // Invalid URL for selected platform
        }
      }
    }
    return false;
  }

  // Get detailed social media error message
  String getSocialMediaErrorMessage() {
    final incompleteEntries = <String>[];
    final invalidUrls = <String>[];

    for (int i = 0; i < socialMediaControllers.length; i++) {
      final platform = socialMediaPlatforms[i];
      final url = socialMediaControllers[i].text.trim();

      // Check if platform is selected but URL is empty
      if (platform.isNotEmpty && url.isEmpty) {
        incompleteEntries.add(platform);
      } else if (url.isNotEmpty) {
        // Check if URL is invalid for the platform
        final platformDomain = socialMediaOptions.firstWhere(
          (option) => option['name'] == platform,
          orElse: () => {'domain': ''},
        )['domain'];
        if (platformDomain == null ||
            platformDomain.isEmpty ||
            !url.toLowerCase().contains(platformDomain)) {
          invalidUrls.add(platform);
        }
      }
    }

    if (incompleteEntries.isNotEmpty) {
      return '${'please_provide_urls_for'.tr}: ${incompleteEntries.join(", ")}';
    }
    if (invalidUrls.isNotEmpty) {
      return '${'invalid_urls_for'.tr}: ${invalidUrls.join(", ")}. ${'please_check_urls_match_platforms'.tr}';
    }
    return 'please_fix_social_media_errors'.tr;
  }

  // Save all changes
  Future<void> saveAllChanges() async {
    if (hasSocialMediaError) {
      snackBar(
        title: 'oops'.tr,
        message: getSocialMediaErrorMessage(),
        isWarning: true,
      );
      return;
    }
    try {
      isLoading.value = true;

      // Check if there are any image changes
      final hasImageChanges = profileImage.value != null ||
          coverImage.value != null ||
          uploadGallery.isNotEmpty;


      // Store current image URLs before update (only if there are image changes)
      String? originalCoverUrl;
      String? originalAvatarUrl;
      if (hasImageChanges) {
        originalCoverUrl = authController.user.value.coverImageUrl;
        originalAvatarUrl = authController.user.value.avatarUrl;
      }

      // Prepare social media data
      final socialMediaList = _prepareSocialMediaData();
      // Create updated user model
      final updatedUser = _createUpdatedUserModel(socialMediaList).obs;
      // Update user profile
      await _updateUserProfile(updatedUser.value);

      // Force refresh UI after successful update
      await _refreshUIAfterUpdate();

      // Only handle image fallbacks if there were image changes
      if (hasImageChanges) {

        // If the new URLs are empty, fallback to original URLs
        if (authController.user.value.coverImageUrl.isEmpty &&
            originalCoverUrl != null &&
            originalCoverUrl.isNotEmpty) {
          currentCoverImageUrl.value = originalCoverUrl;
        }

        if (authController.user.value.avatarUrl.isEmpty &&
            originalAvatarUrl != null &&
            originalAvatarUrl.isNotEmpty) {
          currentAvatarImageUrl.value = originalAvatarUrl;
        }

        // Clear the image selections after successful save
        profileImage.value = null;
        coverImage.value = null;
        selectedProfileImage.value = '';
        selectedCoverImage.value = '';
      }
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_save_settings'.tr,
        isWarning: true,
      );

      // Reset image URLs to user defaults in case of error
      resetImageUrlsToUserDefaults();
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh UI after user profile update
  Future<void> _refreshUIAfterUpdate() async {
    try {
      // Check if there are any image changes
      final hasImageChanges = profileImage.value != null ||
          coverImage.value != null ||
          uploadGallery.isNotEmpty;

      // Store current reactive URLs if no image changes
      String? currentCoverUrl;
      String? currentAvatarUrl;
      if (!hasImageChanges) {
        currentCoverUrl = currentCoverImageUrl.value;
        currentAvatarUrl = currentAvatarImageUrl.value;
      }

      // Preserve displayGallery BEFORE any refresh operations
      // This prevents clearing gallery when refresh happens after image upload
      final currentDisplayGalleryValue = List<String>.from(displayGallery);
      final userGalleryValue = authController.user.value.gallery;


      // Preserve displayGallery if it has items (regardless of user model state)
      // We'll only use it if the user model has empty gallery after refresh
      final shouldPreserveGallery = currentDisplayGalleryValue.isNotEmpty;

      if (shouldPreserveGallery) {
      }

      // Force refresh the auth controller's user model
      authController.user.refresh();

      // Check user gallery after refresh
      final userGalleryAfterRefresh = authController.user.value.gallery;

      // Force refresh this controller
      update();

      // Update controllers with latest user data
      _updateControllersFromProfile(authController.user.value);

      // If displayGallery is now empty but we had data before, and user model still has empty gallery,
      // restore the preserved gallery
      if (shouldPreserveGallery &&
          displayGallery.isEmpty &&
          (userGalleryAfterRefresh == null ||
              userGalleryAfterRefresh.isEmpty)) {
        displayGallery.assignAll(currentDisplayGalleryValue);
      } else if (shouldPreserveGallery &&
          displayGallery.isEmpty &&
          userGalleryAfterRefresh != null &&
          userGalleryAfterRefresh.isNotEmpty) {
        // User model has gallery data now, so don't restore - let the normal update flow handle it
      }

      // Force refresh all reactive variables
      fullNameController.refresh();
      usernameController.refresh();
      emailController.refresh();
      bioController.refresh();
      interestsController.refresh();

      // Restore reactive URLs if no image changes were made
      if (!hasImageChanges) {
        if (currentCoverUrl != null && currentCoverUrl.isNotEmpty) {
          currentCoverImageUrl.value = currentCoverUrl;
        }
        if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
          currentAvatarImageUrl.value = currentAvatarUrl;
        }
      }

      // Final check: If we preserved gallery earlier but it's now empty and user model is empty,
      // restore it one more time as a safety net
      if (shouldPreserveGallery &&
          displayGallery.isEmpty &&
          (userGalleryAfterRefresh == null ||
              userGalleryAfterRefresh.isEmpty)) {
        displayGallery.assignAll(currentDisplayGalleryValue);
      }

      // Final verification: Log the final state

    } catch (e) {
    }
  }

  // Prepare social media data from controllers
  List<Map<String, String>> _prepareSocialMediaData() {
    final socialMediaList = <Map<String, String>>[];

    for (int i = 0; i < socialMediaControllers.length; i++) {
      final platform = socialMediaPlatforms[i];
      final url = socialMediaControllers[i].text.trim();

      if (platform.isNotEmpty && url.isNotEmpty) {
        socialMediaList.add({
          platform: url,
        });
      }
    }

    return socialMediaList;
  }

  // Create updated user model with current data
  UpdateUserModel _createUpdatedUserModel(
      List<Map<String, String>> socialMediaList) {
    final currentUser = authController.user.value;


    return UpdateUserModel(
      name: currentUser.fullname == fullNameController.value.text
          ? currentUser.fullname
          : fullNameController.value.text,
      email: currentUser.email == emailController.value.text
          ? currentUser.email
          : emailController.value.text,
      username: currentUser.username == usernameController.value.text
          ? currentUser.username
          : usernameController.value.text,
      bio: currentUser.bio == bioController.value.text
          ? currentUser.bio
          : bioController.value.text,
      interests: _parseInterests(),
      gallery: _cleanGalleryUrls(getCurrentPhotosGallery.toList()),
      socialMedia: socialMediaList,
    );
  }

  // Parse interests from controller text
  List<String> _parseInterests() {
    final interestsText = interestsController.value.text;
    if (interestsText.isEmpty) return [];

    // Remove square brackets and split by comma
    final cleanText = interestsText.replaceAll(RegExp(r'[\[\]]'), '');
    return cleanText == authController.user.value.interests?.join(',')
        ? authController.user.value.interests!.map((e) => e.toString()).toList()
        : cleanText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
  }

  // Update user profile in backend
  Future<void> _updateUserProfile(UpdateUserModel updatedUser) async {
    try {
      // Preserve uploadGallery before calling updateUserProfile
      // because getCurrentUserProfile() will trigger _updateControllersFromProfile()
      // which clears uploadGallery
      final preservedUploadGallery = List<String>.from(uploadGallery);

      // If name is empty, set it to phone number
      if (updatedUser.name?.trim().isEmpty ?? true) {
        updatedUser =
            updatedUser.copyWith(name: authController.user.value.phoneNumber);
      }
      await authController.updateUserProfile(userUpdated: updatedUser);

      // Restore uploadGallery after getCurrentUserProfile() clears it
      uploadGallery.assignAll(preservedUploadGallery);

      File? compressedAvatar;
      if (profileImage.value != null) {
        if (kIsWeb) {
          // On web, skip compression and use blob URL directly
          compressedAvatar = profileImage.value;
        } else {
          // Use optimized compression for profile images (higher quality, appropriate size)
          compressedAvatar =
              await ImageCompressor.compressProfileImage(profileImage.value!);
        }
      }

      File? compressedCover;
      if (coverImage.value != null) {
        if (kIsWeb) {
          // On web, skip compression and use blob URL directly
          compressedCover = coverImage.value;
        } else {
          compressedCover =
              await ImageCompressor.compressImage(coverImage.value!);
        }
      }
      // Update images only if there are changes
      if (uploadGallery.isNotEmpty ||
          profileImage.value != null ||
          coverImage.value != null) {
        isUserUpdateImage.value = true;

        // Show upload progress dialog
        BuildContext? dialogContext;
        // showDialog(
        //   context: Get.context!,
        //   barrierDismissible: false,
        //   builder: (ctx) {
        //     dialogContext = ctx;
        //     return AlertDialog(
        //       content: Column(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           buildLoadingIndicator(),
        //           const SizedBox(height: 16),
        //           MixedText('uploading'.tr.isNotEmpty ? 'uploading'.tr : 'Please wait...'),
        //         ],
        //       ),
        //     );
        //   },
        // );

        try {
          await authController.updateUserImage(
            avatar: compressedAvatar?.path,
            cover: compressedCover?.path,
            gallery: uploadGallery, // Only upload the new photos
          );
        } catch (e) {
          // Show user-friendly error message
          snackBar(
            title: 'error'.tr,
            message: 'failed_to_upload_image'.tr.isNotEmpty
                ? 'failed_to_upload_image'.tr
                : 'Failed to upload image. Please try again.',
            isWarning: true,
          );
          rethrow; // Re-throw to be caught by outer catch block
        } finally {
          // Ensure dialog is closed
          // if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
          //   Navigator.of(dialogContext!).pop();
          // }
        }

        // Clear the image cache to force refresh of cached images
        await _clearImageCache();

        // Update reactive image URLs to trigger UI updates
        if (authController.user.value.id.isNotEmpty) {
          // Wait a bit for the user model to be fully updated
          await Future.delayed(const Duration(milliseconds: 100));


          // Ensure URLs are full URLs, not relative paths
          String coverUrl = authController.user.value.coverImageUrl;
          String avatarUrl = authController.user.value.avatarUrl;

          // Convert relative paths to full URLs
          if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
            coverUrl = '${domain}$coverUrl';
          }
          if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
            avatarUrl = '${domain}$avatarUrl';
          }


          currentCoverImageUrl.value = coverUrl;
          currentAvatarImageUrl.value = avatarUrl;

        }

        // Force refresh image URLs to trigger UI updates
        forceRefreshImages();

        // Force refresh the UI by triggering a rebuild
        // This ensures the new cover image is displayed immediately
        authController.user.refresh();

        // Force rebuild of the settings screen
        update();

        // Force refresh all reactive variables to ensure UI updates
        fullNameController.refresh();
        usernameController.refresh();
        bioController.refresh();
        interestsController.refresh();

        // Add a small delay to ensure UI updates are processed
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Clear CachedNetworkImage cache to force refresh
  Future<void> _clearImageCache() async {
    try {
      // Clear the CachedNetworkImage cache for both current and reactive URLs
      final coverUrl = authController.user.value.coverImageUrl;
      final avatarUrl = authController.user.value.avatarUrl;

      if (coverUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(coverUrl);
      }

      if (avatarUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(avatarUrl);
      }

      // Also clear reactive URLs if they exist
      if (currentCoverImageUrl.value.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(currentCoverImageUrl.value);
      }

      if (currentAvatarImageUrl.value.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(currentAvatarImageUrl.value);
      }

    } catch (e) {
    }
  }

  // Get reactive cover image URL (allow image cache)
  String getReactiveCoverImageUrl() {
    final url = currentCoverImageUrl.value;
    if (url.isEmpty) {
      // Fallback to user's cover image URL if reactive URL is empty
      final userCoverUrl = authController.user.value.coverImageUrl;
      if (userCoverUrl.isNotEmpty) {
        return userCoverUrl;
      }
      return '';
    }
    return url;
  }

  // Get reactive avatar image URL (allow image cache)
  String getReactiveAvatarImageUrl() {
    final url = currentAvatarImageUrl.value;
    if (url.isEmpty) {
      // Fallback to user's avatar URL if reactive URL is empty
      final userAvatarUrl = authController.user.value.avatarUrl;
      if (userAvatarUrl.isNotEmpty) {
        return userAvatarUrl;
      }
      return '';
    }
    return url;
  }

  // Force refresh image URLs to trigger UI updates
  void forceRefreshImages() {
    // Force refresh the reactive variables
    currentCoverImageUrl.refresh();
    currentAvatarImageUrl.refresh();

    // Also trigger a UI update
    update();

  }

  // Clear reactive image URLs to prevent showing old cached images
  void clearReactiveImageUrls() {
    try {
      currentCoverImageUrl.value = '';
      currentAvatarImageUrl.value = '';
      currentCoverImageUrl.refresh();
      currentAvatarImageUrl.refresh();
    } catch (e) {
    }
  }

  // Reset image URLs to user's current URLs (fallback method)
  void resetImageUrlsToUserDefaults() {
    try {
      final user = authController.user.value;

      // Ensure URLs are full URLs, not relative paths
      String coverUrl = user.coverImageUrl;
      String avatarUrl = user.avatarUrl;

      // Convert relative paths to full URLs
      if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
        coverUrl = '${domain}$coverUrl';
      }
      if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
        avatarUrl = '${domain}$avatarUrl';
      }


      currentCoverImageUrl.value = coverUrl;
      currentAvatarImageUrl.value = avatarUrl;

      // Force refresh
      currentCoverImageUrl.refresh();
      currentAvatarImageUrl.refresh();
      update();

    } catch (e) {
    }
  }

  // Manually refresh cover image (for debugging/testing)
  Future<void> refreshCoverImage() async {
    try {
      await _clearImageCache();
      resetImageUrlsToUserDefaults();
      forceRefreshImages();
    } catch (e) {
    }
  }

  // Cancel edit mode and restore original image URLs
  void cancelEditMode() {
    try {

      // Reset image selections
      profileImage.value = null;
      coverImage.value = null;
      selectedProfileImage.value = '';
      selectedCoverImage.value = '';

      // Reset to user's current URLs
      resetImageUrlsToUserDefaults();

      // Exit edit mode
      isEditMode.value = false;

    } catch (e) {
    }
  }

  // Initialize reactive image URLs with current user data
  void _initializeReactiveImageUrls() {
    try {
      if (authController.user.value.id.isNotEmpty) {
        String coverUrl = authController.user.value.coverImageUrl;
        String avatarUrl = authController.user.value.avatarUrl;

        // Convert relative paths to full URLs
        if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
          coverUrl = '${domain}$coverUrl';
        }
        if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
          avatarUrl = '${domain}$avatarUrl';
        }

        currentCoverImageUrl.value = coverUrl;
        currentAvatarImageUrl.value = avatarUrl;
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  // Clear all image caches (for more comprehensive cache clearing)
  Future<void> clearAllImageCaches() async {
    try {
      // Clear all CachedNetworkImage caches by clearing specific URLs
      // Note: CachedNetworkImage doesn't have a method to clear all caches at once
      // We can only clear specific URLs, so this method is kept for future use
    } catch (e) {
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    buildLogout(
      title: 'delete_account'.tr,
      question: 'are_you_sure_you_want_to_delete_your_account'.tr,
      description:
          'this_action_cannot_be_undone_and_all_your_data_will_be_permanently_deleted'
              .tr,
      icon: Icons.warning_rounded,
      iconColor: const Color(0xFFFF3B30),
      boxColor: const Color(0xFFFF3B30).withOpacity(0.1),
      borderColor: const Color(0xFFFF3B30).withOpacity(0.2),
      confirmText: 'delete_account'.tr,
      cancelText: 'cancel'.tr,
      confirmButtonColor: const Color(0xFFFF3B30),
      onConfirm: () async {
        Get.back(); // Close the confirmation dialog
        try {
          final token = authController.acessToken;
          if (token == null || token.isEmpty) {
            snackBar(
              isWarning: true,
              title: 'oops'.tr,
              message: 'Authorization token missing'.tr,
            );
            return;
          }
          final message = await deleteAccountApiCall(token);
          snackBar(
            title: 'success'.tr,
            message: message ?? 'your_account_has_been_deleted'.tr,
          );
          await Future.delayed(const Duration(milliseconds: 500));
          await authController.logOut();
        } catch (e) {
          snackBar(
            isWarning: true,
            title: 'oops'.tr,
            message: e.toString(),
          );
        }
      },
    );
  }

  // Helper for API call
  Future<String?> deleteAccountApiCall(String token) async {
    return await privacyApi.deleteAccount(token);
  }

  // Logout functionality
  Future<void> buildLogout({
    String? title,
    String? question,
    String? description,
    IconData? icon,
    Color? iconColor,
    Color? boxColor,
    Color? borderColor,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    Color? confirmButtonColor,
  }) async {
    // Add a small delay for Web to ensure the previous UI state is stabilized
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final context = navigatorKey.currentContext ?? Get.context;
    if (context == null) {
      debugPrint('Error: Could not find valid context for bottom sheet');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      enableDrag: true,
      isDismissible: true,
      builder: (modalContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Prevent taps from falling through
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Use SingleChildScrollView only if necessary, but with ClampingPhysics
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          MixedText(
                            title ?? 'logout'.tr,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Content box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: boxColor ?? Colors.red[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor ?? Colors.red[100]!,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  icon ?? Icons.logout_rounded,
                                  color: iconColor ?? Colors.red[400],
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      MixedText(
                                        question ?? 'are_you_sure_you_want_to_logout'.tr,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F1F1F),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      MixedText(
                                        description ??
                                            'you_will_need_to_login_again_to_access_your_account'.tr,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlineButton(
                                  name: cancelText ?? 'cancel'.tr,
                                  onTap: () {
                                    debugPrint('Bottom Sheet: Cancel Clicked');
                                    Navigator.of(modalContext).pop();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FillButton(
                                  color: confirmButtonColor ?? Colors.red[400],
                                  name: confirmText ?? 'logout'.tr,
                                  onTap: () {
                                    debugPrint('Bottom Sheet: Confirm Clicked');
                                    if (onConfirm != null) {
                                      onConfirm();
                                    } else {
                                      authController.logOut();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  void updateProfileImage(File? image) async {
    try {
      isLoading.value = true;

      // Crop profile image if provided
      if (image != null) {
        final croppedFile = await _cropImage(image);
        profileImage.value = croppedFile ?? image; // Use original if crop fails
      } else {
        profileImage.value = null;
      }

      snackBar(
        title: 'success'.tr,
        message: image != null
            ? 'profile_image_updated'.tr
            : 'profile_image_cleared'.tr,
      );

      // Clear image cache to ensure fresh display
      await _clearImageCache();

      // Force refresh image URLs to trigger UI updates
      forceRefreshImages();
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_update_profile_image'.tr,
        isWarning: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void updateCoverImage(File? image) async {
    try {
      isLoading.value = true;
      coverImage.value = image;

      snackBar(
        title: 'success'.tr,
        message:
            image != null ? 'cover_image_updated'.tr : 'cover_image_cleared'.tr,
      );

      // Clear image cache to ensure fresh display
      await _clearImageCache();

      // Force refresh image URLs to trigger UI updates
      forceRefreshImages();
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_update_cover_image'.tr,
        isWarning: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearProfileImage() {
    updateProfileImage(null);
  }

  void clearCoverImage() {
    updateCoverImage(null);
  }

  Future<File?> _getFileFromAsset(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${assetPath.split('/').last}');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleDefaultImageSelection(
    File image,
    bool isCover,
  ) async {
    final file = await _getFileFromAsset(image.path);
    if (isCover) {
      selectedCoverImage.value = image.path;
      coverImage.value = file;
    } else {
      selectedProfileImage.value = image.path;
      profileImage.value = file;
    }
  }

  void showImageSelectionDialog(BuildContext context, {bool isCover = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MixedText(
                      isCover
                          ? 'select_cover_image'.tr
                          : 'select_profile_image'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF666666)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Default Images Section
                MixedText(
                  'default_images'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: isCover
                        ? defaultCoverImages.length
                        : defaultProfileImages.length,
                    itemBuilder: (context, index) {
                      final imagePath = isCover
                          ? defaultCoverImages[index]
                          : defaultProfileImages[index];
                      final isSelected = isCover
                          ? selectedCoverImage.value == imagePath
                          : selectedProfileImage.value == imagePath;

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ZoomTapAnimation(
                          onTap: () async {
                            await _handleDefaultImageSelection(
                              File(imagePath),
                              isCover,
                            );
                            Get.back();
                          },
                          child: Container(
                            width: 100,
                            height:
                                100, // Fixed height to maintain aspect ratio
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit
                                    .expand, // Ensure stack fills the container
                                children: [
                                  Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    width: double.infinity, // Fill the width
                                    height: double.infinity, // Fill the height
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                  if (isSelected)
                                    Container(
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Custom Image Section
                MixedText(
                  'custom_image'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceButton(
                      icon: Icons.camera_alt,
                      label: 'camera'.tr,
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          // Request camera permission first
                          final permissionManager = PermissionManager();
                          final cam = await permissionManager.requestPermission(
                            AppPermission.camera,
                            showBottomSheetOnDenial: true,
                          );
                          if (!cam.granted) {
                            return;
                          }

                          final ImagePicker picker = ImagePicker();
                          XFile? image;
                          if (Platform.isMacOS) {
                            snackBar(
                              title: 'camera'.tr,
                              message: 'camera_not_available_macos'.tr,
                            );
                            // Add initial compression to reduce memory usage
                            // For profile images, limit to 1024x1024 with 85% quality
                            image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth:
                                  isCover ? 1920 : 1024, // Cover can be larger
                              maxHeight: isCover ? 1080 : 1024,
                              imageQuality:
                                  85, // Good quality for profile images
                            );
                            if (image != null) {
                              if (isCover) {
                                coverImage.value = File(image.path);
                              } else {
                                // Crop profile image before setting
                                final croppedFile =
                                    await _cropImage(File(image.path));
                                if (croppedFile != null) {
                                  profileImage.value = croppedFile;
                                }
                              }
                            }
                          } else {
                            // Add initial compression to reduce memory usage
                            // For profile images, limit to 1024x1024 with 85% quality
                            image = await picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth:
                                  isCover ? 1920 : 1024, // Cover can be larger
                              maxHeight: isCover ? 1080 : 1024,
                              imageQuality:
                                  85, // Good quality for profile images
                            );
                            // Show preview dialog with mirror option for camera photos
                            if (image != null) {
                              await _showCameraPhotoPreview(
                                context,
                                File(image.path),
                                isCover: isCover,
                              );
                            }
                          }
                        } catch (e) {
                        }
                      },
                    ),
                    _buildImageSourceButton(
                      icon: Icons.photo_library,
                      label: 'gallery'.tr,
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          // Web doesn't need permission checks - browser handles it
                          if (kIsWeb) {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: isCover ? 1920 : 1024,
                              maxHeight: isCover ? 1080 : 1024,
                              imageQuality: 85,
                            );

                            if (image != null) {
                              if (isCover) {
                                // On web, use blob URL directly
                                coverImage.value = File(image.path);
                              } else {
                                // On web, skip crop dialog and use image directly
                                profileImage.value = File(image.path);
                              }
                            }
                            return;
                          }

                          final permissionManager = PermissionManager();

                          // On iOS, ImagePicker can access limited photos, so we only block if permanently denied
                          // On other platforms, require granted permission
                          if (Platform.isIOS) {
                            // Request permission, but don't show bottom sheet for limited access scenarios
                            await permissionManager.requestPermission(
                              AppPermission.photos,
                              showBottomSheetOnDenial:
                                  false, // Don't show bottom sheet automatically
                            );

                            // Check if permission is permanently denied
                            final permissionStatus =
                                await permissionManager.getPermissionStatus(
                              AppPermission.photos,
                            );

                            // Only block if permanently denied or restricted
                            if (permissionStatus ==
                                    PermissionStatus.permanentlyDenied ||
                                permissionStatus ==
                                    PermissionStatus.restricted) {
                              // Show bottom sheet for permanently denied
                              await permissionManager.showPermissionBottomSheet(
                                AppPermission.photos,
                              );
                              return;
                            }
                            // For other statuses (granted, denied, limited), allow ImagePicker to proceed
                            // ImagePicker can handle limited access scenarios
                          } else {
                            // On non-iOS platforms, request permission normally
                            final photos =
                                await permissionManager.requestPermission(
                              AppPermission.photos,
                              showBottomSheetOnDenial: true,
                            );

                            // On macOS, if photos permission is denied, use FilePicker instead
                            if (Platform.isMacOS && !photos.granted) {
                              try {
                                final FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );

                                if (result != null &&
                                    result.files.single.path != null) {
                                  final file = File(result.files.single.path!);
                                  if (isCover) {
                                    coverImage.value = file;
                                  } else {
                                    // Crop profile image before setting
                                    final croppedFile = await _cropImage(file);
                                    if (croppedFile != null) {
                                      profileImage.value = croppedFile;
                                    }
                                  }
                                }
                              } catch (e) {
                              }
                              return;
                            }

                            // For other platforms, if permission is denied, return
                            if (!photos.granted) {
                              return;
                            }
                          }

                          final ImagePicker picker = ImagePicker();
                          // Add initial compression to reduce memory usage
                          // For profile images, limit to 1024x1024 with 85% quality
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth:
                                isCover ? 1920 : 1024, // Cover can be larger
                            maxHeight: isCover ? 1080 : 1024,
                            imageQuality: 85, // Good quality for profile images
                          );
                          if (image != null) {
                            if (isCover) {
                              coverImage.value = File(image.path);
                            } else {
                              // Crop profile image before setting
                              final croppedFile =
                                  await _cropImage(File(image.path));
                              if (croppedFile != null) {
                                profileImage.value = croppedFile;
                              }
                            }
                          }
                        } catch (e) {
                        }
                      },
                    ),
                  ],
                ),
                if ((isCover && coverImage.value != null) ||
                    (!isCover && profileImage.value != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: FillButton(
                        color: Colors.red,
                        name: 'clear_image'.tr,
                        onTap: () {
                          if (isCover) {
                            clearCoverImage();
                          } else {
                            clearProfileImage();
                          }
                          Navigator.pop(context);
                        },
                        icon: Icons.delete,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FillButton(
      name: label,
      icon: icon,
      onTap: onTap,
    );
  }

  // Add this new method
  Future<void> _loadLanguagePreference() async {
    try {
      final savedLanguageRaw = storage.read('language') ?? 'English';
      final normalizedLanguage = _normalizeLanguageKey(savedLanguageRaw);
      currentLanguage.value = normalizedLanguage;
      selectedLanguage.value = normalizedLanguage;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final localeString = languageCodes[normalizedLanguage] ?? 'en_US';
        final localeParts = localeString.split('_');
        final locale = localeParts.length > 1
            ? Locale(localeParts[0], localeParts[1])
            : Locale(localeParts[0]);
        Get.updateLocale(locale);
      });
    } catch (e) {}
  }

  void addSocialMediaField({String? platform}) {
    socialMediaControllers.add(TextEditingController());
    socialMediaPlatforms.add(platform ?? '');
  }

  void removeSocialMediaField(int index) {
    if (index < socialMediaControllers.length) {
      socialMediaControllers[index].dispose();
      socialMediaControllers.removeAt(index);
      socialMediaPlatforms.removeAt(index);
    }
  }

  void updateSocialMediaPlatform(int index, String platform) {
    if (index < socialMediaPlatforms.length) {
      socialMediaPlatforms[index] = platform;
    }
  }

  void updateSocialMediaUrl(int index, String platform, String url) {
    if (index < socialMediaControllers.length) {
      // Only update text if it's different to avoid cursor/selection issues
      if (socialMediaControllers[index].text != url) {
        socialMediaControllers[index].text = url;
      }
      // Only update platform if it's different to avoid unnecessary rebuilds
      if (socialMediaPlatforms[index] != platform) {
        socialMediaPlatforms[index] = platform;
      }
    }
  }

  // Add this method to handle unblocking users
  void unblockUser(String userId) {
    try {
      blockedUsers.removeWhere((user) => user['id'] == userId);
      snackBar(
        title: 'success'.tr,
        message: 'user_has_been_unblocked_successfully'.tr,
      );
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_unblock_user'.tr,
        isWarning: true,
      );
    }
  }

  // Add this method to handle blocking users
  void blockUser(String userId, String name, String username) {
    try {
      blockedUsers.add({'id': userId, 'name': name, 'username': username});
      snackBar(
        title: 'success'.tr,
        message: 'user_has_been_blocked_successfully'.tr,
      );
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_block_user'.tr,
        isWarning: true,
      );
    }
  }

  void updateProfile() {
    storage.write('userName', fullNameController.value.text);
    storage.write('userUsername', usernameController.value.text);
    storage.write('userEmail', emailController.value.text);
    storage.write('userPhone', phoneController.value.text);
    Get.back();
  }

  // New settings methods
  void updateAudioOutput(String value) async {
    try {
      // Show loading state
      isChangingAudioOutput.value = true;

      // Find the corresponding device in the audio service
      AudioDeviceType targetType;
      switch (value) {
        case 'earpiece':
          targetType = AudioDeviceType.earpiece;
          break;
        case 'bluetooth_device':
          targetType = AudioDeviceType.bluetooth;
          break;
        case 'speaker':
        default:
          targetType = AudioDeviceType.speaker;
          break;
      }

      // Find the device with matching port
      final device = audioOutputService.availableDevices
          .firstWhereOrNull((device) => device.type == targetType);

      if (device != null) {
        final success = await audioOutputService.setAudioOutputDevice(device);
        if (success) {
          selectedAudioOutput.value = value;
          snackBar(
            title: 'audio_output_updated'.tr,
            message: '${'audio_output_has_been_set_to'.tr} ${value}',
          );
        } else {
          snackBar(
            title: 'oops'.tr,
            message: 'failed_to_change_audio_output'.tr,
            isWarning: true,
          );
        }
      } else {
        // If no matching device, fall back to simple storage
        selectedAudioOutput.value = value;
        storage.write('audioOutput', value);
        snackBar(
          title: 'audio_output_updated'.tr,
          message: '${'audio_output_has_been_set_to'.tr} ${value}',
        );
      }
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_change_audio_output'.tr,
        isWarning: true,
      );
    } finally {
      // Finish loading
      isChangingAudioOutput.value = false;
    }
  }

  void updateMediaQuality(String value) {
    selectedMediaQuality.value = value;
    storage.write('mediaQuality', value);
    snackBar(
      title: 'media_quality_updated'.tr,
      message: '${'media_quality_has_been_set_to'.tr} ${value}',
    );
  }

  void updateMessageTone(String value) {
    selectedMessageTone.value = value;
    storage.write('messageTone', value);
    snackBar(
      title: 'message_tone_updated'.tr,
      message: '${'message_tone_has_been_set_to'.tr} ${value}',
    );
  }

  void updateCallRingtone(String value) {
    selectedCallRingtone.value = value;
    storage.write('callRingtone', value);
    snackBar(
      title: 'call_ringtone_updated'.tr,
      message: '${'call_ringtone_has_been_set_to'.tr} ${value}',
    );
  }

  void _loadSettings() {
    selectedAudioOutput.value = storage.read('audioOutput') ?? 'speaker';
    selectedMediaQuality.value = storage.read('mediaQuality') ?? 'auto';
    selectedMessageTone.value = storage.read('messageTone') ?? 'default';
    selectedCallRingtone.value = storage.read('callRingtone') ?? 'default';

    // Load data usage settings
    selectedPhotoDownload.value = storage.read('photoDownload') ?? 'wi-fi_only';
    selectedAudioDownload.value = storage.read('audioDownload') ?? 'wi-fi_only';
    selectedVideoDownload.value = storage.read('videoDownload') ?? 'wi-fi_only';
    selectedDocumentDownload.value =
        storage.read('documentDownload') ?? 'wi-fi_only';

    // Initialize notification settings with default values
    settingsPreference.value = {
      'enter_to_send': storage.read('enterToSend') ?? false,
      'media_auto_download': storage.read('mediaAutoDownload') ?? true,
      'answer_with_volume_button':
          storage.read('answer_with_volume_button') ?? false,
      'low_data_calls': storage.read('lowDataCalls') ?? false,
      'vibrate': storage.read('vibrate') ?? true,
      'mobile_data_download': storage.read('mobileDataDownload') ?? false,
      'wifi_download': storage.read('wifiDownload') ?? true,
    };
  }

  // Add this method to clean baseUrl from gallery items
  List<String> _cleanGalleryUrls(List<String>? gallery) {
    if (gallery == null) return [];

    return gallery.map((url) {
      if (url.contains(baseUrl)) {
        return url.replaceAll(baseUrl, '');
      }
      return url;
    }).toList();
  }

  Future<void> loadUserProfileData() async {

    // If no cache, load from auth controller
    _updateControllersFromProfile(authController.user.value);

    // Ensure reactive URLs are properly set
    _initializeReactiveImageUrls();
  }

  void _updateControllersFromProfile(UserModel profile) {
    try {
      fullNameController.value.text = profile.fullname;
      usernameController.value.text = profile.username;
      phoneController.value.text = profile.phoneNumber;
      emailController.value.text = profile.email;
      bioController.value.text = profile.bio;
    } catch (e) {
      return;
    }

    // Update reactive text length counters
    fullNameTextLength.value = profile.fullname.length;
    usernameTextLength.value = profile.username.length;
    emailTextLength.value = profile.email.length;
    bioTextLength.value = profile.bio.length;

    final savedInterests = profile.interests;
    if (savedInterests != null && savedInterests.toString().isNotEmpty) {
      interestsController.value.text =
          savedInterests.toString().replaceAll(RegExp(r'[\\[\\]]'), '');
    }

    // Load gallery data - CRITICAL: Never clear displayGallery if it has valid data
    // Only update if profile has gallery data, otherwise preserve what we have
    // Make a COPY of profile.gallery to avoid issues if it gets modified
    final profileGallery =
        profile.gallery != null ? List<String>.from(profile.gallery!) : null;
    final currentDisplayGallery = List<String>.from(displayGallery);

    if (profileGallery != null && profileGallery.isNotEmpty) {
      // Filter out local file paths - only keep URLs (http/https) or relative paths that are URLs
      // Local file paths are typically absolute paths starting with /Users, /tmp, etc. or containing file://
      final filteredGallery = profileGallery.where((url) {
        // Keep URLs that start with http:// or https://
        if (url.startsWith('http://') || url.startsWith('https://')) {
          return true;
        }
        // Keep relative paths that look like URLs (contain /uploads/ or similar API paths)
        if (url.startsWith('/') &&
            (url.contains('/uploads/') || url.contains('uploads/'))) {
          return true;
        }
        // Filter out local file paths (absolute paths like /Users/..., /tmp/..., file://, etc.)
        if (url.startsWith('/Users/') ||
            url.startsWith('/tmp/') ||
            url.startsWith('file://') ||
            url.contains('\\') || // Windows paths
            (!url.startsWith('http') &&
                !url.startsWith('/') &&
                url.contains(':'))) {
          // Absolute paths
          return false;
        }
        // Keep other paths (could be relative URLs)
        return true;
      }).toList();

      // Profile has gallery data, use it (but filtered to remove local paths)
      displayGallery.assignAll(filteredGallery);

      // Safety check: If assignAll somehow cleared it, restore from filteredGallery
      if (displayGallery.isEmpty && filteredGallery.isNotEmpty) {
        displayGallery.assignAll(filteredGallery);
      }
    } else {
      // Profile has no gallery data (null or empty)
      // CRITICAL: Always preserve existing displayGallery if it has items
      // Only clear if displayGallery is already empty (initial load scenario)
      if (currentDisplayGallery.isEmpty) {
        // Only clear if displayGallery is already empty (initial load)
        displayGallery.assignAll([]);
      }
      // Otherwise, PRESERVE existing displayGallery - DO NOT CLEAR IT
    }
    // Don't clear uploadGallery if we're in the middle of an image upload operation
    if (!isUserUpdateImage.value) {
      uploadGallery.clear(); // Start with empty upload gallery
    }

    // Check if there are any image changes before updating reactive URLs
    final hasImageChanges = profileImage.value != null ||
        coverImage.value != null ||
        uploadGallery.isNotEmpty;

    // Only update reactive image URLs if there are image changes or if they're currently empty
    if (hasImageChanges || currentCoverImageUrl.value.isEmpty) {
      currentCoverImageUrl.value =
          profile.coverImageUrl.isNotEmpty ? profile.coverImageUrl : '';
    }

    if (hasImageChanges || currentAvatarImageUrl.value.isEmpty) {
      currentAvatarImageUrl.value =
          profile.avatarUrl.isNotEmpty ? profile.avatarUrl : '';
    }

    // Load social media data if available
    final socialMediaData = profile.socialMedia;
    if (socialMediaData != null && socialMediaData.isNotEmpty) {
      receiveSocialMediaData(socialMediaData);
    }
    updateCurrentPhotosGallery();
  }

  // Data usage methods
  void updatePhotoDownload(String value) {
    selectedPhotoDownload.value = value;
    storage.write('photoDownload', value);
    snackBar(
      title: 'photo_download_setting_updated'.tr,
      message: '${'photo_auto_download_has_been_set_to'.tr} ${value.tr}',
    );
  }

  void updateAudioDownload(String value) {
    selectedAudioDownload.value = value;
    storage.write('audioDownload', value);
    snackBar(
      title: 'audio_download_setting_updated'.tr,
      message: '${'audio_auto_download_has_been_set_to'.tr} ${value.tr}',
    );
  }

  void updateVideoDownload(String value) {
    selectedVideoDownload.value = value;
    storage.write('videoDownload', value);
    snackBar(
      title: 'video_download_setting_updated'.tr,
      message: '${'video_auto_download_has_been_set_to'.tr} ${value.tr}',
    );
  }

  void updateDocumentDownload(String value) {
    selectedDocumentDownload.value = value;
    storage.write('documentDownload', value);
    snackBar(
      title: 'document_download_setting_updated'.tr,
      message: '${'document_auto_download_has_been_set_to'.tr} ${value.tr}',
    );
  }

  // Optimized method to handle gallery operations
  Future<void> handleGalleryOperation({
    required String imagePath,
    required bool isAdding,
  }) async {
    try {
      if (!isEditMode.value) {
        snackBar(
          title: 'oops'.tr,
          message: isAdding
              ? 'please_enable_edit_mode_to_add_photos'.tr
              : 'please_enable_edit_mode_to_remove_photos'.tr,
          isWarning: true,
        );
        return;
      }

      isLoading.value = true;

      if (isAdding) {
        // Check for duplicates before adding
        if (uploadGallery.contains(imagePath)) {
          snackBar(
            title: 'oops'.tr,
            message: 'photo_already_exists_in_gallery'.tr,
            isWarning: true,
          );
          return;
        }

        // Check if gallery is full
        if (uploadGallery.length >= maxGalleryPhotos) {
          snackBar(
            title: 'oops'.tr,
            message: 'maximum_10_photos_allowed'.tr,
            isWarning: true,
          );
          return;
        }

        // Validate image file (only for local files, not URLs)
        if (!imagePath.startsWith('http://') &&
            !imagePath.startsWith('https://')) {
          final isValid = await FileValidationService.validateWithUserFeedback(
            filePath: imagePath,
            showSnackbar: true,
          );
          if (!isValid) {
            return;
          }
        }

        // Compress image before adding to gallery (only for local files, not URLs)
        String finalImagePath = imagePath;
        if (!imagePath.startsWith('http://') &&
            !imagePath.startsWith('https://')) {
          try {
            final imageFile = File(imagePath);
            if (await imageFile.exists()) {
              final compressedFile =
                  await ImageCompressor.compressImage(imageFile);
              if (compressedFile != null && await compressedFile.exists()) {
                final originalSize = await imageFile.length();
                final compressedSize = await compressedFile.length();

                // Use compressed file if it's actually smaller
                if (compressedSize < originalSize) {
                  finalImagePath = compressedFile.path;
                } else {
                }
              } else {
              }
            }
          } catch (e) {
            // Continue with original image if compression fails
          }
        }

        uploadGallery.add(finalImagePath);
      } else {
        // Remove from both galleries if present
        if (displayGallery.contains(imagePath)) {
          displayGallery.remove(imagePath);
        }
        if (uploadGallery.contains(imagePath)) {
          uploadGallery.remove(imagePath);
        }
      }

      // Update the displayed photos gallery after changes
      updateCurrentPhotosGallery();

      snackBar(
        title: 'success'.tr,
        message: isAdding
            ? 'photo_added_successfully'.tr
            : 'photo_removed_successfully'.tr,
      );
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message:
            isAdding ? 'failed_to_add_photo'.tr : 'failed_to_remove_photo'.tr,
        isWarning: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Simplified updateGallery method
  Future<void> updateGallery(String imagePath) async {
    await handleGalleryOperation(imagePath: imagePath, isAdding: true);
  }

  // Simplified removeFromGallery method
  Future<void> removeFromGallery(String imagePath) async {
    await handleGalleryOperation(imagePath: imagePath, isAdding: false);
  }

  // Cache management methods
  Future<void> calculateCacheSizes() async {
    try {
      isCalculatingStorage.value = true;
      isClearingCache.value = true;
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getCacheDirectory();

      // Category folders to check
      final Map<String, List<String>> categoryPaths = {
        'Images': ['images', 'thumbnails', '.jpg', '.jpeg', '.png', '.gif'],
        'Videos': ['videos', '.mp4', '.mov', '.avi'],
        'Audio': ['audio', 'voice', '.mp3', '.wav', '.aac', '.m4a'],
        'Documents': [
          'documents',
          '.pdf',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.txt'
        ],
      };

      final Map<String, int> categorySizes = {};
      categoryPaths.keys.forEach((key) => categorySizes[key] = 0);

      bool isInCategory(String path, String category) {
        final pathLower = path.toLowerCase();
        return categoryPaths[category]!
            .any((marker) => pathLower.contains(marker));
      }

      // Scan temp directory (unchanged)
      if (await tempDir.exists()) {
        final tempFiles = await tempDir.list(recursive: true).toList();
        for (final entity in tempFiles) {
          if (entity is File) {
            final stat = await entity.stat();
            for (final category in categoryPaths.keys) {
              if (isInCategory(entity.path, category)) {
                categorySizes[category] =
                    (categorySizes[category] ?? 0) + stat.size;
                break;
              }
            }
          }
        }
      }

      // Scan cache directory (instead of appDir)
      if (await cacheDir.exists()) {
        final cacheFiles = await cacheDir.list(recursive: true).toList();
        for (final entity in cacheFiles) {
          if (entity is File) {
            final stat = await entity.stat();
            for (final category in categoryPaths.keys) {
              if (isInCategory(entity.path, category)) {
                categorySizes[category] =
                    (categorySizes[category] ?? 0) + stat.size;
                break;
              }
            }
          }
        }
      }

      for (final category in categoryPaths.keys) {
        final sizeInBytes = categorySizes[category] ?? 0;
        mediaCacheSizes[category] = _formatFileSize(sizeInBytes);
      }
      final totalSize =
          categorySizes.values.fold<int>(0, (sum, size) => sum + size);
      cacheSize.value = _formatFileSize(totalSize);
    } catch (e) {
    } finally {
      isClearingCache.value = false;
      isCalculatingStorage.value = false;
    }
  }

  // Helper method to format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Helper to get the cache directory in app documents
  Future<Directory> getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/GateKhmerCache');
    if (!(await cacheDir.exists())) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  // Helper to delete files of a specific category
  Future<int> deleteCategoryFiles(String category) async {
    int deletedBytes = 0;
    final tempDir = await getTemporaryDirectory();
    final cacheDir = await getCacheDirectory();

    final Map<String, List<String>> categoryMarkers = {
      'Images': [
        'images',
        'thumbnails',
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        'libCachedImageData'
      ],
      'Videos': ['videos', '.mp4', '.mov', '.avi'],
      'Audio': ['audio', 'voice', '.mp3', '.wav', '.aac', '.m4a'],
      'Documents': [
        'documents',
        '.pdf',
        '.doc',
        '.docx',
        '.xls',
        '.xlsx',
        '.txt'
      ],
    };

    bool isInCategory(String path, String category) {
      final pathLower = path.toLowerCase();
      return categoryMarkers[category]!
          .any((marker) => pathLower.contains(marker));
    }

    // Clear temp directory files (unchanged)
    if (await tempDir.exists()) {
      try {
        final tempFiles = await tempDir.list(recursive: true).toList();
        for (final entity in tempFiles) {
          if (entity is File && isInCategory(entity.path, category)) {
            try {
              if (await entity.exists()) {
                final stat = await entity.stat();
                deletedBytes += stat.size;
                await entity.delete();
              }
            } catch (e) {
            }
          }
        }
      } catch (e) {
      }
    }

    // Clear cache directory files (instead of appDir)
    if (await cacheDir.exists()) {
      try {
        final cacheFiles = await cacheDir.list(recursive: true).toList();
        for (final entity in cacheFiles) {
          if (entity is File && isInCategory(entity.path, category)) {
            try {
              if (await entity.exists()) {
                final stat = await entity.stat();
                deletedBytes += stat.size;
                await entity.delete();
              }
            } catch (e) {
            }
          }
        }
      } catch (e) {
      }
    }

    return deletedBytes;
  }

  /// Reset all settings to default values (called during logout)
  Future<void> resetSettings() async {
    try {

      // Clear all settings from storage
      await storage.remove('language');
      await storage.remove('audioOutput');
      await storage.remove('mediaQuality');
      await storage.remove('messageTone');
      await storage.remove('callRingtone');
      await storage.remove('photoDownload');
      await storage.remove('audioDownload');
      await storage.remove('videoDownload');
      await storage.remove('documentDownload');
      await storage.remove('enterToSend');
      await storage.remove('mediaAutoDownload');
      await storage.remove('answer_with_volume_button');
      await storage.remove('lowDataCalls');
      await storage.remove('vibrate');
      await storage.remove('mobileDataDownload');
      await storage.remove('wifiDownload');
      await storage.remove('userName');
      await storage.remove('userUsername');
      await storage.remove('userEmail');
      await storage.remove('userPhone');


      // Reset settings preferences to default
      settingsPreference.value = {
        'push_notifications': true,
        'sound': true,
      };

      // Reset privacy settings to default
      privacySettings.value = {
        'two_factor_authentication': false,
        'profile_visibility': true,
      };

      // Reset accent color
      accentColor.value = AppColors.primary;

      // Reset audio and media settings
      selectedAudioOutput.value = 'speaker';
      selectedMediaQuality.value = 'auto';
      selectedMessageTone.value = 'default';
      selectedCallRingtone.value = 'default';

      // Reset data usage settings
      selectedPhotoDownload.value = 'wifi_only';
      selectedAudioDownload.value = 'wifi_only';
      selectedVideoDownload.value = 'wifi_only';
      selectedDocumentDownload.value = 'wifi_only';

      // Reset user interface settings
      selectedTheme.value = 'system';
      selectedLanguage.value = 'English';
      currentLanguage.value = 'English';

    } catch (e) {
    }
  }

  Future<void> clearCache({String? mediaType, bool showSnackbar = true}) async {
    try {
      isClearingCache.value = true;

      try {
        await MessageModel.clearMediaCache();
      } catch (e) {
      }

      // Clean up any corrupted files referenced by cache before DB wipe
      try {
        await MessageCacheDbHelper().cleanupCorruptedFiles();
      } catch (e) {
      }

      // Also clear SQLite-based caches (decrypted content, metadata, media files, stickers)
      try {
        await MessageCacheDbHelper().clearAllCache();
      } catch (e) {
      }

      if (mediaType != null) {
        final deletedBytes = await deleteCategoryFiles(mediaType);
        mediaCacheSizes[mediaType] = '0 B';

        if (showSnackbar) {
          snackBar(
            title: 'cache_cleared'.tr,
            message:
                '${mediaType} ${'cache_has_been_cleared'.tr} (${_formatFileSize(deletedBytes)})',
          );
        }
      } else {
        int totalDeleted = 0;
        for (final category in mediaCacheSizes.keys) {
          totalDeleted += await deleteCategoryFiles(category);
          mediaCacheSizes[category] = '0 B';
        }


        // Cache is cleared by deleteCategoryFiles above which removes files from directories
        // CachedNetworkImage.evictFromCache('') with empty string causes errors

        cacheSize.value = '0 B';
        if (showSnackbar) {
          snackBar(
            title: 'cache_cleared'.tr,
            message: 'all_cache_has_been_cleared'.tr +
                ' (${_formatFileSize(totalDeleted)})',
          );
        }
      }
    } catch (e) {
      if (showSnackbar) {
        snackBar(
          title: 'oops'.tr,
          message: 'failed_to_clear_cache'.tr,
          isWarning: true,
        );
      }
    } finally {
      calculateCacheSizes();
      isClearingCache.value = false;
    }
  }

  // Add this new method to receive social media data from API
  void receiveSocialMediaData(List<Map<String, String>> socialMediaData) {
    try {
      // Clear existing controllers and platforms
      for (final controller in socialMediaControllers) {
        controller.dispose();
      }
      socialMediaControllers.clear();
      socialMediaPlatforms.clear();

      // Process each social media entry
      for (final entry in socialMediaData) {
        // Each entry should have a single key-value pair
        if (entry.isNotEmpty) {
          final platform = entry.keys.first;
          final url = entry[platform] ?? '';

          // Create new controller and add the URL
          final controller = TextEditingController(text: url);
          socialMediaControllers.add(controller);
          socialMediaPlatforms.add(platform);
        }
      }

      // If no social media data, don't add empty field - let user add manually
      if (socialMediaControllers.isEmpty) {
      }
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: 'failed_to_load_social_media'.tr,
        isWarning: true,
      );
    }
  }

  void updateCurrentPhotosGallery() {
    // Process gallery paths to convert them to proper URLs
    final processedDisplayGallery = displayGallery
        .map((path) => _processGalleryPath(path))
        .where((path) => path.isNotEmpty) // Filter out invalid paths
        .toList();

    final processedUploadGallery = uploadGallery
        .map((path) => _processGalleryPath(path))
        .where((path) => path.isNotEmpty) // Filter out invalid paths
        .toList();

    getCurrentPhotosGallery.assignAll(
      isEditMode.value
          ? [...processedDisplayGallery, ...processedUploadGallery]
          : processedDisplayGallery,
    );
  }

  // Process gallery path - convert relative paths to URLs, keep local files if they exist
  String _processGalleryPath(String path) {
    if (path.isEmpty) return path;

    // If it's already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Check if it's an iOS temporary file path (these are invalid and shouldn't be stored)
    if (path.startsWith('/private/var/mobile/') ||
        path.startsWith('/private/')) {
      // iOS temp paths are invalid - these should have been uploaded to server
      // Return empty string so the invalid path is filtered out
      return '';
    }

    // First, check if it's a valid local file (macOS/Unix paths start with /, Windows with drive letter)
    // This must be checked BEFORE converting paths starting with / to URLs
    try {
      final file = File(path);
      if (file.existsSync()) {
        // It's a valid local file (newly picked on macOS/Windows/Linux, not yet uploaded)
        return path;
      }
    } catch (e) {
    }

    // If path starts with / but file doesn't exist, check if it looks like a local path
    if (path.startsWith('/')) {
      // Check if it looks like a macOS/Unix local path (e.g., /Users, /home, /tmp)
      if (path.startsWith('/Users/') ||
          path.startsWith('/home/') ||
          path.startsWith('/tmp/') ||
          path.startsWith('/var/') ||
          path.contains('/Users/') ||
          path.contains('/home/')) {
        // Looks like a local path but file doesn't exist - treat as invalid
        return '';
      }
      // Otherwise, assume it's a server relative path and convert to full URL
      return '${domain}${path.replaceFirst('/', '')}';
    }

    // Check Windows paths (C:\, D:\, etc.)
    if (Platform.isWindows && path.contains(':') && !path.contains('http')) {
      // Windows local path - already checked above, but if it got here and doesn't exist, return empty
      return '';
    }

    // Default: assume it's a relative path without leading slash, convert to full URL
    if (path.isNotEmpty && !path.contains('assets/')) {
      return '${domain}$path';
    }

    return path;
  }

  // Add this method to clear all fields
  void clearAllFields() {
    // Reset scroll control
    isLoading.value = false;

    // Reset tab selection
    selectedTab.value = 0;
    selectedTabContent.value = 0;
    isEditMode.value = false;

    // Reset settings states
    settingsPreference.value = {
      'push_notifications': true,
      'sound': true,
    };
    privacySettings.value = {
      'two_factor_authentication': false,
      'profile_visibility': true,
    };
    accentColor.value = AppColors.primary;

    // Reset audio and media settings
    selectedAudioOutput.value = 'speaker';
    selectedMediaQuality.value = 'auto';
    selectedMessageTone.value = 'default';
    selectedCallRingtone.value = 'default';

    // Reset data usage settings
    selectedPhotoDownload.value = 'wifi_only';
    selectedAudioDownload.value = 'wifi_only';
    selectedVideoDownload.value = 'wifi_only';
    selectedDocumentDownload.value = 'wifi_only';

    // Clear form controllers
    fullNameController.value.clear();
    usernameController.value.clear();
    bioController.value.clear();
    interestsController.value.clear();
    newSocialMediaController.value.clear();
    phoneController.value.clear();

    // Reset dropdown values
    selectedLanguage.value = 'English';
    selectedTheme.value = 'light';
    selectedFontSize.value = 'medium';
    selectedLoginHistory.value = 'view_all';
    selectedBlockedUsers.value = 'manage';

    // Reset profile visibility and online status
    profileVisibility.value = 'everyone';
    onlineStatus.value = 'everyone';

    // Reset profile images
    profileImage.value = null;
    coverImage.value = null;
    selectedProfileImage.value = '';
    selectedCoverImage.value = '';

    // Reset language and social media
    currentLanguage.value = 'English';
    socialMediaControllers.clear();
    socialMediaPlatforms.clear();
    showNewTextField.value = false;
    newPlatform.value = '';
    isSelected.value = false;

    // Reset blocked users list
    blockedUsers.value = [
      {'id': '1', 'name': 'User 1', 'username': '@user1'},
      {'id': '2', 'name': 'User 2', 'username': '@user2'},
      {'id': '3', 'name': 'User 3', 'username': '@user3'},
    ];

    // Reset cache management
    cacheSize.value = '0 MB';
    isClearingCache.value = false;
    mediaCacheSizes.value = {
      'Images': '0 MB',
      'Videos': '0 MB',
      'Audio': '0 MB',
      'Documents': '0 MB',
    };

    // Reset gallery
    displayGallery.clear();
    uploadGallery.clear();
    getCurrentPhotosGallery.clear();
    isUserUpdateImage.value = false;
  }

  // Show camera photo preview with mirror option
  /// Crop image for profile picture (square 1:1 aspect ratio)
  /// Falls back to automatic center crop on platforms where ImageCropper is not available
  Future<File?> _cropImage(File imageFile) async {
    // Use ImageCropper on supported platforms (Android, iOS, Web)
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      // For desktop platforms, use automatic center crop as fallback
      return await _cropImageAutomatic(imageFile);
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'crop_image'.tr,
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'crop_image'.tr,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
          WebUiSettings(
            context: Get.context!,
          ),
        ],
      );

      if (croppedFile != null) {
        // On web, skip compression since ImageCompressor uses getTemporaryDirectory()
        if (kIsWeb) {
          return File(croppedFile.path);
        }

        // Compress the cropped image to optimize file size (non-web platforms)
        // This avoids double encoding since ImageCropper may not compress optimally
        final compressedFile = await ImageCompressor.compressProfileImage(
          File(croppedFile.path),
        );
        return compressedFile ?? File(croppedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      // Handle platform-specific errors (like missing UCropActivity)
      // Fallback to automatic crop if ImageCropper fails
      return await _cropImageAutomatic(imageFile);
    } catch (e, stackTrace) {
      // Handle any other errors
      // Fallback to automatic crop if ImageCropper fails
      return await _cropImageAutomatic(imageFile);
    }
  }

  /// Automatic center crop fallback for platforms without ImageCropper support
  /// Compresses the image after cropping to optimize file size
  Future<File?> _cropImageAutomatic(File imageFile) async {
    try {
      // Read the image file
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        return null;
      }

      final width = originalImage.width;
      final height = originalImage.height;

      // Determine the size of the square (use the smaller dimension)
      final size = width < height ? width : height;

      // Calculate the starting position to center the crop
      final x = (width - size) ~/ 2;
      final y = (height - size) ~/ 2;

      // Crop the image to a square
      final croppedImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // Resize if image is larger than 512x512 to optimize file size
      img.Image finalImage = croppedImage;
      if (finalImage.width > 512 || finalImage.height > 512) {
        finalImage = img.copyResize(
          croppedImage,
          width: 512,
          height: 512,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with quality 85 (better than PNG for photos, smaller file size)
      final croppedBytes = img.encodeJpg(finalImage, quality: 85);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final croppedFilePath =
          '${tempDir.path}/cropped_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(croppedFilePath);
      await croppedFile.writeAsBytes(croppedBytes);

      return croppedFile;
    } catch (e) {
      snackBar(
        title: 'error'.tr,
        message: 'failed_to_crop_image'.tr,
        isWarning: true,
      );
      return null;
    }
  }

  Future<void> _showCameraPhotoPreview(
    BuildContext context,
    File imageFile, {
    required bool isCover,
  }) async {
    final isMirrored = false.obs;
    final currentImagePath = imageFile.path.obs;
    File currentImageFile = imageFile;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MixedText(
                      'preview_photo'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Preview Image
                Obx(() {
                  return Container(
                    constraints: BoxConstraints(
                      maxHeight: Get.height * 0.4,
                      maxWidth: Get.width,
                    ),
                    child: Image.file(
                      File(currentImagePath.value),
                      fit: BoxFit.contain,
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    // Mirror Button
                    Expanded(
                      child: Obx(() {
                        return OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final mirroredFile =
                                  await ImageCompressor.mirrorImageHorizontally(
                                      currentImageFile);
                              if (mirroredFile != null) {
                                // Delete old temp file if it was mirrored before
                                if (currentImageFile.path
                                    .contains('mirrored_')) {
                                  try {
                                    await currentImageFile.delete();
                                  } catch (_) {}
                                }
                                currentImageFile = mirroredFile;
                                currentImagePath.value = mirroredFile.path;
                                isMirrored.value = !isMirrored.value;
                              }
                            } catch (e) {
                            }
                          },
                          icon: Icon(
                            Icons.flip,
                            color: isMirrored.value
                                ? AppColors.primary
                                : Colors.grey[600],
                          ),
                          label: MixedText(
                            isMirrored.value ? 'unmirror'.tr : 'mirror'.tr,
                            style: TextStyle(
                              color: isMirrored.value
                                  ? AppColors.primary
                                  : Colors.grey[600],
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isMirrored.value
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    // Use Photo Button
                    Expanded(
                      flex: 2,
                      child: FillButton(
                        name: 'use_photo'.tr,
                        icon: Icons.check,
                        color: AppColors.primary,
                        onTap: () async {
                          Navigator.of(modalContext).pop();
                          if (isCover) {
                            coverImage.value = currentImageFile;
                          } else {
                            // Crop profile image before setting
                            final croppedFile =
                                await _cropImage(currentImageFile);
                            if (croppedFile != null) {
                              profileImage.value = croppedFile;
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onClose() {
    // Dispose text controllers
    fullNameController.value.dispose();
    usernameController.value.dispose();
    emailController.value.dispose();
    bioController.value.dispose();
    interestsController.value.dispose();
    phoneController.value.dispose();
    newSocialMediaController.value.dispose();

    // Dispose social media controllers
    for (final controller in socialMediaControllers) {
      controller.dispose();
    }

    super.onClose();
  }
}
