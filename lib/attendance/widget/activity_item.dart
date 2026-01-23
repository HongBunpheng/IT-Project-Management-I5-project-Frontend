import 'package:flutter/material.dart';
import '../../utils/localization_helper.dart';

class ActivityItemWidget extends StatelessWidget {
  final String type;
  final String date;
  final String time;
  final String statusMessage;

  const ActivityItemWidget({
    super.key,
    required this.type,
    required this.date,
    required this.time,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            type == "checkin" ? Icons.login : Icons.logout,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == "checkin"
                    ? safeLocaleString(context, 'check_in', fallback: 'Check In')
                    : safeLocaleString(
                        context,
                        'check_out',
                        fallback: 'Check Out',
                      ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(date, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(statusMessage, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
