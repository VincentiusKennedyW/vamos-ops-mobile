import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/modules/attendance/widgets/attendance_card.dart';
import 'package:vamos_ops_mobile/app/modules/home/widgets/quick_actions.dart';
import 'package:vamos_ops_mobile/app/modules/home/widgets/stat_strip.dart';
import 'package:vamos_ops_mobile/app/modules/reports/views/notifications_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/widgets/task_tile.dart';
import 'package:vamos_ops_mobile/app/widgets/section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.isOnline,
    required this.onDuty,
    this.checkInAt,
    this.checkOutAt,
    required this.tasks,
    required this.completed,
    this.assignedCount,
    required this.onStart,
    required this.onTask,
    required this.onReport,
    required this.onFinish,
    this.onNotifications,
    this.isBusy = false,
  });

  final String userName;
  final String userRole;
  final bool isOnline;
  final bool onDuty;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<OpsTask> tasks;
  final int completed;
  final int? assignedCount;
  final VoidCallback onStart;
  final ValueChanged<OpsTask> onTask;
  final VoidCallback onReport;
  final VoidCallback onFinish;
  final VoidCallback? onNotifications;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final next = tasks.isEmpty
        ? null
        : tasks.firstWhere(
            (t) => t.state != TaskState.done,
            orElse: () => tasks.first,
          );
    final attention = tasks
        .where((t) => t.kind != TaskKind.routine && t.state != TaskState.done)
        .toList(growable: false);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.onSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 21,
                        fontFamily: AppText.displayFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat pagi, ${userName.split(' ').first}',
                        style: const TextStyle(
                          fontSize: AppText.xl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$userRole · ${isOnline ? 'Online' : 'Offline'}',
                        style: const TextStyle(
                          color: AppColors.onSurfaceMuted,
                          fontSize: AppText.base,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: InkWell(
                        onTap:
                            onNotifications ??
                            () => showNotificationsSheet(context, const []),
                        borderRadius: BorderRadius.circular(13),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.notifications_none_rounded),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 9,
                      top: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          sliver: SliverList.list(
            children: [
              AttendanceCard(
                onDuty: onDuty,
                checkInAt: checkInAt,
                checkOutAt: checkOutAt,
                completed: completed,
                total: assignedCount ?? tasks.length,
                onStart: onStart,
                isBusy: isBusy,
              ),
              if (onDuty) ...[
                const SizedBox(height: AppSpace.lg),
                // Figures first: how much work is left, before the list of it.
                StatStrip(
                  total: assignedCount ?? tasks.length,
                  completed: completed,
                  needsPhoto: attention.where((t) => t.photoRequired).length,
                ),
                const SizedBox(height: AppSpace.xxl),
                const SectionTitle(
                  title: 'Berikutnya',
                  caption: 'Prioritas saat ini',
                ),
                const SizedBox(height: AppSpace.md),
                if (next != null)
                  TaskTile(
                    task: next,
                    featured: true,
                    onTap: () => onTask(next),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpace.xl),
                      child: Text('Belum ada task untuk hari ini.'),
                    ),
                  ),
                const SizedBox(height: AppSpace.xxl),
                SectionTitle(
                  title: 'Butuh perhatian',
                  caption: 'Dari Manager & task sebelumnya',
                  count: attention.length,
                ),
                const SizedBox(height: AppSpace.md),
                if (attention.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.successText,
                        ),
                        SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            'Tidak ada task tambahan. Semua sudah tertangani.',
                            style: TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontSize: AppText.base,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...attention.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.md),
                      child: TaskTile(task: task, onTap: () => onTask(task)),
                    ),
                  ),
                const SizedBox(height: AppSpace.xxl),
                const SectionTitle(
                  title: 'Aksi cepat',
                  caption: 'Lapor temuan atau Clock Out',
                ),
                const SizedBox(height: AppSpace.md),
                QuickActions(onReport: onReport, onFinish: onFinish),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
