import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
import '../../utils/localization_helper.dart';
import 'qr_scanner_screen.dart';
import '../../attendance/screen/attendance_screen.dart';
import '../../services/attendance_service.dart';
import '../../services/timetable_service.dart';
import '../../services/leave_request_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../utils/snackbar.dart';
import '../../utils/pull_to_refresh.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final TimetableService _timetableService = TimetableService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = false;
  List<Map<String, dynamic>> _recent = [];
  int _todayTimetables = 0;
  int _checkedToday = 0;
  bool _isSummaryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() => _isSummaryLoading = true);
    await Future.wait([_loadAttendance(), _loadTodayTimetables()]);
    if (!mounted) return;
    setState(() => _isSummaryLoading = false);
  }

  Future<void> _loadAttendance() async {
    try {
      final userId = await _tokenStorage.readUserId();
      if (userId == null || userId.isEmpty) return;
      final list = await _attendanceService.myAttendance(userId);
      final today = DateTime.now();
      final todayRows = list
          .where((row) => _isSameDay(_parseDate(row), today))
          .toList();
      if (!mounted) return;
      setState(() {
        _checkedToday = todayRows.length;
        _recent = todayRows.take(6).toList();
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadTodayTimetables() async {
    try {
      final userId = await _tokenStorage.readUserId();
      final groupId = await _tokenStorage.readGroupId();

      List<Map<String, dynamic>> raw = const [];
      if (userId != null && userId.isNotEmpty) {
        raw = await _timetableService.listByUser(userId);
      } else if (groupId != null && groupId.isNotEmpty) {
        raw = await _timetableService.listByGroup(groupId);
      } else {
        return;
      }

      final todayIndex = DateTime.now().weekday;
      final today = raw.where((row) {
        final day = readString(row, const ['day_of_week', 'dayOfWeek', 'day']);
        final idx = _weekdayIndex(day);
        return idx == todayIndex;
      }).toList();

      if (!mounted) return;
      setState(() => _todayTimetables = today.length);
    } catch (_) {
      // ignore
    }
  }

  int? _weekdayIndex(String? raw) {
    if (raw == null) return null;
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.startsWith('mon')) return DateTime.monday;
    if (v.startsWith('tue')) return DateTime.tuesday;
    if (v.startsWith('wed')) return DateTime.wednesday;
    if (v.startsWith('thu')) return DateTime.thursday;
    if (v.startsWith('fri')) return DateTime.friday;
    if (v.startsWith('sat')) return DateTime.saturday;
    if (v.startsWith('sun')) return DateTime.sunday;
    return null;
  }

  DateTime? _parseDate(Map<String, dynamic> row) {
    final raw = readString(row, const ['date', 'created_at', 'createdAt']);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      if (raw.length >= 10) {
        try {
          return DateTime.parse(raw.substring(0, 10));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      body: SafeArea(
        bottom: false,
        child: AppPullToRefresh(
          onRefresh: _loadSummary,
          alwaysScrollable: true,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppSizes.spacingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  safeLocaleString(
                    context,
                    'click_qr_code',
                    fallback: 'Click QR Code for Scan',
                  ),
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXL,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingS),
                GestureDetector(
                  onTap: () async {
                    // Check for leave requests before allowing scan
                    setState(() => _isLoading = true);
                    try {
                      final userId = await _tokenStorage.readUserId();
                      if (userId != null && userId.isNotEmpty) {
                        final leaveService = LeaveRequestService();
                        final leaveRequests = await leaveService.byStudent(userId);
                        final today = DateTime.now();
                        
                        final hasLeaveToday = leaveRequests.any((row) {
                          final startStr = readString(row, const ['start_date', 'startDate']);
                          final endStr = readString(row, const ['end_date', 'endDate']);
                          final status = (readString(row, const ['status']) ?? 'pending').toLowerCase();
                          
                          // Block for both pending and approved leaves as per requirement
                          if (status == 'rejected' || status == 'declined' || status == 'cancelled' || status == 'cancel') {
                            return false;
                          }
                          
                          if (startStr == null) return false;
                          try {
                            final start = DateTime.parse(startStr);
                            final end = endStr != null ? DateTime.parse(endStr) : start;
                            final startKey = DateTime(start.year, start.month, start.day);
                            final endKey = DateTime(end.year, end.month, end.day);
                            final todayKey = DateTime(today.year, today.month, today.day);
                            
                            return (todayKey.isAtSameMomentAs(startKey) || todayKey.isAfter(startKey)) &&
                                   (todayKey.isAtSameMomentAs(endKey) || todayKey.isBefore(endKey));
                          } catch (_) {
                            return false;
                          }
                        });

                        if (hasLeaveToday) {
                          setState(() => _isLoading = false);
                          CustomSnackBar.error(
                            title: 'Access Denied',
                            message: 'You cannot scan attendance while on leave.',
                          );
                          return;
                        }
                      }
                    } catch (_) {
                      // If leave check fails, we might want to let them through or block. 
                      // For now, continue to scan as a fallback or just log.
                    }
                    setState(() => _isLoading = false);

                    if (!context.mounted) return;
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QrScannerScreen(),
                      ),
                    );
                    if (!mounted) return;
                    if (result != null && result.isNotEmpty) {
                      setState(() => _isLoading = true);
                      final res = await _attendanceService.checkIn(
                        code: result,
                      );
                      if (!context.mounted) return;
                      setState(() => _isLoading = false);

                      final body = res['body'];
                      final message = body is Map
                          ? (body['message']?.toString() ?? 'Check-in complete')
                          : 'Check-in complete';
                      final statusCode = res['statusCode'];
                      if (statusCode is int &&
                          statusCode >= 200 &&
                          statusCode < 300) {
                        CustomSnackBar.success(title: message);
                      } else {
                        CustomSnackBar.error(title: message);
                      }
                      await _loadAttendance();
                    }
                  },
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // blue corner frame
                        CustomPaint(
                          size: const Size(250, 250),
                          painter: _QrCornerFramePainter(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        // qr
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusM,
                            ),
                          ),
                          child: Icon(
                            Icons.qr_code_2,
                            size: 220,
                            color: isDark ? AppColors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  _isLoading
                      ? 'Checking in...'
                      : safeLocaleString(
                          context,
                          'click_me',
                          fallback: 'Click me',
                        ),
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXL),
                _SummaryCards(
                  todayTimetables: _todayTimetables,
                  checkedToday: _checkedToday,
                  isLoading: _isSummaryLoading,
                ),
                const SizedBox(height: AppSizes.spacingXL),
                Row(
                  children: [
                    Text(
                      safeLocaleString(
                        context,
                        'recent_scan',
                        fallback: 'Recent Scan',
                      ),
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeM,
                        fontWeight: FontWeight.w700,
                        color: appColors.primaryBlue,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text('Attendance'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingS),
                if (_recent.isEmpty)
                  const Text('No recent scans')
                else
                  ..._recent.map((row) {
                    final date = _formatDate(
                      readString(row, const [
                        'date',
                        'created_at',
                        'createdAt',
                      ]),
                    );
                    final inTime = readString(row, const [
                      'check_in_time',
                      'checkInTime',
                      'time_in',
                    ]);
                    final subject = _readSubject(row);
                    final status = readString(row, const [
                      'status',
                      'remark',
                      'attendance_status',
                    ]);
                    return _ScanRow(
                      date: date ?? '-',
                      checkInTime: (inTime == null || inTime.isEmpty)
                          ? '--:--'
                          : inTime,
                      subject: subject ?? 'Class',
                      status: status ?? '',
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }

  String? _readSubject(Map<String, dynamic> row) {
    final timetable =
        asMap(row['timetable']) ??
        asMap(row['schedule']) ??
        asMap(row['class']);
    final subject = asMap(timetable?['subject']);
    return readString(subject ?? timetable ?? row, const [
      'name',
      'title',
      'subject_name',
      'subjectName',
      'subject',
    ]);
  }
}

class _SummaryCards extends StatelessWidget {
  final int todayTimetables;
  final int checkedToday;
  final bool isLoading;

  const _SummaryCards({
    required this.todayTimetables,
    required this.checkedToday,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getPadding(context);
    final spacing = Responsive.isMobile(context)
        ? AppSizes.spacingS
        : AppSizes.spacingM;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacingS),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  number: isLoading ? '—' : todayTimetables.toString(),
                  label: safeLocaleString(
                    context,
                    'timetable',
                    fallback: 'Timetable',
                  ),
                  icon: Icons.calendar_month_outlined,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  number: isLoading ? '—' : checkedToday.toString(),
                  label: safeLocaleString(
                    context,
                    'check_in_today',
                    fallback: 'Check in today',
                  ),
                  icon: Icons.verified_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String number,
    required String label,
    required IconData icon,
  }) {
    final cardPadding = Responsive.isMobile(context)
        ? AppSizes.spacingS
        : AppSizes.spacingM;
    final numberFontSize = Responsive.isMobile(context)
        ? AppSizes.fontSizeXXL
        : AppSizes.fontSizeXXXL;
    final labelFontSize = Responsive.isMobile(context)
        ? AppSizes.fontSizeS
        : AppSizes.fontSizeM;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: numberFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconSizeM, color: AppColors.success),
              const SizedBox(width: AppSizes.spacingXS),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  final String date;
  final String checkInTime;
  final String subject;
  final String status;

  const _ScanRow({
    required this.date,
    required this.checkInTime,
    required this.subject,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.trim().toLowerCase();
    final isPresent =
        checkInTime.trim().isNotEmpty &&
        checkInTime.trim() != '--:--' ||
        normalized.contains('present') ||
        normalized.contains('on time') ||
        normalized.contains('late') ||
        normalized == '1' ||
        normalized == 'true';
    final statusColor = isPresent ? AppColors.success : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingS,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      fontWeight: FontWeight.w700,
                      color: appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: appColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          color: appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingM),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: appColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        checkInTime,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                isPresent ? 'Present' : 'Absent',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCornerFramePainter extends CustomPainter {
  final Color color;

  const _QrCornerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const corner = 40.0;
    const inset = 10.0;

    // top-left
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset + corner, inset),
      paint,
    );
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset, inset + corner),
      paint,
    );
    // top-right
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset - corner, inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + corner),
      paint,
    );
    // bottom-left
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + corner, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset, size.height - inset - corner),
      paint,
    );
    // bottom-right
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - corner, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset, size.height - inset - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrCornerFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
