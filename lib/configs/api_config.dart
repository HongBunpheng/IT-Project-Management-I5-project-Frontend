class ApiConfig {
  /// Base URL for your Laravel API (include `/api`).
  ///
  /// Examples:
  /// - Android emulator: `http://10.0.2.2:8000/api`
  /// - iOS simulator: `http://localhost:8000/api`
  /// - Physical device: `http://<your-lan-ip>:8000/api`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.117:8000/api',
  );
}
