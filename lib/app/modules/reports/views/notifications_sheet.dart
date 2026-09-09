import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';

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
              style: const TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: AppText.base,
              ),
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
                      leading: const Icon(
                        Icons.flag_outlined,
                        color: AppColors.warning,
                      ),
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
