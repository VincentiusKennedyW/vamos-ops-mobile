import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/widgets/action_feedback.dart';

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
        color: AppColors.surfaceSunken,
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
              style: TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: AppText.sm,
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.task_alt, color: AppColors.primary),
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
                    color: AppColors.danger,
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
