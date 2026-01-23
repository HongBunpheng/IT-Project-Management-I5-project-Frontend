import 'package:flutter/material.dart';

class AppPullToRefresh extends StatelessWidget {
  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.alwaysScrollable = false,
    this.displacement,
    this.edgeOffset = 0.0,
    this.color = Colors.grey,
    this.backgroundColor = Colors.white,
    this.notificationPredicate,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final bool alwaysScrollable;
  final double? displacement;
  final double edgeOffset;
  final Color? color;
  final Color backgroundColor;
  final bool Function(ScrollNotification)? notificationPredicate;

  @override
  Widget build(BuildContext context) {
    final Widget content = alwaysScrollable
        ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: child,
            ),
          )
        : child;

    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement ?? 40.0,
      edgeOffset: edgeOffset,
      color: color,
      backgroundColor: backgroundColor,
      notificationPredicate: notificationPredicate ?? _defaultPredicate,
      child: content,
    );
  }

  static bool _defaultPredicate(ScrollNotification notification) {
    return notification.depth == 0;
  }
}
