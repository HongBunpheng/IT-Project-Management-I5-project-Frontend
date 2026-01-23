import 'package:flutter/material.dart';

import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';
import '../../configs/app_theme_extension.dart';
import '../../services/event_service.dart';
import '../../utils/json_utils.dart';
import '../../utils/pull_to_refresh.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventService _eventService = EventService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _events = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await _eventService.list();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _events = const [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: isDark ? const Color(0xFF121212) : AppColors.white,
        foregroundColor: appColors.textPrimary,
        elevation: 0,
      ),
      body: AppPullToRefresh(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.spacingM),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _events.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSizes.spacingS),
                itemBuilder: (context, index) {
                  final row = _events[index];
                  return _EventTile(json: row);
                },
              ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> json;

  const _EventTile({required this.json});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = readString(json, const ['title', 'name']) ?? 'Event';
    final description = readString(json, const ['description']);
    final type = readString(json, const ['type', 'category']) ?? 'event';
    final date =
        readString(json, const ['date']) ??
        _formatDate(readString(json, const ['created_at', 'createdAt']));
    final startTime = readString(json, const ['start_time', 'startTime']);
    final endTime = readString(json, const ['end_time', 'endTime']);

    final timeLabel =
        (startTime != null && startTime.isNotEmpty) ||
            (endTime != null && endTime.isNotEmpty)
        ? '${startTime ?? '--:--'} - ${endTime ?? '--:--'}'
        : null;

    final chipColor = type.toLowerCase().contains('exam')
        ? AppColors.primaryBlue
        : AppColors.purple;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingS,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: chipColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: AppSizes.fontSizeS,
                fontWeight: FontWeight.w700,
                color: chipColor,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeM,
                    fontWeight: FontWeight.w700,
                    color: appColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeS,
                      color: appColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: appColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date ?? '-',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          color: appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timeLabel != null) ...[
                      const SizedBox(width: AppSizes.spacingM),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: appColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeS,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    // Handles "2026-01-22T17:37:54.000000Z" or "2026-01-22"
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }
}
