class AppConfig {
  const AppConfig._();

  static const _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
    return 'http://10.175.194.43:3000/api/v1';
  }

  static String get serverBaseUrl => apiBaseUrl.endsWith('/api/v1')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - '/api/v1'.length)
      : apiBaseUrl;

  static String get authBaseUrl => '$serverBaseUrl/api/auth';
}
