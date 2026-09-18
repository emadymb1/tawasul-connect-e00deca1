import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'config.dart';
import 'offline_cache.dart';
import 'token_store.dart';

/// A page of records plus the server's meta block.
class Page<T> {
  Page({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Thin client over the Tawasul (Gibbon) REST API.
///
/// Collections accept `page`, `pageSize`, `sort`, `search`, `fields` and
/// resource filters whose names are dotted, e.g.
/// `gibbonStudentEnrolment.gibbonPersonID`. `gibbonSchoolYearID` can be added to
/// any request to work in another school year.
class ApiClient {
  ApiClient({required this.tokens, http.Client? httpClient, OfflineCache? cache})
      : _http = httpClient ?? http.Client(),
        cache = cache ?? OfflineCache();

  final TokenStore tokens;
  final http.Client _http;

  /// Last-known responses, used only when the device cannot reach the server.
  final OfflineCache cache;

  /// Set to work in a school year other than the current one.
  String? schoolYearId;

  /// The signed-in account's own school year, kept so the year switcher can
  /// return to it.
  String? defaultSchoolYearId;

  /// Called when the token can no longer be renewed, so the app can sign out.
  void Function()? onSessionExpired;

  /// Called with the endpoint path whenever the server answers 403, so the UI
  /// can hide the areas this user is not allowed to see.
  void Function(String path)? onForbidden;

  /// Called whenever the app starts or stops serving stored data.
  void Function(bool fromCache)? onCacheStateChanged;

  bool _servingFromCache = false;

  /// True when the most recent screen data came from the offline cache.
  bool get servingFromCache => _servingFromCache;

  set servingFromCache(bool value) {
    if (_servingFromCache == value) return;
    _servingFromCache = value;
    onCacheStateChanged?.call(value);
  }

  /// When the cached copy that was last served was stored.
  DateTime? cacheStamp;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalised = path.startsWith('/') ? path : '/$path';
    final params = <String, String>{};
    if (schoolYearId != null) params['gibbonSchoolYearID'] = schoolYearId!;
    query?.forEach((key, value) {
      if (value == null) return;
      params[key] = '$value';
    });
    return Uri.parse('${AppConfig.baseUrl}$normalised')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final session = await tokens.read();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.token}',
    };
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool allowRetry = true,
  }) async {
    final uri = _uri(path, query);
    final isRead = method == 'GET';
    final signature = '$method $uri';

    final http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(await _headers(json: body != null));
      if (body != null) request.body = jsonEncode(body);

      final streamed = await _http.send(request).timeout(AppConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException catch (_) {
      return _fromCacheOrThrow(isRead, signature,
          'No connection to the school server.');
    } on TimeoutException catch (_) {
      return _fromCacheOrThrow(isRead, signature,
          'The school server took too long to answer.');
    } on http.ClientException catch (_) {
      return _fromCacheOrThrow(isRead, signature,
          'No connection to the school server.');
    }

    if (response.statusCode == 401 && allowRetry) {
      final renewed = await _refresh();
      if (renewed) {
        return _send(method, path,
            query: query, body: body, allowRetry: false);
      }
      onSessionExpired?.call();
    }

    final decoded = response.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 400) {
      if (response.statusCode == 403) onForbidden?.call(path);
      String message = 'Request failed (${response.statusCode})';
      String? requestId;
      if (decoded is Map) {
        // v2 shape: {"error":{"code","message","details"},"meta":{"requestID"}}
        final error = decoded['error'];
        if (error is Map) {
          message = (error['message'] ?? error['code'] ?? message).toString();
        } else {
          message = (decoded['detail'] ??
                  decoded['title'] ??
                  decoded['message'] ??
                  message)
              .toString();
        }
        final meta = decoded['meta'];
        requestId = (meta is Map ? meta['requestID'] : null)?.toString() ??
            decoded['requestID']?.toString();
      }
      throw ApiException(response.statusCode, message, requestId: requestId);
    }

    if (isRead) {
      servingFromCache = false;
      cacheStamp = null;
      unawaited(cache.write(signature, decoded));
    }
    return decoded;
  }

  /// Offline fallback: serve the last successful copy of this exact request.
  Future<dynamic> _fromCacheOrThrow(
      bool isRead, String signature, String message) async {
    if (isRead) {
      final cached = await cache.read(signature);
      if (cached != null) {
        servingFromCache = true;
        cacheStamp = cached.storedAt;
        return cached.body;
      }
    }
    throw ApiException(0, message);
  }

  Future<bool> _refresh() async {
    final session = tokens.current ?? await tokens.read();
    final refreshToken = session?.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await _http
          .post(
            _uri('/auth/refresh'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(AppConfig.timeout);
      if (response.statusCode >= 400) return false;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final map = data is Map && data['data'] is Map
          ? data['data'] as Map
          : data as Map;
      final token = (map['token'] ?? map['accessToken'])?.toString();
      if (token == null) return false;
      await tokens.save(StoredSession(
        token: token,
        refreshToken:
            (map['refreshToken'] ?? refreshToken).toString(),
        expiresAt: DateTime.tryParse(map['expiresAt']?.toString() ?? ''),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Single object (or the `data` object of a wrapped response).
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final decoded = await _send('GET', path, query: query);
    if (decoded is Map && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  /// Collection endpoint.
  Future<Page<Map<String, dynamic>>> getPage(
    String path, {
    int page = 1,
    int? pageSize,
    String? sort,
    String? search,
    String? fields,
    Map<String, dynamic> filters = const {},
  }) async {
    final decoded = await _send('GET', path, query: {
      'page': page,
      'pageSize': pageSize ?? AppConfig.defaultPageSize,
      if (sort != null) 'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
      if (fields != null) 'fields': fields,
      ...filters,
    });

    final map = decoded as Map;
    final items = (map['data'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final meta = Map<String, dynamic>.from(map['meta'] as Map? ?? const {});
    int intOf(String key, int fallback) =>
        int.tryParse('${meta[key] ?? fallback}') ?? fallback;

    return Page(
      items: items,
      page: intOf('page', page),
      pageSize: intOf('pageSize', pageSize ?? AppConfig.defaultPageSize),
      total: intOf('total', items.length),
      totalPages: intOf('totalPages', 1),
    );
  }

  /// Convenience: just the records of the first page.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    int pageSize = AppConfig.defaultPageSize,
    String? sort,
    String? search,
    String? fields,
    Map<String, dynamic> filters = const {},
  }) async {
    final result = await getPage(
      path,
      pageSize: pageSize,
      sort: sort,
      search: search,
      fields: fields,
      filters: filters,
    );
    return result.items;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body)
          .then((d) => _unwrap(d));

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body).then((d) => _unwrap(d));

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body).then((d) => _unwrap(d));

  Future<void> delete(String path) => _send('DELETE', path);

  /// Raw GET that returns whatever JSON the server sends (used for
  /// `/openapi.json`, which is not wrapped in a `data` envelope).
  Future<dynamic> getRaw(String path) => _send('GET', path);

  Map<String, dynamic> _unwrap(dynamic decoded) {
    if (decoded is Map && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }

  /// Unauthenticated login call.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _http
        .post(
          _uri('/auth/login'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(AppConfig.timeout);

    final decoded = response.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      final message = decoded is Map
          ? (decoded['detail'] ?? decoded['title'] ?? 'Sign in failed')
              .toString()
          : 'Sign in failed';
      throw ApiException(response.statusCode, message);
    }
    return _unwrap(decoded);
  }
}
