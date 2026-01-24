import '../../utils/json_utils.dart';

class LeaveRequest {
  final String id;
  final String userId;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isHalfDay;
  final DateTime? createdAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isHalfDay,
    this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: readString(json, const ['id', '_id']) ?? '',
      userId: readString(json, const ['user_id', 'userId']) ?? '',
      reason: readString(json, const ['reason', 'description']) ?? '',
      startDate: DateTime.tryParse(readString(json, const ['start_date', 'startDate']) ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(readString(json, const ['end_date', 'endDate']) ?? '') ?? DateTime.now(),
      status: readString(json, const ['status']) ?? 'pending',
      isHalfDay: json['is_half_day'] == true || json['isHalfDay'] == true,
      createdAt: DateTime.tryParse(readString(json, const ['created_at', 'createdAt']) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reason': reason,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'is_half_day': isHalfDay,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase() == 'awaiting';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected' || status.toLowerCase() == 'declined';
}
