import 'package:get/get.dart' show Response;

import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/session_store.dart';
import '../models/auth_session.dart';
import 'auth_api_provider.dart';

abstract interface class AuthRepositoryContract {
  Future<AuthSession?> restore();
  Future<AuthSession> login(String email, String password);
  Future<void> logout();
}

class AuthRepository implements AuthRepositoryContract {
  AuthRepository(this._provider, this._store);

  final AuthApiProvider _provider;
  final SessionStoreContract _store;

  @override
  Future<AuthSession?> restore() async {
    final token = await _store.load();
    if (token == null || token.isEmpty) return null;
    try {
      final user = await _loadUser(token);
      return AuthSession(token: token, user: user);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _store.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthSession> login(String email, String password) async {
    final response = await _provider.login(email, password);
    final body = _body(response);
    final token = body['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('Server tidak mengembalikan sesi mobile.');
    }
    await _store.save(token);
    try {
      final user = await _loadUser(token);
      return AuthSession(token: token, user: user);
    } catch (_) {
      await _store.clear();
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final token = _store.token;
    try {
      if (token != null && token.isNotEmpty) await _provider.logout(token);
    } finally {
      await _store.clear();
    }
  }

  Future<AuthUser> _loadUser(String token) async {
    final body = _body(await _provider.session(token));
    final rawUser = body['user'];
    if (rawUser is Map<String, dynamic>) return AuthUser.fromJson(rawUser);
    if (rawUser is Map) {
      return AuthUser.fromJson(rawUser.cast<String, dynamic>());
    }
    throw const ApiException('Format sesi pengguna tidak valid.');
  }

  Map<String, dynamic> _body(Response<dynamic> response) {
    final statusCode = response.statusCode;
    final raw = response.body;
    if (statusCode != null && statusCode >= 200 && statusCode < 300) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.cast<String, dynamic>();
      throw const ApiException('Format respons API tidak valid.');
    }
    if (statusCode == null) {
      throw ApiException(
        'Tidak dapat terhubung ke VAMOS API di ${AppConfig.serverBaseUrl}. '
        'Pastikan laptop dan HP berada di Wi-Fi yang sama.',
      );
    }
    final message = raw is Map
        ? (raw['message'] ?? raw['error'] ?? 'Autentikasi gagal.').toString()
        : 'Autentikasi gagal (HTTP $statusCode).';
    throw ApiException(message, statusCode: statusCode);
  }
}
