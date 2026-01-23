import 'package:flutter/material.dart';

import 'widgets/common/app_header.dart';
import 'widgets/common/custom_bottom_navigation_bar.dart';
import 'dashboard/screen/dashboard_screen.dart';
import 'checkin/screen/checkin_screen.dart';
import 'exam/screen/exam_scores_screen.dart';
import 'timetable/screen/timetable_screen.dart';
import 'account/screen/profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  static MainShellState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  void setTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  bool _showHeaderForIndex(int index) => index != 4;

  @override
  Widget build(BuildContext context) {
    final showHeader = _showHeaderForIndex(_index);

    return Scaffold(
      body: Column(
        children: [
          if (showHeader)
            AppHeader(
              onProfileTap: () => setTab(4),
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                DashboardView(),
                CheckInScreen(),
                ExamScoresScreen(),
                TimetableView(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _index,
        onTap: setTab,
      ),
    );
  }
}

void goToMainTab(BuildContext context, int index) {
  final state = MainShell.maybeOf(context);
  if (state != null) {
    state.setTab(index);
    return;
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => MainShell(initialIndex: index)),
  );
}
