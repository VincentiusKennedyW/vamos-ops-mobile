import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/core/utils/date_time_labels.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/app/widgets/action_feedback.dart';

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
              style: TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: AppText.sm,
              ),
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
                    label: Text('Start ${dateTimeLabel(scheduledAt)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('create-task-due-time'),
                    onPressed: saving ? null : _pickDueAt,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('Deadline ${dateTimeLabel(dueAt)}'),
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
                  color: AppColors.danger,
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
