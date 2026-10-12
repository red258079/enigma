import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _phases = [
    {'key': 'preparation', 'label': '1. Chuẩn bị'},
    {'key': 'adaptation', 'label': '2. Hòa nhập'},
    {'key': 'sustain', 'label': '3. Duy trì'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start at Adaptation
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final phaseKey = _phases[_tabController.index]['key']!;
        Provider.of<TaskProvider>(context, listen: false).setPhase(phaseKey);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nhiệm vụ 3 Chặng Thực tập'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _phases.map((p) => Tab(text: p['label'])).toList(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppColors.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ chặng: ${(taskProvider.progressPercentage * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${taskProvider.completedCount}/${taskProvider.tasks.length} nhiệm vụ',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: taskProvider.progressPercentage,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Tasks List
            Expanded(
              child: taskProvider.isLoading && taskProvider.tasks.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      itemCount: taskProvider.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = taskProvider.tasks[index];
                        return _buildTaskCard(task, taskProvider);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, TaskProvider provider) {
    Color pillarColor = AppColors.primary;
    String pillarName = 'Tổng quát';

    switch (task.pillar) {
      case 'physical':
        pillarColor = AppColors.pillarPhysical;
        pillarName = 'Thể chất';
        break;
      case 'sleep':
        pillarColor = AppColors.pillarSleep;
        pillarName = 'Giấc ngủ';
        break;
      case 'mental':
        pillarColor = AppColors.pillarMental;
        pillarName = 'Tinh thần';
        break;
      case 'social':
        pillarColor = AppColors.pillarSocial;
        pillarName = 'Giao tiếp';
        break;
      case 'career':
        pillarColor = AppColors.pillarCareer;
        pillarName = 'Nghề nghiệp / 5S';
        break;
    }

    return InkWell(
      onTap: () => provider.toggleTask(task),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isCompleted ? AppColors.secondary.withOpacity(0.4) : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isCompleted,
              activeColor: AppColors.secondary,
              checkColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (_) => provider.toggleTask(task),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pillarColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pillarName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: pillarColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: task.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
