import 'package:get/get.dart' show Response;

import '../../core/config/app_config.dart';
import '../../core/errors/api_exception.dart';
import '../../core/services/device_services.dart';
import '../../../data.dart';
import '../providers/ops_api_provider.dart';

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

class OpsArea {
  const OpsArea(this.id, this.name);
  final String id, name;
}

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
    final body = _body(
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
    final body = _body(await _provider.fetchReports(page));
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
    (_body(await _provider.fetchReport(id))['item'] as Map)
        .cast<String, dynamic>(),
  );

  @override
  Future<OpsTask> getTask(String id) async => OpsTask.fromJson(
    (_body(await _provider.fetchTask(id))['item'] as Map)
        .cast<String, dynamic>(),
  );

  @override
  Future<List<OpsArea>> getAreas() async {
    final body = _body(await _provider.fetchAreas());
    return (body['items'] as List)
        .where((a) => a['active'] == true)
        .map((a) => OpsArea(a['id'] as String, a['name'] as String))
        .toList();
  }

  @override
  Future<StaffHomeData> getHome() async {
    final response = await _provider.fetchHome();
    final body = _body(response);
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
    final body = _body(
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
        (_body(await _provider.updateTask(taskId, state.apiValue))['item']
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
    _ensureSuccess(response);
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
    _ensureSuccess(response);
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
    _ensureSuccess(response);
  }

  @override
  Future<String> uploadTaskEvidence(
    String taskId,
    CapturedPhoto photo, {
    required String phase,
    required String description,
  }) async {
    final body = _body(
      await _provider.uploadTaskEvidence(taskId, photo, phase, description),
    );
    final item = body['item'];
    if (item is Map && item['id'] != null) return item['id'].toString();
    throw const ApiException('Server tidak mengembalikan ID foto evidence.');
  }

  @override
  Future<String> uploadPurposePhoto(String purpose, CapturedPhoto photo) async {
    final body = _body(await _provider.uploadPurposePhoto(purpose, photo));
    final item = body['item'];
    if (item is Map && item['id'] != null) return item['id'].toString();
    throw const ApiException('Server tidak mengembalikan ID foto evidence.');
  }

  Map<String, dynamic> _body(Response<dynamic> response) {
    _ensureSuccess(response);
    final body = response.body;
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    throw const ApiException('Format respons API tidak valid.');
  }

  void _ensureSuccess(Response<dynamic> response) {
    final statusCode = response.statusCode;
    final body = response.body;
    if (statusCode != null && statusCode >= 200 && statusCode < 300) return;
    if (statusCode == null) {
      final reason = response.statusText?.trim();
      throw ApiException(
        'Tidak dapat terhubung ke VAMOS API di ${AppConfig.apiBaseUrl}. '
        'Pastikan dashboard API aktif dan alamat perangkat benar'
        '${reason == null || reason.isEmpty ? '.' : ' ($reason).'}',
      );
    }
    final message = body is Map
        ? (body['message'] ??
                  body['error'] ??
                  'API request gagal (HTTP $statusCode)')
              .toString()
        : 'API request gagal (HTTP $statusCode).';
    throw ApiException(message, statusCode: statusCode);
  }
}
