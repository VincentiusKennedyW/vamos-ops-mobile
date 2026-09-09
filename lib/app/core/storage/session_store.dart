import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStoreContract {
  String? get token;
  Future<String?> load();
  Future<void> save(String token);
  Future<void> clear();
}

class SessionStore implements SessionStoreContract {
  SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'vamos.auth.session_token';
  final FlutterSecureStorage _storage;
  String? _token;

  @override
  String? get token => _token;

  @override
  Future<String?> load() async {
    _token = await _storage.read(key: _tokenKey);
    return _token;
  }

  @override
  Future<void> save(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> clear() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }
}
