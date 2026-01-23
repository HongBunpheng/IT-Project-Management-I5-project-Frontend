import 'package:flutter/material.dart';
import '../../configs/app_colors.dart';
import '../../configs/app_sizes.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Dummy tasks (no backend yet)
    final tasks = [
      _TaskItem(
        title: 'Office Project',
        taskCount: 23,
        progress: 0.7,
        color: Colors.redAccent,
        icon: Icons.work,
      ),
      _TaskItem(
        title: 'Personal Project',
        taskCount: 30,
        progress: 0.52,
        color: Colors.purple,
        icon: Icons.person,
      ),
      _TaskItem(
        title: 'Daily Study',
        taskCount: 30,
        progress: 0.87,
        color: Colors.orange,
        icon: Icons.menu_book,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text('Task', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                const Text(
                  'Task',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeXL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spacingM),

            /// TASK LIST
            ...tasks.map(
              (task) => _TaskCard(
                task: task,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _NoExamScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// MODELS (LOCAL DUMMY)
/// ----------------------------
class _TaskItem {
  final String title;
  final int taskCount;
  final double progress;
  final Color color;
  final IconData icon;

  _TaskItem({
    required this.title,
    required this.taskCount,
    required this.progress,
    required this.color,
    required this.icon,
  });
}

/// ----------------------------
/// TASK CARD UI (IMAGE 2 STYLE)
/// ----------------------------
class _TaskCard extends StatelessWidget {
  final _TaskItem task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: task.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(task.icon, color: task.color),
            ),

            const SizedBox(width: 12),

            /// TITLE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.taskCount} Tasks',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            /// PROGRESS %
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    value: task.progress,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey.shade200,
                    color: task.color,
                  ),
                ),
                Text(
                  '${(task.progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// DUMMY DESTINATION SCREEN
/// ----------------------------
class _NoExamScreen extends StatelessWidget {
  const _NoExamScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text('Start Quiz', style: TextStyle(color: Colors.black)),
      ),
      body: const Center(
        child: Text(
          'No exam yet 🙂',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
