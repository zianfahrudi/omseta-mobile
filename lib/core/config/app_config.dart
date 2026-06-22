/// Global application configuration.
class AppConfig {
  AppConfig._();

  /// API base URL.
  ///
  /// Defaults to production, but can be overridden at run/build time without
  /// touching the code, e.g. for local development:
  ///
  /// ```
  /// flutter run --dart-define=API_BASE_URL=http://localhost:18080/api/v1
  /// ```
  ///
  /// Catatan pemilihan host saat memakai server lokal:
  /// - Desktop (macOS/Windows) & iOS Simulator : http://localhost:18080/api/v1
  /// - Android Emulator                        : http://10.0.2.2:18080/api/v1
  /// - HP fisik (Android/iOS) di Wi-Fi sama    : http://<IP-LAN-komputer>:18080/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://omseta.ziandev.site/api/v1',
  );

  /// Request timeout.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
