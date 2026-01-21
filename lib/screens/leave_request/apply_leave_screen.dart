import 'package:flutter/material.dart';
import '../../widgets/common/primary_button.dart';
import '../../configs/app_colors.dart';
import 'leave_request_detail_screen.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  bool _isHalfDay = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill dates as per screenshot for demo
    _startDate = DateTime(2025, 1, 2);
    _endDate = DateTime(2025, 1, 2);
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Select Date";
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
          'Apply Leave',
          style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Date
              const Text(
                'Start Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_startDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Date
              const Text(
                'End Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_endDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reason
              const Text(
                'Reason for leave',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                 height: 150,
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                 child: TextField(
                   controller: _reasonController,
                   maxLines: null,
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     hintText: 'Enter reason...',
                     hintStyle: TextStyle(color: Colors.grey),
                   ),
                 ),
              ),
              const SizedBox(height: 16),
              
              // Half Day Checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Is half day leave?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                   SizedBox(
                    height: 24,
                    width: 24,
                     child: Checkbox(
                      value: _isHalfDay,
                      onChanged: (val) {
                        setState(() => _isHalfDay = val ?? false);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(color: Colors.grey.shade400),
                     ),
                   )
                ],
              ),
              
              const Spacer(),

              // Buttons
              Row(
                children: [
                   Expanded(
                     child: SizedBox(
                       height: 50,
                       child: OutlinedButton(
                         onPressed: () => Navigator.pop(context),
                         style: OutlinedButton.styleFrom(
                           side: BorderSide(color: Colors.grey.shade300),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: const Text('Cancel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeaveRequestDetailScreen(
                                    startDate: _formatDate(_startDate),
                                    endDate: _formatDate(_endDate),
                                    reason: _reasonController.text.isNotEmpty ? _reasonController.text : "I am not able to join due i have a bad health.",
                                    isHalfDay: _isHalfDay,
                                  ),
                                ),
                              );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF154888), // Dark Blue
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
