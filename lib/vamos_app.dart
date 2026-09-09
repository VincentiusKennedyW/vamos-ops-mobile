import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/theme/app_tokens.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/modules/auth/views/login_screen.dart';
import 'app/modules/auth/views/splash_screen.dart';
import 'app/modules/staff/bindings/staff_binding.dart';
import 'app/modules/staff/controllers/staff_controller.dart';
import 'app/routes/app_routes.dart';
import 'data.dart';
import 'app/core/config/app_config.dart';
import 'app/core/storage/session_store.dart';

export 'app/core/theme/app_tokens.dart';

// Legacy names kept so existing screens keep compiling; each one now points at
// the shared token layer in app/core/theme/app_tokens.dart. `muted` was
// #77808C (4.0:1 on white) and now clears WCAG AA.
const ink = AppColors.onSurface;
const vamosGreen = AppColors.primary;
const canvas = AppColors.surfaceSunken;
const muted = AppColors.onSurfaceMuted;
const line = AppColors.border;
const paleGreen = AppColors.primarySubtle;
const warning = AppColors.warning;
const danger = AppColors.danger;

String _clockLabel(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _dateTimeLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${_clockLabel(local)}';
}

String _durationLabel(DateTime start, DateTime end) {
  final minutes = end.difference(start).inMinutes;
  if (minutes < 60) return '$minutes menit';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours jam' : '$hours jam $remainder menit';
}

class VamosApp extends StatelessWidget {
  const VamosApp({super.key, this.initialBinding, this.initialRoute});

  final Bindings? initialBinding;
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VAMOS OPS',
      debugShowCheckedModeBanner: false,
      theme: buildVamosTheme(),
      initialBinding: initialBinding ?? AppBinding(),
      initialRoute: initialRoute ?? AppRoutes.splash,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 320),
      getPages: [
        GetPage<dynamic>(
          name: AppRoutes.splash,
          page: SplashScreen.new,
          transition: Transition.noTransition,
        ),
        GetPage<dynamic>(
          name: AppRoutes.login,
          page: LoginScreen.new,
          transition: Transition.fadeIn,
        ),
        GetPage<dynamic>(
          name: AppRoutes.staff,
          page: StaffShell.new,
          binding: StaffBinding(),
          transition: Transition.fadeIn,
        ),
      ],
    );
  }
}

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
                    color: vamosGreen,
                    strokeWidth: 2.3,
                  ),
                ),
                SizedBox(height: 13),
                Text(
                  'Memuat data operasional',
                  style: TextStyle(color: muted, fontSize: AppText.base),
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

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontFamily: AppText.displayFamily,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: AppText.base),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

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
                    color: ink,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        color: vamosGreen,
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
                          color: muted,
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
                        side: const BorderSide(color: line),
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
                          color: danger,
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
              _AttendanceCard(
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
                _StatStrip(
                  total: assignedCount ?? tasks.length,
                  completed: completed,
                  needsPhoto: attention.where((t) => t.photoRequired).length,
                ),
                const SizedBox(height: AppSpace.xxl),
                const _SectionTitle(
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
                _SectionTitle(
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
                const _SectionTitle(
                  title: 'Aksi cepat',
                  caption: 'Lapor temuan atau Clock Out',
                ),
                const SizedBox(height: AppSpace.md),
                _QuickActions(onReport: onReport, onFinish: onFinish),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.onDuty,
    required this.checkInAt,
    required this.checkOutAt,
    required this.completed,
    required this.total,
    required this.onStart,
    required this.isBusy,
  });
  final bool onDuty;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int completed;
  final int total;
  final VoidCallback onStart;
  final bool isBusy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 25,
          offset: Offset(0, 13),
        ),
      ],
    ),
    child: checkOutAt != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CLOCK OUT SELESAI',
                style: TextStyle(
                  color: vamosGreen,
                  fontSize: AppText.sm,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Absensi hari ini lengkap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontFamily: AppText.displayFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Clock In ${_clockLabel(checkInAt)}  ·  Clock Out ${_clockLabel(checkOutAt)}',
                style: const TextStyle(
                  color: AppColors.onInverseMuted,
                  fontSize: AppText.base,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Task dikunci setelah Clock Out.',
                style: TextStyle(
                  color: AppColors.onInverseMuted,
                  fontSize: AppText.sm,
                ),
              ),
            ],
          )
        : onDuty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: vamosGreen,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: vamosGreen, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ON DUTY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppText.base,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Clock In ${_clockLabel(checkInAt)}',
                    style: const TextStyle(
                      color: AppColors.onInverseMuted,
                      fontSize: AppText.sm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppText.heroLg,
                      fontFamily: AppText.displayFamily,
                      height: 0.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ' / $total task selesai',
                    style: const TextStyle(
                      color: AppColors.onInverseMuted,
                      fontSize: AppText.base,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${total == 0 ? 0 : (completed / total * 100).round()}%',
                    style: const TextStyle(
                      color: vamosGreen,
                      fontSize: AppText.lg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceInverseRaised,
                  color: vamosGreen,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.onInverseSubtle,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Di dalam geofence · akurasi 8 m',
                    style: TextStyle(
                      color: AppColors.onInverseSubtle,
                      fontSize: AppText.xs,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CLOCK IN HARI INI',
                style: TextStyle(
                  color: vamosGreen,
                  fontSize: AppText.sm,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Siap mulai bekerja?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontFamily: AppText.displayFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lokasi Anda terdeteksi di Vamos Arena Fit.',
                style: TextStyle(
                  color: AppColors.onInverseMuted,
                  fontSize: AppText.base,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isBusy ? null : onStart,
                icon: isBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isBusy ? 'MEMPROSES…' : 'CLOCK IN'),
              ),
            ],
          ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.caption, this.count});
  final String title;
  final String caption;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppText.xl,
                    fontFamily: AppText.displayFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppText.xs,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(color: muted, fontSize: AppText.base),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Compact figure strip under the shift card. Three read-only stats that answer
/// "how much is left today" without opening the Task tab.
class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.total,
    required this.completed,
    required this.needsPhoto,
  });
  final int total;
  final int completed;
  final int needsPhoto;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label, IconData icon, Color tone) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: tone),
                const SizedBox(height: AppSpace.sm),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppText.xxl,
                    fontFamily: AppText.displayFamily,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: AppText.sm,
                  ),
                ),
              ],
            ),
          ),
        );
    return Row(
      children: [
        tile(
          '$total',
          'Task hari ini',
          Icons.task_alt_rounded,
          AppColors.onSurfaceMuted,
        ),
        const SizedBox(width: AppSpace.md),
        tile(
          '$completed',
          'Selesai',
          Icons.check_circle_outline_rounded,
          AppColors.successText,
        ),
        const SizedBox(width: AppSpace.md),
        tile(
          '$needsPhoto',
          'Perlu bukti',
          Icons.photo_camera_outlined,
          AppColors.warningText,
        ),
      ],
    );
  }
}

/// Two-up action grid. Replaces the single full-width outlined button plus the
/// low-contrast text link that previously hid Clock Out at the very bottom;
/// destructive/shift-ending actions stay visually separated (HIG).
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onReport, required this.onFinish});
  final VoidCallback onReport;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    Widget action({
      required IconData icon,
      required String label,
      required String caption,
      required VoidCallback onTap,
      required Color tone,
      required Color background,
    }) => Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 19, color: tone),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: AppText.md,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: const TextStyle(
                        color: AppColors.onSurfaceMuted,
                        fontSize: AppText.sm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // IntrinsicHeight so both tiles match the taller one. A bare
    // CrossAxisAlignment.stretch would ask for infinite height inside the
    // unbounded sliver list and blow up layout.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          action(
            icon: Icons.flag_outlined,
            label: 'Lapor temuan',
            caption: 'Kerusakan atau stok',
            onTap: onReport,
            tone: AppColors.warningText,
            background: AppColors.warningSubtle,
          ),
          const SizedBox(width: AppSpace.md),
          action(
            icon: Icons.logout_rounded,
            label: 'Clock Out',
            caption: 'Catat Clock Out hari ini',
            onTap: onFinish,
            tone: AppColors.dangerText,
            background: AppColors.dangerSubtle,
          ),
        ],
      ),
    );
  }
}

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
        ? danger
        : task.kind == TaskKind.issue
        ? AppColors.accent
        : task.kind == TaskKind.handover
        ? warning
        : vamosGreen;
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
                            color: muted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (showDate && task.scheduledAt != null)
                      Text(
                        'Rencana: ${_dateTimeLabel(task.scheduledAt!)}',
                        style: const TextStyle(
                          color: muted,
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
                          ? 'ONGOING · Start ${_dateTimeLabel(task.startedAt!)}'
                          : '${task.time}  ·  ${task.area}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: AppText.xs,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({
    super.key,
    required this.tasks,
    required this.onTask,
    required this.onCreate,
    this.date,
    this.today,
    this.loading = false,
    this.hasMore = false,
    this.error,
    this.onDate,
    this.scope = 'day',
    this.rangeFrom,
    this.rangeTo,
    this.onRange,
    this.onAllDates,
    this.onRefresh,
    this.onMore,
  });
  final List<OpsTask> tasks;
  final ValueChanged<OpsTask> onTask;
  final VoidCallback onCreate;
  final DateTime? date, today, rangeFrom, rangeTo;
  final String scope;
  final ValueChanged<DateTimeRange>? onRange;
  final VoidCallback? onAllDates;
  final bool loading, hasMore;
  final String? error;
  final ValueChanged<DateTime>? onDate;
  final Future<void> Function()? onRefresh, onMore;
  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final date = widget.date ?? DateTime.now();
    final today = widget.today ?? DateTime.now();
    final shown = widget.tasks
        .where(
          (t) =>
              filter == 'all' ||
              (filter == 'done'
                  ? t.state == TaskState.done
                  : t.state != TaskState.done),
        )
        .toList();
    return Column(
      children: [
        ScreenHeader(
          title: widget.scope == 'all'
              ? 'Semua task'
              : widget.scope == 'range'
              ? 'Task rentang waktu'
              : DateUtils.isSameDay(date, today)
              ? 'Task hari ini'
              : 'Riwayat task',
          subtitle: 'Task pribadi dan assignment crew',
          action: IconButton.filled(
            key: const Key('create-task-button'),
            tooltip: 'Tambah task',
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('task-date-picker'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(today.year + 5, 12, 31),
                    );
                    if (picked != null) widget.onDate?.call(picked);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    MaterialLocalizations.of(context).formatMediumDate(date),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onDate?.call(today),
                child: const Text('Hari ini'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Semua waktu'),
                selected: widget.scope == 'all',
                onSelected: (_) => widget.onAllDates?.call(),
              ),
              ChoiceChip(
                label: const Text('Rentang tanggal'),
                selected: widget.scope == 'range',
                onSelected: (_) async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(today.year + 5, 12, 31),
                    initialDateRange:
                        widget.rangeFrom != null && widget.rangeTo != null
                        ? DateTimeRange(
                            start: widget.rangeFrom!,
                            end: widget.rangeTo!,
                          )
                        : null,
                  );
                  if (range != null) widget.onRange?.call(range);
                },
              ),
            ],
          ),
        ),
        if (widget.scope == 'range' &&
            widget.rangeFrom != null &&
            widget.rangeTo != null)
          Text(
            '${MaterialLocalizations.of(context).formatMediumDate(widget.rangeFrom!)} – ${MaterialLocalizations.of(context).formatMediumDate(widget.rangeTo!)}',
            style: const TextStyle(color: muted),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: {'all': 'Semua', 'pending': 'Pending', 'done': 'Selesai'}
                .entries
                .map(
                  (item) => ChoiceChip(
                    label: Text(item.value),
                    selected: filter == item.key,
                    onSelected: (_) {
                      setState(() => filter = item.key);
                    },
                  ),
                )
                .toList(),
          ),
        ),
        if (widget.loading && shown.isEmpty) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            child: ListView.builder(
              key: ValueKey(
                'tasks-${widget.scope}-${widget.rangeFrom}-${widget.rangeTo}-${date.toIso8601String()}-$filter',
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              itemCount: shown.length + 1,
              itemBuilder: (context, index) {
                if (index == shown.length) {
                  return _PageFooter(
                    loading: widget.loading,
                    hasMore: widget.hasMore,
                    error: widget.error,
                    empty: shown.isEmpty,
                    emptyText: 'Belum ada task pada tanggal dan filter ini.',
                    onMore: widget.onMore,
                    onRetry: () => widget.onRefresh?.call(),
                  );
                }
                final task = shown[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskTile(
                    task: task,
                    showDate: widget.scope != 'day',
                    onTap: () => widget.onTask(task),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.loading,
    required this.hasMore,
    required this.empty,
    required this.emptyText,
    this.error,
    this.onMore,
    this.onRetry,
  });
  final bool loading, hasMore, empty;
  final String emptyText;
  final String? error;
  final VoidCallback? onMore, onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        if (error != null) ...[
          Text(error!, style: const TextStyle(color: danger)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ] else if (loading)
          const Center(child: CircularProgressIndicator())
        else if (empty)
          Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
        if (hasMore && error == null)
          OutlinedButton(
            onPressed: loading ? null : onMore,
            child: const Text('Muat lebih banyak'),
          ),
      ],
    ),
  );
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({
    super.key,
    required this.reports,
    required this.onCreate,
    required this.onReport,
    this.loading = false,
    this.hasMore = false,
    this.error,
    this.onRefresh,
    this.onMore,
  });
  final List<OpsReport> reports;
  final VoidCallback onCreate;
  final ValueChanged<OpsReport> onReport;
  final bool loading, hasMore;
  final String? error;
  final Future<void> Function()? onRefresh, onMore;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenHeader(
        title: 'Report',
        subtitle: 'Temuan & info operasional Anda',
        action: IconButton.filled(
          tooltip: 'Tambah report',
          onPressed: onCreate,
          icon: const Icon(Icons.add),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: onRefresh ?? () async {},
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            itemCount: reports.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('LAPOR / TEMUAN BARU'),
                  ),
                );
              }
              if (index == reports.length + 1) {
                return _PageFooter(
                  loading: loading,
                  hasMore: hasMore,
                  error: error,
                  empty: reports.isEmpty,
                  emptyText: 'Belum ada report.',
                  onMore: onMore,
                  onRetry: () => onRefresh?.call(),
                );
              }
              final report = reports[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportTile(
                  onTap: () => onReport(report),
                  title: report.title,
                  category: _categoryLabel(report.category),
                  area: report.area,
                  time: _relativeTime(report.createdAt),
                  status: report.status.replaceAll('_', ' '),
                  color: report.status == 'DONE'
                      ? vamosGreen
                      : report.status == 'FOLLOW_UP'
                      ? warning
                      : danger,
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
  static String _categoryLabel(String value) => switch (value) {
    'DAMAGE' => 'KERUSAKAN',
    'STOCK' => 'STOK / BARANG',
    'OPERATIONAL' => 'OPERASIONAL',
    _ => 'INFO / USULAN',
  };
  static String _relativeTime(DateTime value) {
    final minutes = DateTime.now().difference(value.toLocal()).inMinutes;
    if (minutes < 60) return '${minutes.clamp(1, 59)} menit lalu';
    if (minutes < 1440) return '${minutes ~/ 60} jam lalu';
    return '${minutes ~/ 1440} hari lalu';
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.title,
    required this.category,
    required this.area,
    required this.time,
    required this.status,
    required this.color,
    required this.onTap,
  });
  final String title, category, area, time, status;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: color,
                    fontSize: AppText.xs,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: AppText.xs,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: muted),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppText.md,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '$area  ·  $time',
              style: const TextStyle(color: muted, fontSize: AppText.xs),
            ),
          ],
        ),
      ),
    ),
  );
}

typedef ReportDetailLoader =
    Future<OpsReport> Function(OpsReport report, bool refresh);

void showReportDetailSheet(
  BuildContext context,
  OpsReport report,
  ReportDetailLoader load,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportDetailSheet(report: report, load: load),
  );
}

class _ReportDetailSheet extends StatefulWidget {
  const _ReportDetailSheet({required this.report, required this.load});
  final OpsReport report;
  final ReportDetailLoader load;

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  late OpsReport report;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    report = widget.report;
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final detail = await widget.load(report, refresh);
      if (mounted) setState(() => report = detail);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Detail report gagal dimuat. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = report.status == 'DONE'
        ? vamosGreen
        : report.status == 'FOLLOW_UP'
        ? warning
        : danger;
    final evidenceCount = report.evidence.isNotEmpty
        ? report.evidence.length
        : report.evidenceCount;
    return Container(
      key: const Key('report-detail-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _DetailPill(
                  label: ReportScreen._categoryLabel(report.category),
                  color: statusColor,
                ),
                const Spacer(),
                _DetailPill(
                  label: report.status.replaceAll('_', ' '),
                  color: statusColor,
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.title,
              style: const TextStyle(
                fontFamily: AppText.displayFamily,
                fontSize: AppText.xl,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (report.number.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(report.number, style: const TextStyle(color: muted)),
            ],
            const SizedBox(height: 18),
            Text(
              report.description.isEmpty
                  ? 'Tidak ada deskripsi tambahan.'
                  : report.description,
              style: const TextStyle(fontSize: AppText.base, height: 1.5),
            ),
            const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ReportFact(label: 'Area', value: report.area),
                    const Divider(height: 24),
                    _ReportFact(
                      label: 'Prioritas',
                      value: report.priority.replaceAll('_', ' '),
                    ),
                    const Divider(height: 24),
                    _ReportFact(
                      label: 'Dilaporkan',
                      value: _dateTimeLabel(report.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            if (loading) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(),
            ],
            if (error != null) ...[
              const SizedBox(height: 18),
              Text(error!, style: const TextStyle(color: danger)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _load(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Bukti foto ($evidenceCount)',
              style: const TextStyle(
                fontSize: AppText.md,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (!loading && report.evidence.isEmpty)
              const Text(
                'Report ini belum memiliki unggahan foto.',
                style: TextStyle(color: muted),
              ),
            ...report.evidence.indexed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 10,
                        child: _EvidencePhoto(id: entry.$2.id),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          entry.$2.fileName.isEmpty
                              ? 'Foto ${entry.$1 + 1} · ${_dateTimeLabel(entry.$2.createdAt)}'
                              : '${entry.$2.fileName} · ${_dateTimeLabel(entry.$2.createdAt)}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: AppText.xs,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: AppText.xs,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ReportFact extends StatelessWidget {
  const _ReportFact({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 96,
        child: Text(label, style: const TextStyle(color: muted)),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

class MeScreen extends StatelessWidget {
  const MeScreen({
    super.key,
    this.userName = 'Andi Saputra',
    this.userRole = 'Crew Padel',
    this.venueName = '',
    this.isOnline = true,
    this.performance = const StaffPerformance(),
    this.onSettings,
    this.onSync,
    this.onLogout,
  });

  final String userName;
  final String userRole;
  final String venueName;
  final bool isOnline;
  final StaffPerformance performance;
  final VoidCallback? onSettings;
  final VoidCallback? onSync;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
    children: [
      Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                userName
                    .split(' ')
                    .where((part) => part.isNotEmpty)
                    .map((part) => part[0])
                    .take(2)
                    .join(),
                style: const TextStyle(
                  color: vamosGreen,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  venueName.isEmpty ? userRole : '$userRole · $venueName',
                  style: const TextStyle(color: muted, fontSize: AppText.base),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan aplikasi',
            onPressed:
                onSettings ?? () => showAppSettingsSheet(context, isOnline),
            icon: const Icon(Icons.settings_outlined, color: muted),
          ),
        ],
      ),
      const SizedBox(height: 26),
      _SectionTitle(
        title: 'Riwayat kerja',
        caption: _monthLabel(DateTime.now()),
      ),
      const SizedBox(height: 10),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                value: '${performance.attendanceDays}',
                label: 'Hari hadir',
              ),
              Container(width: 1, height: 38, color: line),
              _Stat(
                value: '${performance.taskCompletionRate}%',
                label: 'Task tuntas',
              ),
              Container(width: 1, height: 38, color: line),
              _Stat(
                value: '${performance.completedTasks}',
                label: 'Task selesai',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          onTap:
              onSync ??
              () => showActionMessage(
                context,
                'Sinkronisasi dijalankan dari halaman utama aplikasi.',
              ),
          leading: Icon(
            isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: isOnline ? vamosGreen : warning,
          ),
          title: Text(
            isOnline ? 'Semua data tersinkron' : 'Perlu sinkron ulang',
            style: const TextStyle(
              fontSize: AppText.base,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: const Text(
            'Ketuk untuk mengambil data terbaru',
            style: TextStyle(fontSize: AppText.xs),
          ),
          trailing: const Icon(Icons.refresh_rounded),
        ),
      ),
      if (onLogout != null) ...[
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('logout-button'),
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('KELUAR DARI VAMOS OPS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: danger,
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: danger.withValues(alpha: 0.32)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    ],
  );

  static String _monthLabel(DateTime value) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }
}

void showActionMessage(BuildContext context, String message) {
  showActionFeedback(context, 'Informasi', message);
}

void showActionFeedback(BuildContext context, String title, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(message),
        ],
      ),
    ),
  );
}

void showNotificationsSheet(BuildContext context, List<OpsReport> reports) {
  final active = reports.where((report) => report.status != 'DONE').toList();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(
                fontSize: 21,
                fontFamily: AppText.displayFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              active.isEmpty
                  ? 'Tidak ada notifikasi baru.'
                  : '${active.length} report masih memerlukan tindak lanjut.',
              style: const TextStyle(color: muted, fontSize: AppText.base),
            ),
            const SizedBox(height: 16),
            if (active.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.notifications_none_rounded),
                title: Text('Semua beres'),
              )
            else
              ...active
                  .take(4)
                  .map(
                    (report) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined, color: warning),
                      title: Text(report.title),
                      subtitle: Text('${report.area} · ${report.status}'),
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}

void showAppSettingsSheet(BuildContext context, bool isOnline) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan aplikasi',
              style: TextStyle(
                fontSize: 21,
                fontFamily: AppText.displayFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: isOnline ? vamosGreen : warning,
              ),
              title: const Text('Koneksi VAMOS API'),
              subtitle: Text(isOnline ? 'Terhubung' : 'Tidak terhubung'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Akun demo'),
              subtitle: Text('Penggantian akun tersedia setelah auth aktif.'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: AppText.xl,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(color: muted, fontSize: AppText.xs),
      ),
    ],
  );
}

typedef TaskUpdateCallback =
    Future<bool> Function(OpsTask task, TaskState state);

typedef ErrorMessageProvider = String? Function();
typedef EvidenceCaptureCallback =
    Future<String?> Function(String taskId, String phase, String description);

void showTaskSheet(
  BuildContext context,
  OpsTask task,
  TaskUpdateCallback onUpdate, {
  ErrorMessageProvider? errorMessage,
  EvidenceCaptureCallback? onCaptureEvidence,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskSheet(
      task: task,
      onUpdate: onUpdate,
      errorMessage: errorMessage,
      onCaptureEvidence: onCaptureEvidence,
    ),
  );
}

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({
    required this.task,
    required this.onUpdate,
    this.errorMessage,
    this.onCaptureEvidence,
  });
  final OpsTask task;
  final TaskUpdateCallback onUpdate;
  final ErrorMessageProvider? errorMessage;
  final EvidenceCaptureCallback? onCaptureEvidence;
  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  bool saving = false;
  bool capturing = false;
  String? actionError;
  String? capturedPhotoPath;
  final evidenceDescriptionController = TextEditingController();
  late OpsTask task;
  bool detailLoading = false;
  @override
  void initState() {
    super.initState();
    task = widget.task;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!Get.isRegistered<StaffController>()) return;
    setState(() => detailLoading = true);
    try {
      final fresh = await Get.find<StaffController>().taskDetail(task);
      if (mounted) setState(() => task = fresh);
    } catch (_) {
      if (mounted) {
        setState(
          () => actionError =
              'Detail terbaru gagal dimuat. Tutup dan buka kembali untuk mencoba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => detailLoading = false);
    }
  }

  @override
  void dispose() {
    evidenceDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capturePhase = task.state == TaskState.pending ? 'BEFORE' : 'AFTER';
    final requiresPhoto = task.state == TaskState.pending
        ? task.evidencePolicy == 'before_after'
        : task.state == TaskState.inProgress &&
              (task.evidencePolicy == 'after' ||
                  task.evidencePolicy == 'before_after');
    final phaseEvidenceCount = capturePhase == 'BEFORE'
        ? task.beforeEvidenceCount
        : task.afterEvidenceCount;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            26 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: paleGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    kindLabel(task.kind),
                    style: const TextStyle(
                      color: AppColors.successText,
                      fontSize: AppText.xs,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Tutup detail task',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 23,
                fontFamily: AppText.displayFamily,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${task.time}  ·  ${task.area}',
              style: const TextStyle(color: muted, fontSize: AppText.base),
            ),
            if (task.scheduledAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Waktu Start (rencana) ${_dateTimeLabel(task.scheduledAt!)}${task.dueAt != null ? ' · Deadline ${_dateTimeLabel(task.dueAt!)} · Lead time ${_durationLabel(task.scheduledAt!, task.dueAt!)}' : ''}',
                  style: const TextStyle(
                    color: muted,
                    fontSize: AppText.sm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (task.startedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Start aktual ${_dateTimeLabel(task.startedAt!)}${task.completedAt == null ? ' · sedang berjalan' : ' · End ${_dateTimeLabel(task.completedAt!)}'}',
                  style: const TextStyle(
                    color: warning,
                    fontSize: AppText.sm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (task.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  task.note,
                  style: const TextStyle(
                    color: muted,
                    height: 1.5,
                    fontSize: AppText.base,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            if (detailLoading) const LinearProgressIndicator(),
            if (task.evidence.isNotEmpty) ...[
              const _SectionTitle(
                title: 'Bukti foto',
                caption: 'Ketuk foto untuk memperbesar',
              ),
              const SizedBox(height: 12),
              ...task.evidence.map(
                (item) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${item.phase == "BEFORE" ? "Sebelum" : "Sesudah"} · ${_dateTimeLabel(item.createdAt)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (context) => Dialog(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      tooltip: 'Tutup foto',
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.sizeOf(context).height * .6,
                                    child: InteractiveViewer(
                                      child: _EvidencePhoto(
                                        id: item.id,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: SizedBox(
                            height: 180,
                            child: _EvidencePhoto(id: item.id),
                          ),
                        ),
                        if (item.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(item.description),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (requiresPhoto)
              Card(
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('task-evidence-description'),
                        controller: evidenceDescriptionController,
                        enabled: !saving && !capturing,
                        minLines: 2,
                        maxLines: 3,
                        maxLength: 500,
                        onChanged: (_) {
                          if (actionError != null) {
                            setState(() => actionError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Deskripsi foto (opsional)',
                          hintText: capturePhase == 'BEFORE'
                              ? 'Jelaskan kondisi sebelum task dikerjakan'
                              : 'Jelaskan hasil atau kondisi setelah task',
                          helperText: 'Boleh dikosongkan',
                          prefixIcon: const Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: saving || capturing ? null : _captureEvidence,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (capturedPhotoPath != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(capturedPhotoPath!),
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                          height: 90,
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: muted,
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  Icon(
                                    capturedPhotoPath != null ||
                                            phaseEvidenceCount > 0
                                        ? Icons.check_circle_rounded
                                        : Icons.camera_alt_outlined,
                                    color:
                                        capturedPhotoPath != null ||
                                            phaseEvidenceCount > 0
                                        ? vamosGreen
                                        : ink,
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Text(
                                      capturing
                                          ? 'Mengunggah foto…'
                                          : capturedPhotoPath != null ||
                                                phaseEvidenceCount > 0
                                          ? 'Foto evidence tersimpan · ketuk untuk tambah'
                                          : 'Ambil foto ${capturePhase.toLowerCase()} untuk task ini',
                                      style: const TextStyle(
                                        fontSize: AppText.sm,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (capturing)
                                    const SizedBox.square(
                                      dimension: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      capturedPhotoPath != null ||
                                              phaseEvidenceCount > 0
                                          ? Icons.refresh_rounded
                                          : Icons.add_circle,
                                      color: vamosGreen,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (actionError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  actionError!,
                  key: const Key('task-action-error'),
                  style: const TextStyle(
                    color: danger,
                    fontSize: AppText.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            if (task.state != TaskState.done)
              FilledButton.icon(
                onPressed: saving || capturing || detailLoading
                    ? null
                    : () => _save(
                        task.state == TaskState.pending
                            ? TaskState.inProgress
                            : TaskState.done,
                        successMessage: task.state == TaskState.pending
                            ? 'Task dimulai dan waktu Start tercatat.'
                            : 'Task selesai dan waktu End tercatat.',
                      ),
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        task.state == TaskState.pending
                            ? Icons.play_arrow_rounded
                            : Icons.stop_rounded,
                      ),
                label: Text(
                  saving
                      ? 'MENYIMPAN…'
                      : task.state == TaskState.pending
                      ? 'START TASK'
                      : 'END TASK',
                ),
              )
            else
              FilledButton.icon(
                onPressed: null,
                icon: Icon(Icons.check_circle_rounded),
                label: Text('TASK SELESAI'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureEvidence() async {
    final description = evidenceDescriptionController.text.trim();
    if (widget.onCaptureEvidence == null) {
      showActionMessage(context, 'Kamera tidak tersedia pada sesi ini.');
      return;
    }
    setState(() {
      capturing = true;
      actionError = null;
    });
    final phase = task.state == TaskState.pending ? 'BEFORE' : 'AFTER';
    final path = await widget.onCaptureEvidence!(task.id, phase, description);
    if (!mounted) return;
    setState(() {
      capturing = false;
      if (path != null) {
        capturedPhotoPath = path;
      } else {
        actionError = widget.errorMessage?.call();
      }
    });
    if (path != null) {
      showActionFeedback(
        context,
        'Foto tersimpan',
        'Evidence berhasil diunggah dan ditautkan ke task.',
      );
    }
  }

  Future<void> _save(TaskState state, {required String successMessage}) async {
    if (state == TaskState.inProgress &&
        task.evidencePolicy == 'before_after' &&
        task.beforeEvidenceCount == 0 &&
        capturedPhotoPath == null) {
      setState(() {
        actionError = 'Ambil dan unggah foto before sebelum memulai task.';
      });
      return;
    }
    if (state == TaskState.done &&
        (task.evidencePolicy == 'after' ||
            task.evidencePolicy == 'before_after') &&
        task.afterEvidenceCount == 0 &&
        capturedPhotoPath == null) {
      setState(() {
        actionError = 'Ambil dan unggah foto after sebelum menyelesaikan task.';
      });
      return;
    }
    setState(() {
      saving = true;
      actionError = null;
    });
    final saved = await widget.onUpdate(task, state);
    if (!mounted) return;
    if (!saved) {
      setState(() {
        saving = false;
        actionError =
            widget.errorMessage?.call() ?? 'Task gagal disimpan. Coba lagi.';
      });
      return;
    }
    showActionFeedback(context, 'Berhasil', successMessage);
    Navigator.pop(context);
  }
}

void showCreateTaskSheet(BuildContext context, StaffController controller) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateTaskSheet(controller: controller),
  );
}

class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet({required this.controller});
  final StaffController controller;

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String priority = 'NORMAL';
  String evidencePolicy = 'none';
  late DateTime scheduledAt;
  late DateTime dueAt;
  bool saving = false;
  String? formError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    scheduledAt = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    dueAt = scheduledAt.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      decoration: const BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Tambah task pribadi',
              style: TextStyle(
                fontSize: 23,
                fontFamily: AppText.displayFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Task dibuat untuk akun Anda dan langsung tersinkron ke dashboard manager.',
              style: TextStyle(color: muted, fontSize: AppText.sm),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('create-task-title'),
              controller: titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (formError != null) setState(() => formError = null);
              },
              decoration: const InputDecoration(
                labelText: 'Nama pekerjaan',
                hintText: 'Contoh: Cek stok handuk',
              ),
            ),
            const SizedBox(height: 11),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(
              initialValue: priority,
              items:
                  const {
                        'LOW': 'Rendah',
                        'NORMAL': 'Normal',
                        'MEDIUM': 'Sedang',
                        'HIGH': 'Tinggi',
                      }.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) => priority = value ?? priority,
              decoration: const InputDecoration(labelText: 'Prioritas'),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('create-task-start-time'),
                    onPressed: saving ? null : _pickScheduledAt,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text('Start ${_dateTimeLabel(scheduledAt)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('create-task-due-time'),
                    onPressed: saving ? null : _pickDueAt,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('Deadline ${_dateTimeLabel(dueAt)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(
              initialValue: evidencePolicy,
              items:
                  const {
                        'none': 'Tanpa foto wajib',
                        'after': 'Foto selesai wajib',
                        'before_after': 'Foto before & after wajib',
                      }.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) =>
                  setState(() => evidencePolicy = value ?? evidencePolicy),
              decoration: InputDecoration(
                labelText: 'Bukti kerja',
                helperMaxLines: 3,
                helperText: evidencePolicy == 'none'
                    ? 'Task dapat diselesaikan tanpa foto.'
                    : evidencePolicy == 'after'
                    ? 'Unggah foto setelah bekerja, sebelum End Task.'
                    : 'Unggah foto sebelum Start Task dan setelah bekerja, sebelum End Task.',
              ),
            ),
            if (formError != null) ...[
              const SizedBox(height: 10),
              Text(
                formError!,
                style: const TextStyle(
                  color: danger,
                  fontSize: AppText.base,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('submit-created-task'),
              onPressed: saving ? null : _submit,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task_rounded),
              label: Text(saving ? 'MENYIMPAN…' : 'TAMBAH TASK'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickScheduledAt() async {
    final selected = await _pickDateTime(scheduledAt);
    if (selected != null && mounted) {
      setState(() {
        scheduledAt = selected;
        if (!dueAt.isAfter(scheduledAt)) {
          dueAt = scheduledAt.add(const Duration(hours: 1));
        }
        formError = null;
      });
    }
  }

  Future<void> _pickDueAt() async {
    final selected = await _pickDateTime(dueAt);
    if (selected != null && mounted) {
      setState(() {
        dueAt = selected;
        formError = dueAt.isAfter(scheduledAt)
            ? null
            : 'Deadline harus setelah Waktu Start.';
      });
    }
  }

  Future<void> _submit() async {
    final title = titleController.text.trim();
    if (title.length < 3) {
      setState(() => formError = 'Nama pekerjaan minimal 3 karakter.');
      return;
    }
    if (!dueAt.isAfter(scheduledAt)) {
      setState(() => formError = 'Deadline harus setelah Waktu Start.');
      return;
    }
    setState(() {
      saving = true;
      formError = null;
    });
    final saved = await widget.controller.createTask(
      title: title,
      description: descriptionController.text.trim(),
      priority: priority,
      evidencePolicy: evidencePolicy,
      scheduledAt: scheduledAt,
      dueAt: dueAt,
    );
    if (!mounted) return;
    if (!saved) {
      setState(() {
        saving = false;
        formError =
            widget.controller.errorMessage.value ??
            'Task gagal dibuat. Coba lagi.';
      });
      return;
    }
    Navigator.pop(context);
    showActionFeedback(
      context,
      'Task ditambahkan',
      'Task pribadi tersinkron ke dashboard manager.',
    );
  }
}

void showReportSheet(BuildContext context, StaffController controller) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportFormSheet(controller: controller),
  );
}

class _ReportFormSheet extends StatefulWidget {
  const _ReportFormSheet({required this.controller});
  final StaffController controller;

  @override
  State<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<_ReportFormSheet> {
  final descriptionController = TextEditingController();
  String category = 'DAMAGE';
  String? areaId;
  @override
  void initState() {
    super.initState();
    widget.controller.loadAreas();
  }

  bool saving = false;
  String? formError;

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      decoration: const BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Lapor / Temuan',
              style: TextStyle(
                fontSize: 23,
                fontFamily: AppText.displayFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Pilih lokasi temuan. Waktu dan pelapor tercatat otomatis.',
              style: TextStyle(color: muted, fontSize: AppText.sm),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: category,
              items:
                  const {
                        'DAMAGE': 'Kerusakan',
                        'STOCK': 'Stok / Barang',
                        'OPERATIONAL': 'Masalah Operasional',
                        'INFO': 'Info / Usulan',
                      }.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) => category = value ?? category,
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            const SizedBox(height: 11),
            Obx(() {
              final c = widget.controller;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.areasLoading.value) const LinearProgressIndicator(),
                  DropdownButtonFormField<String>(
                    key: const Key('report-area-picker'),
                    initialValue: areaId,
                    isExpanded: true,
                    items: c.areas
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) => setState(() => areaId = value),
                    decoration: const InputDecoration(
                      labelText: 'Lokasi / Area',
                      hintText: 'Seluruh venue (opsional)',
                    ),
                  ),
                  if (c.areasError.value != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.areasError.value!,
                            style: const TextStyle(color: danger),
                          ),
                        ),
                        TextButton(
                          onPressed: c.loadAreas,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                ],
              );
            }),
            const SizedBox(height: 11),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              onChanged: (_) {
                if (formError != null) setState(() => formError = null);
              },
              decoration: const InputDecoration(
                labelText: 'Deskripsi singkat',
                hintText: 'Apa yang Anda temukan?',
              ),
            ),
            if (formError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  formError!,
                  key: const Key('report-form-error'),
                  style: const TextStyle(
                    color: danger,
                    fontSize: AppText.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 15),
            FilledButton(
              onPressed: saving ? null : _submit,
              child: Text(saving ? 'MENGIRIM…' : 'KIRIM REPORT'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    final description = descriptionController.text.trim();
    if (description.length < 3) {
      setState(() => formError = 'Deskripsi minimal 3 karakter.');
      return;
    }
    setState(() {
      saving = true;
      formError = null;
    });
    final saved = await widget.controller.createReport(
      title: description.length > 80
          ? description.substring(0, 80)
          : description,
      description: description,
      category: category,
      areaId: areaId,
    );
    if (saved && mounted) {
      showActionFeedback(
        context,
        'Report terkirim',
        'Manager dapat melihat report ini di dashboard.',
      );
      Navigator.pop(context);
    } else if (mounted) {
      setState(() {
        saving = false;
        formError =
            widget.controller.errorMessage.value ??
            'Report gagal dikirim. Coba lagi.';
      });
    }
  }
}

void showHandoverSheet(
  BuildContext context,
  int completed,
  int total,
  Future<String?> Function(String notes) finish,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _HandoverSheet(completed: completed, total: total, finish: finish),
  );
}

class _HandoverSheet extends StatefulWidget {
  const _HandoverSheet({
    required this.completed,
    required this.total,
    required this.finish,
  });

  final int completed;
  final int total;
  final Future<String?> Function(String notes) finish;

  @override
  State<_HandoverSheet> createState() => _HandoverSheetState();
}

class _HandoverSheetState extends State<_HandoverSheet> {
  final notesController = TextEditingController();
  bool saving = false;
  String? actionError;

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      decoration: const BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Catatan Clock Out',
              style: TextStyle(
                fontSize: 23,
                fontFamily: AppText.displayFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Ringkasan disusun otomatis dari aktivitas Anda.',
              style: TextStyle(color: muted, fontSize: AppText.sm),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.task_alt, color: vamosGreen),
                        const SizedBox(width: 10),
                        Text(
                          '${widget.completed} / ${widget.total} task selesai',
                          style: const TextStyle(
                            fontSize: AppText.base,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // const Divider(height: 28, color: line),
                    // const Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.sync_alt, color: warning),
                    //     SizedBox(width: 10),
                    //     Expanded(
                    //       child: Text(
                    //         'Laundry handuk belum selesai — menunggu vendor.',
                    //         style: TextStyle(
                    //           fontSize: AppText.base,
                    //           height: 1.4,
                    //           fontWeight: FontWeight.w700,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const Divider(height: 28, color: line),
                    // const Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Icon(Icons.flag_outlined, color: danger),
                    //     SizedBox(width: 10),
                    //     Expanded(
                    //       child: Text(
                    //         '2 report aktif: lampu Court 3 dan stok sabun.',
                    //         style: TextStyle(
                    //           fontSize: AppText.base,
                    //           height: 1.4,
                    //           fontWeight: FontWeight.w700,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan tambahan (opsional)',
              ),
            ),
            if (actionError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  actionError!,
                  key: const Key('handover-action-error'),
                  style: const TextStyle(
                    color: danger,
                    fontSize: AppText.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: saving ? null : _submit,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(saving ? 'MENYIMPAN…' : 'CLOCK OUT'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    setState(() {
      saving = true;
      actionError = null;
    });
    final error = await widget.finish(notesController.text.trim());
    if (!mounted) return;
    if (error != null) {
      setState(() {
        saving = false;
        actionError = error;
      });
      return;
    }
    showActionFeedback(
      context,
      'Clock Out berhasil',
      'Lokasi, selfie, dan catatan tersimpan.',
    );
    Navigator.pop(context);
  }
}

class _EvidencePhoto extends StatefulWidget {
  const _EvidencePhoto({required this.id, this.fit = BoxFit.cover});
  final String id;
  final BoxFit fit;
  @override
  State<_EvidencePhoto> createState() => _EvidencePhotoState();
}

class _EvidencePhotoState extends State<_EvidencePhoto> {
  int attempt = 0;
  @override
  Widget build(BuildContext context) {
    final token = Get.isRegistered<SessionStoreContract>()
        ? Get.find<SessionStoreContract>().token
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        '${AppConfig.apiBaseUrl}/media/${widget.id}?retry=$attempt',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        fit: widget.fit,
        width: double.infinity,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) => Center(
          child: TextButton.icon(
            onPressed: () => setState(() => attempt++),
            icon: const Icon(Icons.refresh),
            label: const Text('Foto gagal dimuat · coba lagi'),
          ),
        ),
      ),
    );
  }
}
