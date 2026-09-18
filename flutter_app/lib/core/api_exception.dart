class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.requestId});

  final int statusCode;
  final String message;
  final String? requestId;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  /// The request never reached the server (no network / timeout).
  bool get isOffline => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
