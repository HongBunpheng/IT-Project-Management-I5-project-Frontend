import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final margin = Responsive.getPadding(context);

    return Container(
      margin: EdgeInsets.only(
        top: margin,
        left: margin,
        right: margin,
        bottom: margin,
      ),
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isMobile(context)
            ? AppSizes.spacingS
            : AppSizes.spacingM,
        vertical: AppSizes.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.qr_code_scanner,
            index: 1,
            isActive: currentIndex == 1,
          ),
          _buildNavItem(
            context,
            icon: Icons.menu_book,
            index: 2,
            isActive: currentIndex == 2,
          ),
          _buildNavItem(
            context,
            icon: Icons.schedule,
            index: 3,
            isActive: currentIndex == 3,
          ),
          _buildNavItem(
            context,
            icon: Icons.person,
            index: 4,
            isActive: currentIndex == 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.black : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: AppSizes.iconSizeM),
      ),
    );
  }
}
