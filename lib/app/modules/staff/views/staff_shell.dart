import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/modules/attendance/views/handover_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/auth/controllers/auth_controller.dart';
import 'package:vamos_ops_mobile/app/modules/home/views/home_screen.dart';
import 'package:vamos_ops_mobile/app/modules/profile/views/me_screen.dart';
import 'package:vamos_ops_mobile/app/modules/reports/views/notifications_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/reports/views/report_detail_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/reports/views/report_form_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/reports/views/report_screen.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/views/create_task_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/views/task_detail_sheet.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/views/task_screen.dart';
import 'package:vamos_ops_mobile/app/widgets/action_feedback.dart';

class StaffShell extends GetView<StaffController> {
  const StaffShell({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    if (!controller.hasLoaded.value) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(
                  image: AssetImage('vamos-logo.png'),
                  width: 210,
                  semanticLabel: 'Vamos Arena Fit',
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.3,
                  ),
                ),
                SizedBox(height: 13),
                Text(
                  'Memuat data operasional',
                  style: TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: AppText.base,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final currentTasks = controller.tasks.toList(growable: false);
    final pages = [
      HomeScreen(
        userName: controller.userName.value,
        userRole: controller.userRole.value,
        isOnline: controller.isOnline.value,
        onDuty: controller.onDuty,
        checkInAt: controller.checkInAt.value,
        checkOutAt: controller.checkOutAt.value,
        tasks: currentTasks,
        completed: controller.completedCount,
        assignedCount: controller.assignedCount.value,
        isBusy: controller.isMutating.value,
        onNotifications: () => showNotificationsSheet(
          context,
          controller.reports.toList(growable: false),
        ),
        onStart: () async {
          final saved = await controller.clockIn();
          if (!context.mounted) return;
          if (saved) {
            _notify(
              context,
              'Clock In berhasil',
              'Lokasi dan selfie tersimpan di database.',
            );
          } else {
            _notifyError(context);
          }
        },
        onTask: (task) => showTaskSheet(
          context,
          task,
          (item, state) => controller.setTaskState(item, state),
          errorMessage: () => controller.errorMessage.value,
          onCaptureEvidence: (taskId, phase, description) =>
              controller.captureTaskEvidence(
                taskId,
                phase: phase,
                description: description,
              ),
        ),
        onReport: () => showReportSheet(context, controller),
        onFinish: () => showHandoverSheet(
          context,
          controller.completedCount,
          controller.assignedCount.value,
          (notes) async {
            final saved = await controller.clockOut(notes: notes);
            return saved
                ? null
                : controller.errorMessage.value ??
                      'Handover gagal disimpan. Coba lagi.';
          },
        ),
      ),
      TaskScreen(
        tasks: controller.taskList.toList(growable: false),
        date: controller.taskDate.value,
        scope: controller.taskScope.value,
        rangeFrom: controller.taskFrom.value,
        rangeTo: controller.taskTo.value,
        onAllDates: () => controller.loadTasks(scope: 'all'),
        onRange: (range) => controller.loadTasks(
          scope: 'range',
          from: range.start,
          to: range.end,
        ),
        today: controller.today.value,
        loading: controller.tasksLoading.value,
        hasMore: controller.tasksHasMore.value,
        error: controller.tasksError.value,
        onDate: (date) => controller.loadTasks(date: date),
        onRefresh: () => controller.loadTasks(refresh: true),
        onMore: () => controller.loadTasks(more: true),
        onCreate: () => showCreateTaskSheet(context, controller),
        onTask: (task) => showTaskSheet(
          context,
          task,
          (item, state) => controller.setTaskState(item, state),
          errorMessage: () => controller.errorMessage.value,
          onCaptureEvidence: (taskId, phase, description) =>
              controller.captureTaskEvidence(
                taskId,
                phase: phase,
                description: description,
              ),
        ),
      ),
      ReportScreen(
        loading: controller.reportsLoading.value,
        hasMore: controller.reportsHasMore.value,
        error: controller.reportsError.value,
        onRefresh: () => controller.loadReports(refresh: true),
        onMore: () => controller.loadReports(more: true),
        reports: controller.reports.toList(growable: false),
        onCreate: () => showReportSheet(context, controller),
        onReport: (report) => showReportDetailSheet(
          context,
          report,
          (item, refresh) => controller.reportDetail(item, refresh: refresh),
        ),
      ),
      MeScreen(
        userName: controller.userName.value,
        userRole: controller.userRole.value,
        venueName: controller.venueName.value,
        isOnline: controller.isOnline.value,
        performance: controller.performance.value,
        onSync: () async {
          await controller.refreshHome();
          if (!context.mounted) return;
          if (controller.isOnline.value) {
            _notify(
              context,
              'Sinkron selesai',
              'Data terbaru berhasil dimuat.',
            );
          } else {
            _notifyError(context);
          }
        },
        onLogout: Get.isRegistered<AuthController>()
            ? () => _confirmLogout(context, Get.find<AuthController>())
            : null,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: controller.selectedTab.value, children: pages),
            if (controller.isLoading.value)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedTab.value,
        onDestinationSelected: (value) => controller.selectedTab.value = value,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  });

  void _notify(BuildContext context, String title, String message) {
    showActionFeedback(context, title, message);
  }

  void _notifyError(BuildContext context) {
    _notify(
      context,
      'Aksi gagal',
      controller.errorMessage.value ?? 'Terjadi kendala. Silakan coba lagi.',
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AuthController authController,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari VAMOS OPS?'),
        content: const Text(
          'Sesi di perangkat ini akan diakhiri. Data yang sudah tersimpan tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
    if (confirmed == true) await authController.logout();
  }
}
