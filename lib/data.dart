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
      beforeEvidenceCount: _intValue(json['beforeEvidenceCount']),
      afterEvidenceCount: _intValue(json['afterEvidenceCount']),
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

  static int _intValue(dynamic value) => switch (value) {
    int number => number,
    num number => number.round(),
    _ => int.tryParse(value?.toString() ?? '') ?? 0,
  };

  static String _displayTime(dynamic raw) {
    if (raw == null) return '—';
    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class TaskEvidence {
  const TaskEvidence({
    required this.id,
    required this.phase,
    required this.description,
    required this.createdAt,
  });
  final String id, phase, description;
  final DateTime createdAt;
  factory TaskEvidence.fromJson(Map<String, dynamic> json) => TaskEvidence(
    id: json['id'].toString(),
    phase: json['phase'].toString(),
    description: json['description']?.toString() ?? '',
    createdAt: DateTime.parse(json['createdAt'].toString()),
  );
}

class OpsPage<T> {
  const OpsPage(this.items, {this.hasMore = false});
  final List<T> items;
  final bool hasMore;
}

class OpsReport {
  const OpsReport({
    required this.id,
    required this.number,
    required this.title,
    required this.category,
    required this.area,
    required this.status,
    required this.createdAt,
    this.description = '',
    this.priority = 'NORMAL',
    this.evidenceCount = 0,
    this.evidence = const [],
    this.detailLoaded = false,
  });

  factory OpsReport.fromJson(Map<String, dynamic> json) => OpsReport(
    id: json['id'].toString(),
    number: json['number']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    category: json['category']?.toString() ?? 'INFO',
    area: json['area']?.toString() ?? 'Venue',
    status: json['status']?.toString() ?? 'OPEN',
    description: json['description']?.toString() ?? '',
    priority: json['priority']?.toString() ?? 'NORMAL',
    evidenceCount: OpsTask._intValue(json['evidenceCount']),
    evidence: ((json['evidence'] as List?) ?? const [])
        .map(
          (item) =>
              ReportEvidence.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(),
    detailLoaded: json.containsKey('evidence'),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
  );

  final String id;
  final String number;
  final String title;
  final String category;
  final String area;
  final String status;
  final String description;
  final String priority;
  final int evidenceCount;
  final List<ReportEvidence> evidence;
  final bool detailLoaded;
  final DateTime createdAt;
}

class ReportEvidence {
  const ReportEvidence({
    required this.id,
    required this.createdAt,
    this.fileName = '',
  });

  factory ReportEvidence.fromJson(Map<String, dynamic> json) => ReportEvidence(
    id: json['id'].toString(),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    fileName: json['fileName']?.toString() ?? '',
  );

  final String id;
  final DateTime createdAt;
  final String fileName;
}

class StaffHomeData {
  const StaffHomeData({
    required this.userName,
    required this.userRole,
    required this.attendanceStatus,
    required this.checkInAt,
    this.checkOutAt,
    required this.tasks,
    required this.reports,
    this.venueName = '',
    this.today,
    this.assignedCount,
    this.completedCount,
    this.performance = const StaffPerformance(),
  });

  factory StaffHomeData.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final attendance = (json['attendance'] as Map?)?.cast<String, dynamic>();
    return StaffHomeData(
      userName: user['name']?.toString() ?? 'Andi Saputra',
      userRole: user['role']?.toString() ?? 'Crew Padel',
      venueName: user['venue']?.toString() ?? '',
      attendanceStatus:
          attendance?['attendanceStatus']?.toString() ?? 'NOT_CHECKED_IN',
      checkInAt: DateTime.tryParse(attendance?['checkInAt']?.toString() ?? ''),
      checkOutAt: DateTime.tryParse(
        attendance?['checkOutAt']?.toString() ?? '',
      ),
      tasks: ((json['tasks'] as List?) ?? const [])
          .map(
            (item) => OpsTask.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      reports: ((json['reports'] as List?) ?? const [])
          .map(
            (item) => OpsReport.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      today: DateTime.tryParse(json['today']?.toString() ?? ''),
      assignedCount: (json['stats'] as Map?)?['assigned'] as int?,
      completedCount: (json['stats'] as Map?)?['completed'] as int?,
      performance: StaffPerformance.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  final String userName;
  final String userRole;
  final String attendanceStatus;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<OpsTask> tasks;
  final List<OpsReport> reports;
  final String venueName;
  final DateTime? today;
  final int? assignedCount, completedCount;
  final StaffPerformance performance;
}

class StaffPerformance {
  const StaffPerformance({
    this.attendanceDays = 0,
    this.taskCompletionRate = 0,
    this.completedTasks = 0,
  });
  factory StaffPerformance.fromJson(Map<String, dynamic> json) =>
      StaffPerformance(
        attendanceDays: (json['attendanceDays'] as num?)?.toInt() ?? 0,
        taskCompletionRate: (json['taskCompletionRate'] as num?)?.toInt() ?? 0,
        completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      );
  final int attendanceDays, taskCompletionRate, completedTasks;
}

String kindLabel(TaskKind kind) => switch (kind) {
  TaskKind.routine => 'ROUTINE',
  TaskKind.manager => 'MANAGER',
  TaskKind.handover => 'HANDOVER',
  TaskKind.issue => 'ISSUE',
};
