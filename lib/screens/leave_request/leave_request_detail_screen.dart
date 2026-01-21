import 'package:flutter/material.dart';

class LeaveRequestDetailScreen extends StatelessWidget {
  final String startDate;
  final String endDate;
  final String reason;
  final bool isHalfDay;

  const LeaveRequestDetailScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.isHalfDay,
  });

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue, size: 28),
            onPressed: () {
              // Could navigate to apply new leave, or just dummy
            },
          ),
        ],
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                const SizedBox(height: 10),
                // Month Header (Mirrors screen 0 for context, though screen 2 shows details)
                // Actually screen 2 overlays details on top of calendar or separate screen?
                // Image 2 shows "Leave Request" title (Blue), Pending tag, and details.
                // It looks like a modal or separate screen content. Let's make it a full screen as requested.
                
                const Text(
                  'October 2025',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Reusing the calendar visual from screen 1 might be overkill or confusing if static.
                // The screenshot seems to show the calendar in background but greyed out?
                // Or maybe it's just the details part. 
                // Let's implement the visible content: Title "Leave Request", Pending badge, Details.
                
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Leave Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF154888), // Dark Blue
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC80).withValues(alpha: 0.5), // Light Orange
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                _buildDetailRow('Start Date:', startDate),
                const SizedBox(height: 12),
                _buildDetailRow('End Date:', endDate),
                const SizedBox(height: 12),
                _buildDetailRow('Half day:', isHalfDay ? 'Yes' : 'No'),
                const SizedBox(height: 24),
                
                const Text(
                  'Reason:',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                    color: Colors.black87
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apply on Tue 20,July 2025', // Mock submission date
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                
                const Spacer(),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                     onPressed: () {
                       // Navigate back to Leave Request Screen (Calendar)
                       // Pop until we hit LeaveRequestScreen. 
                       // ApplyLeaveScreen pushed this, LeaveRequestScreen pushed ApplyLeaveScreen.
                       // So pop x2.
                       int count = 0;
                       Navigator.popUntil(context, (route) {
                         return count++ == 2;
                       });
                     },
                     style: OutlinedButton.styleFrom(
                       side: BorderSide(color: Colors.grey.shade300),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                     ),
                     child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal)),
                   ),
                ),
                const SizedBox(height: 16),
             ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500, // Slightly lighter than label
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
