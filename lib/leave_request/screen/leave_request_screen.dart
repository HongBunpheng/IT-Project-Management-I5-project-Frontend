import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import 'apply_leave_screen.dart';
import 'leave_request_detail_screen.dart';
import '../../services/leave_request_service.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final List<String> _weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  final LeaveRequestService _leaveService = LeaveRequestService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = true;
  String? _errorMessage;
  DateTime _focusedMonth = DateTime.now();

  final Map<int, Map<String, dynamic>> _dayRequests = {};

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dayRequests.clear();
    });

    try {
      final userId = await _tokenStorage.readUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Missing user id. Please login again.');
      }
      final rows = await _leaveService.byStudent(userId);

      for (final row in rows) {
        final start = readString(row, const ['start_date', 'startDate']);
        if (start == null) continue;

        final parsed = DateTime.tryParse(start);
        if (parsed == null) continue;
        if (parsed.year == _focusedMonth.year &&
            parsed.month == _focusedMonth.month) {
          _dayRequests[parsed.day] = row;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _monthLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayOffset = firstDayOfMonth.weekday - 1; // 1=Mon, so offset is 0 for Mon

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark 
            ? AppColors.primaryBlue.withValues(alpha: 0.2)
            : AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: isDark
            ? Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              )
            : null,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: appColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leave Request',
          style: TextStyle(
            color: appColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue, size: 28),
            onPressed: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: const ApplyLeaveScreen(),
                  );
                },
              );
              
              if (result is Map && result['success'] == true) {
                _loadLeaveRequests();
                
                // Construct basic data for detail screen if not fully provided
                final request = asMap(result['request']) ?? {};
                final id = readString(request, const ['id', '_id']);
                final startDate = readString(request, const ['start_date', 'startDate']) ?? '';
                final endDate = readString(request, const ['end_date', 'endDate']) ?? '';
                final reason = readString(request, const ['reason']) ?? '';
                final status = readString(request, const ['status']) ?? 'Pending';

                if (!context.mounted) return;
                
                // Show detail screen immediately after success
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return FractionallySizedBox(
                      heightFactor: 0.8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
                        child: LeaveRequestDetailScreen(
                          id: id,
                          startDate: startDate,
                          endDate: endDate,
                          reason: reason,
                          status: status,
                          isAdmin: false, 
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Date Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _monthLabel(_focusedMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(
                              _focusedMonth.year,
                              _focusedMonth.month - 1,
                              1,
                            );
                          });
                          _loadLeaveRequests();
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(
                              _focusedMonth.year,
                              _focusedMonth.month + 1,
                              1,
                            );
                          });
                          _loadLeaveRequests();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calendar Grid
              // Weekday Headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekDays
                    .map(
                      (day) => SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Calendar Cells
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadLeaveRequests,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        itemCount: daysInMonth + firstDayOffset,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                        itemBuilder: (context, index) {
                          if (index < firstDayOffset) {
                            return const SizedBox.shrink(); // Offset
                          }
                          final day = index - firstDayOffset + 1;

                          return _buildDayCell(day);
                        },
                      ),
              ),

              // Legend
              Container(
                margin: const EdgeInsets.only(bottom: 54),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.orange, 'Awaiting'),
                    _buildLegendItem(Colors.green, 'Approved'),
                    _buildLegendItem(Colors.red, 'Declined'),
                    _buildLegendItem(Colors.grey, 'Cancel'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(int day) {
    Color textColor = Colors.grey.shade700;

    Widget cellContent;

    // Status Logic
    if (_dayRequests.containsKey(day)) {
      final request = _dayRequests[day]!;
      final status = (readString(request, const ['status']) ?? 'awaiting').toLowerCase();
      
      textColor = (status == 'awaiting' || status == 'pending') ? Colors.black : Colors.white;

      switch (status) {
        case 'declined':
        case 'rejected':
          cellContent = Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEF5350), // Red
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
          break;
        case 'approved':
          cellContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              const CircleAvatar(radius: 4, backgroundColor: Colors.green),
            ],
          );
          break;
        case 'awaiting':
        case 'pending':
        default:
          cellContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              const CircleAvatar(radius: 4, backgroundColor: Colors.orange),
            ],
          );
          break;
      }
    } else {
      // Default cell
      cellContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: TextStyle(fontSize: 16, color: textColor)),
            if (day == 6) ...[
              const SizedBox(height: 4),
              const CircleAvatar(radius: 4, backgroundColor: Colors.grey),
            ] else ...[
              const SizedBox(height: 12), // Placeholder height
            ],
          ],
        ),
      );
    }

    return InkWell(
      onTap: _dayRequests.containsKey(day) ? () => _onDayTapped(day) : null,
      borderRadius: BorderRadius.circular(20),
      child: cellContent,
    );
  }

  void _onDayTapped(int day) {
    final request = _dayRequests[day];
    if (request == null) return;

    final startDate = readString(request, const ['start_date', 'startDate']) ?? '';
    final endDate = readString(request, const ['end_date', 'endDate']) ?? '';
    final reason = readString(request, const ['reason']) ?? '';
    final status = readString(request, const ['status']) ?? 'Pending';
    final isHalfDay = request['is_half_day'] == true || request['isHalfDay'] == true;
    final id = readString(request, const ['id', '_id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
            child: LeaveRequestDetailScreen(
              id: id,
              startDate: startDate,
              endDate: endDate,
              reason: reason,
              status: status,
              isAdmin: false, 
            ),
          ),
        );
      },
    ).then((_) => _loadLeaveRequests()); // Refresh on close
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}
