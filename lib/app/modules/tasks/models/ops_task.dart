import 'package:vamos_ops_mobile/app/data/models/json_values.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/task_evidence.dart';

enum TaskKind { routine, manager, handover, issue }

enum TaskState { pending, inProgress, done }

extension TaskStateApi on TaskState {
  String get apiValue => switch (this) {
    TaskState.pending => 'PENDING',
    TaskState.inProgress => 'IN_PROGRESS',
    TaskState.done => 'DONE',
  };
}

class OpsTask {
  const OpsTask({
    required this.id,
    required this.title,
    required this.area,
    required this.time,
    required this.kind,
    required this.state,
    this.note = '',
    this.photoRequired = false,
    this.evidenceCount = 0,
    this.beforeEvidenceCount = 0,
    this.afterEvidenceCount = 0,
    this.evidencePolicy = 'none',
    this.scheduledAt,
    this.dueAt,
    this.startedAt,
    this.completedAt,
    this.startedBy,
    this.evidence = const [],
  });

  final String id;
  final String title;
  final String area;
  final String time;
  final TaskKind kind;
  final TaskState state;
  final String note;
  final bool photoRequired;
  final int evidenceCount;
  final int beforeEvidenceCount;
  final int afterEvidenceCount;
  final String evidencePolicy;
  final DateTime? scheduledAt;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? startedBy;
  final List<TaskEvidence> evidence;

  OpsTask copyWith({
    String? id,
    TaskState? state,
    DateTime? startedAt,
    DateTime? completedAt,
    String? startedBy,
    int? evidenceCount,
    int? beforeEvidenceCount,
    int? afterEvidenceCount,
    List<TaskEvidence>? evidence,
  }) => OpsTask(
    id: id ?? this.id,
    title: title,
    area: area,
    time: time,
    kind: kind,
    state: state ?? this.state,
    note: note,
    photoRequired: photoRequired,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    beforeEvidenceCount: beforeEvidenceCount ?? this.beforeEvidenceCount,
    afterEvidenceCount: afterEvidenceCount ?? this.afterEvidenceCount,
    evidencePolicy: evidencePolicy,
    scheduledAt: scheduledAt,
    dueAt: dueAt,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    startedBy: startedBy ?? this.startedBy,
    evidence: evidence ?? this.evidence,
  );

  factory OpsTask.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'PENDING';
    final evidencePolicy = json['evidencePolicy']?.toString() ?? 'none';
    return OpsTask(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      area: json['area']?.toString() ?? 'Venue',
      time: _displayTime(json['dueAt'] ?? json['scheduledAt']),
      kind: switch (json['kind']?.toString()) {
        'MANAGER' => TaskKind.manager,
        'HANDOVER' => TaskKind.handover,
        'ISSUE' => TaskKind.issue,
        _ => TaskKind.routine,
      },
      state: switch (status) {
        'DONE' => TaskState.done,
        'IN_PROGRESS' => TaskState.inProgress,
        _ => TaskState.pending,
      },
      note: json['description']?.toString() ?? '',
      photoRequired:
          evidencePolicy == 'after' || evidencePolicy == 'before_after',
      evidenceCount: switch (json['evidenceCount']) {
        int value => value,
        num value => value.round(),
        _ => int.tryParse(json['evidenceCount']?.toString() ?? '') ?? 0,
      },
      beforeEvidenceCount: intValue(json['beforeEvidenceCount']),
      afterEvidenceCount: intValue(json['afterEvidenceCount']),
      evidencePolicy: evidencePolicy,
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
      dueAt: DateTime.tryParse(json['dueAt']?.toString() ?? ''),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      startedBy: json['startedBy']?.toString(),
      evidence: ((json['evidence'] as List?) ?? [])
          .map(
            (item) =>
                TaskEvidence.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  static String _displayTime(dynamic raw) {
    if (raw == null) return '—';
    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

String kindLabel(TaskKind kind) => switch (kind) {
  TaskKind.routine => 'ROUTINE',
  TaskKind.manager => 'MANAGER',
  TaskKind.handover => 'HANDOVER',
  TaskKind.issue => 'ISSUE',
};
