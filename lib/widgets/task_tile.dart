import 'package:flutter/material.dart';
import '../models/recovery_task.dart';
import '../models/wellbeing_score.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final RecoveryTask task;
  final VoidCallback? onToggle;

  const TaskTile({
    super.key,
    required this.task,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final pillarInfo = PillarInfo.registry[task.pillar]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? AppTheme.surfaceColor(context).withValues(alpha: 0.6)
            : AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.isCompleted
              ? AppTheme.accentMint.withValues(alpha: 0.35)
              : AppTheme.borderColor(context),
          width: 1,
        ),
        boxShadow: task.isCompleted
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Checkbox
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? AppTheme.accentMint : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: task.isCompleted ? AppTheme.accentMint : AppTheme.textMuted.withValues(alpha: 0.5),
                        width: 1.8,
                      ),
                      boxShadow: task.isCompleted
                          ? [
                              BoxShadow(
                                color: AppTheme.accentMint.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pillarInfo.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(pillarInfo.icon, size: 11, color: pillarInfo.color),
                                const SizedBox(width: 4),
                                Text(
                                  pillarInfo.title,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: pillarInfo.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (task.durationMinutes > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${task.durationMinutes} phút',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceMuted(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted
                              ? AppTheme.onSurfaceMuted(context)
                              : AppTheme.onSurface(context),
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppTheme.onSurfaceMuted(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: task.isCompleted
                              ? AppTheme.onSurfaceMuted(context).withValues(alpha: 0.5)
                              : AppTheme.onSurfaceSecondary(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
