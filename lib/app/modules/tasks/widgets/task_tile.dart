import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/core/utils/date_time_labels.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    this.featured = false,
    this.showDate = false,
  });
  final OpsTask task;
  final VoidCallback onTap;
  final bool featured, showDate;

  @override
  Widget build(BuildContext context) {
    final kindColor = task.kind == TaskKind.manager
        ? AppColors.danger
        : task.kind == TaskKind.issue
        ? AppColors.accent
        : task.kind == TaskKind.handover
        ? AppColors.warning
        : AppColors.primary;
    return Card(
      color: featured ? AppColors.primarySubtle : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  task.state == TaskState.done
                      ? Icons.check_rounded
                      : task.kind == TaskKind.manager
                      ? Icons.bolt_rounded
                      : task.kind == TaskKind.handover
                      ? Icons.sync_alt_rounded
                      : Icons.task_alt_rounded,
                  color: kindColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          kindLabel(task.kind),
                          style: TextStyle(
                            color: kindColor,
                            fontSize: AppText.xs,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (task.photoRequired) ...[
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.photo_camera_outlined,
                            size: 12,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (showDate && task.scheduledAt != null)
                      Text(
                        'Rencana: ${dateTimeLabel(task.scheduledAt!)}',
                        style: const TextStyle(
                          color: AppColors.onSurfaceMuted,
                          fontSize: AppText.xs,
                        ),
                      ),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: AppText.base,
                        fontWeight: FontWeight.w700,
                        decoration: task.state == TaskState.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.state == TaskState.inProgress &&
                              task.startedAt != null
                          ? 'ONGOING · Start ${dateTimeLabel(task.startedAt!)}'
                          : '${task.time}  ·  ${task.area}',
                      style: const TextStyle(
                        color: AppColors.onSurfaceMuted,
                        fontSize: AppText.xs,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
