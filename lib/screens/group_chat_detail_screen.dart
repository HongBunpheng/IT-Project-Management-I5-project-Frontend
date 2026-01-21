import 'dart:async';
import 'dart:convert';
import 'package:gate_khmer_ai/core/widgets/mixed_text.dart';
import 'dart:io';
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gate_khmer_ai/app_shell.dart';
import 'package:get/get.dart';
import 'package:gate_khmer_ai/core/config/avatar_url_checker.dart';
import 'package:gate_khmer_ai/core/config/buttons/buttons_widget.dart';
import 'package:gate_khmer_ai/core/config/snack_bar.dart';
import 'package:gate_khmer_ai/core/constants/controllers.dart';
import 'package:gate_khmer_ai/core/theme/colors.dart';
import 'package:gate_khmer_ai/core/utils/font_utils.dart';
import 'package:gate_khmer_ai/core/db/message_cache_db_helper.dart';
import 'package:gate_khmer_ai/core/utils/build_message_list_shimmer.dart';
import 'package:gate_khmer_ai/core/utils/build_user_online_status.dart';
import 'package:gate_khmer_ai/core/utils/format_time_stamp.dart';
import 'package:gate_khmer_ai/core/utils/loading_indicator.dart';
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:gate_khmer_ai/core/utils/network_utils.dart';
import 'package:gate_khmer_ai/core/utils/responsive_utils.dart';
import 'package:gate_khmer_ai/core/utils/user_status_utils.dart';
import 'package:gate_khmer_ai/core/widgets/drag_drop_wrapper.dart';
import 'package:gate_khmer_ai/features/components/bottom_navigation_bar/views/bottom_navigation_bar_screen.dart';
import 'package:gate_khmer_ai/features/components/drawer/views/custom_drawer.dart';
import 'package:gate_khmer_ai/features/components/message/views/message_input.dart';
import 'package:gate_khmer_ai/features/components/message/views/widgets/message_item/group_message_item.dart';
import 'package:gate_khmer_ai/features/components/message/views/widgets/message_option.dart'
    hide groupSocketService;
import 'package:gate_khmer_ai/features/screens/chat/models/checklist_message_model.dart';
import 'package:gate_khmer_ai/features/screens/chat/models/message_model.dart';
import 'package:gate_khmer_ai/features/screens/chat/models/pinned_messages_list_model.dart';
import 'package:gate_khmer_ai/features/screens/chat/views/header/widgets/profile_message.dart';
import 'package:gate_khmer_ai/features/screens/group/models/groups/group_by_id_response.dart';
import 'package:gate_khmer_ai/features/screens/group/views/group_detail/ai_group_insights_dialog.dart';
import 'package:gate_khmer_ai/features/screens/group/views/group_dialog.dart';
import 'package:gate_khmer_ai/features/screens/group/views/header/group_chat_header.dart';
import 'package:gate_khmer_ai/features/screens/setting/api_call/privacy_security_api.dart';
import 'package:gate_khmer_ai/services/global_rss_service.dart';
import 'package:gate_khmer_ai/services/network/network_service.dart';
import 'package:get/get.dart';
import 'package:gate_khmer_ai/core/widgets/authenticated_avatar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF2C2C2C)
          ..style = PaintingStyle.fill;

    // Data for the bar chart
    final data = [
      {'name': 'John Doe', 'value': 1.0},
      {'name': 'Emily Davis', 'value': 0.0},
      {'name': 'Michael Wilson', 'value': 2.0},
      {'name': 'Sarah Brown', 'value': 2.0},
    ];

    final barWidth = size.width / (data.length * 2); // Leave space between bars
    final maxValue = data.map((e) => e['value'] as double).reduce(max);
    final scale = size.height / maxValue;

    // Draw bars
    for (var i = 0; i < data.length; i++) {
      final value = data[i]['value'] as double;
      final height = value * scale;
      final left = i * barWidth * 2 + barWidth / 2;
      final top = size.height - height;

      canvas.drawRect(Rect.fromLTWH(left, top, barWidth, height), paint);

      // Draw name labels
      final name = data[i]['name'] as String;
      final textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: FontUtils.createTextStyle(
            name,
            color: const Color(0xFF9E9E9E),
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left - textPainter.width / 2 + barWidth / 2, size.height + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget wrapper for SelectionArea that allows long press to pass through on mobile
/// This prevents SelectionArea from intercepting long press gestures needed for message options
class _GroupSelectionAreaWrapper extends StatelessWidget {
  const _GroupSelectionAreaWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        !kIsWeb && (GetPlatform.isAndroid || GetPlatform.isIOS);

    // On mobile, don't use SelectionArea to avoid intercepting long press gestures
    // Long press is needed for message options (pin, delete, etc.)
    if (isMobile) {
      // Return child directly without SelectionArea on mobile
      // This allows long press gestures to reach MessageItem's GestureDetector
      return child;
    }

    // On desktop/web, use SelectionArea normally for text selection
    return SelectionArea(child: child);
  }
}

class GroupChatDetailScreen extends StatefulWidget {
  const GroupChatDetailScreen({
    super.key,
    this.hideDrawer = false,
    this.fromNotification = false,
  });
  final bool hideDrawer;
  final bool fromNotification;

  @override
  State<GroupChatDetailScreen> createState() => _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends State<GroupChatDetailScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep widget alive to prevent recreation

  late AnimationController _animationController;
  bool isImageLoading = false;
  // Use a local ScrollController to avoid attaching the shared controller to multiple ListViews
  final ScrollController _scrollController = ScrollController();
  // GlobalKey for MessageInput to maintain stability and prevent keyboard from closing
  late final GlobalKey _groupMessageInputKey;
  // Connectivity subscription
  // late final StreamSubscription _connectivitySubscription;

  // Add isPaginating flag
  bool isPaginating = false;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _initialMessagesSubscription;
  Worker? _groupChangeWorker; // Listen to group changes

  // Track the current group ID to detect group switches
  String _currentGroupId = '';

  // Track the last message for robust auto-scroll
  MessageModel? _lastMessage;

  // Track if initial group messages have been loaded
  bool _initialGroupMessagesLoaded = false;

  // Search controller and focus node
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  Worker? _searchFocusWorker;
  Worker? _readReceiptWorker; // Worker for read receipt listener
  final GlobalKey _searchTextFieldKey = GlobalKey();

  // Sticky date header state
  final Rx<DateTime?> _firstVisibleDate = Rx<DateTime?>(null);
  final RxBool _isScrolling = false.obs;
  Timer? _scrollTimer;

  // Note: Online status tracking is now handled centrally via chatController.usersOnlineStatus
  // No need for local tracking - the centralized map tracks all users automatically

  // Track last responsive change for throttling (from ChatDetailScreen pattern)
  DateTime? _lastResponsiveChange;
  // Track last screen size for resize detection
  Size? _lastScreenSize;

  @override
  void initState() {
    // Initialize GlobalKey for MessageInput to maintain stability
    final instanceId = DateTime.now().millisecondsSinceEpoch;
    _groupMessageInputKey = GlobalKey(
      debugLabel: 'groupMessageInput_$instanceId',
    );

    // Listen to search state changes to auto-focus search field
    _searchFocusWorker = ever(groupController.isSearching, (isSearching) {
      if (isSearching && mounted) {
        // Request focus after widget is built and animation starts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && groupController.isSearching.value) {
            searchFocusNode.requestFocus();
          }
        });
        // Also request focus after animation completes as backup (AnimatedSwitcher duration is 250ms)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted &&
              groupController.isSearching.value &&
              !searchFocusNode.hasFocus) {
            searchFocusNode.requestFocus();
          }
        });
        // Final backup - request focus again after a longer delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted &&
              groupController.isSearching.value &&
              !searchFocusNode.hasFocus) {
            searchFocusNode.requestFocus();
          }
        });
      }
    });

    // Add debug print to check if this is from a killed state notification
    // If opened from a notification, keep the flag true while this screen is alive
    if (widget.fromNotification) {
      groupController.isFromNotificationTap.value = true;
    }
    groupController.isGroupInitializing.value = false;
    groupController
        .resetShimmerState(); // Reset shimmer state when entering group chat
    super.initState();
    // Ensure no lingering focus from previous screens
    FocusManager.instance.primaryFocus?.unfocus();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Set up online status tracking for group members
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupOnlineStatusTracking();
    });

    // Check for blocked members after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBlockedMembers(context);
      // Load pinned messages for the group chat
      final groupChatId = groupController.groupById.value.chatId;
      if (groupChatId.isNotEmpty) {
        chatController.getPinnedMessages(groupChatId);
      }
    });

    // --- Rehydrate decryptedContentCache for all visible group messages ---
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _rehydrateVoiceMessageCache();
    });

    // Remove AnimatedList insertItem logic
    // groupController.groupMessages.listen((messages) {
    //   if (_listKey.currentState != null && messages.isNotEmpty) {
    //     // Insert at the top (reverse: true)
    //     _listKey.currentState!.insertItem(0);
    //   }
    // });
    // Optionally, scroll to top when a new message arrives
    // Use proper subscription management to avoid disposal issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagesSubscription = groupController.groupMessages.listen((messages) {
        if (mounted && _scrollController.hasClients) {
          // Only scroll if a new message is added at the bottom (not when loading more)
          if (_lastMessage == null ||
              (messages.isNotEmpty && messages.first.id != _lastMessage!.id)) {
            if (!isPaginating) {
              final position = _scrollController.position;
              final isNearBottom =
                  position.pixels <= 100; // reverse: true, 0 is bottom
              final isSentByMe =
                  messages.isNotEmpty &&
                  messages.first.senderId == authController.user.value.id;
              if (isSentByMe || isNearBottom) {
                _scrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            }
          }
          // Update the last message reference
          if (messages.isNotEmpty) {
            _lastMessage = messages.first;
          }
        }
      });
    });

    // Listen for loading more messages when scrolled to top
    _scrollController.addListener(_onScrollLoadMore);

    // Listen for when group messages are first loaded
    // Use proper subscription management to avoid disposal issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialMessagesSubscription = groupController.groupMessages.listen((
        messages,
      ) {
        if (mounted && messages.isNotEmpty && !_initialGroupMessagesLoaded) {
          _initialGroupMessagesLoaded = true;
        }
      });

      // Initialize current group ID from selectedGroup or currentGroupId
      final initialSelectedGroup = groupController.selectedGroup.value;
      if (initialSelectedGroup != null) {
        _currentGroupId = initialSelectedGroup.id;
      } else {
        _currentGroupId = groupController.currentGroupId.value;
      }

      // Listen to group changes (selectedGroup) to reload messages only
      // This prevents full screen rebuild when switching groups
      _groupChangeWorker = ever(groupController.selectedGroup, (selectedGroup) {
        if (mounted && selectedGroup != null) {
          final newGroupId = selectedGroup.id;
          // Only load messages if group actually changed and is not empty
          if (newGroupId != _currentGroupId &&
              newGroupId.isNotEmpty &&
              _currentGroupId.isNotEmpty) {
            final oldGroupId = _currentGroupId;
            _currentGroupId = newGroupId;
            // Only load messages, don't rebuild the entire screen
            _loadMessagesForGroup(newGroupId, selectedGroup.chatId);
          } else if (_currentGroupId.isEmpty && newGroupId.isNotEmpty) {
            // First time loading a group
            _currentGroupId = newGroupId;
          }
        }
      });
    });

    // Handle notification tap scenario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // For notification taps, delay setting isGroupInitializing to false to prevent GroupScreen interference
      if (groupController.isFromNotificationTap.value ||
          widget.fromNotification) {
        // For notification navigation, also ensure we're on the correct tab
        bottomNavigationBarController.currentIndex.value = 1;

        // For notification taps, delay setting isGroupInitializing to false to prevent GroupScreen worker interference
      } else {
        groupController.isGroupInitializing.value = false;
      }
    });

    // Send read receipts ONLY when user actually opens the group chat screen
    // This ensures messages are only marked as read when user views them, not on app restart
    // Wait for messages to be loaded before sending read receipts for real-time UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if messages are already loaded (fast path)
      if (groupController.groupMessages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            final groupId = groupController.groupById.value.id;
            final groupChatId = groupController.groupById.value.chatId;

            if (groupId.isNotEmpty && groupChatId.isNotEmpty) {
              groupController.sendGroupReadReceiptsWhenViewing(groupId);
            }
          }
        });
      } else {
        // Wait for messages to load, then send read receipts
        // Use a one-time listener that auto-disposes after first trigger
        _readReceiptWorker = ever(groupController.groupMessages, (messages) {
          if (mounted && messages.isNotEmpty && _readReceiptWorker != null) {
            final groupId = groupController.groupById.value.id;
            final groupChatId = groupController.groupById.value.chatId;

            if (groupId.isNotEmpty && groupChatId.isNotEmpty) {
              // Send read receipts after messages are loaded
              // This ensures the UI can update immediately when status changes
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  groupController.sendGroupReadReceiptsWhenViewing(groupId);
                }
              });
              // Dispose the worker after first successful trigger
              _readReceiptWorker?.dispose();
              _readReceiptWorker = null;
            }
          }
        });

        // Fallback: Send after delay if messages still not loaded
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted && _readReceiptWorker != null) {
            _readReceiptWorker?.dispose();
            _readReceiptWorker = null;
            final groupId = groupController.groupById.value.id;
            final groupChatId = groupController.groupById.value.chatId;

            if (groupId.isNotEmpty &&
                groupChatId.isNotEmpty &&
                groupController.groupMessages.isNotEmpty) {
              groupController.sendGroupReadReceiptsWhenViewing(groupId);
            }
          }
        });
      }
    });

    // Add a longer delay to ensure proper navigation handling for notification taps
    // Skip resetting navigation flags when opened from a notification
    if (widget.fromNotification) {
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        // Always reset flags regardless of mounted state to prevent stuck states
        // The mounted check was causing issues with notification navigation
        groupController.hasNavigatedToGroupChat.value = false;

        // Handle notification vs normal navigation
        if (groupController.isFromNotificationTap.value ||
            widget.fromNotification) {
          // For notification taps, set isGroupInitializing to false after delay to prevent GroupScreen interference
          groupController.isGroupInitializing.value = false;
          // For notification taps, keep isFromNotificationTap true until user goes back
          // This ensures proper back navigation behavior
        } else {
          groupController.isFromNotificationTap.value = false;
          groupController.isGroupInitializing.value = false;
        }
      });
    }

    // Listen for connectivity changes
    // _connectivitySubscription =
    //     Connectivity().onConnectivityChanged.listen((result) {
    //   if (result != ConnectivityResult.none) {
    //     // Network is back, reload group messages from server
    //     groupController
    //         .getOptimizedGroupMessages(groupController.groupById.value.id);
    //   }
    // });

    // Removed auto-focus behavior
  }

  void _onScrollLoadMore() {
    // If the user scrolls near the top (reverse: true, so offset near maxScrollExtent)
    if (_scrollController.hasClients) {
      final position = _scrollController.position;

      // Update scrolling state
      _isScrolling.value = true;
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 300), () {
        _isScrolling.value = false;
      });

      // Update first visible date based on scroll position
      _updateFirstVisibleDate();

      if (position.pixels >= position.maxScrollExtent - 100) {
        // Load more messages
        if (!isPaginating) {
          isPaginating = true;
          groupController
              .loadMoreGroupMessages(groupController.groupById.value.id)
              .whenComplete(() {
                isPaginating = false;
              });
        }
      }
    }
  }

  void _updateFirstVisibleDate() {
    if (!_scrollController.hasClients) return;

    final messages = groupController.groupMessages;
    if (messages.isEmpty) return;

    final position = _scrollController.position;
    // For reversed ListView, pixels = 0 is at the bottom (newest messages)
    // We need to estimate which message is visible at the top of the viewport
    // Since ListView is reversed, we calculate from the bottom
    final scrollOffset = position.pixels;

    // Estimate item height (average message height)
    const estimatedItemHeight = 80.0;

    // Calculate which item index is at the top of the viewport
    // In a reversed list, index 0 is at the bottom (pixels = 0)
    // As we scroll up (pixels increase), we see older messages (higher indices)
    final itemsFromBottom = (scrollOffset / estimatedItemHeight).floor();
    final estimatedIndex = itemsFromBottom.clamp(0, messages.length - 1);

    if (estimatedIndex < messages.length) {
      final message = messages[estimatedIndex];
      final dateTime = message.scheduledAt ?? message.createdAt;
      _firstVisibleDate.value = dateTime.toLocal();
    }
  }

  /// Load messages for a group without rebuilding the entire screen
  /// This is called when switching groups to optimize performance
  Future<void> _loadMessagesForGroup(String groupId, String chatId) async {
    if (!mounted) return;

    try {
      // Immediately set isGroupInitializing to false to prevent any loading UI
      groupController.isGroupInitializing.value = false;

      // Reset pagination state
      groupController.resetMessagePagination();

      // Set the current group ID
      groupController.currentGroupId.value = groupId;

      // Reset initial messages loaded flag
      _initialGroupMessagesLoaded = false;
      _lastMessage = null;

      // Check network status
      final bool isOnline = await NetworkUtils.checkConnectionWithError();

      if (isOnline) {
        // Load group info and cached messages
        await groupController.fetchGroupById(groupId);
        await groupController.getOptimizedGroupMessages(groupId);
        // Keep isGroupInitializing false - no loading UI
        groupController.isGroupInitializing.value = false;

        // Update online status tracking for new group members
        _setupOnlineStatusTracking();

        // Clear unread count when user opens the group chat
        if (chatId.isNotEmpty) {
          chatController.clearUnreadCountForChat(chatId);
        }

        // Load scheduled messages in background for this chat
        messageInputController.getScheduledMessages(
          isGroup: true,
          chatId: chatId,
        );

        // Ensure socket is connected and join group
        if (!chatService.isSocketConnected) {
          if (authController.acessToken != null) {
            await chatService.connectWebSocket(authController.acessToken!);
          }
          if (!chatService.isSocketConnected) {
            return;
          }
        }

        groupSocketService.joinGroup(chatId, (resp) async {
          if (resp['success'] == false) {
            snackBar(
              title: 'Error',
              message: resp['error'] ?? 'Failed to join group',
              isWarning: true,
            );
            return;
          }
          if (resp['success'] == true && resp['group'] != null && mounted) {
            // Group joined successfully, messages will be updated via stream
            // Ensure group listeners are set up (for typing and recording indicators)
            // This is important in case the socket reconnected or listeners weren't set up yet
            groupChatService.setupGroupListenersOnConnection(force: true);
          }
        });

        // Load pinned messages for the group chat
        if (chatId.isNotEmpty) {
          chatController.getPinnedMessages(chatId);
        }

        // Send read receipts
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && groupId.isNotEmpty) {
            groupController.sendGroupReadReceiptsWhenViewing(groupId);
          }
        });
      } else {
        // Offline mode - load from cache
        await groupController.fetchGroupById(groupId);
        await groupController.getOptimizedGroupMessages(groupId);
        // Keep isGroupInitializing false - no loading UI
        groupController.isGroupInitializing.value = false;

        // Clear unread count
        if (chatId.isNotEmpty) {
          chatController.clearUnreadCountForChat(chatId);
        }
      }

      // Scroll to bottom after messages are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      groupController.isGroupInitializing.value = false;
    }
  }

  /// Set up socket listeners to track online status for all group members
  /// Note: Online status is now tracked centrally via chatController.usersOnlineStatus
  /// This method is kept for backward compatibility but no longer needed
  /// The centralized tracking in ChatService handles all user_online/user_offline events
  void _setupOnlineStatusTracking() {
    if (!mounted) return;
    // No local tracking needed - centralized map in chatController handles everything
  }

  Future<void> _checkBlockedMembers(BuildContext context) async {
    final groupId = groupController.groupById.value.id;
    final userId = authController.user.value.id;
    final alertKey = '$groupId-$userId';

    if (groupController.shownBlockedAlerts.contains(alertKey)) return;
    groupController.shownBlockedAlerts.add(alertKey);

    final token = authController.acessToken;
    if (token == null) return;
    try {
      final blockedUsers = await fetchBlockedUsers(token);
      final blockedUserIds = blockedUsers.map((u) => u.id).toSet();
      final groupMembers = groupController.groupById.value.members;
      final blockedMembers =
          groupMembers.where((m) => blockedUserIds.contains(m.userId)).toList();
      if (blockedMembers.isNotEmpty) {
        final names = blockedMembers.map((m) => m.user.name).join(', ');
        snackBar(
          title: 'blocked_members'.tr,
          message:
              blockedMembers.length == 1
                  ? 'You have blocked this member in the group: $names.'
                  : 'You have blocked these members in the group: $names.',
          isWarning: true,
        );
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Utility to rehydrate decryptedContentCache for all visible group messages
  Future<void> _rehydrateVoiceMessageCache() async {
    final messages = groupController.groupMessages;
    for (final msg in messages) {
      if (msg.type == 'VOICE' && msg.content.startsWith('/')) {
        final file = File(msg.content);
        if (await file.exists()) {
          await MessageCacheDbHelper().cacheDecryptedContent(
            msg.id,
            msg.content,
            'VOICE',
            filePath: msg.content,
          );
        }
      }
    }
    // SQLite cache is automatically managed
  }

  @override
  void dispose() {
    groupController.isGroupInitializing.value = false;
    groupController.currentGroupId.value = '';

    messageInputController.textMessageController.value.clear();
    // Clear message input when leaving the group chat screen
    messageInputController.messageText.value = '';

    // Reset initial messages loaded flag
    _initialGroupMessagesLoaded = false;

    _animationController.dispose();
    // Remove scroll listener and dispose safely
    if (_scrollController.hasClients) {
      _scrollController.removeListener(_onScrollLoadMore);
    }
    _scrollController.dispose();
    // Cancel stream subscriptions
    _messagesSubscription?.cancel();
    _initialMessagesSubscription?.cancel();
    // Dispose search focus worker
    _searchFocusWorker?.dispose();
    // Dispose group change worker
    _groupChangeWorker?.dispose();
    // Dispose read receipt worker
    _readReceiptWorker?.dispose();
    // Dispose search controller and focus node
    searchController.dispose();
    searchFocusNode.dispose();
    // Clean up online status tracking
    if (chatService.socket != null) {
      try {
        chatService.socket!.off('user_online');
        chatService.socket!.off('user_offline');
      } catch (e) {}
    }
    // Note: Online status tracking is now centralized - no cleanup needed
    // Cancel connectivity subscription
    // _connectivitySubscription.cancel();

    // Reset navigation flags when group chat detail screen is disposed
    groupController.hasNavigatedToGroupChat.value = false;

    // Handle disposal for notification taps
    if (groupController.isFromNotificationTap.value) {
      // Don't reset notification flags immediately - let the navigation system handle it
      // This prevents the flag from being reset when the screen is rebuilt
      groupController.isGroupInitializing.value = false;
    } else {
      groupController.isFromNotificationTap.value = false;
    }
    chatService.sendActiveChatChanged(null);

    super.dispose();
  }

  // Add method to handle responsive changes
  void _handleResponsiveChange() {
    // Throttle calls to prevent excessive re-renders (from ChatDetailScreen)
    if (_lastResponsiveChange != null &&
        DateTime.now().difference(_lastResponsiveChange!).inMilliseconds <
            100) {
      return;
    }
    _lastResponsiveChange = DateTime.now();

    // Use direct screen size check instead of ResponsiveUtils to avoid timing issues
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isLandscape = screenWidth > screenHeight;

    // More conservative thresholds for mobile detection
    final isMobile = screenWidth < 1024 || !isLandscape;

    // If user resizes from mobile to desktop, navigate back to group list
    if (!isMobile && !widget.hideDrawer) {
      // Navigate back to group list
      Get.back();
      return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentSize = MediaQuery.of(context).size;

        // Only handle if screen size actually changed (not just keyboard opening)
        if (_lastScreenSize == null ||
            _lastScreenSize!.width != currentSize.width ||
            _lastScreenSize!.height != currentSize.height) {
          _lastScreenSize = currentSize;

          // Only handle responsive changes for desktop/web (width > 600)
          if (currentSize.width > 600) {
            _handleResponsiveChange();
          } else {}
        } else {}
      }
    });
  }

  @override
  void didUpdateWidget(GroupChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle hideDrawer parameter changes
    if (oldWidget.hideDrawer != widget.hideDrawer && widget.hideDrawer) {
      Get.back();
    }

    // Handle responsive changes (mobile to desktop or vice versa)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleResponsiveChange();
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final drawerKey = GlobalKey<ScaffoldState>();
    final responsive = ResponsiveUtils(context);

    return AppShell(
      child: PopScope(
        onPopInvoked: (bool didPop) {
          // Use post frame callback to avoid setState during navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Safely clear focus before tearing down widgets
              FocusManager.instance.primaryFocus?.unfocus();

              if (chatController.isDrawerOpen.value) {
                drawerKey.currentState?.closeDrawer();
              }

              // Reset navigation flags when user goes back
              groupController.hasNavigatedToGroupChat.value = false;

              // Reset all flags
              groupController.isFromNotificationTap.value = false;
              groupController.isGroupInitializing.value = false;
            }
          });
        },
        child: Stack(
          children: [
            Scaffold(
              key: drawerKey,
              backgroundColor: Colors.white,
              resizeToAvoidBottomInset: true,
              // Prevent keyboard from dismissing on tap outside
              extendBody: false,
              drawer:
                  (responsive.isDesktop ||
                          responsive.isIPadLandscape ||
                          widget.hideDrawer)
                      ? null
                      : CustomDrawer(
                        onChatSelected: () {
                          if (chatController.isDrawerOpen.value) {
                            drawerKey.currentState?.closeDrawer();
                          }
                        },
                      ),
              drawerEnableOpenDragGesture:
                  !(responsive.isDesktop ||
                      responsive.isIPadLandscape ||
                      widget.hideDrawer),
              drawerScrimColor: Colors.black54,
              drawerEdgeDragWidth: Get.width * 0.2,
              appBar: GroupChatHeader(
                onMenuTap: () {
                  if (!(responsive.isDesktop ||
                      responsive.isIPadLandscape ||
                      widget.hideDrawer)) {
                    drawerKey.currentState?.openDrawer();
                  }
                },
                // onCallTap: () async {
                //   await groupCallController.startGroupCall();
                // },
                onInfoTap: () {
                  // Navigate to settings with proper navigation context
                  Get.to(() => BottomNavigationBarScreen());
                  bottomNavigationBarController.currentIndex.value = 4;
                  settingsController.selectedTab.value = 3;
                },
                context: context,
                onGroupInfoTap: (context) async {
                  final hasConnection =
                      await NetworkUtils.checkConnectionWithError();
                  _buildMoreDialog(
                    context,
                    groupController.groupById.value.name,
                    groupController.groupById.value.members,
                    hasConnection: hasConnection,
                  );
                },
                onMoreTap: () {
                  if (groupController.isSearching.value) {
                    // Close search
                    groupController.isSearching.value = false;
                    groupController.searchQuery.value = '';
                    searchController.clear();
                    searchFocusNode.unfocus();
                  } else {
                    // Open search
                    groupController.isSearching.value = true;
                    groupController.searchMessages(
                      groupController.groupById.value.id,
                      groupController.searchQuery.value,
                    );
                    // Focus will be handled by the ever() listener in initState
                  }
                },
                hideDrawer:
                    responsive.isDesktop ||
                    responsive.isIPadLandscape ||
                    widget.hideDrawer,
              ),
              body: DragDropWrapper(
                targetId: groupController.groupById.value.chatId,
                isGroup: true,
                onFileDropped: () {},
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      children: [
                        // Search bar (same style as personal chat)
                        _buildSearchBar(),
                        // Header section with Pin, RSS, and Checklist tabs
                        _buildHeaderSection(),
                        // Message list area - keyboard won't auto-dismiss on scroll
                        // Use Listener to dismiss keyboard when tapping in message list (not search bar or message input)
                        Expanded(
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: (_) {
                              // Only dismiss keyboard if not searching
                              // When searching, allow search field to maintain focus
                              if (!groupController.isSearching.value) {
                                FocusScope.of(context).unfocus();
                              }
                            },
                            child: _buildListChat(context),
                          ),
                        ),
                        // Only show sending indicator if actually sending a message, not when loading messages
                        // Wrapped in RepaintBoundary to prevent rebuilds when keyboard opens
                        RepaintBoundary(
                          child: Obx(() {
                            if (groupController
                                    .loadingMessage
                                    .value
                                    .isNotEmpty &&
                                (groupController.loadingMessage.value.contains(
                                      'sending',
                                    ) ||
                                    groupController.loadingMessage.value
                                        .contains('uploading'))) {
                              return buildSendingMessageIndicator();
                            }
                            return const SizedBox.shrink();
                          }),
                        ),

                        // Typing and Recording Indicators - wrapped in RepaintBoundary to prevent rebuilds
                        RepaintBoundary(
                          child: Obx(() {
                            final chatId =
                                groupController.groupById.value.chatId;
                            if (chatId.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            // Access reactive Rx objects directly so Obx can track them
                            // GetX tracks the Rx object, then we access .value to get the data
                            final typingDataRx =
                                groupChatService.groupUserTypingData;
                            final recordingDataRx =
                                groupChatService.groupUserRecordingVoiceData;
                            final typingData = typingDataRx.value;
                            final recordingDataMap = recordingDataRx.value;

                            // Debug: Log reactive value state

                            // Check if typing indicator is for this group using group-specific service
                            if (typingData.isTyping &&
                                typingData.chatId == chatId &&
                                typingData.senderId !=
                                    authController.user.value.id) {
                              // Get user name from group members - always use name
                              final typingUserId = typingData.senderId;
                              final member = groupController
                                  .groupById
                                  .value
                                  .members
                                  .firstWhereOrNull(
                                    (m) => m.userId == typingUserId,
                                  );
                              // Always use name if available and not empty, otherwise fallback to 'Someone'
                              final userName =
                                  member != null
                                      ? (member.user.name.isNotEmpty
                                          ? member.user.name
                                          : 'Someone')
                                      : 'Someone';

                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  bottom: 8,
                                ),
                                child: buildTypingIndicator(name: userName),
                              );
                            }

                            // Check if someone is recording a voice message using group-specific service
                            // For groups we only care that another user is recording;
                            // the socket event may include chatId to scope it.
                            if (recordingDataMap != null) {
                              final senderUserId =
                                  recordingDataMap['senderUserId'] as String?;
                              // Handle both bool and dynamic types for isRecording
                              final isRecordingValue =
                                  recordingDataMap['isRecording'];
                              final isRecording =
                                  isRecordingValue == true ||
                                  isRecordingValue == 1 ||
                                  isRecordingValue == 'true';
                              final recordingChatId =
                                  recordingDataMap['chatId'] as String?;

                              // If chatId is provided, ensure it matches this group's chatId.
                              // If not provided (null/empty), show the indicator since we're
                              // in a specific group detail screen context.
                              final bool isSameGroup =
                                  recordingChatId == null ||
                                  recordingChatId.isEmpty ||
                                  recordingChatId == chatId;

                              if (senderUserId != null &&
                                  senderUserId !=
                                      authController.user.value.id &&
                                  isRecording &&
                                  isSameGroup) {
                                // Get user name from group members - always use name
                                final member = groupController
                                    .groupById
                                    .value
                                    .members
                                    .firstWhereOrNull(
                                      (m) => m.userId == senderUserId,
                                    );
                                // Always use name if available and not empty, otherwise fallback to 'Someone'
                                final userName =
                                    (member != null &&
                                            member.user.name.isNotEmpty)
                                        ? member.user.name
                                        : 'Someone';

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 8,
                                  ),
                                  child: buildVoiceRecordingIndicator(
                                    name: userName,
                                  ),
                                );
                              } else {}
                            } else {}

                            return const SizedBox.shrink();
                          }),
                        ),

                        // Show selection actions bar when in selection mode, otherwise show MessageInput
                        // Use a wrapper widget that isolates MessageInput from reactive rebuilds
                        _GroupMessageInputWrapper(
                          key: _groupMessageInputKey,
                          buildSelectionActions: _buildSelectionActions,
                        ),
                      ],
                    ),
                    // Sticky date header that shows when scrolling - positioned below RSS Feeds header section
                    Obx(() {
                      // Calculate position dynamically:
                      // AppBar: ~56px
                      // Search bar: always visible, ~68px (10px top margin + ~48px height + 10px bottom margin)
                      // Header section: ~48px (8px top padding + ~40px content + 8px bottom padding), hidden when searching or in selection mode
                      final appBarHeight = 56.0;
                      final searchBarHeight = 68.0; // Always visible
                      final headerSectionHeight =
                          (chatController.isSelectionMode.value ||
                                  groupController.isSearching.value)
                              ? 0.0
                              : 48.0;
                      final topPosition =
                          appBarHeight + searchBarHeight + headerSectionHeight;

                      return Positioned(
                        top:
                            topPosition, // Position below the header section (RSS Feeds)
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isScrolling.value ? 1.0 : 0.0,
                          child: _buildStickyDateHeader(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed focus helper to comply with no auto-focus requirement

  /// Handle finding and scrolling to a message by index
  void handleFindTheIndexOfTheMessage(MessageModel message, int index) {
    if (message.id.isEmpty) {
      return;
    }

    final messageIndex = groupController.groupMessages.indexWhere(
      (msg) => msg.id == message.id,
    );

    if (messageIndex != -1) {
      // Scroll to the message - ListView is reversed, so we need to calculate the position
      final reversedIndex =
          groupController.groupMessages.length - 1 - messageIndex;
      if (_scrollController.hasClients) {
        // Estimate item height (adjust based on your actual message height)
        const estimatedItemHeight = 100.0;
        final targetOffset = reversedIndex * estimatedItemHeight;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {}
  }

  /// Simplified group message list to behave like private chat:
  /// - Single Obx watching the messages list
  /// - Plain ListView.builder with stable keys
  /// - No extra wrappers/caching that can recreate audio widgets
  Widget _buildListChat(BuildContext context) {
    // Use a StatefulWidget wrapper to prevent rebuilds when keyboard opens
    return _StableMessageListWidget(
      scrollController: _scrollController,
      onHandleMessageTap:
          (message) => _handleMessageTap(message, context, isGroup: true),
      onBuildSearchResultItem:
          (message, context) => _buildSearchResultItem(message, context),
      formatDate: _formatDate,
    );
  }

  Future<dynamic> _buildMoreDialog(
    BuildContext context,
    String name,
    List<GroupByIdMember> members, {
    bool hasConnection = true,
  }) {
    final responsive = ResponsiveUtils(context);
    // DEBUG: Print groupById contents when opening group info modal
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.95,
              maxChildSize: 0.95,
              minChildSize: 0.75,
              expand: false,
              builder:
                  (context, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 6, bottom: 2),
                            width: 28,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(1.25),
                            ),
                          ),
                        ),
                        // Group info header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Profile title (Bigger and bolder)
                                    MixedText(
                                      'profile'.tr,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C2C2C),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Avatar with enhanced shadow
                                    Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.12,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                              spreadRadius: -2,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.network(
                                            groupController
                                                    .groupById
                                                    .value
                                                    .avatarUrl ??
                                                '',
                                            width:
                                                responsive.isDesktop ? 80 : 100,
                                            height:
                                                responsive.isDesktop ? 80 : 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              final size =
                                                  responsive.isDesktop
                                                      ? 80
                                                      : 100;
                                              return CircleAvatar(
                                                radius: size / 2,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child: Icon(
                                                  Icons.group,
                                                  color: Colors.grey[600],
                                                  size: size * 0.45,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Group name with better typography
                                    MixedText(
                                      groupController.groupById.value.name,
                                      style: TextStyle(
                                        fontSize:
                                            responsive.isDesktop ? 18 : 20,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1A1A1A),
                                        letterSpacing: -0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    // Created date with modern pill design
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F2F5),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey[300]!.withOpacity(
                                            0.5,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: MixedText(
                                        '${'created_on'.tr} ${formatTimestamp(groupController.groupById.value.createdAt.toString())}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF5F6368),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Bio Section with improved design
                                    if ((groupController
                                            .groupById
                                            .value
                                            .description)
                                        .isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[200]!,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.description_outlined,
                                                  size: 14,
                                                  color: Colors.blueGrey[400],
                                                ),
                                                const SizedBox(width: 8),
                                                MixedText(
                                                  'description'.tr,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.blueGrey[600],
                                                    letterSpacing: 0.5,
                                                    textBaseline:
                                                        TextBaseline.alphabetic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            MixedText(
                                              groupController
                                                  .groupById
                                                  .value
                                                  .description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: const Color(0xFF3C4043),
                                                height: 1.5,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons with modern card design
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (groupController.groupById.value.members.any(
                                (member) =>
                                    member.role == 'ADMIN' &&
                                    member.userId ==
                                        authController.user.value.id,
                              ))
                                _buildActionButton(
                                  icon: Icons.person_add_outlined,
                                  label: 'add_members'.tr,
                                  backgroundColor: const Color(0xFFE8F5E8),
                                  iconColor: const Color(0xFF2E7D32),
                                  onTap:
                                      () => showMemberSelectionDialog(
                                        groupController.selectedMembers,
                                        ifAddMemberInGroup: true,
                                      ),
                                ),
                              if (groupController.groupById.value.members.any(
                                (member) =>
                                    member.role == 'ADMIN' &&
                                    member.userId ==
                                        authController.user.value.id,
                              ))
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  label: 'edit_group'.tr,
                                  backgroundColor: const Color(0xFFE3F2FD),
                                  iconColor: const Color(0xFF1976D2),
                                  onTap: () => _showEditGroupDialog(),
                                ),
                              _buildActionButton(
                                icon: Icons.auto_awesome,
                                label: 'insights'.tr,
                                backgroundColor: const Color(0xFFFFF8E1),
                                iconColor: const Color(0xFFF57C00),
                                onTap:
                                    () => showAIGroupInsightsBottomSheet(
                                      context,
                                      groupId:
                                          groupController
                                              .groupById
                                              .value
                                              .chatId,
                                    ),
                              ),
                              _buildActionButton(
                                icon: Icons.more_horiz_outlined,
                                label: 'more'.tr,
                                backgroundColor: const Color(0xFFF3E5F5),
                                iconColor: const Color(0xFF7B1FA2),
                                onTap: () => _showActionsDialog(context),
                              ),
                            ],
                          ),
                        ),
                        // Members section
                        _buildMembersSection(context, members),
                      ],
                    ),
                  ),
            ),
          ),
    );
  }

  Padding _buildMembersSection(
    BuildContext context,
    List<GroupByIdMember> allMembers,
  ) {
    // Ensure current user is at the top of the list
    final String currentUserId = authController.user.value.id;
    final List<GroupByIdMember> sortedMembers = [
      ...allMembers.where((m) => m.userId == currentUserId),
      ...allMembers.where((m) => m.userId != currentUserId),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Members header with modern design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(() {
                    // Count online members using the centralized status map
                    final onlineCount =
                        sortedMembers
                            .where(
                              (member) =>
                                  UserStatusUtils.isUserOnline(member.userId),
                            )
                            .length;

                    return Row(
                      children: [
                        MixedText(
                          '${'members'.tr} (${sortedMembers.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color:
                                    onlineCount > 0
                                        ? Colors.green
                                        : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            MixedText(
                              '$onlineCount ${'online'.tr}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    onlineCount > 0
                                        ? Colors.green
                                        : Colors.grey,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Members list with enhanced container - now acts as the light grey background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50], // Light grey background
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[200]!, width: 0.5),
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: sortedMembers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder:
                  (context, index) =>
                      _buildMemberItemWithRemove(context, sortedMembers[index]),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog() {
    final TextEditingController nameController = TextEditingController(
      text: groupController.groupById.value.name,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: groupController.groupById.value.description,
    );
    XFile? selectedImage;

    Future<void> _pickImage() async {
      if (mounted) {
        setState(() {
          isImageLoading = true;
        });
      }
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedImage = pickedFile;
        // Force rebuild to show new image
        Get.forceAppUpdate();
      }
      if (mounted) {
        setState(() {
          isImageLoading = false;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.95,
                    minChildSize: 0.7,
                    expand: false,
                    builder:
                        (context, scrollController) => SingleChildScrollView(
                          controller: scrollController,
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
                                const SizedBox(height: 20),
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () => Get.back(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.transparent,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    MixedText(
                                      'edit_group'.tr,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => Get.back(),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                MixedText(
                                  'make_changes_to_your_group_here_click_save_when_you_re_done'
                                      .tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(
                                      0xFF2C2C2C,
                                    ).withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Group Profile Image
                                Center(
                                  child: Stack(
                                    children: [
                                      ClipOval(
                                        child:
                                            isImageLoading
                                                ? SizedBox(
                                                  width: 80,
                                                  height: 80,
                                                  child: Center(
                                                    child:
                                                        buildLoadingIndicator(),
                                                  ),
                                                )
                                                : (selectedImage != null
                                                    ? (kIsWeb
                                                        ? Image.network(
                                                          selectedImage!.path,
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover,
                                                        )
                                                        : Image.file(
                                                          File(
                                                            selectedImage!.path,
                                                          ),
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover,
                                                        ))
                                                    : ClipOval(
                                                      child: Image.network(
                                                        groupController
                                                                .groupById
                                                                .value
                                                                .avatarUrl ??
                                                            '',
                                                        width: 80,
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return CircleAvatar(
                                                            radius: 40,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[200],
                                                            child: Icon(
                                                              Icons.group,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              size: 32,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap: () async {
                                            await _pickImage();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Group Info
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.group_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MixedText(
                                          '${groupController.groupById.value.totalMemberCount} members',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(
                                              0xFF2C2C2C,
                                            ).withOpacity(0.6),
                                          ),
                                        ),
                                        MixedText(
                                          'Created on ${formatTimestamp(groupController.groupById.value.createdAt.toString())}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(
                                              0xFF2C2C2C,
                                            ).withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Group Name Input
                                MixedText(
                                  'group_name'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: nameController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: InputBorder.none,
                                      hintText: 'enter_group_name'.tr,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Group Description Input
                                MixedText(
                                  'description'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: descriptionController,
                                    maxLines: 3,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: InputBorder.none,
                                      hintText: 'enter_group_description'.tr,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Buttons
                                SizedBox(
                                  width: double.infinity,
                                  child: FillButton(
                                    onTap: () {
                                      groupController.updateGroupInfo(
                                        groupController.groupById.value.id,
                                        name: nameController.text,
                                        description: descriptionController.text,
                                        avatarFile: selectedImage,
                                      );
                                    },
                                    name: 'save_changes'.tr,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlineButton(
                                    onTap: () => Get.back(),
                                    name: 'cancel'.tr,
                                  ),
                                ),
                                // Add bottom padding for safe area
                                SizedBox(
                                  height: MediaQuery.of(context).padding.bottom,
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
          ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ZoomTapAnimation(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor.withOpacity(0.9),
                    backgroundColor.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  label == 'Mute'
                      ? (groupController.isMuted.value
                          ? Icons.notifications_off_outlined
                          : Icons.notifications_outlined)
                      : icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            MixedText(
              label == 'Mute'
                  ? (groupController.isMuted.value ? 'Unmute' : 'Mute')
                  : label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C2C).withOpacity(0.7),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItemWithRemove(
    BuildContext context,
    GroupByIdMember member,
  ) {
    final String currentUserId = authController.user.value.id;
    final responsive = ResponsiveUtils(context);
    // Determine if the current user is an admin
    final bool isCurrentUserAdmin = groupController.groupById.value.members.any(
      (m) => m.userId == currentUserId && m.role == 'ADMIN',
    );
    final bool isSelf = member.userId == currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (isSelf) {
              return;
            }
            final hasConnection = await NetworkUtils.checkConnectionWithError();
            await userProfileController.getUserProfile(member.userId);
            buildProfileUser(
              context,
              userProfileController.userProfile.value,
              hasConnection: hasConnection,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Avatar
                ClipOval(
                  child: AuthenticatedAvatarWidget(
                    imageUrl: member.user.avatarUrl ?? '',
                    width: responsive.isDesktop ? 32 : 44,
                    height: responsive.isDesktop ? 32 : 44,
                    fit: BoxFit.cover,
                    errorWidget: _buildInitialsAvatar(
                      member.user.name,
                      responsive.isDesktop ? 32 : 44,
                    ),
                    placeholder: _buildInitialsAvatar(
                      member.user.name,
                      responsive.isDesktop ? 32 : 44,
                    ),
                  ),
                ),
                SizedBox(width: responsive.isDesktop ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: MixedText(
                              member.user.name,
                              style: TextStyle(
                                fontSize: responsive.isDesktop ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.role == 'ADMIN' ||
                              member.userId ==
                                  groupController
                                      .groupById
                                      .value
                                      .creatorId) ...[
                            const SizedBox(width: 8),
                            MixedText(
                              (member.userId ==
                                          groupController
                                              .groupById
                                              .value
                                              .creatorId
                                      ? 'owner'
                                      : 'admin')
                                  .tr,
                              style: TextStyle(
                                fontSize: responsive.isDesktop ? 11 : 13,
                                color: const Color(0xFF0088CC),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (member.userId == authController.user.value.id) ...[
                        buildUserOnlineStatus(),
                      ] else ...[
                        Obx(() {
                          final userId = member.userId;
                          final isOnline = UserStatusUtils.isUserOnline(userId);
                          final statusDisplay =
                              UserStatusUtils.getUserStatusDisplay(userId);

                          return MixedText(
                            statusDisplay,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isOnline
                                      ? const Color(0xFF0088CC)
                                      : const Color(0xFF8E8E93),
                              fontWeight:
                                  isOnline ? FontWeight.w500 : FontWeight.w400,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                // Only show remove button if current user is admin and not removing themselves
                if (isCurrentUserAdmin && !isSelf) ...[
                  const SizedBox(width: 8),
                  ZoomTapAnimation(
                    onTap: () {
                      settingsController.buildLogout(
                        title: 'Remove Member'.tr,
                        question: 'Are you sure?'.tr,
                        description:
                            'This action cannot be undone. User will be removed from the group.'
                                .tr,
                        icon: Icons.person_remove_outlined,
                        iconColor: Colors.redAccent,
                        boxColor: const Color(0xFFFFF5F5),
                        borderColor: const Color(0xFFFFE5E5),
                        confirmText: 'Remove'.tr,
                        cancelText: 'cancel'.tr,
                        confirmButtonColor: Colors.redAccent,
                        onConfirm: () {
                          groupController.removeMemberFromGroup(
                            groupController.groupById.value.id,
                            memberUserId: member.userId,
                            memberName: member.user.name,
                          );
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      );
                    },
                    child: Icon(
                      Icons.person_remove_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, double size) {
    final initials =
        name.isNotEmpty
            ? name
                .trim()
                .split(' ')
                .map((e) => e[0].toUpperCase())
                .take(2)
                .join()
            : '?';

    final Color backgroundColor = Colors.grey[200]!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: MixedText(
        initials,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showActionsDialog(BuildContext context) {
    // Check if current user is an admin (role == 'ADMIN')
    final bool isAdmin = groupController.groupById.value.members.any(
      (member) =>
          member.role == 'ADMIN' &&
          member.userId == authController.user.value.id,
    );
    final RxBool isPrivate = false.obs;
    final RxBool onlyAdminsCanSendMessages = false.obs;
    final RxBool onlyAdminsCanAddMembers = false.obs;
    final RxBool onlyAdminsCanEditInfo = false.obs;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => GroupActionsBottomSheetContent(
            isAdmin: isAdmin,
            isPrivate: isPrivate,
            onlyAdminsCanSendMessages: onlyAdminsCanSendMessages,
            onlyAdminsCanAddMembers: onlyAdminsCanAddMembers,
            onlyAdminsCanEditInfo: onlyAdminsCanEditInfo,
            buildSettingToggle: _buildSettingToggle,
            buildDangerButton: _buildDangerButton,
          ),
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MixedText(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                MixedText(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ZoomTapAnimation(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF3B30), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MixedText(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(height: 2),
                  MixedText(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFFF3B30)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(List<MessageModel> group, BuildContext context) {
    final message = group.first;
    final messageId = message.id;
    return RepaintBoundary(
      child: AnimatedContainer(
        key: ValueKey(messageId),
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Obx(() {
          // Get the latest message from the reactive list to handle status updates (same pattern as private chat)
          final currentMessage =
              groupController.groupMessages.firstWhereOrNull(
                (m) => m.id == messageId,
              ) ??
              message;

          // ✅ FIX: Use ID comparison instead of object equality
          final isSelected = chatController.selectedMessages.any(
            (m) => m.id == messageId,
          );
          return GroupMessageItem(
            key: ValueKey(messageId),
            message:
                currentMessage, // Use reactive message instead of static message
            messageGroup: group.length > 1 ? group : null,
            onLongPress:
                () => _handleMessageTap(currentMessage, context, isGroup: true),
            onTap:
                () => _handleMessageTap(currentMessage, context, isGroup: true),
            isSelected: isSelected,
            searchTerm: null,
          );
        }),
      ),
    );
  }

  void _handleMessageTap(
    MessageModel message,
    BuildContext context, {
    bool isGroup = false,
  }) {
    if (chatController.isSelectionMode.value) {
      chatController.toggleMessageSelection(message);
    } else {
      showMessageOptions(
        context,
        message,
        userProfileController.userProfile.value,
        isGroup: isGroup,
      );
    }
  }

  List<List<MessageModel>> groupMediaMessages(List<MessageModel> messages) {
    final List<List<MessageModel>> grouped = [];
    int i = 0;
    while (i < messages.length) {
      final current = messages[i];
      if ((current.type == 'IMAGE' || current.type == 'VIDEO')) {
        // Start a new group for consecutive images/videos from the same sender within 3 seconds
        final group = <MessageModel>[current];
        int j = i + 1;
        while (j < messages.length) {
          final next = messages[j];
          final timeDiff =
              (current.scheduledAt ?? current.createdAt)
                  .difference(next.scheduledAt ?? next.createdAt)
                  .inSeconds
                  .abs();
          if ((next.type == 'IMAGE' || next.type == 'VIDEO') &&
              current.senderId == next.senderId &&
              timeDiff <= 3) {
            group.add(next);
            i = j;
            j++;
            // If group reaches 8, break to start a new batch
            if (group.length == 8) {
              break;
            }
          } else {
            break;
          }
        }
        grouped.add(List<MessageModel>.from(group));
        i++;
      } else {
        grouped.add([current]);
        i++;
      }
    }
    return grouped;
  }

  Widget buildSendingMessageIndicator() {
    final label =
        groupController.loadingMessage.value.isNotEmpty
            ? groupController.loadingMessage.value
            : 'sending_message'.tr;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          buildLoadingIndicator(),
          const SizedBox(width: 16),
          MixedText(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Header section with Pin, RSS, and Checklist tabs
  Widget _buildHeaderSection() {
    return Obx(() {
      // Don't show tabs in selection mode or when searching
      if (chatController.isSelectionMode.value ||
          groupController.isSearching.value) {
        return const SizedBox.shrink();
      }

      // Filter pinned messages to only show those pinned by the logged-in user
      final currentUserId = authController.user.value.id;
      final userPinnedMessages =
          chatController.pinnedMessagesList
              .where((pinned) => pinned.pinnedBy.id == currentUserId)
              .toList();
      final hasPinned = userPinnedMessages.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pin tab - only show if there are pinned messages
            if (hasPinned)
              Expanded(
                child: _buildHeaderChip(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder:
                          (context) => _PinnedMessageModal(
                            pinnedMessages: userPinnedMessages,
                            initialIndex: 0,
                            handleFindTheIndexOfTheMessage: (message, index) {
                              // Scroll to message in group chat
                            },
                          ),
                    );
                  },
                  icon: Icons.push_pin_outlined,
                  color: AppColors.primary,
                  title: 'pin'.tr,
                ),
              ),
            if (hasPinned) const SizedBox(width: 10),
            // RSS Feed tab
            Expanded(
              child: _buildHeaderChip(
                onTap:
                    () async => await GlobalRssService.openRssBottomSheet(
                      context,
                      chatId: groupController.groupById.value.chatId,
                    ),
                icon: Icons.rss_feed,
                color: Colors.blue,
                title: 'rss_feeds'.tr,
              ),
            ),
            const SizedBox(width: 10),
            // Checklist tab
            Expanded(
              child: _buildHeaderChip(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder:
                        (sheetContext) => GlobalChecklistModal(
                          conversationId:
                              groupController.groupById.value.chatId,
                          initialMineOnly: true,
                        ),
                  );
                },
                icon: Icons.checklist_outlined,
                color: Colors.teal,
                title: 'checklists'.tr,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderChip({
    Key? key,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2), width: 0.5),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              MixedText(
                title,
                style: FontUtils.createTextStyle(
                  title,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder:
            (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.vertical,
                child: child,
              ),
            ),
        child:
            groupController.isSearching.value
                ? GestureDetector(
                  // Prevent taps from propagating to parent widgets
                  onTap: () {
                    // Ensure search field gets focus when tapping on search bar
                    if (!searchFocusNode.hasFocus) {
                      searchFocusNode.requestFocus();
                    }
                  },
                  child: Container(
                    key: const ValueKey('searchBar'),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.search,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            key: _searchTextFieldKey,
                            controller: searchController,
                            focusNode: searchFocusNode,
                            autofocus:
                                true, // Auto-focus search input when search bar appears
                            // Disable the default context menu to prevent "Select All" from appearing on right-click
                            contextMenuBuilder: (context, editableTextState) {
                              return const SizedBox.shrink(); // Return empty widget to hide context menu
                            },
                            onChanged: (query) {
                              groupController.searchQuery.value = query;
                              if (query.trim().isEmpty) {
                                // If search is empty, clear search results but keep search UI open
                                groupController.searchResults.clear();
                                groupController.isSearchLoading.value = false;
                                groupController.searchCurrentPage.value = 1;
                                groupController.searchHasMoreItems.value = true;
                                groupController.searchIsLoadingMore.value =
                                    false;
                              } else {
                                groupController.debouncedSearch(
                                  groupController.groupById.value.id,
                                  query,
                                );
                              }
                            },
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'search'.tr,
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        Obx(
                          () =>
                              groupController.searchQuery.value.isNotEmpty
                                  ? AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: IconButton(
                                      key: const ValueKey('clearBtn'),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                      splashRadius: 20,
                                      onPressed: () {
                                        searchController.clear();
                                        // Clear search results but keep search UI open
                                        groupController.searchQuery.value = '';
                                        groupController.searchResults.clear();
                                        groupController.isSearchLoading.value =
                                            false;
                                        groupController
                                            .searchCurrentPage
                                            .value = 1;
                                        groupController
                                            .searchHasMoreItems
                                            .value = true;
                                        groupController
                                            .searchIsLoadingMore
                                            .value = false;
                                      },
                                      tooltip: 'clear'.tr,
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 4),
                        // Close search button - always visible
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.grey,
                            size: 22,
                          ),
                          splashRadius: 20,
                          onPressed: () {
                            // Close search feature entirely
                            groupController.isSearching.value = false;
                            searchController.clear();
                            groupController.clearSearch();
                          },
                          tooltip: 'close'.tr,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
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
    List children,
    List<String> textParts,
    int currentLevel,
  ) {
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
      if (operation is Map<String, dynamic> &&
          operation.containsKey('insert')) {
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

  /// Check if text contains markdown formatting
  bool _hasMarkdownFormatting(String text) {
    if (text.isEmpty) return false;
    final markdownPatterns = [
      RegExp(r'\*\*.*?\*\*'),
      RegExp(r'\*.*?\*'),
      RegExp(r'__.*?__'),
      RegExp(r'_.*?_'),
      RegExp(r'`.*?`'),
      RegExp(r'```[\s\S]*?```'),
      RegExp(r'^#{1,6}\s', multiLine: true),
      RegExp(r'^\s*[-*+]\s', multiLine: true),
      RegExp(r'^\s*\d+\.\s', multiLine: true),
      RegExp(r'\[.*?\]\(.*?\)'),
      RegExp(r'!\[.*?\]\(.*?\)'),
      RegExp(r'^>', multiLine: true),
      RegExp(r'^---+$', multiLine: true),
      RegExp(r'^\|.*\|$', multiLine: true),
    ];
    return markdownPatterns.any((pattern) => pattern.hasMatch(text));
  }

  Widget _buildSearchResultItem(MessageModel message, BuildContext context) {
    String senderName = message.sender.name;
    String avatarUrl = message.sender.avatarUrl ?? '';
    if (senderName.isEmpty || avatarUrl.isEmpty) {
      final currentUser = userProfileController.userProfile.value;
      if (senderName.isEmpty) {
        senderName =
            currentUser.fullname.isNotEmpty
                ? currentUser.fullname
                : currentUser.phoneNumber;
      }
      if (avatarUrl.isEmpty) {
        avatarUrl = checkAndReturnAvatarUrl(currentUser.avatarUrl);
      }
    }
    final searchTerm = groupController.searchQuery.value.trim();

    Widget _highlightText(String text, String query) {
      String displayText = text;
      if (_isAppFlowyJson(text)) {
        displayText = _convertAppFlowyToText(text);
      }
      if (_hasMarkdownFormatting(displayText)) {
        return SizedBox(
          height: 60,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: MarkdownBody(
              data: displayText,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.2,
                ),
                h1: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
                h2: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
                h3: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
                strong: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
                em: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                  height: 1.2,
                ),
                code: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey,
                  color: Colors.black87,
                  height: 1.2,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                listBullet: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.2,
                ),
                tableHead: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  backgroundColor: Colors.transparent,
                  height: 1.2,
                ),
                tableBody: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.2,
                ),
                tableBorder: TableBorder.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              shrinkWrap: true,
              fitContent: true,
            ),
          ),
        );
      }
      if (query.isEmpty) {
        return MixedText(
          displayText,
          style: FontUtils.createTextStyle(
            displayText,
            fontSize: 14,
            color: Colors.black87,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      }
      final lowerText = displayText.toLowerCase();
      final lowerQuery = query.toLowerCase();
      final spans = <TextSpan>[];
      int start = 0;
      int index;
      while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
        if (index > start) {
          final textSegment = displayText.substring(start, index);
          spans.add(
            TextSpan(
              text: textSegment,
              style: FontUtils.createTextStyle(
                textSegment,
                color: Colors.black87,
              ),
            ),
          );
        }
        final highlightText = displayText.substring(
          index,
          index + query.length,
        );
        spans.add(
          TextSpan(
            text: highlightText,
            style: FontUtils.createTextStyle(
              highlightText,
              color: const Color(0xFF1976D2),
              fontWeight: FontWeight.w600,
              backgroundColor: const Color(0xFFE3F2FD),
            ),
          ),
        );
        start = index + query.length;
      }
      if (start < displayText.length) {
        final remainingText = displayText.substring(start);
        spans.add(
          TextSpan(
            text: remainingText,
            style: FontUtils.createTextStyle(
              remainingText,
              color: Colors.black87,
            ),
          ),
        );
      }
      return RichText(
        text: TextSpan(
          style: FontUtils.createTextStyle(displayText, fontSize: 14),
          children: spans,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    return ZoomTapAnimation(
      key: ValueKey('search-result-${message.id}'),
      onTap: () {
        groupController.isSearching.value = false;
        final messageIndex = groupController.groupMessages.indexWhere(
          (msg) => msg.id == message.id,
        );
        if (messageIndex != -1) {
          handleFindTheIndexOfTheMessage(message, messageIndex);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.type != 'SYSTEM') ...[
                ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MixedText(
                            senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF2C2C2C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        MixedText(
                          formatTimestamp(
                            (message.scheduledAt ?? message.createdAt)
                                .toIso8601String(),
                          ),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (message.isForwarded)
                      FutureBuilder<String>(
                        future: message.decryptedContent,
                        builder: (context, snapshot) {
                          final content =
                              snapshot.hasData && snapshot.data!.isNotEmpty
                                  ? snapshot.data!
                                  : message.content;
                          if (message.type == 'CHECKLIST') {
                            try {
                              final jsonData = json.decode(content);
                              final checklist = ChecklistMessageModel.fromJson(
                                jsonData,
                              );
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.forward,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.checklist,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _highlightText(
                                      checklist.title,
                                      searchTerm,
                                    ),
                                  ),
                                ],
                              );
                            } catch (e) {
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.forward,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.checklist,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  MixedText(
                                    'checklist_message'.tr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              );
                            }
                          } else {
                            return Row(
                              children: [
                                const Icon(
                                  Icons.forward,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                _highlightText(content, searchTerm),
                              ],
                            );
                          }
                        },
                      )
                    else if (message.type == 'IMAGE')
                      Row(
                        children: [
                          const Icon(Icons.image, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          MixedText(
                            'image_message'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    else if (message.type == 'VIDEO')
                      Row(
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          MixedText(
                            'video_message'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    else if (message.type == 'FILE')
                      Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          MixedText(
                            'file_message'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    else if (message.type == 'VOICE')
                      Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          MixedText(
                            'voice_message'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    else if (message.type == 'STICKER')
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_emotions,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          MixedText(
                            'sticker_message'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    else if (message.type == 'CHECKLIST')
                      FutureBuilder<String>(
                        future: message.decryptedContent,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            try {
                              final jsonData = json.decode(snapshot.data!);
                              final checklist = ChecklistMessageModel.fromJson(
                                jsonData,
                              );
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.checklist,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _highlightText(
                                      checklist.title,
                                      searchTerm,
                                    ),
                                  ),
                                ],
                              );
                            } catch (e) {
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.checklist,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  MixedText(
                                    'checklist_message'.tr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              );
                            }
                          } else {
                            return Row(
                              children: [
                                const Icon(
                                  Icons.checklist,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                MixedText(
                                  'checklist_message'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      )
                    else
                      FutureBuilder<String>(
                        future: message.decryptedContent,
                        builder: (context, snapshot) {
                          final content =
                              snapshot.hasData && snapshot.data!.isNotEmpty
                                  ? snapshot.data!
                                  : message.content;
                          return _highlightText(content, searchTerm);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final thisYear = today.year;

    // Get month name
    String getMonthName(int month) {
      switch (month) {
        case 1:
          return 'january'.tr;
        case 2:
          return 'february'.tr;
        case 3:
          return 'march'.tr;
        case 4:
          return 'april'.tr;
        case 5:
          return 'may'.tr;
        case 6:
          return 'june'.tr;
        case 7:
          return 'july'.tr;
        case 8:
          return 'august'.tr;
        case 9:
          return 'september'.tr;
        case 10:
          return 'october'.tr;
        case 11:
          return 'november'.tr;
        case 12:
          return 'december'.tr;
        default:
          return '';
      }
    }

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'today'.tr;
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'yesterday'.tr;
    } else if (date.year == thisYear) {
      // Same year, show day and month
      return '${date.day} ${getMonthName(date.month)}';
    } else {
      // Different year, show full date
      return '${date.day} ${getMonthName(date.month)} ${date.year}';
    }
  }

  Widget _buildStickyDateHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(() {
            final date = _firstVisibleDate.value;
            if (date == null) {
              return const SizedBox.shrink();
            }
            final dateDay = DateTime(date.year, date.month, date.day);
            return MixedText(
              _formatDate(dateDay),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSelectionActions(
    BuildContext context,
    List<MessageModel> messages,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Delete button
            Expanded(
              child: FillButton(
                onTap: () {
                  // Delete all selected messages
                  handleDeleteMessage(context);
                },
                name: 'delete'.tr,
                color: const Color(0xFFFF3B30),
                icon: Icons.delete_outline,
              ),
            ),
            const SizedBox(width: 12),
            // Forward button
            Expanded(
              child: FillButton(
                onTap: () {
                  if (chatController.selectedMessages.isNotEmpty) {
                    // Create a copy of the selected messages to avoid issues with list being modified
                    final messagesToForward = List<MessageModel>.from(
                      chatController.selectedMessages,
                    );
                    // Store in the controller for tracking
                    chatController.forwardedMessages.clear();
                    chatController.forwardedMessages.addAll(messagesToForward);
                    chatController.forwardedMessagesCount.value =
                        messagesToForward.length;
                    chatController.isForwardingMessage.value = true;

                    handleForwardMessage(context, messagesToForward);
                    // Clear selection mode after forwarding
                    chatController.selectedMessages.clear();
                    chatController.isSelectionMode.value = false;
                  }
                },
                name: 'forward'.tr,
                color: AppColors.primary,
                icon: Icons.forward_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupActionsBottomSheetContent extends StatelessWidget {
  const GroupActionsBottomSheetContent({
    super.key,
    required this.isAdmin,
    required this.isPrivate,
    required this.onlyAdminsCanSendMessages,
    required this.onlyAdminsCanAddMembers,
    required this.onlyAdminsCanEditInfo,
    required this.buildSettingToggle,
    required this.buildDangerButton,
  });
  final bool isAdmin;
  final RxBool isPrivate;
  final RxBool onlyAdminsCanSendMessages;
  final RxBool onlyAdminsCanAddMembers;
  final RxBool onlyAdminsCanEditInfo;
  final Widget Function({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  })
  buildSettingToggle;
  final Widget Function({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  })
  buildDangerButton;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        margin: const EdgeInsets.only(top: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.transparent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    MixedText(
                      'group_settings'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Admin Role Section
                // if (isAdmin) ...[
                //   Container(
                //     padding: const EdgeInsets.all(16),
                //     decoration: BoxDecoration(
                //       color: Colors.green.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Row(
                //       children: [
                //         const Icon(Icons.admin_panel_settings,
                //             color: Colors.green),
                //         const SizedBox(width: 12),
                //         Expanded(
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               MixedText(
                //                 'admin_controls'.tr,
                //                 style: const TextStyle(
                //                   fontSize: 16,
                //                   fontWeight: FontWeight.w600,
                //                   color: Colors.green,
                //                 ),
                //               ),
                //               const SizedBox(height: 4),
                //               MixedText(
                //                 'you_have_administrative_privileges_for_this_group'
                //                     .tr,
                //                 style: TextStyle(
                //                   fontSize: 14,
                //                   color: Colors.grey[600],
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                //   const SizedBox(height: 24),
                // ],

                // Privacy Settings Section
                // MixedText(
                //   'privacy_settings'.tr,
                //   style: const TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.w600,
                //     color: Color(0xFF2C2C2C),
                //   ),
                // ),
                // const SizedBox(height: 16),

                // // Private Group Toggle
                // Obx(() => buildSettingToggle(
                //       title: 'private_group'.tr,
                //       subtitle:
                //           'only_members_can_see_group_info_and_messages'.tr,
                //       value: isPrivate.value,
                //       onChanged: (value) => isPrivate.value = value,
                //       icon: Icons.lock_outline,
                //       iconColor: Colors.blue,
                //     )),

                // const SizedBox(height: 16),
                // const Divider(),
                // const SizedBox(height: 16),

                // // Admin Permissions Section
                // MixedText(
                //   'admin_permissions'.tr,
                //   style: const TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.w600,
                //     color: Color(0xFF2C2C2C),
                //   ),
                // ),
                // const SizedBox(height: 16),

                // // Only admins can send messages
                // Obx(() => buildSettingToggle(
                //       title: 'only_admins_can_send_messages'.tr,
                //       subtitle:
                //           'restrict_message_sending_to_administrators_only'.tr,
                //       value: onlyAdminsCanSendMessages.value,
                //       onChanged: (value) =>
                //           onlyAdminsCanSendMessages.value = value,
                //       icon: Icons.message_outlined,
                //       iconColor: Colors.green,
                //     )),

                // const SizedBox(height: 16),

                // // Only admins can add members
                // Obx(() => buildSettingToggle(
                //       title: 'only_admins_can_add_members'.tr,
                //       subtitle:
                //           'restrict_member_addition_to_administrators_only'.tr,
                //       value: onlyAdminsCanAddMembers.value,
                //       onChanged: (value) =>
                //           onlyAdminsCanAddMembers.value = value,
                //       icon: Icons.person_add_outlined,
                //       iconColor: Colors.orange,
                //     )),

                // const SizedBox(height: 16),

                // // Only admins can edit info
                // Obx(() => buildSettingToggle(
                //       title: 'only_admins_can_edit_info'.tr,
                //       subtitle:
                //           'restrict_group_info_editing_to_administrators_only'
                //               .tr,
                //       value: onlyAdminsCanEditInfo.value,
                //       onChanged: (value) => onlyAdminsCanEditInfo.value = value,
                //       icon: Icons.edit_outlined,
                //       iconColor: Colors.purple,
                //     )),

                // const SizedBox(height: 24),

                // // Danger Zone
                // MixedText(
                //   'danger_zone'.tr,
                //   style: const TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.w600,
                //     color: Color(0xFFFF3B30),
                //   ),
                // ),
                // const SizedBox(height: 16),

                // Leave Group Button (for members only - not admins)
                if (!isAdmin)
                  buildDangerButton(
                    title: 'leave_group'.tr,
                    subtitle:
                        'you_will_no_longer_receive_messages_from_this_group'
                            .tr,
                    icon: Icons.exit_to_app,
                    onTap: () {
                      groupController.leaveGroup(
                        groupController.groupById.value.id,
                      );
                    },
                  ),

                // Delete Group Button (for admins only)
                if (isAdmin)
                  buildDangerButton(
                    title: 'delete_group'.tr,
                    subtitle: 'this_action_cannot_be_undone'.tr,
                    icon: Icons.delete_forever,
                    onTap: () async {
                      // Close both modals (actions modal and group info modal)
                      // Close all open bottom sheets/modals
                      while (Get.isBottomSheetOpen ?? false) {
                        Get.back();
                        // Small delay between each pop
                        await Future.delayed(const Duration(milliseconds: 50));
                      }

                      // Also try Navigator.pop() as a fallback
                      int popCount = 0;
                      while (Navigator.of(context).canPop() && popCount < 3) {
                        Navigator.of(context).pop();
                        popCount++;
                        await Future.delayed(const Duration(milliseconds: 50));
                      }

                      // Small delay to ensure modals are fully closed
                      await Future.delayed(const Duration(milliseconds: 100));

                      // Then delete the group
                      await groupController.deleteGroup(
                        groupController.groupById.value.id,
                      );
                    },
                  ),

                // const SizedBox(height: 24),

                // // Save Button
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       // Save settings logic would go here
                //       Navigator.of(context).pop();
                //       snackBar(
                //         title: 'settings_saved'.tr,
                //         message:
                //             'group_settings_have_been_updated_successfully'.tr,
                //       );
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.green,
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       elevation: 0,
                //     ),
                //     child: MixedText(
                //       'save_changes'.tr,
                //       style: const TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.w600,
                //         color: Colors.white,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modal widget for displaying pinned message details
class _PinnedMessageModal extends StatelessWidget {
  const _PinnedMessageModal({
    super.key,
    required this.pinnedMessages,
    this.initialIndex = 0,
    required this.handleFindTheIndexOfTheMessage,
  });
  final List<PinnedMessageListItem> pinnedMessages;
  final int initialIndex;
  final void Function(MessageModel, int) handleFindTheIndexOfTheMessage;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsets = MediaQuery.of(context).viewInsets;
    // Calculate height to be full screen (100% of available height)
    final modalHeight = screenHeight - viewInsets.top - viewInsets.bottom;

    return Padding(
      padding: viewInsets,
      child: Container(
        height: modalHeight,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MixedText(
                  'pinned_messages'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pinnedMessages.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final pinMessage = pinnedMessages[idx];
                  final pinnedAtStr = formatTimestamp(
                    pinMessage.pinnedAt.toString(),
                  );
                  final bool isSentByMe =
                      pinMessage.message.senderId ==
                      authController.user.value.id;
                  return Material(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Use Obx to reactively get the latest message from groupMessages
                            // This ensures checklist updates sync properly
                            return Obx(() {
                              // Get the latest message from groupMessages, fallback to pinned message if not found
                              final latestMessage =
                                  groupController.groupMessages
                                      .firstWhereOrNull(
                                        (msg) =>
                                            msg.id == pinMessage.message.id,
                                      ) ??
                                  pinMessage.message;

                              // For messages from other users, remove left spacing to prevent overflow
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child:
                                    isSentByMe
                                        ? GroupMessageItem(
                                          message: latestMessage,
                                          onLongPress:
                                              () => showMessageOptions(
                                                context,
                                                latestMessage,
                                                userProfileController
                                                    .userProfile
                                                    .value,
                                                isGroup: true,
                                                showInMessage:
                                                    false, // Show sender info in message
                                                onScrollToMessage:
                                                    handleFindTheIndexOfTheMessage,
                                              ),
                                          onTap: () {
                                            // Scroll to message in group chat
                                            final messageIndex = groupController
                                                .groupMessages
                                                .indexWhere(
                                                  (msg) =>
                                                      msg.id ==
                                                      latestMessage.id,
                                                );
                                            if (messageIndex != -1) {
                                              handleFindTheIndexOfTheMessage(
                                                groupController
                                                    .groupMessages[messageIndex],
                                                messageIndex,
                                              );
                                            }
                                          },
                                          isSelected: false,
                                          messageGroup: null,
                                          searchTerm: null,
                                          maxWidth:
                                              constraints
                                                  .maxWidth, // Pass available width from LayoutBuilder
                                          showInMessage:
                                              false, // Show sender info in message, not in overlay
                                          onScrollToMessageForOverlay:
                                              handleFindTheIndexOfTheMessage, // Pass scroll callback for overlay
                                          onReplyTap: (repliedToMessageId) {
                                            // Handle reply tap in group chat
                                            final repliedToIndex =
                                                groupController.groupMessages
                                                    .indexWhere(
                                                      (msg) =>
                                                          msg.id ==
                                                          repliedToMessageId,
                                                    );
                                            if (repliedToIndex != -1) {
                                              handleFindTheIndexOfTheMessage(
                                                groupController
                                                    .groupMessages[repliedToIndex],
                                                repliedToIndex,
                                              );
                                            }
                                          },
                                        )
                                        : Align(
                                          alignment: Alignment.centerLeft,
                                          child: Transform.translate(
                                            offset: const Offset(-15, 0),
                                            // Remove left padding for messages from other users
                                            child: SizedBox(
                                              width: constraints.maxWidth - 5,
                                              // Reduce width to prevent overflow
                                              child: GroupMessageItem(
                                                message: latestMessage,
                                                onLongPress:
                                                    () => showMessageOptions(
                                                      context,
                                                      latestMessage,
                                                      userProfileController
                                                          .userProfile
                                                          .value,
                                                      isGroup: true,
                                                      showInMessage:
                                                          false, // Show sender info in message
                                                      onScrollToMessage:
                                                          handleFindTheIndexOfTheMessage,
                                                    ),
                                                onTap: () {
                                                  // Scroll to message in group chat
                                                  final messageIndex =
                                                      groupController
                                                          .groupMessages
                                                          .indexWhere(
                                                            (msg) =>
                                                                msg.id ==
                                                                latestMessage
                                                                    .id,
                                                          );
                                                  if (messageIndex != -1) {
                                                    handleFindTheIndexOfTheMessage(
                                                      groupController
                                                          .groupMessages[messageIndex],
                                                      messageIndex,
                                                    );
                                                  }
                                                },
                                                isSelected: false,
                                                messageGroup: null,
                                                searchTerm: null,
                                                maxWidth:
                                                    constraints.maxWidth -
                                                    40, // Reduce maxWidth to prevent overflow
                                                showInMessage:
                                                    false, // Show sender info in message, not in overlay
                                                onScrollToMessageForOverlay:
                                                    handleFindTheIndexOfTheMessage, // Pass scroll callback for overlay
                                                onReplyTap: (
                                                  repliedToMessageId,
                                                ) {
                                                  // Handle reply tap in group chat
                                                  final repliedToIndex =
                                                      groupController
                                                          .groupMessages
                                                          .indexWhere(
                                                            (msg) =>
                                                                msg.id ==
                                                                repliedToMessageId,
                                                          );
                                                  if (repliedToIndex != -1) {
                                                    handleFindTheIndexOfTheMessage(
                                                      groupController
                                                          .groupMessages[repliedToIndex],
                                                      repliedToIndex,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MixedText(
                            'pinned_at'.tr + ': ' + pinnedAtStr,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey[300], height: 1),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper for message items that handles selection state separately
// Uses StatefulWidget with AutomaticKeepAliveClientMixin to prevent recreation
// This prevents the entire message list from rebuilding when selection changes
class _MessageItemWrapper extends StatefulWidget {
  const _MessageItemWrapper({
    super.key,
    required this.message,
    required this.onLongPress,
    required this.onTap,
    required this.isGroup,
  });

  final MessageModel message;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final bool isGroup;

  @override
  State<_MessageItemWrapper> createState() => _MessageItemWrapperState();
}

class _MessageItemWrapperState extends State<_MessageItemWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep widget alive to prevent recreation

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Use a more targeted Obx that only rebuilds when this message's selection changes
    // Wrap in RepaintBoundary to isolate selection rebuilds
    return RepaintBoundary(
      child: Obx(() {
        // Only check if this specific message is selected
        // This is more efficient than checking the entire list
        final selectedMessages = chatController.selectedMessages;
        final isSelected = selectedMessages.any(
          (m) => m.id == widget.message.id,
        );

        // Use a stable key to prevent widget recreation
        // Flutter will preserve the widget if the key stays the same
        return GroupMessageItem(
          key: ValueKey('group_message_${widget.message.id}'),
          message: widget.message,
          onLongPress: widget.onLongPress,
          onTap: widget.onTap,
          isSelected: isSelected,
          searchTerm: null,
        );
      }),
    );
  }
}

// Stable message list that doesn't rebuild when keyboard opens
// Uses StatefulWidget with AutomaticKeepAliveClientMixin to prevent unnecessary rebuilds
class _StableMessageList extends StatefulWidget {
  const _StableMessageList({
    super.key,
    required this.scrollController,
    required this.onBuildMessageWidgets,
    required this.onHandleMessageTap,
  });

  final ScrollController scrollController;
  final List<Widget> Function(List<MessageModel> messages)
  onBuildMessageWidgets;
  final void Function(MessageModel message) onHandleMessageTap;

  @override
  State<_StableMessageList> createState() => _StableMessageListState();
}

class _StableMessageListState extends State<_StableMessageList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep widget alive to prevent recreation

  List<MessageModel> _messages = [];
  String _messagesKey = '';
  List<Widget> _cachedMessageWidgets =
      []; // Cache widgets to prevent recreation
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _searchSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize messages immediately
    _updateMessages();
    // Listen to message changes manually instead of using Obx
    _messagesSubscription = groupController.groupMessages.listen((messages) {
      if (mounted && !groupController.isSearching.value) {
        _updateMessages();
      }
    });
    // Also listen to search results
    _searchSubscription = groupController.searchResults.listen((messages) {
      if (mounted && groupController.isSearching.value) {
        _updateMessages();
      }
    });
  }

  void _updateMessages() {
    if (!mounted) return;

    final isSearching = groupController.isSearching.value;
    final currentMessages =
        isSearching
            ? groupController.searchResults
            : groupController.groupMessages;

    // Create a key from message IDs AND statuses to detect status changes
    // This ensures the cache invalidates when read receipts update message status
    final String newKey =
        currentMessages.isEmpty
            ? 'empty'
            : '${currentMessages.length}_${currentMessages.first.id}_${currentMessages.first.status}_${currentMessages.last.id}_${currentMessages.last.status}';

    // Always update messages to get latest status, but only rebuild widgets if key changed
    // This ensures we have the latest message data even if widget cache is valid
    final updatedMessages = List<MessageModel>.from(currentMessages);

    if (newKey != _messagesKey) {
      setState(() {
        _messages = updatedMessages;
        _messagesKey = newKey;
        // Rebuild widgets only when messages change
        _cachedMessageWidgets = widget.onBuildMessageWidgets(_messages);
      });
    } else {
      // Even if key didn't change, update the messages list to ensure we have latest status
      // This is important for read receipt updates where only status changes
      setState(() {
        _messages = updatedMessages;
        // Force widget rebuild for status changes
        _cachedMessageWidgets = widget.onBuildMessageWidgets(_messages);
      });
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _searchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_messages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use cached widgets - they only rebuild when messages actually change
    // This prevents audio players from reinitializing when keyboard opens
    // Initialize cache if empty
    if (_cachedMessageWidgets.isEmpty && _messages.isNotEmpty) {
      _cachedMessageWidgets = widget.onBuildMessageWidgets(_messages);
    }
    final messageWidgets = _cachedMessageWidgets;

    // Use Builder to capture stable context and prevent MediaQuery rebuilds
    return Builder(
      builder: (context) {
        return Stack(
          children: [
            Column(
              children: [
                // Messages list with ListView.builder
                Expanded(
                  key: ValueKey('message_list_expanded_$_messagesKey'),
                  child: _GroupSelectionAreaWrapper(
                    child: ListView.builder(
                      key: ValueKey(
                        'message_list_$_messagesKey',
                      ), // Stable key based on messages
                      reverse: true,
                      controller: widget.scrollController,
                      itemCount: messageWidgets.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,
                      // Use stable keys to prevent widget recreation
                      itemBuilder: (context, index) {
                        return messageWidgets[index];
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// Stable message list widget that prevents rebuilds when keyboard opens
class _StableMessageListWidget extends StatefulWidget {
  const _StableMessageListWidget({
    required this.scrollController,
    required this.onHandleMessageTap,
    required this.onBuildSearchResultItem,
    required this.formatDate,
  });

  final ScrollController scrollController;
  final void Function(MessageModel message) onHandleMessageTap;
  final Widget Function(MessageModel message, BuildContext context)
  onBuildSearchResultItem;
  final String Function(DateTime date) formatDate;

  @override
  State<_StableMessageListWidget> createState() =>
      _StableMessageListWidgetState();
}

class _StableMessageListWidgetState extends State<_StableMessageListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      // Force observation of groupMessages to ensure reactivity
      final _ = groupController.groupMessages.length;

      final RxList<MessageModel> source =
          groupController.isSearching.value
              ? groupController.searchResults
              : groupController.groupMessages;

      final List<MessageModel> messages = List<MessageModel>.from(source);

      // Handle search loading state
      if (groupController.isSearching.value &&
          groupController.searchQuery.value.trim().isNotEmpty) {
        if (groupController.isSearchLoading.value && messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildLoadingIndicator(),
                const SizedBox(height: 16),
                MixedText(
                  groupController.searchIsLoadingMore.value
                      ? 'Loading more results...'
                      : 'Searching messages...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                MixedText(
                  'this_may_take_a_few_seconds'.tr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        } else if (!groupController.isSearchLoading.value && messages.isEmpty) {
          // Show no results when search is complete and no results found
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                MixedText(
                  'no_messages_found'.tr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                MixedText(
                  'try_different_keywords'.tr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }
      }

      if (messages.isEmpty && !groupController.isSearching.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MixedText(
                  'today'.tr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF0F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: MixedText(
                  'group_created'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40), // Spacing from the bottom input area
            ],
          ),
        );
      }

      return _GroupSelectionAreaWrapper(
        child: ListView.builder(
          // Only reverse when not searching, or when searching with empty query (keep normal order)
          // When searching with non-empty query, don't reverse (show results from top)
          reverse:
              !groupController.isSearching.value ||
              groupController.searchQuery.value.trim().isEmpty,
          controller: widget.scrollController,
          itemCount: messages.length,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          itemBuilder: (context, index) {
            // Always get the latest message from groupController to ensure we have updated status
            // This is critical for read receipt updates where only status changes
            final messageId = messages[index].id;
            final latestMessage =
                (groupController.isSearching.value
                        ? groupController.searchResults
                        : groupController.groupMessages)
                    .firstWhereOrNull((m) => m.id == messageId) ??
                messages[index];

            // Show search result item when searching with non-empty query
            if (groupController.isSearching.value &&
                groupController.searchQuery.value.trim().isNotEmpty) {
              return widget.onBuildSearchResultItem(latestMessage, context);
            }

            // Calculate date for current message
            final dateTime =
                latestMessage.scheduledAt ?? latestMessage.createdAt;
            final messageDate = dateTime.toLocal();
            final messageDay = DateTime(
              messageDate.year,
              messageDate.month,
              messageDate.day,
            );

            // Check if we need to show a date divider
            // Since list is reversed, compare with next older message (index + 1)
            final showDateDivider =
                index < messages.length - 1
                    ? () {
                      final nextMessageId = messages[index + 1].id;
                      final nextMessage =
                          (groupController.isSearching.value
                                  ? groupController.searchResults
                                  : groupController.groupMessages)
                              .firstWhereOrNull((m) => m.id == nextMessageId) ??
                          messages[index + 1];
                      final nextDateTime =
                          nextMessage.scheduledAt ?? nextMessage.createdAt;
                      final nextDate = nextDateTime.toLocal();
                      final nextDay = DateTime(
                        nextDate.year,
                        nextDate.month,
                        nextDate.day,
                      );
                      return messageDay.toString() != nextDay.toString();
                    }()
                    : true; // Always show date divider for the last (oldest) message

            final isSelected = chatController.selectedMessages.any(
              (m) => m.id == latestMessage.id,
            );

            // Use stable key based only on message ID to prevent audio player recreation
            // Status updates are handled reactively inside GroupMessageItem via Obx
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date divider
                if (showDateDivider)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: MixedText(
                              widget.formatDate(messageDay),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Message item
                GroupMessageItem(
                  key: ValueKey(
                    'group_message_${latestMessage.id}',
                  ), // Stable key - status handled internally
                  message:
                      latestMessage, // Use latest message with updated status
                  onLongPress: () => widget.onHandleMessageTap(latestMessage),
                  onTap: () => widget.onHandleMessageTap(latestMessage),
                  isSelected: isSelected,
                  searchTerm: null,
                  showInMessage:
                      true, // Show sender info/avatar on the left like private chat
                ),
              ],
            );
          },
        ),
      );
    });
  }
}

// Wrapper widget that isolates MessageInput from reactive rebuilds
// Only rebuilds when chatId actually changes, not when other observables change
class _GroupMessageInputWrapper extends StatefulWidget {
  const _GroupMessageInputWrapper({
    super.key,
    required this.buildSelectionActions,
  });

  final Widget Function(BuildContext, List<MessageModel>) buildSelectionActions;

  @override
  State<_GroupMessageInputWrapper> createState() =>
      _GroupMessageInputWrapperState();
}

class _GroupMessageInputWrapperState extends State<_GroupMessageInputWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _currentChatId;
  Worker? _chatIdWorker;

  @override
  void initState() {
    super.initState();
    // Watch chatId changes using a Worker instead of Obx
    _chatIdWorker = ever(groupController.groupById, (group) {
      final newChatId = group.chatId;
      if (mounted && newChatId != _currentChatId) {
        setState(() {
          _currentChatId = newChatId;
        });
      }
    });
    _currentChatId = groupController.groupById.value.chatId;
  }

  @override
  void dispose() {
    _chatIdWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Get chatId from state (updated by Worker, not Obx)
    final chatId = _currentChatId ?? groupController.groupById.value.chatId;

    // Build MessageInput once and keep it stable - only rebuild when chatId changes
    // Store it in a variable to prevent recreation on every build
    final messageInput =
        chatId.isNotEmpty
            ? RepaintBoundary(
              key: ValueKey('message_input_repaint_$chatId'),
              child: MessageInput(
                key: ValueKey('group_message_input_$chatId'),
                targetId: chatId,
                isGroup: true,
                onTextChanged: (text) {
                  // MessageInput handles typing indicators internally for groups
                },
                onSend: () {
                  // Send message to group chat
                  messageInputController.handleSendMessage(
                    isGroup: true,
                    targetId: chatId,
                  );
                },
              ),
            )
            : const SizedBox.shrink();

    // Use Obx only for conditional rendering (selection mode, loading, searching)
    // MessageInput widget itself is stable and won't rebuild unless chatId changes
    return Obx(() {
      // Hide MessageInput when searching
      if (groupController.isSearching.value) {
        return const SizedBox.shrink();
      }

      // Show selection actions if in selection mode
      if (chatController.isSelectionMode.value) {
        return widget.buildSelectionActions(
          context,
          List<MessageModel>.from(groupController.groupMessages),
        );
      }

      // Hide if loading
      if (groupController.isGroupHeaderLoading.value) {
        return const SizedBox.shrink();
      }

      // Return stable MessageInput - only rebuilds when chatId changes (via setState)
      return messageInput;
    });
  }
}
