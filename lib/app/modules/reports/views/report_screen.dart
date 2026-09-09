import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/modules/reports/format/report_labels.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/modules/reports/widgets/report_tile.dart';
import 'package:vamos_ops_mobile/app/widgets/page_footer.dart';
import 'package:vamos_ops_mobile/app/widgets/screen_header.dart';

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
                return PageFooter(
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
                child: ReportTile(
                  onTap: () => onReport(report),
                  title: report.title,
                  category: reportCategoryLabel(report.category),
                  area: report.area,
                  time: _relativeTime(report.createdAt),
                  status: report.status.replaceAll('_', ' '),
                  color: report.status == 'DONE'
                      ? AppColors.primary
                      : report.status == 'FOLLOW_UP'
                      ? AppColors.warning
                      : AppColors.danger,
                ),
              );
            },
          ),
        ),
      ),
    ],
  );

  static String _relativeTime(DateTime value) {
    final minutes = DateTime.now().difference(value.toLocal()).inMinutes;
    if (minutes < 60) return '${minutes.clamp(1, 59)} menit lalu';
    if (minutes < 1440) return '${minutes ~/ 60} jam lalu';
    return '${minutes ~/ 1440} hari lalu';
  }
}
