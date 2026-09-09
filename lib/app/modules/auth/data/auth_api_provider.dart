import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/config/app_config.dart';

class AuthApiProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.authBaseUrl;
    httpClient.timeout = const Duration(seconds: 12);
    httpClient.addRequestModifier<dynamic>((request) {
      request.headers['Accept'] = 'application/json';
      return request;
    });
    super.onInit();
  }

  Future<Response<dynamic>> login(String email, String password) =>
      post<dynamic>('/login', {
        'email': email.trim(),
        'password': password,
        'client': 'mobile',
      });

  Future<Response<dynamic>> session(String token) =>
      get<dynamic>('/session', headers: {'Authorization': 'Bearer $token'});

  Future<Response<dynamic>> logout(String token) => post<dynamic>(
    '/logout',
    const <String, dynamic>{},
    headers: {'Authorization': 'Bearer $token'},
  );
}
