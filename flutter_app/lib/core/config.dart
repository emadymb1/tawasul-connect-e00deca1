class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'TAWASUL_BASE_URL',
    defaultValue:
        'https://se.fiksutilitoimisto.fi/modules/Rest%20API/api.php/v2',
  );

  /// Requests time out after this long.
  static const Duration timeout = Duration(seconds: 30);

  static const int defaultPageSize = 50;
}
