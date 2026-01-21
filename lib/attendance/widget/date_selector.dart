import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';

class DateSelector extends StatelessWidget {
  final List<Map<String, String>> days;
  final int selectedIndex;
  final Function(int) onSelect;

  const DateSelector({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isActive = index == selectedIndex;

          return GestureDetector(
            onTap: () => onSelect(index),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColors.primaryBlue : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index]["day"]!,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index]["weekday"]!,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
