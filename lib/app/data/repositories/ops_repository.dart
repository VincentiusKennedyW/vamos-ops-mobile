import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_area.dart';
import 'package:vamos_ops_mobile/app/data/models/ops_page.dart';
import 'package:vamos_ops_mobile/app/data/models/staff_home_data.dart';
import 'package:vamos_ops_mobile/app/data/providers/api_response.dart';
import 'package:vamos_ops_mobile/app/data/providers/ops_api_provider.dart';
import 'package:vamos_ops_mobile/app/data/repositories/ops_repository_contract.dart';
import 'package:vamos_ops_mobile/app/modules/reports/models/ops_report.dart';
import 'package:vamos_ops_mobile/app/modules/tasks/models/ops_task.dart';

class OpsRepository
    implements
        OpsRepositoryContract,
        PagedOpsRepositoryContract,
        AreasRepositoryContract,
        ReportDetailRepositoryContract {
  OpsRepository(this._provider);

  final OpsApiProvider _provider;

  @override
  Future<OpsPage<OpsTask>> getTasks(
    String date,
    int page,
    String status, {
    String? from,
    String? to,
    bool allDates = false,
  }) async {
    final body = decodeApiBody(
      await _provider.fetchTasks(
        date,
        page,
        status,
        from: from,
        to: to,
        allDates: allDates,
      ),
    );
    return OpsPage(
      (body['items'] as List)
          .map(
            (item) => OpsTask.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      hasMore: (body['pagination'] as Map)['hasMore'] == true,
    );
  }

  @override
  Future<OpsPage<OpsReport>> getReports(int page) async {
    final body = decodeApiBody(await _provider.fetchReports(page));
    return OpsPage(
      (body['items'] as List)
          .map(
            (item) => OpsReport.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      hasMore: (body['pagination'] as Map)['hasMore'] == true,
    );
  }

  @override
  Future<OpsReport> getReport(String id) async => OpsReport.fromJson(
    (decodeApiBody(await _provider.fetchReport(id))['item'] as Map)
        .cast<String, dynamic>(),
  );

  @override
  Future<OpsTask> getTask(String id) async => OpsTask.fromJson(
    (decodeApiBody(await _provider.fetchTask(id))['item'] as Map)
        .cast<String, dynamic>(),
  );

  @override
  Future<List<OpsArea>> getAreas() async {
    final body = decodeApiBody(await _provider.fetchAreas());
    return (body['items'] as List)
        .where((a) => a['active'] == true)
        .map((a) => OpsArea(a['id'] as String, a['name'] as String))
        .toList();
  }

  @override
  Future<StaffHomeData> getHome() async {
    final response = await _provider.fetchHome();
    final body = decodeApiBody(response);
    return StaffHomeData.fromJson(body);
  }

  @override
  Future<OpsTask> createTask({
    required String title,
    required String description,
    required String priority,
    required String evidencePolicy,
    required DateTime scheduledAt,
    required DateTime dueAt,
  }) async {
    final body = decodeApiBody(
      await _provider.createTask({
        'title': title,
        'description': description,
        'kind': 'ROUTINE',
        'priority': priority,
        'evidencePolicy': evidencePolicy,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'dueAt': dueAt.toUtc().toIso8601String(),
      }),
    );
    return OpsTask.fromJson((body['item'] as Map).cast<String, dynamic>());
  }

  @override
  Future<OpsTask> updateTask(String taskId, TaskState state) async =>
      OpsTask.fromJson(
        (decodeApiBody(
                  await _provider.updateTask(taskId, state.apiValue),
                )['item']
                as Map)
            .cast<String, dynamic>(),
      );

  @override
  Future<void> createReport({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? areaId,
    String? sourceTaskId,
    required String evidenceId,
  }) async {
    final response = await _provider.createReport({
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      if (areaId != null) 'areaId': areaId,
      if (sourceTaskId != null) 'sourceTaskId': sourceTaskId,
      'evidenceId': evidenceId,
    });
    ensureApiSuccess(response);
  }

  @override
  Future<void> recordAttendance({
    required String action,
    required double latitude,
    required double longitude,
    required String selfieId,
  }) async {
    final key = '${DateTime.now().microsecondsSinceEpoch}-$action';
    final response = await _provider.recordAttendance({
      'action': action,
      'latitude': latitude,
      'longitude': longitude,
      'selfieId': selfieId,
    }, key);
    ensureApiSuccess(response);
  }

  @override
  Future<void> submitHandover({
    required int completedCount,
    required int totalCount,
    required List<String> outstandingTaskIds,
    required String notes,
  }) async {
    final response = await _provider.submitHandover({
      'completedCount': completedCount,
      'totalCount': totalCount,
      'outstandingTaskIds': outstandingTaskIds,
      'notes': notes,
    });
    ensureApiSuccess(response);
  }

  @override
  Future<String> uploadTaskEvidence(
    String taskId,
    CapturedPhoto photo, {
    required String phase,
    required String description,
  }) async {
    final body = decodeApiBody(
      await _provider.uploadTaskEvidence(taskId, photo, phase, description),
    );
    final item = body['item'];
    if (item is Map && item['id'] != null) return item['id'].toString();
    throw const ApiException('Server tidak mengembalikan ID foto evidence.');
  }

  @override
  Future<String> uploadPurposePhoto(String purpose, CapturedPhoto photo) async {
    final body = decodeApiBody(
      await _provider.uploadPurposePhoto(purpose, photo),
    );
    final item = body['item'];
    if (item is Map && item['id'] != null) return item['id'].toString();
    throw const ApiException('Server tidak mengembalikan ID foto evidence.');
  }
}
