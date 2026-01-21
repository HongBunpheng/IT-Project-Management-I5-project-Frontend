import 'package:flutter/material.dart';
import '../configs/app_colors.dart';
import '../configs/app_sizes.dart';
import '../services/notification_service.dart';
import '../utils/responsive.dart';
import '../utils/json_utils.dart';
import '../widgets/notification_item.dart';
import '../models/notification_model.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  String _selectedFilter = 'All'; // All, Unread, Read

  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  List<NotificationModel> _allNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _notificationService.list();
      if (!mounted) return;
      setState(() {
        _allNotifications = raw.map(_mapToModel).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  NotificationModel _mapToModel(Map<String, dynamic> json) {
    final id = readString(json, const ['id']) ?? '';
    final title = readString(json, const ['title', 'type']) ?? 'Notification';
    final message = readString(json, const ['message', 'body']) ?? '';
    final isRead =
        (json['is_read'] == true) ||
        (json['isRead'] == true) ||
        (readInt(json, const ['is_read']) ?? 0) == 1;

    final timestamp =
        readString(json, const ['created_at', 'createdAt', 'date']) ?? '';

    return NotificationModel(
      id: id,
      senderName: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead,
      hasActions: false,
    );
  }

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Unread':
        return _allNotifications.where((n) => !n.isRead).toList();
      case 'Read':
        return _allNotifications.where((n) => n.isRead).toList();
      default:
        return _allNotifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSizes.spacingS,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: AppSizes.iconSizeM,
                      color: AppColors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeXL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  _buildFilterTab('All'),
                  SizedBox(width: AppSizes.spacingL),
                  _buildFilterTab('Unread'),
                  SizedBox(width: AppSizes.spacingL),
                  _buildFilterTab('Read'),
                ],
              ),
            ),
            SizedBox(height: AppSizes.spacingM),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          return NotificationItem(
                            notification: notification,
                            onDelete: () {
                              setState(() {
                                _allNotifications.removeWhere(
                                  (n) => n.id == notification.id,
                                );
                              });
                            },
                            onDecline: () async {
                              try {
                                await _notificationService.markAsRead(
                                  notification.id,
                                );
                              } catch (_) {
                                // ignore
                              }
                              if (!mounted) return;
                              setState(() {
                                final idx = _allNotifications.indexWhere(
                                  (n) => n.id == notification.id,
                                );
                                if (idx != -1) {
                                  _allNotifications[idx] = NotificationModel(
                                    id: notification.id,
                                    senderName: notification.senderName,
                                    message: notification.message,
                                    timestamp: notification.timestamp,
                                    isRead: true,
                                    hasActions: notification.hasActions,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Column(
        children: [
          Text(
            filter,
            style: TextStyle(
              fontSize: AppSizes.fontSizeM,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Container(
            width: 40,
            height: 2,
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
