import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';

class AttendanceToggleButton extends StatelessWidget {
  final bool isMonthView;
  final VoidCallback onToggle;

  const AttendanceToggleButton({
    super.key,
    required this.isMonthView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: isMonthView
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width:
                  MediaQuery.of(context).size.width *
                  0.45, // Roughly half minus padding
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isMonthView ? null : onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Month',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isMonthView ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: !isMonthView ? null : onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Week',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: !isMonthView ? Colors.white : Colors.black87,
                      ),
                    ),
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
