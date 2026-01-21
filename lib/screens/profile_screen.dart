import 'package:flutter/material.dart';
import '../configs/app_colors.dart';
import '../configs/app_sizes.dart';
import '../widgets/common/app_header.dart';
import '../widgets/common/custom_bottom_navigation_bar.dart';
import 'dashboard/dashboard_view.dart';
import 'checkin_screen.dart';
import 'exam_scores_screen.dart';
import 'timetable_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentBottomNavIndex = 4; // Settings is index 4

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CheckInScreen()),
        );
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
        // Already on settings
        setState(() => _currentBottomNavIndex = 4);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.spacingL),
                children: const [
                  _SettingItem(icon: Icons.person, label: 'Account'),
                  _SettingItem(icon: Icons.notifications, label: 'Notifications'),
                  _SettingItem(icon: Icons.lock, label: 'Privacy'),
                  _SettingItem(icon: Icons.info_outline, label: 'About'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SettingItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: AppSizes.fontSizeM,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () {},
    );
  }
}
