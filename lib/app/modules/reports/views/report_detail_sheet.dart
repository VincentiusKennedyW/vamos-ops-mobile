import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/core/utils/date_time_labels.dart';
import 'package:vamos_ops_mobile/app/modules/reports/format/report_labels.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/widgets/detail_pill.dart';
import 'package:vamos_ops_mobile/app/widgets/evidence_photo.dart';

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
        ? AppColors.primary
        : report.status == 'FOLLOW_UP'
        ? AppColors.warning
        : AppColors.danger;
    final evidenceCount = report.evidence.isNotEmpty
        ? report.evidence.length
        : report.evidenceCount;
    return Container(
      key: const Key('report-detail-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
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
                DetailPill(
                  label: reportCategoryLabel(report.category),
                  color: statusColor,
                ),
                const Spacer(),
                DetailPill(
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
              Text(
                report.number,
                style: const TextStyle(color: AppColors.onSurfaceMuted),
              ),
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
                      value: dateTimeLabel(report.createdAt),
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
              Text(error!, style: const TextStyle(color: AppColors.danger)),
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
                style: TextStyle(color: AppColors.onSurfaceMuted),
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
                        child: EvidencePhoto(id: entry.$2.id),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          entry.$2.fileName.isEmpty
                              ? 'Foto ${entry.$1 + 1} · ${dateTimeLabel(entry.$2.createdAt)}'
                              : '${entry.$2.fileName} · ${dateTimeLabel(entry.$2.createdAt)}',
                          style: const TextStyle(
                            color: AppColors.onSurfaceMuted,
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

class _ReportFact extends StatelessWidget {
  const _ReportFact({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 96,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.onSurfaceMuted),
        ),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );
}
