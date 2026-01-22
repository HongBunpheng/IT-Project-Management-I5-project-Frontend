import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../utils/localization_helper.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) return;
              final barcodes = capture.barcodes;
              final raw = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
              if (raw == null || raw.isEmpty) return;
              _handled = true;
              Navigator.pop(context, raw);
            },
          ),
          // Dark overlay outside scanning area
          Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingM,
                        vertical: AppSizes.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: Text(
                        safeLocaleString(context, 'scan_qr_code', fallback: 'Scan QR Code'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontSizeL,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _controller.toggleTorch(),
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scanning frame with corner indicators
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border: Border.all(
                  color: appColors.primaryBlue,
                  width: 3,
                ),
              ),
              child: CustomPaint(
                painter: _QrScannerCornerPainter(color: appColors.primaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScannerCornerPainter extends CustomPainter {
  final Color color;

  _QrScannerCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const inset = 0.0;

    // Top-left corner
    canvas.drawLine(
      Offset(inset, inset + cornerLength),
      Offset(inset, inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, inset),
      Offset(inset + cornerLength, inset),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - inset - cornerLength, inset),
      Offset(size.width - inset, inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(inset, size.height - inset - cornerLength),
      Offset(inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + cornerLength, size.height - inset),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - inset - cornerLength, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset, size.height - inset - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrScannerCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
