import 'package:flutter/material.dart';
import 'dart:async';

import '../configs/app_colors.dart';
import '../configs/app_sizes.dart';


class CustomSnackBar {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static ValueNotifier<bool>? _visible;

  static void show({
    required String title,
    required String message,
    required SnackBarType type,
    Duration? duration,
  }) {
    final navigatorState = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigatorState == null || context == null) return;

    final backgroundColor = switch (type) {
      SnackBarType.success => AppColors.success,
      SnackBarType.error => AppColors.error,
      SnackBarType.info => AppColors.info,
    };

    _hideImmediate();

    final visible = ValueNotifier<bool>(false);
    _visible = visible;

    _entry = OverlayEntry(
      builder: (context) => _TopSnackBar(
        title: title,
        message: message,
        backgroundColor: backgroundColor,
        visible: visible,
        onDismissed: _hideImmediate,
      ),
    );

    final overlay = navigatorState.overlay;
    if (overlay == null) return;
    overlay.insert(_entry!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_visible == visible) visible.value = true;
    });

    final displayDuration = duration ?? const Duration(seconds: 2);
    _timer = Timer(displayDuration, () {
      _hideAnimated(visible);
    });
  }

  static void _hideAnimated(ValueNotifier<bool> visible) {
    if (_visible != visible) return;
    visible.value = false;
    Future.delayed(const Duration(milliseconds: 220), () {
      if (_visible == visible) _hideImmediate();
    });
  }

  static void _hideImmediate() {
    _timer?.cancel();
    _timer = null;

    _visible = null;

    _entry?.remove();
    _entry = null;
  }

  static void success({
    required String title,
    String message = '',
    Duration? duration,
  }) {
    show(
      title: title,
      message: message,
      type: SnackBarType.success,
      duration: duration,
    );
  }

  static void info({
    required String title,
    String message = '',
    Duration? duration,
  }) {
    show(
      title: title,
      message: message,
      type: SnackBarType.info,
      duration: duration,
    );
  }

  static void error({
    required String title,
    String message = '',
    Duration? duration,
  }) {
    show(
      title: title,
      message: message,
      type: SnackBarType.error,
      duration: duration,
    );
  }
}

enum SnackBarType { success, error, info }

class _TopSnackBar extends StatelessWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final ValueNotifier<bool> visible;
  final VoidCallback onDismissed;

  const _TopSnackBar({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.visible,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + AppSizes.spacingS,
      left: AppSizes.spacingM,
      right: AppSizes.spacingM,
      child: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (context, isVisible, child) {
          return AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: isVisible ? Offset.zero : const Offset(0, -0.25),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isVisible ? 1 : 0,
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDismissed,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingM,
                vertical: AppSizes.spacingM,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: AppSizes.fontSizeM,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.spacingXS),
                          Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: AppSizes.fontSizeS,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
