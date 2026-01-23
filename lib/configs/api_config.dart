class ApiConfig {

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://103.6.168.136/api',
  );
}
