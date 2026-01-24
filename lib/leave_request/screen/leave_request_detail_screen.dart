import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
import '../../services/leave_request_service.dart';
import '../../utils/snackbar.dart';

class LeaveRequestDetailScreen extends StatefulWidget {
  final String? id;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final bool isAdmin;

  const LeaveRequestDetailScreen({
    super.key,
    this.id,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'Pending',
    this.isAdmin = false,
  });

  @override
  State<LeaveRequestDetailScreen> createState() => _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState extends State<LeaveRequestDetailScreen> {
  late String _currentStatus;
  bool _isProcessing = false;
  final LeaveRequestService _leaveService = LeaveRequestService();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
  }

  Future<void> _updateStatus(bool approve) async {
    if (widget.id == null) return;

    setState(() => _isProcessing = true);
    try {
      final res = approve 
          ? await _leaveService.approve(widget.id!)
          : await _leaveService.reject(widget.id!);
      
      if (!mounted) return;
      
      final statusCode = res['statusCode'];
      if (statusCode is int && statusCode >= 200 && statusCode < 300) {
        setState(() {
          _currentStatus = approve ? 'Approved' : 'Rejected';
          _isProcessing = false;
        });
        CustomSnackBar.success(
          title: approve ? 'Request Approved' : 'Request Rejected',
        );
      } else {
        setState(() => _isProcessing = false);
        final body = res['body'];
        final message = body is Map ? (body['message']?.toString() ?? 'Error') : 'Error';
        CustomSnackBar.error(title: 'Action Failed', message: message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      CustomSnackBar.error(title: 'Error', message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isPending = _currentStatus.toLowerCase() == 'pending' || 
                           _currentStatus.toLowerCase() == 'awaiting';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark 
            ? AppColors.primaryBlue.withValues(alpha: 0.2)
            : AppColors.white,
        elevation: 0,
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
            size: AppSizes.iconSizeM,
            color: appColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leave Request',
          style: TextStyle(
            color: appColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSizes.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.spacingS),
              Text(
                '${_getMonthYear(widget.startDate)}',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Leave Request',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeL,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF154888), // Dark Blue
                    ),
                  ),
                  _buildStatusBadge(_currentStatus),
                ],
              ),
              const SizedBox(height: AppSizes.spacingXL),

              _buildLabelValue('Start Date', widget.startDate),
              const SizedBox(height: AppSizes.spacingM),
              _buildLabelValue('End Date', widget.endDate),
              const SizedBox(height: AppSizes.spacingL),

              const Text(
                'Reason:',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                widget.reason,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeM,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              
              const Spacer(),
              
              if (widget.isAdmin && isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : () => _updateStatus(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusL),
                            ),
                          ),
                          child: _isProcessing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                            : const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _updateStatus(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusL),
                            ),
                          ),
                          child: _isProcessing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Approve',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else if (isPending) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your request is waiting for approval from management.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: AppSizes.fontSizeS,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
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

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'rejected':
      case 'declined':
        color = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'pending':
      case 'awaiting':
      default:
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingS,
        vertical: AppSizes.spacingXS,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: AppSizes.fontSizeS,
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeS,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthYear(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      final now = DateTime.now();
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[now.month - 1]} ${now.year}';
    }
  }
}
