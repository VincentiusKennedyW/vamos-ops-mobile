import 'dart:io';

import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/config/app_config.dart';
import 'package:vamos_ops_mobile/app/core/services/device_services.dart';
import 'package:vamos_ops_mobile/app/core/storage/session_store.dart';

class OpsApiProvider extends GetConnect {
  OpsApiProvider([this._sessionStore]);

  final SessionStoreContract? _sessionStore;

  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 12);
    httpClient.addRequestModifier<dynamic>((request) {
      request.headers['Accept'] = 'application/json';
      final token = _sessionStore?.token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });
    super.onInit();
  }

  Future<Response<dynamic>> fetchTasks(
    String date,
    int page,
    String status, {
    String? from,
    String? to,
    bool allDates = false,
  }) => get<dynamic>(
    '/tasks',
    query: {
      if (allDates)
        'allDates': 'true'
      else if (from != null) ...{
        'from': from,
        'to': to!,
      } else
        'date': date,
      'page': page.toString(),
      'pageSize': '20',
      if (status != 'all') 'status': status,
    },
  );
  Future<Response<dynamic>> fetchReports(int page) => get<dynamic>(
    '/reports',
    query: {'page': page.toString(), 'pageSize': '20'},
  );
  Future<Response<dynamic>> fetchReport(String id) =>
      get<dynamic>('/reports/$id');
  Future<Response<dynamic>> fetchTask(String id) => get<dynamic>('/tasks/$id');

  Future<Response<dynamic>> fetchAreas() => get<dynamic>('/areas');

  Future<Response<dynamic>> fetchHome() => get<dynamic>('/staff/me/home');

  Future<Response<dynamic>> createTask(Map<String, dynamic> payload) =>
      post<dynamic>('/tasks', payload);

  Future<Response<dynamic>> updateTask(String taskId, String status) =>
      patch<dynamic>('/tasks/$taskId', {'status': status});

  Future<Response<dynamic>> createReport(Map<String, dynamic> payload) =>
      post<dynamic>('/reports', payload);

  Future<Response<dynamic>> recordAttendance(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) => post<dynamic>(
    '/attendance',
    payload,
    headers: {'Idempotency-Key': idempotencyKey},
  );

  Future<Response<dynamic>> submitHandover(Map<String, dynamic> payload) =>
      post<dynamic>('/handovers', payload);

  Future<Response<dynamic>> uploadTaskEvidence(
    String taskId,
    CapturedPhoto photo,
    String phase,
    String description,
  ) => post<dynamic>(
    '/media',
    FormData({
      'taskId': taskId,
      'phase': phase,
      'description': description,
      'file': MultipartFile(
        File(photo.path),
        filename: photo.name,
        contentType: photo.mimeType,
      ),
    }),
  );

  Future<Response<dynamic>> uploadPurposePhoto(
    String purpose,
    CapturedPhoto photo,
  ) => post<dynamic>(
    '/media',
    FormData({
      'purpose': purpose,
      'file': MultipartFile(
        File(photo.path),
        filename: photo.name,
        contentType: photo.mimeType,
      ),
    }),
  );
}
