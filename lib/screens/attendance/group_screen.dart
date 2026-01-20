import 'dart:async';
import 'dart:convert'; // Added for jsonDecode
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' show GetPlatform;
import 'package:gate_khmer_ai/core/config/background/bg_screen.dart';
import 'package:gate_khmer_ai/core/config/snack_bar.dart';
import 'package:gate_khmer_ai/core/config/spacing.dart';
import 'package:gate_khmer_ai/core/constants/controllers.dart';
import 'package:gate_khmer_ai/core/constants/icon_logo_widget.dart';
import 'package:gate_khmer_ai/core/theme/colors.dart';
import 'package:gate_khmer_ai/core/theme/text_style.dart';
import 'package:gate_khmer_ai/core/tour/services/custom_tour_service.dart';
import 'package:gate_khmer_ai/core/utils/font_utils.dart';
import 'package:gate_khmer_ai/core/utils/format_time_stamp.dart';
import 'package:gate_khmer_ai/core/utils/group_list_shimmer.dart';
import 'package:gate_khmer_ai/core/utils/highlighted_text.dart';
import 'package:gate_khmer_ai/core/utils/loading_indicator.dart';
import 'package:gate_khmer_ai/core/utils/responsive_utils.dart';
import 'package:gate_khmer_ai/core/utils/user_status_utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:gate_khmer_ai/core/utils/vibration_utils.dart';
import 'package:gate_khmer_ai/core/widgets/cross_platform_gesture_detector.dart';
import 'package:gate_khmer_ai/core/widgets/mixed_text.dart';
import 'package:gate_khmer_ai/features/screens/group/controllers/group_folder_controller.dart';
import 'package:gate_khmer_ai/features/screens/group/models/group_folders/folders_group_response.dart';
import 'package:gate_khmer_ai/features/screens/group/models/groups/groups_list_response.dart';
import 'package:gate_khmer_ai/features/screens/group/views/group_detail/group_chat_detail_screen.dart';
import 'package:gate_khmer_ai/features/screens/group/views/group_dialog.dart';
import 'package:gate_khmer_ai/features/screens/group/views/group_folder_dialog.dart';
import 'package:gate_khmer_ai/features/screens/group/views/widgets/group_folder_list_shimmer.dart';
import 'package:get/get.dart';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'package:gate_khmer_ai/core/widgets/resizable_desktop_split_view.dart';
import 'package:gate_khmer_ai/core/widgets/desktop_navigation_toggle.dart';
import 'package:gate_khmer_ai/core/widgets/desktop_search_bar.dart';
import 'package:gate_khmer_ai/features/components/global_screen_header/global_screen_header.dart';
import 'package:gate_khmer_ai/features/components/drawer/views/custom_drawer.dart';

// Helper to convert a hex color string like '#fee440' to a Color
Color colorFromHex(String hexColor) {
  final buffer = StringBuffer();
  if (hexColor.length == 6 || hexColor.length == 7) buffer.write('ff');
  buffer.write(hexColor.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

// Helper to map a string icon name to IconData
IconData iconFromString(String iconName) {
  switch (iconName) {
    case 'folder':
      return Icons.folder;
    case 'group':
      return Icons.group;
    case 'star':
      return Icons.star;
    // Add more mappings as needed
    default:
      return Icons.folder;
  }
}

/// Check if text is AppFlowy JSON format
bool _isAppFlowyJson(String text) {
  if (text.isEmpty) return false;
  try {
    final Map<String, dynamic> json = jsonDecode(text);
    return json.containsKey('document') &&
        json['document'] is Map<String, dynamic> &&
        json['document'].containsKey('children');
  } catch (e) {
    return false;
  }
}

/// Convert AppFlowy JSON to formatted text
String _convertAppFlowyToText(String jsonString) {
  try {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final textParts = <String>[];
    if (json.containsKey('document')) {
      final document = json['document'] as Map<String, dynamic>;
      if (document.containsKey('children')) {
        final children = document['children'] as List;
        _processAppFlowyChildren(children, textParts, 0);
      }
    }
    return textParts.join('\n');
  } catch (e) {
    return jsonString;
  }
}

/// Process AppFlowy children and convert to text
void _processAppFlowyChildren(
    List children, List<String> textParts, int currentLevel) {
  for (final child in children) {
    if (child is Map<String, dynamic>) {
      final childType = child['type'] as String?;
      final childData = child['data'] as Map<String, dynamic>?;
      if (childData != null && childData.containsKey('delta')) {
        final delta = childData['delta'] as List;
        final text = _extractTextFromDelta(delta);
        if (text.isNotEmpty) {
          if (childType == 'heading') {
            final level = childData['level'] ?? 1;
            textParts.add('${'#' * level} $text');
          } else if (childType == 'bulleted_list') {
            textParts.add('• $text');
          } else if (childType == 'numbered_list') {
            textParts.add('1. $text');
          } else if (childType == 'quote') {
            textParts.add('> $text');
          } else if (childType == 'code') {
            textParts.add('```\n$text\n```');
          } else {
            textParts.add(text);
          }
        } else {
          textParts.add('');
        }
      }
      if (child.containsKey('children') && child['children'] is List) {
        final nestedChildren = child['children'] as List;
        _processAppFlowyChildren(nestedChildren, textParts, currentLevel + 1);
      }
    }
  }
}

/// Extract text from AppFlowy delta operations
String _extractTextFromDelta(List delta) {
  final textParts = <String>[];
  for (final operation in delta) {
    if (operation is Map<String, dynamic> && operation.containsKey('insert')) {
      final text = operation['insert'].toString();
      if (text.isNotEmpty) {
        final attributes = operation['attributes'] as Map<String, dynamic>?;
        if (attributes != null) {
          String formattedText = text;
          if (attributes['strikethrough'] == true) {
            formattedText = '~~$formattedText~~';
          }
          if (attributes['underline'] == true) {
            formattedText = '_${formattedText}_';
          }
          if (attributes['italic'] == true) {
            formattedText = '*$formattedText*';
          }
          if (attributes['bold'] == true) {
            formattedText = '**$formattedText**';
          }
          if (attributes['code'] == true) {
            formattedText = '`$formattedText`';
          }
          textParts.add(formattedText);
        } else {
          textParts.add(text);
        }
      } else {
        textParts.add('');
      }
    }
  }
  return textParts.join('');
}

class GroupScreen extends StatefulWidget {
  GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  // =============================================
  // Properties
  // =============================================
  final List<GlobalKey> showcaseKeys = List.generate(5, (index) => GlobalKey());
  final GlobalKey _groupSearchKey = GlobalKey();
  final GlobalKey _groupFoldersKey = GlobalKey();
  final GlobalKey _groupListKey = GlobalKey();
  final GlobalKey _addGroupKey = GlobalKey();
  bool _tourAttempted = false;
  int _tourRetryCount = 0;
  static const int _maxTourRetries = 5;
  final searchController = TextEditingController();
  final ScrollController _folderScrollController = ScrollController();
  Timer? _typingTimer;
  late Worker? _groupInitWorker;
  Worker? _tourWorker;

  // Search state variables using GetX
  final RxBool _showSearch = false.obs;
  final RxString _search = ''.obs;

  // Split view controller
  final ResizableDesktopSplitViewController _splitViewController = ResizableDesktopSplitViewController();
  


  // Responsive layout state - now using controller's selected group
  // final Rx<GroupListItem?> _selectedGroup = Rx<GroupListItem?>(null);

  @override
  void initState() {
    super.initState();

    _groupInitWorker =
        ever(groupController.isGroupInitializing, (bool isLoading) {

      // Early return if we're in notification mode to prevent interference
      if (groupController.isFromNotificationTap.value) {
        return;
      }

      // Also skip if navigation has already been initiated (prevents duplicate navigation)
      if (groupController.hasNavigatedToGroupChat.value) {
        return;
      }

      // Skip if we're already on GroupChatDetailScreen
      final currentRoute = Get.currentRoute.toString();
      if (currentRoute.contains('GroupChatDetailScreen')) {
        return;
      }

      if (isLoading) {
        // Loading dialog removed - messages load in background without popup
      } else {

        // Defer navigation and responsive checks to next frame to avoid locked tree and missing MediaQuery
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // Determine if large screen safely - block navigation on desktop and iPad landscape
          bool isLargeScreen = false;
          final mq = MediaQuery.maybeOf(context);
          if (mq != null) {
            final responsive = ResponsiveUtils(context);
            isLargeScreen =
                responsive.isLargeScreen && !responsive.isIPadPortrait;
          } else {
            isLargeScreen =
                false; // Default to mobile behavior to allow navigation
          }


          // Only navigate back if we're already on a group chat detail screen
          // This prevents navigation during normal user interactions
          final currentRoute = Get.currentRoute.toString();
          final isAlreadyOnGroupChatDetail =
              currentRoute.contains('GroupChatDetailScreen');

          if (isLargeScreen && isAlreadyOnGroupChatDetail) {
            // Clear the selected group to prevent auto-navigation
            groupController.clearSelectedGroup();
            // Navigate back to group list
            Get.back();
            return;
          }

          // If we're on a large screen, don't navigate to group chat detail screen
          // This prevents navigation on desktop/iPad landscape regardless of current route
          if (isLargeScreen) {
            return;
          }

          if (!isLargeScreen) {

            // Clear search when navigating to group chat detail screen
            if (_showSearch.value || _search.value.isNotEmpty) {
              _showSearch.value = false;
              _search.value = '';
              searchController.clear();
              groupController.updateSearchQuery('');
              bottomNavigationBarController.setSearchActive(false);
            }

            Get.to(
              () => GroupChatDetailScreen(
                hideDrawer: isLargeScreen,
              ),
            );
          } else {
          }
        });

        // Skip the second navigation logic to prevent interference with normal user interactions
        // The first navigation logic in the post-frame callback is sufficient
      }
    });

    // Auto-start showcase on first render (once per install unless forced)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tourAttempted) {
        _tourAttempted = true;
        try {
          if (Get.isRegistered<CustomTourService>()) {
            final tour = Get.find<CustomTourService>();

            // Check if there's already a pending tour tick
            if (tour.groupsTourTick.value > 0 &&
                tour.shouldRunGroupsTour() &&
                !tour.isActive) {
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) {
                  _startResponsiveTour(tour);
                } else {
                  try {
                    _startResponsiveTourFallback(tour);
                  } catch (e) {
                  }
                }
              });
            }

            // Listen for external tour triggers while this screen is active
            _tourWorker = ever(tour.groupsTourTick, (_) {
              // Always run tour when triggered externally, regardless of _tourAttempted

              if (tour.shouldRunGroupsTour() && !tour.isActive) {
                if (mounted) {
                  // Add a small delay to ensure screen is fully rendered
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _startResponsiveTour(tour);
                    } else {
                      try {
                        _startResponsiveTourFallback(tour);
                      } catch (e) {
                      }
                    }
                  });
                } else {
                  try {
                    _startResponsiveTourFallback(tour);
                  } catch (e) {
                  }
                }
              } else {
              }
            });
          } else {
            _startShowcaseIfReady();
          }
        } catch (_) {}
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  /// Start responsive tour based on screen size
  void _startResponsiveTour(CustomTourService tour) {

    if (!mounted) {
      return;
    }

    // Check retry limit to prevent infinite loops
    if (_tourRetryCount >= _maxTourRetries) {
      _tourRetryCount = 0; // Reset for future attempts
      return;
    }

    // Check if essential GlobalKeys have valid contexts with more robust checking
    final bool searchValid = _groupSearchKey.currentContext != null &&
        _groupSearchKey.currentContext!.mounted;
    final bool foldersValid = _groupFoldersKey.currentContext != null &&
        _groupFoldersKey.currentContext!.mounted;
    final bool groupListValid = _groupListKey.currentContext != null &&
        _groupListKey.currentContext!.mounted;
    final bool addGroupValid = _addGroupKey.currentContext != null &&
        _addGroupKey.currentContext!.mounted;


    // For external triggers, be more lenient with validation to avoid disposal issues
    if (!searchValid || !foldersValid || !groupListValid || !addGroupValid) {
      _tourRetryCount++;
      // Use shorter delay for external triggers
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _startResponsiveTour(tour);
        } else {
          _tourRetryCount = 0; // Reset retry count
        }
      });
      return;
    }

    // Reset retry count on successful validation
    _tourRetryCount = 0;


    try {
      // Determine screen size and start appropriate tour
      final responsive = ResponsiveUtils(context);
      final isLargeScreen =
          responsive.isLargeScreen && !responsive.isIPadPortrait;


      if (isLargeScreen) {
        // Start desktop tour
        tour
            .startGroupsTourDesktop(
          context,
          searchKey: _groupSearchKey,
          foldersKey: _groupFoldersKey,
          groupListKey: _groupListKey,
          addGroupKey: _addGroupKey,
        )
            .then((_) {
          // Only mark as done when tour actually completes successfully
          tour.markGroupsTourDone();
        }).catchError((error) {
          // Don't mark tour as done if there was an error
        });
      } else {
        // Start mobile tour
        tour
            .startGroupsTour(
          context,
          searchKey: _groupSearchKey,
          foldersKey: _groupFoldersKey,
          groupListKey: _groupListKey,
          addGroupKey: _addGroupKey,
        )
            .then((_) {
          // Only mark as done when tour actually completes successfully
          tour.markGroupsTourDone();
        }).catchError((error) {
          // Don't mark tour as done if there was an error
        });
      }
    } catch (e) {
    }
  }

  /// Fallback method to start tour when widget is not mounted
  void _startResponsiveTourFallback(CustomTourService tour) {

    try {
      // Try to get the current context from GetX
      final context = Get.context;
      if (context == null) {
        return;
      }

      // Check if GlobalKeys are still valid
      final bool searchValid = _groupSearchKey.currentContext != null;
      final bool foldersValid = _groupFoldersKey.currentContext != null;
      final bool groupListValid = _groupListKey.currentContext != null;
      final bool addGroupValid = _addGroupKey.currentContext != null;


      if (!searchValid || !foldersValid || !groupListValid || !addGroupValid) {
        return;
      }

      // Determine screen size and start appropriate tour
      final responsive = ResponsiveUtils(context);
      final isLargeScreen =
          responsive.isLargeScreen && !responsive.isIPadPortrait;


      if (isLargeScreen) {
        tour
            .startGroupsTourDesktop(
          context,
          searchKey: _groupSearchKey,
          foldersKey: _groupFoldersKey,
          groupListKey: _groupListKey,
          addGroupKey: _addGroupKey,
        )
            .then((_) {
          tour.markGroupsTourDone();
        }).catchError((error) {
        });
      } else {
        tour
            .startGroupsTour(
          context,
          searchKey: _groupSearchKey,
          foldersKey: _groupFoldersKey,
          groupListKey: _groupListKey,
          addGroupKey: _addGroupKey,
        )
            .then((_) {
          tour.markGroupsTourDone();
        }).catchError((error) {
        });
      }
    } catch (e) {
    }
  }

  void _startShowcaseIfReady([int attempt = 0]) {
    if (!mounted) return;
    // Avoid starting while dialog is open
    if (Get.isDialogOpen ?? false) {
      if (attempt < 10) {
        Future.delayed(const Duration(milliseconds: 200),
            () => _startShowcaseIfReady(attempt + 1));
      }
      return;
    }

    final ctx1 = _groupSearchKey.currentContext;
    final ctx2 = _groupFoldersKey.currentContext;
    final ctx3 = _groupListKey.currentContext;
    final ctx4 = _addGroupKey.currentContext;
    if (ctx1 != null && ctx2 != null && ctx3 != null && ctx4 != null) {
      try {
        // Check if the context is still active before starting showcase
        if (mounted &&
            context.mounted &&
            ctx1.mounted &&
            ctx2.mounted &&
            ctx3.mounted &&
            ctx4.mounted) {
          final controller = Get.find<CustomTourService>();
          controller.startGroupsTour(
            context,
            searchKey: _groupSearchKey,
            foldersKey: _groupFoldersKey,
            groupListKey: _groupListKey,
            addGroupKey: _addGroupKey,
          );
        }
      } catch (e) {
      }
    } else if (attempt < 10) {
      // Wait for widgets to mount/render
      Future.delayed(const Duration(milliseconds: 200),
          () => _startShowcaseIfReady(attempt + 1));
    } else {
    }
  }



  @override
  void dispose() {

    try {
      // Clear search when disposing the screen
      if (_showSearch.value || _search.value.isNotEmpty) {
        _showSearch.value = false;
        _search.value = '';
        searchController.clear();
        groupController.updateSearchQuery('');
        bottomNavigationBarController.setSearchActive(false);
      }

      // Do not clear selected group on dispose to maintain state when navigating back
      // This matches conversation_screen behavior and avoids header shimmer on resize

      searchController.dispose();
      _folderScrollController.dispose();
      _groupInitWorker?.dispose();
      _tourWorker?.dispose();
      if (_typingTimer != null) {
        _typingTimer!.cancel();
      }
      // Clear reactive variables
      _showSearch.close();
      _search.close();
      // Reset tour retry count
      _tourRetryCount = 0;
    } catch (e) {
    } finally {
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle screen resize during tour
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<CustomTourService>()) {
        final tour = Get.find<CustomTourService>();
        tour.handleScreenResize(context);
      }
    });

    final responsive = ResponsiveUtils(context);
    final isLargeScreen =
        responsive.screenWidth >= 1100 && !responsive.isPortrait;
    
    // Clear group selection when in mobile/tablet view
    if (!isLargeScreen) {
      // If we're in mobile/tablet view, clear the selection
      if (groupController.selectedGroup.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            groupController.clearSelectedGroup();
          }
        });
      }
    }

    return isLargeScreen
        ? _buildLargeScreenLayout(responsive)
        : BgScreen(
            drawer: const CustomDrawer(),
            child: _buildMobileLayout(responsive),
          );
  }

  // =============================================
  // Responsive Layout Methods
  // =============================================

    Widget _buildMobileLayout(ResponsiveUtils responsive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(),
        const VLSpace(),
        // Only show chat toggle for screens smaller than desktop size
        if (MediaQuery.of(context).size.width < 1100) ...[
          _buildChatToggle(),
          const VSSpace(),
        ],
        _buildFolderList(),
        const VSSpace(),
        _buildGroupConversationList(),
      ],
    );
  }

  Widget _buildLargeScreenLayout(ResponsiveUtils responsive) {
    return ResizableDesktopSplitView(
      controller: _splitViewController,
      storageKey: 'global_resizable_panel_width', // Shared across all screens for consistent width
      leftChildBuilder: (context, width) {
        final showProfileOnly = width < 300.0;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: showProfileOnly
                  ? _buildProfileOnlyView(width,
                      key: const ValueKey('profile-only'))
                  : _buildFullGroupView(
                      key: const ValueKey('full-view')),
            ),
          ),
        );
      },
      rightChild: Obx(() {
        final selectedGroup = groupController.selectedGroup.value;
        if (selectedGroup == null) {
          return _buildGroupPlaceholder(responsive);
        }
        return _buildGroupChatDetailScreen(responsive);
      }),
    );
  }

  Widget _buildFullGroupView({Key? key}) {
    return Column(
      key: key,
      children: [
        const SizedBox(height: 16),
        _buildChatToggle(),
        const SizedBox(height: 12),
        _buildDesktopSearchBar(),
        const VSSpace(),
        _buildFolderList(),
        const VSSpace(),
        _buildGroupConversationList(),
      ],
    );
  }



  Widget _buildGroupChatDetailScreen(ResponsiveUtils responsive) {
    // Use a stable key to prevent widget recreation when switching groups
    // This allows the GroupChatDetailScreen to stay alive and only update messages
    return const GroupChatDetailScreen(
      key: ValueKey('stable_group_chat_detail_screen'),
      hideDrawer: true,
    );
  }

  Widget _buildGroupPlaceholder(ResponsiveUtils responsive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: responsive.responsiveHeight(
              mobile: 64,
              tablet: 80,
              desktop: 96,
            ),
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: responsive.spacingL),
          MixedText(
            'Select a group to start chatting',
            style: FontUtils.createTextStyle(
              'Select a group to start chatting',
              fontSize: responsive.responsiveFontSize(
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              color: Colors.grey.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // Helper Methods
  // =============================================

  // Removed responsive logo sizing helper



  Widget _buildChatToggle() {
    return Obx(() {
      final currentIndex = bottomNavigationBarController.currentIndex.value;
      return DesktopNavigationToggle(
        currentIndex: currentIndex,
        onTabSelected: (index) {
          bottomNavigationBarController.currentIndex.value = index;
        },
      );
    });
  }

 

  Widget _buildDesktopSearchBar() {
    return DesktopSearchBar(
      controller: searchController,
      hintText: 'search_groups'.tr,
      onChanged: (val) {
        _search.value = val;
        groupController.updateSearchQuery(val);
      },
      onClear: () {
        _search.value = '';
        searchController.clear();
        groupController.updateSearchQuery('');
        _showSearch.value = false;
      },
      showClearButton: _search.value.isNotEmpty.obs,
      onAddPressed: () {
        createNewGroup();
      },
      addIcon: Icons.group_add_outlined,
    );
  }

  Widget _buildTitle() {
    return GlobalScreenHeader(
      searchController: searchController,
      showSearch: _showSearch,
      searchValue: _search,
      searchHintText: 'search_groups'.tr,
      onSearchChanged: (val) async {
        groupController.updateSearchQuery(val);
      },
      onSearchClear: () {
        groupController.updateSearchQuery('');
        bottomNavigationBarController.setSearchActive(false);
      },
      onAddPressed: createNewGroup,
      addIcon: Icons.group_add_outlined,
      searchKey: _groupSearchKey,
      addButtonKey: _addGroupKey,
    );
  }

  // =============================================
  // Group Conversation List Section
  // =============================================
  Widget _buildGroupConversationList() {
    return Expanded(
      key: _groupListKey,
      child: GroupChatListWidget(
        selectedGroup: groupController.selectedGroup.value,
        onGroupTap: (group) {
          final responsive = ResponsiveUtils(context);

          if (responsive.isLargeScreen && !responsive.isIPadPortrait) {
            // For large screens (excluding iPad portrait), select the group and show group chat detail screen
            groupController.selectedGroup.value = group;
            // Initialize group chat for the selected group without navigation
            groupController.handleTapGroupConversation(
              group.id,
              group.chatId,
              context: context,
              shouldNavigate: false,
              group: group,
            );
          } else {
            // For mobile screens and iPad portrait, navigate to group chat detail screen
            groupController.handleTapGroupConversation(
              group.id,
              group.chatId,
              context: context,
              shouldNavigate: true,
              group: group,
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileOnlyView(double currentWidth, {Key? key}) {
    return Obx(() {
      // Use the same groupList as GroupChatListWidget - it's already filtered by folder at controller level
      final groups = groupController.groupList;
      final selectedGroup = groupController.selectedGroup.value;
      
      // Ensure minimum width for avatar display
      final avatarSize = math.min(56.0, (currentWidth - 16) * 0.8);

      return Container(
        key: key,
        width: currentWidth,
        constraints: const BoxConstraints(
          minWidth: 80.0, // _minProfileOnlyWidth
          maxWidth: double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Expand icon at the top
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // When clicked, expand the panel back to show full group list
                    _splitViewController.setWidth(250.0);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            // Group avatars list
            Expanded(
              child: groupController.isGroupLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : groups.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Icon(
                              Icons.group_outlined,
                              color: Colors.grey.withOpacity(0.5),
                              size: 32,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            final isSelected = selectedGroup?.id == group.id;

                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    // Select group
                                    groupController.selectedGroup.value = group;
                                    groupController.handleTapGroupConversation(
                                      group.id,
                                      group.chatId,
                                      context: context,
                                      shouldNavigate: false,
                                      group: group,
                                    );
                                  },
                                  child: Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    constraints: BoxConstraints(
                                      maxWidth: avatarSize,
                                      maxHeight: avatarSize,
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.withOpacity(0.3),
                                        width: isSelected ? 3 : 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? AppColors.primary
                                                  .withOpacity(0.3)
                                              : Colors.black.withOpacity(0.1),
                                          blurRadius: isSelected ? 8 : 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        imageUrl: group.avatarUrl ?? '',
                                        width: avatarSize,
                                        height: avatarSize,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.group,
                                              color: Colors.grey[600],
                                              size: avatarSize * 0.4,
                                            ),
                                          );
                                        },
                                        errorWidget: (context, url, error) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.group,
                                              color: Colors.grey[600],
                                              size: avatarSize * 0.4,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFolderList() {
    return Obx(() {
      final responsive = ResponsiveUtils(context);
      final isLargeScreen =
          responsive.isLargeScreen && !responsive.isIPadPortrait;
      
      // No need to check _leftPanelWidth here because this method is only called from full view widgets
      // or mobile layout. Profile-only mode is a separate widget structure.

      if (groupFolderController.isLoading.value) {
        return const GroupFolderListShimmer();
      }

      return Padding(
        padding: EdgeInsets.only(
          left: isLargeScreen ? 16.0 : 0.0, // Add left padding for iPad/desktop
        ),
        child: SizedBox(
          key: _groupFoldersKey,
          height: 40,
          child: _buildFolderListView(),
        ),
      );
    });
  }

  /// Build folder list view with web scrolling support
  Widget _buildFolderListView() {
    final listView = ListView.builder(
      controller: _folderScrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: groupFolderController.groupFolders.length +
          1, // +1 for new folder button
      itemBuilder: (context, index) {
        if (index == 0) {
          // New folder button at first position
          return ZoomTapAnimation(
            onTap: () {
              showCreateFolderGroupDialog();
            },
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: Colors.grey[300]!,
                  strokeWidth: 2,
                  dashPattern: [5, 5],
                ),
                child: Icon(
                  Icons.create_new_folder,
                  size: 24,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        } else {
          // Regular folders (index - 1 because we added the new folder button at index 0)
          final folder = groupFolderController.groupFolders[index - 1];
          return _buildFolderItem(folder, index - 1, context);
        }
      },
    );
    
    // Wrap in ScrollConfiguration for web to enable mouse wheel scrolling
    if (kIsWeb) {
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
          scrollbars: true,
        ),
        child: listView,
      );
    }
    return listView;
  }

  Widget _buildFolderItem(
    FolderGroup folder,
    int index,
    BuildContext context,
  ) {
    final color = Color(int.parse('0xFF${folder.color.replaceAll('#', '')}'));
    return GestureDetector(
      onSecondaryTap: () => _handleFolderLongTap(folder, index, context),
      child: ZoomTapAnimation(
        onTap: () => _handleFolderTap(folder, index, context),
        onLongTap: () => _handleFolderLongTap(folder, index, context),
        child: Obx(() {
          // Access reactive variable directly in Obx builder so GetX can track it
          final selectedIndex = groupFolderController.selectedFolderIndex.value;
          return _buildFolder(
            index,
            color,
            iconFromString(folder.icon),
            folder,
            groupFolderController,
          );
        }),
      ),
    );
  }

  void _scrollToFolder(int index) {
    // Check if folder list is scrollable (content width > viewport width)
    if (!_folderScrollController.hasClients) return;
    
    final scrollPosition = _folderScrollController.position;
    final maxScrollExtent = scrollPosition.maxScrollExtent;
    
    // Only scroll if content can actually be scrolled
    if (maxScrollExtent <= 0) return;
    
    // Estimate folder width (including margin and padding)
    const double newFolderButtonWidth = 44; // New folder button width
    const double newFolderMargin = 16; // Margin after new folder button
    const double folderWidth = 120; // Approximate width of folder item
    const double folderMargin = 12; // Margin between folders
    
    // Calculate offset: account for new folder button + margins + folder positions
    double offset = newFolderButtonWidth + newFolderMargin + 
                    (folderWidth + folderMargin) * index;
    
    // Clamp offset to valid scroll range
    offset = offset.clamp(0.0, maxScrollExtent);

    _folderScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Programmatically select a folder by its id, scroll it into view and
  /// refresh the group list for that folder. This mirrors the logic used
  /// when the user taps a folder chip.
  void _selectFolderById(String folderId) {
    try {
      final int index = groupFolderController.groupFolders
          .indexWhere((f) => f.id == folderId);
      if (index == -1) {
        return;
      }
      final folder = groupFolderController.groupFolders[index];
      _handleFolderTap(folder, index, context);
    } catch (e) {
    }
  }

  /// Toggle pinned state for a group chatId and refresh list ordering.
  Future<void> _toggleGroupPinnedState(String chatId) async {
    try {
      // Look up the group by its chatId
      final group =
          groupController.groupList.firstWhereOrNull((g) => g.chatId == chatId);
      if (group == null) {
        return;
      }

      final bool newPinned = !group.isPinned;

      // Inform backend so pinned state is stored in database per user.
      await groupController.groupService
          .setGroupPinnedState(group.id, isPinned: newPinned);

      // Reload groups from backend so UI reflects latest pin state & ordering.
      await groupController.fetchGroups();
    } catch (e) {
    }
  }

  /// Confirm with the user and delete the group via controller.
  /// Check if current user is an admin of the group
  bool _isCurrentUserAdmin(String groupChatId) {
    final group = groupController.groupList
        .firstWhereOrNull((g) => g.chatId == groupChatId);
    if (group == null) return false;

    final currentUserId = authController.user.value.id;
    return group.members.any(
        (member) => member.userId == currentUserId && member.role == 'ADMIN');
  }

  Future<void> _confirmAndLeaveGroup(String groupChatId) async {
    try {
      final group = groupController.groupList
          .firstWhereOrNull((g) => g.chatId == groupChatId);
      final groupId = group?.id ?? '';
      if (groupId.isEmpty) {
        snackBar(
          title: 'oops'.tr,
          message: 'Group not found',
          isWarning: true,
        );
        return;
      }

      settingsController.buildLogout(
        title: 'leave_group'.tr,
        question: 'Are you sure?'.tr,
        description: 'you_will_need_to_be_invited_again_to_join_this_group'.tr,
        icon: Icons.logout_rounded,
        confirmText: 'leave_group'.tr,
        onConfirm: () async {
          final resp = await groupController.leaveGroup(groupId);
          if (resp != null && resp.success) {
            // Remove from list and refresh UI
            groupController.groupList.removeWhere((g) => g.chatId == groupChatId);
            groupController.groupList.refresh();
            snackBar(title: 'success'.tr, message: 'you_have_left_the_group'.tr);
            Get.back(); // Close bottom sheet
          } else if (resp != null && !resp.success) {
            snackBar(
              title: 'oops'.tr,
              message: resp.message,
              isWarning: true,
            );
          }
        },
      );
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: e.toString(),
        isWarning: true,
      );
    }
  }

  Future<void> _confirmAndDeleteGroup(String groupChatId) async {
    try {
      final group = groupController.groupList
          .firstWhereOrNull((g) => g.chatId == groupChatId);
      final groupId = group?.id ?? '';
      if (groupId.isEmpty) {
        snackBar(
          title: 'oops'.tr,
          message: 'Group not found',
          isWarning: true,
        );
        return;
      }

      settingsController.buildLogout(
        title: 'delete_group'.tr,
        question: 'Are you sure?'.tr,
        description: 'this_action_cannot_be_undone_and_all_messages_will_be_lost'.tr,
        icon: Icons.delete_forever_rounded,
        confirmText: 'delete'.tr,
        confirmButtonColor: Colors.redAccent,
        onConfirm: () async {
          final resp = await groupController.deleteGroup(groupId);
          if (resp != null && resp.success) {
            // Remove from list and refresh UI
            groupController.groupList.removeWhere((g) => g.chatId == groupChatId);
            groupController.groupList.refresh();
            snackBar(title: 'success'.tr, message: 'delete_group'.tr);
            Get.back(); // Close bottom sheet
          } else if (resp != null && !resp.success) {
            snackBar(
              title: 'oops'.tr,
              message: resp.message,
              isWarning: true,
            );
          }
        },
      );
    } catch (e) {
      snackBar(
        title: 'oops'.tr,
        message: e.toString(),
        isWarning: true,
      );
    }
  }

  void _handleFolderTap(
    FolderGroup folder,
    int index,
    BuildContext context,
  ) {
    groupFolderController.selectedFolderIndex.value = index;

    // Scroll to the selected folder
    _scrollToFolder(index);

    if (index == 0) {
      groupController.forceRefreshGroups();
    } else {
      groupController.fetchGroups(folderId: folder.id);
    }
  }

  Future<void> _handleFolderLongTap(
    FolderGroup folder,
    int index,
    BuildContext context,
  ) async {
    if (folder.id == 'all') {
      snackBar(
        title: 'oops'.tr,
        message: 'cannot_edit_all_groups'.tr,
        isWarning: true,
      );
      return;
    }
    await VibrationUtils.vibrate();
    if (groupFolderController.isLoading.value) {
      return;
    }
    groupFolderController.selectedFolderIndex.value = index;
    await groupController.fetchGroups(folderId: folder.id);
    _showFolderOptions(folder, context);
  }

  Widget _buildFolder(
    int index,
    Color folderColor,
    IconData folderIcon,
    FolderGroup folder,
    GroupFolderController groupFolderController,
  ) {
    final isSelected = groupFolderController.selectedFolderIndex.value == index;
    final isAllGroups = folder.id == 'all';

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? folderColor.withOpacity(0.9)
              : Colors.white.withOpacity(0.95),
          border: Border.all(
            color: isSelected ? folderColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? folderColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container with improved styling
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : folderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isAllGroups
                    ? Icon(
                        Icons.group,
                        size: 20,
                        color: isSelected ? Colors.white : folderColor,
                      )
                    : Icon(
                        folderIcon,
                        size: 20,
                        color: isSelected ? Colors.white : folderColor,
                      ),
              ),
              const SizedBox(width: 6),
              // Text with improved styling
              Flexible(
                child: MixedText(
                  folder.name.length > 12
                      ? '${folder.name.substring(0, 10)}...'
                      : folder.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderOptions(
    FolderGroup folder,
    BuildContext context,
  ) {
    final bool isAllGroupsFolder = folder.id == 'all';
    if (isAllGroupsFolder) {
      snackBar(
        title: 'oops'.tr,
        message: 'cannot_edit_all_groups'.tr,
        isWarning: true,
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MixedText(
                    'folder_options'.tr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 24,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 24),
              Obx(() {
                if (groupFolderController.isLoading.value) {
                  return buildLoadingIndicator();
                }
                return Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.edit_outlined,
                      title: 'edit_folder'.tr,
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        Get.back();
                        showEditFolderGroupDialog(folder);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildOptionTile(
                      icon: Icons.delete_outline,
                      title: 'delete_folder'.tr,
                      color: const Color(0xFFF44336),
                      onTap: () async {
                        Get.back();
                        await groupFolderController
                            .deleteGroupFolder(folder.id);
                      },
                    ),
                  ],
                );
              }),
              // Safe area bottom padding
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ZoomTapAnimation(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MixedText(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showGroupOptions(String groupChatId) {
    final selectedFolder = groupFolderController
        .groupFolders[groupFolderController.selectedFolderIndex.value];
    final isAllGroups = selectedFolder.id == 'all';
    final group = groupController.groupList
        .firstWhereOrNull((g) => g.chatId == groupChatId);
    groupFolderController.fetchGroupFolders();
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
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
            const SizedBox(height: 20),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MixedText(
                  'group_options'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Group Info
            if (group != null) ...[
              Center(
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.network(
                        group.avatarUrl ?? '',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.group,
                                color: Colors.grey[600], size: 22),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    MixedText(
                      group.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 99, 99, 99),
                        height:
                            1.2, // Line height multiplier (1.2 = 120% of font size)
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
            // Options
            // Pin / Unpin group (local, per device)
            ListTile(
              leading:
                  const Icon(Icons.push_pin_outlined, color: Color(0xFF4CAF50)),
              title: MixedText(
                // Toggle label based on current pinned state (from backend flag)
                (() {
                  final group = groupController.groupList
                      .firstWhereOrNull((g) => g.chatId == groupChatId);
                  final isPinned = group?.isPinned ?? false;
                  return isPinned ? 'unpin'.tr : 'pin'.tr;
                })(),
              ),
              onTap: () async {
                Get.back();
                await _toggleGroupPinnedState(groupChatId);
              },
            ),
            // Leave Group (for members) or Delete Group (for admins)
            Builder(
              builder: (context) {
                final isAdmin = _isCurrentUserAdmin(groupChatId);
                return ListTile(
                  leading: Icon(
                    isAdmin ? Icons.delete_outline : Icons.exit_to_app,
                    color: const Color(0xFFF44336),
                  ),
                  title: MixedText(
                    isAdmin ? 'delete_group'.tr : 'leave_group'.tr,
                  ),
                  onTap: () async {
                    Get.back();
                    if (isAdmin) {
                      await _confirmAndDeleteGroup(groupChatId);
                    } else {
                      await _confirmAndLeaveGroup(groupChatId);
                    }
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_copy_outlined,
                  color: Color(0xFF2196F3)),
              title: MixedText('add_to_folder'.tr),
              onTap: () async {
                Get.back();
                // Show folder selection dialog
                final selectedFolderId = await showSelectFolderDialog();
                if (selectedFolderId != null) {
                  try {
                    await groupFolderController
                        .addGroupsToFolder(selectedFolderId, [groupChatId]);
                    snackBar(
                        title: 'success'.tr,
                        message: 'group_added_to_folder'.tr);
                  } catch (e) {
                    snackBar(
                        title: 'oops'.tr,
                        message: e.toString(),
                        isWarning: true);
                  }
                }
              },
            ),
            if (!isAllGroups)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: Color(0xFFF44336)),
                title: MixedText('remove_from_folder'.tr),
                onTap: () async {
                  Get.back();
                  try {
                    await groupFolderController.removeGroupFromFolderService(
                        selectedFolder.id, groupChatId);
                    snackBar(
                        title: 'success'.tr,
                        message: 'group_removed_from_folder'.tr);
                  } catch (e) {
                    snackBar(
                        title: 'oops'.tr,
                        message: e.toString(),
                        isWarning: true);
                  }
                },
              ),
            // You can add more options here (edit, delete, etc.)
            // Add bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Dialog to select a folder (excluding 'All')
  Future<String?> showSelectFolderDialog() async {
    final folders =
        groupFolderController.groupFolders.where((f) => f.id != 'all').toList();
    String? selectedFolderId;
    await showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        width: double.infinity,
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
            const SizedBox(height: 20),
            // Header
            MixedText('select_folder'.tr,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            // Folder List
            ...folders.map((folder) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(iconFromString(folder.icon),
                        color: Color(int.parse(
                            '0xFF${folder.color.replaceAll('#', '')}'))),
                    title: MixedText(
                      folder.name,
                      maxLines: 2, // Limit to 2 lines
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onTap: () {
                      selectedFolderId = folder.id;
                      Get.back();
                    },
                  ),
                )),
            // Add bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
    return selectedFolderId;
  }
}

class GroupChatListWidget extends StatelessWidget {
  const GroupChatListWidget({
    super.key,
    this.isDrawer = false,
    this.selectedGroup,
    this.onGroupTap,
  });
  final bool isDrawer;
  final GroupListItem? selectedGroup;
  final Function(GroupListItem)? onGroupTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (groupController.isGroupLoading.value) {
        return SizedBox(
            height: Get.height * 0.5, child: const GroupListShimmer());
      }

      final selectedIndex = groupFolderController.selectedFolderIndex.value;
      final folder = groupFolderController.groupFolders[selectedIndex];

      // Build filtered groups:
      // - For "All" folder, hide archived groups so they only appear in Archive.
      // - For other folders, use groupList as loaded from backend.
      final List<GroupListItem> allGroups =
          List<GroupListItem>.from(groupController.groupList);
      List<GroupListItem> displayGroups = allGroups;

      // Find Archive folder by name
      final FolderGroup? archiveFolder = groupFolderController.groupFolders
          .firstWhereOrNull((f) => f.name.toLowerCase().contains('archive'));
      if (folder.id == 'all' && archiveFolder != null) {
        final Set<String> archivedChatIds =
            archiveFolder.chats.map((c) => c.id).toSet();
        displayGroups = allGroups
            .where((g) => !archivedChatIds.contains(g.chatId))
            .toList();
      }

      // Sort so that pinned groups (from backend isPinned flag) appear at the top.
      displayGroups.sort((a, b) {
        // Handle potential null values defensively to prevent runtime errors
        // Even though isPinned is declared as non-nullable, handle edge cases
        bool aPinned = false;
        bool bPinned = false;
        try {
          aPinned = a.isPinned;
        } catch (e) {
          // If accessing isPinned throws an error, default to false
        }
        try {
          bPinned = b.isPinned;
        } catch (e) {
          // If accessing isPinned throws an error, default to false
        }
        if (aPinned == bPinned) return 0;
        return aPinned ? -1 : 1;
      });

      if (displayGroups.isEmpty && !groupController.isGroupLoading.value) {
        // Check if we're currently searching
        if (groupController.isSearching.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: Get.height * 0.1),
                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                MixedText(
                  'no_search_results'.tr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                MixedText(
                  'try_different_search_terms'.tr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: Get.height * 0.1),
                Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                MixedText(
                  '${'no_groups_in'.tr} ${folder.name}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
      }
      // Ensure only one Slidable (swipe actions) is open at a time.
      // Wrapping the list with SlidableAutoCloseBehavior will automatically
      // close any previously opened Slidable when a new one is opened.
      return SlidableAutoCloseBehavior(
        child: ListView.builder(
          padding: (!kIsWeb && (GetPlatform.isIOS || GetPlatform.isAndroid))
              ? EdgeInsets.zero
              : const EdgeInsets.only(left: 15, right: 15),
          physics: const BouncingScrollPhysics(),
          itemCount: displayGroups.length,
          itemBuilder: (context, index) {
            final group = displayGroups[index];
            return GroupCardWidget(
              id: group.id,
              chatId: group.chatId,
              name: group.name,
              lastMessage: group.lastMessage == null
                  ? 'group_created'.tr
                  : group.lastMessage?.type == 'SYSTEM'
                      ? (group.lastMessage?.preview ?? 'group_created'.tr)
                      : (group.lastMessage?.type == 'CALL'
                          ? 'call_message'.tr
                          : group.lastMessage?.type == 'CHECKLIST'
                              ? group.lastMessage?.preview ?? ''
                              : group.lastMessage?.preview ?? ''),
              typeMessage: group.lastMessage?.type ?? '',
              members: group.members,
              date: group.lastMessage?.timestamp.toIso8601String() ?? '',
              avatarUrl: group.avatarUrl ?? '',
              lastMessageObj:
                  group.lastMessage, // Pass the full LastMessage object
              isPinned: group.isPinned,
              onTap: () async {
                if (onGroupTap != null) {
                  onGroupTap!(group);
                } else {
                  await groupController.handleTapGroupConversation(
                      group.id, group.chatId,
                      context: context, group: group);
                }
              },
              onLongTap: () {
                // ignore: use_build_context_synchronously
                final state =
                    context.findAncestorStateOfType<_GroupScreenState>();
                state?.showGroupOptions(group.chatId);
              },
              isDrawer: isDrawer,
              isSelected: selectedGroup?.id == group.id,
            );
          },
        ),
      );
    });
  }
}

class GroupCardWidget extends StatelessWidget {
  const GroupCardWidget({
    super.key,
    required this.id,
    required this.chatId,
    required this.name,
    required this.lastMessage,
    required this.typeMessage,
    required this.members,
    required this.date,
    required this.avatarUrl,
    this.lastMessageObj,
    this.onTap,
    this.onLongTap,
    this.isDrawer = false,
    this.isSelected = false,
    required this.isPinned,
  });
  final String id;
  final String chatId;
  final String name;
  final String lastMessage;
  final String typeMessage;
  final List<GroupListMember> members;
  final String date;
  final String avatarUrl;
  final LastMessage? lastMessageObj; // Full LastMessage object for status
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
  final bool isDrawer;
  final bool isSelected;

  /// Whether this group is pinned for the current user (from backend).
  final bool isPinned;

  // Constants for online indicator styling (matching conversation card)
  static const double _onlineIndicatorSize = 14.0;
  static const double _onlineIndicatorBorderWidth = 2.0;
  static const Color _onlineIndicatorColor = Colors.green;
  static const Color _onlineIndicatorBorderColor = Colors.white;

  /// Build unread count badge for group card
  static Widget _buildGroupUnreadCountBadge(int count) {
    final responsive = ResponsiveUtils(Get.context!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: MixedText(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.responsiveFontSize(
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Widget buildGroupCardStatusIcon(String? status, bool isSentByMe) {
    if (!isSentByMe || status == null || status.isEmpty) {
      return const SizedBox();
    }

    switch (status) {
      case 'SENDING':
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E9E9E)),
          ),
        );
      case 'FAILED':
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: Color(0xFFFF3B30),
        );
      case 'SENT':
        // Single tick for SENT in group chats
        return const Icon(
          Icons.done,
          size: 12,
          color: Color(0xFF9E9E9E),
        );
      case 'DELIVERED':
        // Double tick for DELIVERED in group chats
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Color(0xFF9E9E9E),
        );
      case 'READ':
        // Double tick in blue for READ in group chats
        return const Icon(
          Icons.done_all,
          size: 12,
          color: AppColors.primary,
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Check if this group is currently selected
      final responsive = ResponsiveUtils(context);
      final selectedGroup = groupController.selectedGroup.value;
      final bool isCurrentlySelected =
          selectedGroup?.id == id && !responsive.isMobile;

      const double avatarSize = 56;
      const double cardPadding = 10.0;
      const double titleFontSize = 16;
      const double subFontSize = 12;
      const double borderWidth = 1.0;
      const double selectedBorderWidth = 2.0;
      const double borderRadius = 16.0;
      final Color cardColor = isCurrentlySelected
          ? AppColors.primary.withOpacity(0.1)
          : Colors.white;
      final Color borderColor =
          isCurrentlySelected ? AppColors.primary : const Color(0xFFE5E5E5);

      final Widget content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.group,
                          color: Colors.grey[600], size: avatarSize * 0.4),
                    );
                  },
                ),
              ),
              // Online status indicator - wrapped in Obx for reactivity
              // Concept: Online status belongs to USER, not GROUP
              // If any member (excluding self) is online according to the centralized status map, show green dot
              Obx(() {
                // Check if any member (excluding self) is online using multi-user map
                final currentUserId = authController.user.value.id;
                final hasOnlineMember = members.any((member) =>
                    member.userId != currentUserId &&
                    UserStatusUtils.isUserOnline(member.userId));

                return hasOnlineMember
                    ? Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: _onlineIndicatorSize,
                          height: _onlineIndicatorSize,
                          decoration: BoxDecoration(
                            color: _onlineIndicatorColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _onlineIndicatorBorderColor,
                              width: _onlineIndicatorBorderWidth,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => HighlightedText(
                      text: name,
                      highlightText: groupController.isSearching.value
                          ? groupController.searchQuery.value
                          : null,
                      style: const TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      highlightStyle: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2C),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                      ),
                    )),
                const SizedBox(height: 4),
                Obx(() {
                  // Access reactive values directly (without .value) so Obx tracks them
                  final typingData = groupChatService.groupUserTypingData;
                  final recordingData =
                      groupChatService.groupUserRecordingVoiceData;

                  // Check for typing indicator for this group using group-specific service
                  if (typingData.value.isTyping &&
                      typingData.value.chatId == chatId &&
                      typingData.value.senderId !=
                          authController.user.value.id) {
                    // Get user name from group members - always use name
                    final typingUserId = typingData.value.senderId;
                    final group = groupController.groupList.firstWhereOrNull(
                      (g) => g.chatId == chatId,
                    );
                    String userName = 'Someone';
                    if (group != null) {
                      final member = group.members.firstWhereOrNull(
                        (m) => m.userId == typingUserId,
                      );
                      if (member != null) {
                        // Always use name if available, otherwise fallback to 'Someone'
                        userName =
                            (member.name != null && member.name!.isNotEmpty)
                                ? member.name!
                                : 'Someone';
                      }
                    }

                    return Row(
                      children: [
                        LoadingAnimationWidget.waveDots(
                          color: AppColors.primary,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: MixedText(
                            '$userName ${'is_typing'.tr}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }

                  // Check if someone is recording a voice message using group-specific service
                  // For groups we only care that another user is recording in THIS group.
                  if (recordingData.value != null) {
                    final senderUserId =
                        recordingData.value!['senderUserId'] as String?;
                    final isRecording =
                        recordingData.value!['isRecording'] == true;
                    final recordingChatId =
                        recordingData.value!['chatId'] as String?;

                    // If chatId is provided, ensure it matches this group's chatId.
                    // If not provided (null/empty), don't show to prevent showing on all groups.
                    // Only show when chatId explicitly matches this specific group.
                    final bool isSameGroup = recordingChatId != null &&
                        recordingChatId.isNotEmpty &&
                        recordingChatId == chatId;

                    if (senderUserId != null &&
                        senderUserId != authController.user.value.id &&
                        isRecording &&
                        isSameGroup) {
                      // Get user name from group members - always use name
                      final group = groupController.groupList.firstWhereOrNull(
                        (g) => g.chatId == chatId,
                      );
                      String userName = 'Someone';
                      if (group != null) {
                        final member = group.members.firstWhereOrNull(
                          (m) => m.userId == senderUserId,
                        );
                        if (member != null) {
                          // Always use name if available, otherwise fallback to 'Someone'
                          userName =
                              (member.name != null && member.name!.isNotEmpty)
                                  ? member.name!
                                  : 'Someone';
                        }
                      }

                      return Row(
                        children: [
                          LoadingAnimationWidget.staggeredDotsWave(
                            color: AppColors.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: MixedText(
                              '$userName ${'is_recording_voice'.tr}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E9E9E),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }
                  }

                  // Show normal last message
                  return _TypeMessageWidget(
                    typeMessage: typeMessage,
                    lastMessage: lastMessage,
                    isForwarded: lastMessageObj?.isForwarded ?? false,
                  );
                }),
                // Profile member section hidden below last message
                // if (!isDrawer) ...[
                //   const SizedBox(height: 8),
                //   Row(
                //     children: [
                //       SizedBox(
                //         width: 100,
                //         height: 32,
                //         child: Stack(
                //           children: [
                //             ...members.take(3).map(
                //                   (member) => Positioned(
                //                     left: members.indexOf(member) * 16.0,
                //                     child: ClipOval(
                //                       child: Image.network(
                //                         member.avatarUrl ?? '',
                //                         width: 28,
                //                         height: 28,
                //                         fit: BoxFit.cover,
                //                         errorBuilder: (context, error, stackTrace) {
                //                           return CircleAvatar(
                //                             radius: 14,
                //                             backgroundColor: Colors.grey[200],
                //                             child: Icon(Icons.person, color: Colors.grey[600], size: 14),
                //                           );
                //                         },
                //                       ),
                //                     ),
                //                   ),
                //                 ),
                //             if (members.length > 3)
                //               const Positioned(
                //                 left: 48,
                //                 child: _MoreMembersCircle(),
                //               ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            // Get unread count for this group from chatController
            final unreadCount = chatController.unreadCounts[chatId] ?? 0;

            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MixedText(
                  formatTimestamp(date),
                  style: const TextStyle(
                    fontSize: subFontSize,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                if (isPinned) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.push_pin,
                    size: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                ],
                // Show unread count badge if there are unread messages
                if (unreadCount > 0) ...[
                  const SizedBox(width: 6),
                  GroupCardWidget._buildGroupUnreadCountBadge(unreadCount),
                ] else if (lastMessageObj != null &&
                    lastMessageObj!.isSender) ...[
                  // Add status icon if message was sent by current user and no unread messages
                  const SizedBox(width: 4),
                  buildGroupCardStatusIcon(
                    lastMessageObj!.status,
                    lastMessageObj!.isSender,
                  ),
                ],
              ],
            );
          }),
        ],
      );

      // Wrap in Slidable to handle swipe left actions: Pin/Unpin, Delete, Archive.
      // Wrap everything in a bottom padding so card and action buttons share height.
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Slidable(
            key: ValueKey('group_card_$chatId'),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.75, // 3 actions
              children: [
                // Pin / Unpin
                CustomSlidableAction(
                  onPressed: (ctx) async {
                    final state =
                        ctx.findAncestorStateOfType<_GroupScreenState>();
                    await state?._toggleGroupPinnedState(chatId);
                  },
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.push_pin, size: 18),
                      const SizedBox(height: 4),
                      Text(
                        isPinned ? 'unpin'.tr : 'pin'.tr,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Delete Group (for admins) or Leave Group (for members)
                Builder(
                  builder: (context) {
                    final state =
                        context.findAncestorStateOfType<_GroupScreenState>();
                    final isAdmin = state?._isCurrentUserAdmin(chatId) ?? false;

                    return CustomSlidableAction(
                      onPressed: (ctx) async {
                        final state =
                            ctx.findAncestorStateOfType<_GroupScreenState>();
                        if (isAdmin) {
                          await state?._confirmAndDeleteGroup(chatId);
                        } else {
                          await state?._confirmAndLeaveGroup(chatId);
                        }
                      },
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAdmin ? Icons.delete : Icons.exit_to_app,
                            size: 18,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAdmin ? 'delete'.tr : 'leave_group'.tr,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Archive / Unarchive
                CustomSlidableAction(
                  onPressed: (ctx) async {
                    final selectedIndex =
                        groupFolderController.selectedFolderIndex.value;
                    final selectedFolder =
                        groupFolderController.groupFolders[selectedIndex];

                    // Find Archive folder
                    FolderGroup? archiveFolder;
                    for (final f in groupFolderController.groupFolders) {
                      if (f.name.toLowerCase().contains('archive')) {
                        archiveFolder = f;
                        break;
                      }
                    }

                    try {
                      final state =
                          ctx.findAncestorStateOfType<_GroupScreenState>();

                      if (archiveFolder != null &&
                          selectedFolder.id == archiveFolder.id) {
                        // Currently in Archive → Unarchive
                        await groupFolderController
                            .removeGroupFromFolderService(
                                archiveFolder.id, chatId);

                        final previousFolderId =
                            groupFolderController.lastFolderForGroup[chatId];
                        if (previousFolderId != null &&
                            previousFolderId.isNotEmpty &&
                            previousFolderId != 'all') {
                          await groupFolderController
                              .addGroupsToFolder(previousFolderId, [chatId]);
                          groupFolderController.lastFolderForGroup
                              .remove(chatId);
                          state?._selectFolderById(previousFolderId);
                        } else {
                          state?._selectFolderById('all');
                        }

                        snackBar(
                          title: 'success'.tr,
                          message: 'group_removed_from_folder'.tr,
                        );
                      } else if (archiveFolder != null) {
                        // Move into existing Archive folder
                        if (selectedFolder.id != 'all') {
                          groupFolderController.lastFolderForGroup[chatId] =
                              selectedFolder.id;
                        }

                        for (final f in groupFolderController.groupFolders) {
                          if (f.id == 'all' || f.id == archiveFolder.id)
                            continue;
                          try {
                            await groupFolderController
                                .removeGroupFromFolderService(f.id, chatId);
                          } catch (_) {}
                        }

                        await groupFolderController
                            .addGroupsToFolder(archiveFolder.id, [chatId]);
                        state?._selectFolderById(archiveFolder.id);

                        snackBar(
                          title: 'success'.tr,
                          message: 'group_added_to_folder'.tr,
                        );
                      } else {
                        // No Archive folder yet → create it and move group
                        if (selectedFolder.id != 'all') {
                          groupFolderController.lastFolderForGroup[chatId] =
                              selectedFolder.id;
                          await groupFolderController
                              .removeGroupFromFolderService(
                                  selectedFolder.id, chatId);
                        }

                        await groupFolderController.createGroupFolder(
                          name: 'archive'.tr,
                          icon: 'folder',
                          color: '#9E9E9E',
                          groupChatIds: [chatId],
                        );
                        await groupFolderController.fetchGroupFolders();

                        final FolderGroup? newArchiveFolder =
                            groupFolderController.groupFolders.firstWhereOrNull(
                                (f) =>
                                    f.name.toLowerCase().contains('archive'));
                        if (newArchiveFolder != null) {
                          state?._selectFolderById(newArchiveFolder.id);
                        }

                        snackBar(
                          title: 'success'.tr,
                          message: 'group_added_to_folder'.tr,
                        );
                      }
                    } catch (e) {
                      snackBar(
                        title: 'oops'.tr,
                        message: e.toString(),
                        isWarning: true,
                      );
                    }
                  },
                  backgroundColor: Colors.grey[600] ?? Colors.grey,
                  foregroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.archive_outlined, size: 18),
                      const SizedBox(height: 4),
                      Text(
                        'archive'.tr,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            child: CrossPlatformConversationGestureDetector(
              onTap: onTap,
              onLongPress: onLongTap,
              enableVibration: true,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isDrawer ? null : Get.width,
                padding: const EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: isDrawer
                      ? null
                      : Border.all(
                          color: borderColor,
                          width: isCurrentlySelected
                              ? selectedBorderWidth
                              : borderWidth,
                        ),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// Profile member section hidden - widget no longer used
// class _MoreMembersCircle extends StatelessWidget {
//   const _MoreMembersCircle();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 28,
//       height: 28,
//       decoration: const BoxDecoration(
//         color: Color(0xFFF6F6F6),
//         shape: BoxShape.circle,
//       ),
//       child: Center(
//         child: Builder(
//           builder: (_) {
//             final parent =
//                 context.findAncestorWidgetOfExactType<GroupCardWidget>();
//             final extra = (parent?.members.length ?? 0) - 3;
//             return MixedText(
//               '+$extra',
//               style: const TextStyle(
//                 color: Color(0xFF2C2C2C),
//                 fontSize: 11,
//                 fontWeight: FontWeight.w500,
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

class _TypeMessageWidget extends StatelessWidget {
  const _TypeMessageWidget({
    required this.typeMessage,
    required this.lastMessage,
    this.isForwarded = false,
  });
  final String typeMessage;
  final String lastMessage;
  final bool isForwarded;

  @override
  Widget build(BuildContext context) {
    final RxString rxTypeMessage = typeMessage.obs;
    final RxString rxLastMessage = lastMessage.obs;
    return Obx(() {
      if ([
        'VOICE',
        'IMAGE',
        'VIDEO',
        'FILE',
        'LOCATION',
        'STICKER',
        'ALBUM',
        'CALL',
        'CHECKLIST',
      ].contains(rxTypeMessage.value)) {
        IconData icon;
        String label;
        if (rxTypeMessage.value == 'CHECKLIST') {
          icon = Icons.checklist;
          // Try to parse checklist preview JSON
          String checklistTitle = 'Checklist';
          try {
            final preview = rxLastMessage.value;
            if (preview.trim().startsWith('{') &&
                preview.trim().endsWith('}')) {
              final Map<String, dynamic> json = jsonDecode(preview);
              if (json.containsKey('title')) {
                checklistTitle = json['title'].toString();
              }
            }
          } catch (_) {}
          label = checklistTitle;
          return Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: HighlightedText(
                  text: label,
                  highlightText: groupController.isSearching.value
                      ? groupController.searchQuery.value
                      : null,
                  style: SmallTextStyles.grey('label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  highlightStyle: SmallTextStyles.grey('label').copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ],
          );
        }
        switch (rxTypeMessage.value) {
          case 'VOICE':
            icon = Icons.mic;
            label = 'voice_message'.tr;
            break;
          case 'IMAGE':
            icon = Icons.image;
            label = 'image_message'.tr;
            break;
          case 'VIDEO':
            icon = Icons.videocam;
            label = 'video_message'.tr;
            break;
          case 'LOCATION':
            icon = Icons.location_on;
            label = 'location_message'.tr;
            break;
          case 'STICKER':
            icon = Icons.emoji_emotions_outlined;
            label = 'sticker'.tr;
            break;
          case 'ALBUM':
            icon = Icons.photo_library_outlined;
            label = 'album_message'.tr;
            break;
          case 'CALL':
            icon = Icons.call;
            label = 'call_message'.tr;
            break;
          case 'FILE':
          default:
            icon = Icons.insert_drive_file;
            label = 'file_message'.tr;
        }
        return Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: HighlightedText(
                text: label,
                highlightText: groupController.isSearching.value
                    ? groupController.searchQuery.value
                    : null,
                style: SmallTextStyles.grey('label'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                highlightStyle: SmallTextStyles.grey('label').copyWith(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      } else {
        // Extract content from forwarded message JSON if needed
        String displayText = rxLastMessage.value;
        bool isForwardedFromContent = isForwarded;

        // Check if the message is a forwarded message JSON wrapper
        if (displayText.trim().startsWith('{') &&
            displayText.trim().endsWith('}')) {
          try {
            final Map<String, dynamic> json =
                jsonDecode(displayText) as Map<String, dynamic>;

            // Check if it's a forwarded message
            if (json.containsKey('content') &&
                json.containsKey('isForwarded') &&
                json['isForwarded'] == true) {
              // Mark as forwarded if not already set
              isForwardedFromContent = true;
              // Extract the actual content from forwarded message
              final extractedContent = json['content']?.toString();
              if (extractedContent != null && extractedContent.isNotEmpty) {
                displayText = extractedContent;
              }
            } else if (json.containsKey('content')) {
              // Regular JSON with content field (not forwarded)
              displayText = json['content'].toString();
            }
          } catch (e) {
            // If parsing fails, use original text
          }
        }

        // Convert AppFlowy JSON to markdown/text if needed
        if (_isAppFlowyJson(displayText)) {
          displayText = _convertAppFlowyToText(displayText);
        }

        // Convert multi-line messages to a single line with '...' hint
        final trimmedText = displayText.trim();
        final previewText = trimmedText.contains('\n')
            ? '${trimmedText.replaceAll('\n', ' ')} ...'
            : trimmedText;

        // Show forward icon if message is forwarded (same as chat detail screen)
        return Row(
          children: [
            if (isForwardedFromContent)
              Icon(
                Icons.forward,
                size: 16,
                color: Colors.grey[600],
              ),
            if (isForwardedFromContent) const SizedBox(width: 4),
            Expanded(
              child: HighlightedText(
                text: previewText,
                highlightText: groupController.isSearching.value
                    ? groupController.searchQuery.value
                    : null,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
                highlightStyle: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF9E9E9E),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      }
    });
  }
}

class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final dashWidth = dashPattern[0];
    final dashSpace = dashPattern[1];
    final pathMetrics = path.computeMetrics().first;
    final distance = pathMetrics.length;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final start = i * (dashWidth + dashSpace);
      final end = start + dashWidth;
      if (end <= distance) {
        final dashPath = pathMetrics.extractPath(start, end);
        canvas.drawPath(dashPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
