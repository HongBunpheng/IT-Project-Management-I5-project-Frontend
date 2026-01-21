import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../widget/notification_item.dart';
import '../model/notification_model.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  String _selectedFilter = 'All'; // All, Unread, Read

  final List<NotificationModel> _allNotifications = [
    NotificationModel(
      id: '1',
      senderName: 'Kadorukuriki',
      message: 'you have time schedule for today',
      timestamp: 'Last Wednesday at 9:42 AM',
      isRead: false,
      hasActions: true,
    ),
    NotificationModel(
      id: '2',
      senderName: 'Kadorukuriki',
      message: 'scan successful!!!',
      timestamp: 'Last Wednesday at 9:42 AM',
      isRead: true,
    ),
    NotificationModel(
      id: '3',
      senderName: 'Kadorukuriki',
      message: 'attached a file to submit',
      timestamp: 'Last Wednesday at 9:42 AM',
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      senderName: 'Kadorukuriki',
      message: 'attached a file to submit',
      timestamp: 'Last Wednesday at 9:42 AM',
      isRead: false,
    ),
  ];

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
              child: ListView.builder(
                itemCount: _filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notification = _filteredNotifications[index];
                  return NotificationItem(
                    notification: notification,
                    onDelete: () {
                      setState(() {
                        _allNotifications.removeWhere((n) => n.id == notification.id);
                      });
                    },
                    onDecline: () {
                      // Simple mark as read/declined
                      setState(() {
                        _allNotifications[index] = NotificationModel(
                          id: notification.id,
                          senderName: notification.senderName,
                          message: notification.message,
                          timestamp: notification.timestamp,
                          isRead: true,
                          hasActions: notification.hasActions,
                        );
                      });
                    },
                  );
                },
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
              color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
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
