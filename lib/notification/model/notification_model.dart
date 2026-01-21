class NotificationModel {
  final String id;
  final String senderName;
  final String message;
  final String timestamp;
  final bool isRead;
  final bool hasActions;

  NotificationModel({
    required this.id,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.hasActions = false,
  });
}
