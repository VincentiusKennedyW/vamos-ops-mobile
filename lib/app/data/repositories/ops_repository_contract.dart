import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_area.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_page.dart';
import 'package:vamos_ops_mobile/app/data/models/staff_home_data.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

abstract interface class OpsRepositoryContract {
  Future<StaffHomeData> getHome();
  Future<OpsTask> createTask({
    required String title,
    required String description,
    required String priority,
    required String evidencePolicy,
    required DateTime scheduledAt,
    required DateTime dueAt,
  });
  Future<OpsTask> updateTask(String taskId, TaskState state);
  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? areaId,
    String? sourceTaskId,
    required String evidenceId,
  });
  Future<void> recordAttendance({
    required String action,
    required double latitude,
    required double longitude,
    required String selfieId,
  });
  Future<void> submitHandover({
    required int completedCount,
    required int totalCount,
    required List<String> outstandingTaskIds,
    required String notes,
  });
  Future<String> uploadTaskEvidence(
    String taskId,
    CapturedPhoto photo, {
    required String phase,
    required String description,
  });
  Future<String> uploadPurposePhoto(String purpose, CapturedPhoto photo);
}

abstract interface class PagedOpsRepositoryContract {
  Future<OpsPage<OpsTask>> getTasks(
    String date,
    int page,
    String status, {
    String? from,
    String? to,
    bool allDates = false,
  });
  Future<OpsPage<OpsReport>> getReports(int page);
  Future<OpsTask> getTask(String id);
}

abstract interface class AreasRepositoryContract {
  Future<List<OpsArea>> getAreas();
}

abstract interface class ReportDetailRepositoryContract {
  Future<OpsReport> getReport(String id);
}
