import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/core/utils/date_time_labels.dart';
import 'package:vamos_ops_mobile/app/modules/staff/controllers/staff_controller.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';
import 'package:vamos_ops_mobile/app/widgets/action_feedback.dart';
import 'package:vamos_ops_mobile/app/widgets/evidence_photo.dart';
import 'package:vamos_ops_mobile/app/widgets/section_title.dart';

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
        color: AppColors.surfaceSunken,
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
                    color: AppColors.primarySubtle,
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
              style: const TextStyle(
                color: AppColors.onSurfaceMuted,
                fontSize: AppText.base,
              ),
            ),
            if (task.scheduledAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Waktu Start (rencana) ${dateTimeLabel(task.scheduledAt!)}${task.dueAt != null ? ' · Deadline ${dateTimeLabel(task.dueAt!)} · Lead time ${durationLabel(task.scheduledAt!, task.dueAt!)}' : ''}',
                  style: const TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: AppText.sm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (task.startedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Start aktual ${dateTimeLabel(task.startedAt!)}${task.completedAt == null ? ' · sedang berjalan' : ' · End ${dateTimeLabel(task.completedAt!)}'}',
                  style: const TextStyle(
                    color: AppColors.warning,
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
                    color: AppColors.onSurfaceMuted,
                    height: 1.5,
                    fontSize: AppText.base,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            if (detailLoading) const LinearProgressIndicator(),
            if (task.evidence.isNotEmpty) ...[
              const SectionTitle(
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
                          '${item.phase == "BEFORE" ? "Sebelum" : "Sesudah"} · ${dateTimeLabel(item.createdAt)}',
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
                                      child: EvidencePhoto(
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
                            child: EvidencePhoto(id: item.id),
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
                                            color: AppColors.onSurfaceMuted,
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
                                        ? AppColors.primary
                                        : AppColors.onSurface,
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
                                      color: AppColors.primary,
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
                    color: AppColors.danger,
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
