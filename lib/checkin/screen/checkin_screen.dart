import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/responsive.dart';
import '../../utils/localization_helper.dart';
import 'qr_scanner_screen.dart';
import '../../services/attendance_service.dart';
import '../../services/timetable_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../utils/snackbar.dart';

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
  int _totalRooms = 0;
  int _totalCheckedIns = 0;
  bool _isSummaryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() => _isSummaryLoading = true);
    await Future.wait([_loadAttendance(), _loadRooms()]);
    if (!mounted) return;
    setState(() => _isSummaryLoading = false);
  }

  Future<void> _loadAttendance() async {
    try {
      final userId = await _tokenStorage.readUserId();
      if (userId == null || userId.isEmpty) return;
      final list = await _attendanceService.myAttendance(userId);
      if (!mounted) return;
      setState(() {
        _totalCheckedIns = list.length;
        _recent = list.take(6).toList();
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadRooms() async {
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

      final rooms = <String>{};
      for (final row in raw) {
        final classroom = asMap(row['classroom']);
        final roomName =
            (classroom != null
                ? readString(classroom, const ['name'])
                : null) ??
            readString(row, const ['room', 'classroom_name', 'classroom']);
        final normalized = roomName?.trim();
        if (normalized != null && normalized.isNotEmpty) {
          rooms.add(normalized);
        }
      }

      if (!mounted) return;
      setState(() => _totalRooms = rooms.length);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      body: SingleChildScrollView(
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
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
                if (!mounted) return;
                if (result != null && result.isNotEmpty) {
                  setState(() => _isLoading = true);
                  final res = await _attendanceService.checkIn(code: result);
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
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
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
                  : safeLocaleString(context, 'click_me', fallback: 'Click me'),
              style: const TextStyle(
                fontSize: AppSizes.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXL),
            _SummaryCards(
              totalRooms: _totalRooms,
              totalCheckedIns: _totalCheckedIns,
              isLoading: _isSummaryLoading,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
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
            ),
            const SizedBox(height: AppSizes.spacingS),
            if (_recent.isEmpty)
              const Text('No recent scans')
            else
              ..._recent.map((row) {
                final code = readString(row, const ['code', 'qr_code']) ?? '-';
                final date =
                    readString(row, const ['date', 'created_at']) ?? '-';
                final inTime = readString(row, const ['check_in_time']) ?? '-';
                final outTime =
                    readString(row, const ['check_out_time']) ?? '-';
                return _ScanRow(
                  code: code,
                  date: date,
                  inTime: inTime,
                  outTime: outTime,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final int totalRooms;
  final int totalCheckedIns;
  final bool isLoading;

  const _SummaryCards({
    required this.totalRooms,
    required this.totalCheckedIns,
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
                safeLocaleString(
                  context,
                  'rooms',
                  fallback: 'ROOMS',
                ).toUpperCase(),
                style: TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              Text(
                safeLocaleString(context, 'view_rooms', fallback: 'View Rooms'),
                style: TextStyle(
                  fontSize: AppSizes.fontSizeM,
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
                  number: isLoading ? '—' : totalRooms.toString(),
                  label: safeLocaleString(context, 'rooms', fallback: 'Rooms'),
                  icon: Icons.grid_view,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  number: isLoading ? '—' : totalCheckedIns.toString(),
                  label: safeLocaleString(
                    context,
                    'checked_ins',
                    fallback: 'Checked-ins',
                  ),
                  icon: Icons.people,
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
  final String code;
  final String date;
  final String inTime;
  final String outTime;

  const _ScanRow({
    required this.code,
    required this.date,
    required this.inTime,
    required this.outTime,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? Colors.pinkAccent.shade200 : Colors.pinkAccent;

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
              height: 32,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Text(
              code,
              style: TextStyle(
                fontSize: AppSizes.fontSizeM,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Text(
                date,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeM,
                  color: appColors.textPrimary,
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark ? Colors.blue.shade300 : Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  inTime,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeS,
                    color: isDark ? Colors.blue.shade300 : Colors.blue,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingS),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark ? Colors.red.shade300 : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  outTime,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeS,
                    color: isDark ? Colors.red.shade300 : Colors.red,
                  ),
                ),
              ],
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
