import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/app/widgets/action_feedback.dart';

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
              style: TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: AppText.sm,
              ),
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
                            style: const TextStyle(color: AppColors.danger),
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
                    color: AppColors.danger,
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
