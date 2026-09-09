import 'package:get/get.dart' show Response;
import 'package:vamos_ops_mobile/app/core/config/app_config.dart';
import 'package:vamos_ops_mobile/app/core/errors/api_exception.dart';

Map<String, dynamic> decodeApiBody(Response<dynamic> response) {
  ensureApiSuccess(response);
  final body = response.body;
  if (body is Map<String, dynamic>) return body;
  if (body is Map) return body.cast<String, dynamic>();
  throw const ApiException('Format respons API tidak valid.');
}

void ensureApiSuccess(Response<dynamic> response) {
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
