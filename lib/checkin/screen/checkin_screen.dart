import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';
import '../../custom_bottom_navigation_bar.dart';
import '../../dashboard/screen/dashboard_screen.dart';
import '../../exam/screen/exam_scores_screen.dart';
import '../../timetable/screen/timetable_screen.dart';
import 'qr_scanner_screen.dart';
import '../../services/attendance_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = false;
  List<Map<String, dynamic>> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    try {
      final userId = await _tokenStorage.readUserId();
      if (userId == null || userId.isEmpty) return;
      final list = await _attendanceService.myAttendance(userId);
      if (!mounted) return;
      setState(() {
        _recent = list.take(6).toList();
      });
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getPadding(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSizes.spacingL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.spacingL),
              const Text(
                'Click QR Code for Scan',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                    await _loadRecent();
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
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          size: 220,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                _isLoading ? 'Checking in...' : 'Click me',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: AppSizes.spacingXL),
              const _SummaryCards(totalRooms: 5, totalCheckedIns: 27),
              const SizedBox(height: AppSizes.spacingXL),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Scan',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A74DA),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              if (_recent.isEmpty)
                const Text('No recent scans')
              else
                ..._recent.map((row) {
                  final code =
                      readString(row, const ['code', 'qr_code']) ?? '-';
                  final date =
                      readString(row, const ['date', 'created_at']) ?? '-';
                  final inTime =
                      readString(row, const ['check_in_time']) ?? '-';
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
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardView()),
              );
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ExamScoresScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TimetableView()),
              );
              break;
            case 4:
              break;
          }
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final int totalRooms;
  final int totalCheckedIns;

  const _SummaryCards({
    required this.totalRooms,
    required this.totalCheckedIns,
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
            children: const [
              Text(
                'ROOMS',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              Text(
                'View Rooms',
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
                  number: totalRooms.toString(),
                  label: 'Rooms',
                  icon: Icons.grid_view,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  number: totalCheckedIns.toString(),
                  label: 'Checked-ins',
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

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Text(
            code,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeM,
              fontWeight: FontWeight.w600,
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Text(
              date,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeM,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                inTime,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              const Icon(Icons.access_time, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                outTime,
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
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
