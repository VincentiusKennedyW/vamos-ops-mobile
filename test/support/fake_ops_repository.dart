import 'dart:async';

import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/data/models/staff_home_data.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

class FakeOpsRepository implements OpsRepositoryContract {
  bool failTaskUpdate = false;
  String? uploadedTaskId;
  String? uploadedPhase;
  String? uploadedDescription;
  String? lastAttendanceAction;
  int updateCalls = 0;
  double? lastLatitude;
  double? lastLongitude;
  String? createdTaskTitle;
  DateTime? createdTaskScheduledAt;
  int homeCalls = 0;
  Completer<OpsTask>? taskUpdateCompleter;
  Completer<OpsTask>? taskCreateCompleter;

  @override
  Future<OpsTask> createTask({
    required String title,
    required String description,
    required String priority,
    required String evidencePolicy,
    required DateTime scheduledAt,
    required DateTime dueAt,
  }) async {
    createdTaskTitle = title;
    createdTaskScheduledAt = scheduledAt;
    if (taskCreateCompleter != null) return taskCreateCompleter!.future;
    return OpsTask(
      id: 'created-task',
      title: title,
      area: 'Venue',
      time: '17:00',
      kind: TaskKind.routine,
      state: TaskState.pending,
      note: description,
      evidencePolicy: evidencePolicy,
      scheduledAt: scheduledAt,
      dueAt: dueAt,
    );
  }

  @override
  Future<String> uploadTaskEvidence(
    String taskId,
    CapturedPhoto photo, {
    required String phase,
    required String description,
  }) async {
    uploadedTaskId = taskId;
    uploadedPhase = phase;
    uploadedDescription = description;
    return 'evidence-1';
  }

  @override
  Future<String> uploadPurposePhoto(
    String purpose,
    CapturedPhoto photo,
  ) async => 'evidence-1';

  @override
  Future<StaffHomeData> getHome() async {
    homeCalls++;
    return StaffHomeData(
      userName: 'API Staff',
      userRole: 'Crew Padel',
      attendanceStatus: 'ON_DUTY',
      checkInAt: DateTime(2026, 9, 2, 5, 57),
      tasks: const [
        OpsTask(
          id: 'task-api',
          title: 'API task',
          area: 'Court 1',
          time: '10:00',
          kind: TaskKind.routine,
          state: TaskState.pending,
        ),
      ],
      reports: const [],
      today: DateTime(2026, 9, 3),
    );
  }

  @override
  Future<OpsTask> updateTask(String taskId, TaskState state) async {
    updateCalls += 1;
    if (failTaskUpdate) throw const ApiException('simulated failure');
    if (taskUpdateCompleter != null) return taskUpdateCompleter!.future;
    return OpsTask(
      id: taskId,
      title: 'API task',
      area: 'Court 1',
      time: '10:00',
      kind: TaskKind.routine,
      state: state,
    );
  }

  @override
  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? areaId,
    String? sourceTaskId,
    required String evidenceId,
  }) async {}

  @override
  Future<void> recordAttendance({
    required String action,
    required double latitude,
    required double longitude,
    required String selfieId,
  }) async {
    lastAttendanceAction = action;
    lastLatitude = latitude;
    lastLongitude = longitude;
  }

  @override
  Future<void> submitHandover({
    required int completedCount,
    required int totalCount,
    required List<String> outstandingTaskIds,
    required String notes,
  }) async {}
}
