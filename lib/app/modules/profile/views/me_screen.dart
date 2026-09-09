import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/data/models/staff_performance.dart';
import 'package:vamos_ops_mobile/app/modules/profile/views/app_settings_sheet.dart';
import 'package:vamos_ops_mobile/app/widgets/action_feedback.dart';
import 'package:vamos_ops_mobile/app/widgets/section_title.dart';

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
              color: AppColors.onSurface,
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
                  color: AppColors.primary,
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
                  style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: AppText.base,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan aplikasi',
            onPressed:
                onSettings ?? () => showAppSettingsSheet(context, isOnline),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
      const SizedBox(height: 26),
      SectionTitle(
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
              Container(width: 1, height: 38, color: AppColors.border),
              _Stat(
                value: '${performance.taskCompletionRate}%',
                label: 'Task tuntas',
              ),
              Container(width: 1, height: 38, color: AppColors.border),
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
            color: isOnline ? AppColors.primary : AppColors.warning,
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
            foregroundColor: AppColors.danger,
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.32)),
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
        style: const TextStyle(
          color: AppColors.onSurfaceMuted,
          fontSize: AppText.xs,
        ),
      ),
    ],
  );
}
