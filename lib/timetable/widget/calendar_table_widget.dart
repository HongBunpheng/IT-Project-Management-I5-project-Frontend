import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../utils/responsive.dart';

class CalendarTableWidget extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime currentMonth;
  final Function(DateTime) onDateSelected;
  final Function(DateTime)? onMonthChanged; // Optional callback for month navigation
  final Map<DateTime, int>? tasksCount; // Map of date to task count

  const CalendarTableWidget({
    super.key,
    required this.selectedDate,
    required this.currentMonth,
    required this.onDateSelected,
    this.onMonthChanged,
    this.tasksCount,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final daysInMonth = lastDayOfMonth.day;
    final today = DateTime.now();

    // Calculate total weeks needed
    final totalDays = firstDayWeekday - 1 + daysInMonth;
    final weeks = (totalDays / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with month/year and navigation
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.getPadding(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              // Month/Year with navigation arrows
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.primaryBlue),
                      onPressed: () {
                        final prevMonth = DateTime(
                          currentMonth.year,
                          currentMonth.month - 1,
                        );
                        if (onMonthChanged != null) {
                          onMonthChanged!(prevMonth);
                        } else {
                          onDateSelected(prevMonth);
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
                      child: Text(
                        '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
                      onPressed: () {
                        final nextMonth = DateTime(
                          currentMonth.year,
                          currentMonth.month + 1,
                        );
                        if (onMonthChanged != null) {
                          onMonthChanged!(nextMonth);
                        } else {
                          onDateSelected(nextMonth);
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.spacingM),
        // Calendar table
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.getPadding(context),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                // Weekday headers
                _buildWeekdayHeaders(),
                // Calendar grid
                ...List.generate(weeks, (weekIndex) {
                  return _buildWeekRow(
                    weekIndex,
                    firstDayOfMonth,
                    firstDayWeekday,
                    daysInMonth,
                    today,
                    selectedDate,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusM),
        ),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekRow(
    int weekIndex,
    DateTime firstDayOfMonth,
    int firstDayWeekday,
    int daysInMonth,
    DateTime today,
    DateTime selectedDate,
  ) {
    return Row(
      children: List.generate(7, (dayIndex) {
        final dayNumber = weekIndex * 7 + dayIndex - (firstDayWeekday - 1) + 1;
        
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          // Empty cell for days outside the month
          return Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  right: dayIndex < 6
                      ? BorderSide(color: AppColors.borderLight, width: 0.5)
                      : BorderSide.none,
                  bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
                ),
              ),
            ),
          );
        }

        final date = DateTime(
          firstDayOfMonth.year,
          firstDayOfMonth.month,
          dayNumber,
        );
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected = date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        
        // Get task count for this date
        final dateKey = DateTime(date.year, date.month, date.day);
        final hasTasks = tasksCount != null && tasksCount![dateKey] != null;
        final taskCount = tasksCount?[dateKey] ?? 0;

        return Expanded(
          child: GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : isToday
                        ? AppColors.cardBlue
                        : Colors.transparent,
                border: Border(
                  right: dayIndex < 6
                      ? BorderSide(color: AppColors.borderLight, width: 0.5)
                      : BorderSide.none,
                  bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeM,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.white
                          : isToday
                              ? AppColors.primaryBlue
                              : AppColors.textPrimary,
                    ),
                  ),
                  if (hasTasks && taskCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
