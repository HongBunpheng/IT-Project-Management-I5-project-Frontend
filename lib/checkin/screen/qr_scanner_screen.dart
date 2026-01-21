import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Scan QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.fontSizeL,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // Simple overlay frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

