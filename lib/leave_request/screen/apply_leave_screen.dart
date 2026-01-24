import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
import 'leave_request_detail_screen.dart';
import '../../services/leave_request_service.dart';
import '../../utils/snackbar.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  final LeaveRequestService _leaveService = LeaveRequestService();

  @override
  void initState() {
    super.initState();
    // Pre-fill dates with current date
    _startDate = DateTime.now();
    _endDate = DateTime.now();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final baseTheme = Theme.of(context);
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.textPrimary,
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        // Force consistent, white popup + typography/colors from configs
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: colorScheme,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.white,
              headerBackgroundColor: AppColors.primaryBlue,
              headerForegroundColor: AppColors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.white
                    : AppColors.textPrimary,
              ),
              yearForegroundColor: WidgetStateProperty.all(
                AppColors.textPrimary,
              ),
              todayForegroundColor: WidgetStateProperty.all(
                AppColors.primaryBlue,
              ),
              todayBorder: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                textStyle: const TextStyle(
                  fontSize: AppSizes.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.white),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Select Date";
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String? _isoDate(DateTime? date) {
    if (date == null) return null;
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      resizeToAvoidBottomInset: true, // Let Scaffold handle resizing
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
          'Apply Leave',
          style: TextStyle(
            color: appColors.textPrimary,
            fontSize: AppSizes.fontSizeL,
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
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Start Date
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectDate(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusS,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(_startDate),
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSizeM,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: AppSizes.iconSizeM,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // End Date
                      const Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectDate(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusS,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(_endDate),
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSizeM,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: AppSizes.iconSizeM,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      const Text(
                        'Reason for leave',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(minHeight: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: TextField(
                          controller: _reasonController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter reason...',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Buttons (fixed at bottom; scroll when keyboard opens)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusM,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: AppSizes.fontSizeM,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                final startIso = _isoDate(_startDate);
                                final endIso = _isoDate(_endDate);
                                final reason = _reasonController.text.trim();

                                if (startIso == null || endIso == null) {
                                  CustomSnackBar.error(
                                    title: 'Please select dates',
                                  );
                                  return;
                                }
                                if (reason.isEmpty) {
                                  CustomSnackBar.error(
                                    title: 'Please enter a reason',
                                  );
                                  return;
                                }

                                setState(() => _isSubmitting = true);
                                final res = await _leaveService.create(
                                  reason: reason,
                                  startDateIso: startIso,
                                  endDateIso: endIso,
                                  isHalfDay: false,
                                );
                                if (!context.mounted) return;
                                setState(() => _isSubmitting = false);
                                
                                final statusCode = res['statusCode'];
                                if (statusCode is int &&
                                    statusCode >= 200 &&
                                    statusCode < 300) {
                                  CustomSnackBar.success(
                                    title: 'Leave request submitted',
                                  );
                                  // Close ApplyLeaveScreen and pass the new request back
                                  Navigator.pop(context, {
                                    'success': true,
                                    'request': res['body'] is Map ? res['body'] : null,
                                  });
                                } else {
                                  final body = res['body'];
                                  final message = body is Map
                                      ? (body['message']?.toString() ??
                                            'Failed to submit')
                                      : 'Failed to submit';
                                  CustomSnackBar.error(
                                    title: 'Failed to submit',
                                    message: message,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue, // Dark Blue
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusM,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppSizes.fontSizeM,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
