import 'package:flutter/material.dart';
import '../../widgets/common/primary_button.dart';
import 'apply_leave_screen.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  DateTime _focusedDate = DateTime(2025, 10, 1);
  final List<String> _weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  
  // Mock mock data for calendar status
  // 8: Declined (Red)
  // 16: Approved (Green)
  // 21, 22: Awaiting (Orange)
  final Map<int, String> _leaveStatus = {
    8: 'declined',
    16: 'approved',
    21: 'awaiting',
    22: 'awaiting',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Leave Request',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue, size: 28),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApplyLeaveScreen()),
              );
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
                    'October 2025',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: const [
                       Icon(Icons.arrow_back_ios, size: 16),
                       SizedBox(width: 24),
                       Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calendar Grid
              // Weekday Headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekDays.map((day) => SizedBox(
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
                )).toList(),
              ),
              const SizedBox(height: 16),
              
              // Calendar Cells
              Expanded(
                child: GridView.builder(
                  itemCount: 31 + 2, // 31 days + 2 offset
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,  
                  ),
                  itemBuilder: (context, index) {
                    if (index < 2) return const SizedBox.shrink(); // Offset
                    final day = index - 1;
                    
                    return _buildDayCell(day);
                  },
                ),
              ),

              // Legend
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute evenly
                      children: [
                        _buildLegendItem(Colors.orange, 'Awaiting'),
                        _buildLegendItem(Colors.green, 'Approved'),
                        _buildLegendItem(Colors.red, 'Declined'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(width: 12), // Align somewhat with Awaiting
                        _buildLegendItem(Colors.grey, 'Cancel'),
                      ],
                    ),
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
    Color? bgColor;
    Color textColor = Colors.grey.shade700;
    
    // Status Logic
    if (_leaveStatus.containsKey(day)) {
      final status = _leaveStatus[day];
      textColor = status == 'awaiting' ? Colors.black : Colors.white;
      
      switch (status) {
        case 'declined':
          bgColor = const Color(0xFFEF5350); // Red
          break;
        case 'approved':
          bgColor = const Color(0xFF66BB6A); // Green - small dot logic needs CustomPainter, using simple circle for now or stack
          // For 'approved' (16) screenshot shows green DOT, others show full circle? 
          // Actually screenshot 8 is RED circle. 16 is GREEN DOT. 21, 22 ORANGE DOT.
          // Let's implement dots for some, circle for others based on image.
          // Screenshot:
          // 8: Red Circle background, white text.
          // 16: Green Dot below text.
          // 21, 22: Orange Dot below text.
          // 6: Grey Dot below text.
          
          // Let's refactor to match that specific look.
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              const CircleAvatar(radius: 4, backgroundColor: Colors.green),
            ],
          );

        case 'awaiting':
           return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              const CircleAvatar(radius: 4, backgroundColor: Colors.orange),
            ],
          );
        case 'declined':
           // Already handled above but let's separate
           break;
      }
    }
    
    // Specific Override for "8" (Declined) -> Red Circle
    if (day == 8) {
       return Container(
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
    }
    
    // Default cell
    return Center(
      child: Column( // Use Column to reserve space for dot if needed for alignment consistency
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Text(
            '$day',
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
          if (_leaveStatus.containsKey(day) && _leaveStatus[day] != 'declined') ...[
             const SizedBox(height: 4),
             CircleAvatar(
               radius: 4, 
               backgroundColor: _leaveStatus[day] == 'approved' ? Colors.green : Colors.orange
             ),
          ] else if (day == 6) ...[ // Specific case for '6' in screenshot
             const SizedBox(height: 4),
             const CircleAvatar(radius: 4, backgroundColor: Colors.grey),
          ] else ...[
             const SizedBox(height: 12), // Placeholder height to keep alignment
          ]
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
