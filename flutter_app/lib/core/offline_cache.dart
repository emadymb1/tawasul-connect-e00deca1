import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores the last successful response of every GET request so the app can
/// still show the previous data when the phone is offline.
///
/// Nothing here invents data: entries are written only after the server
/// answered, and they are served only when the network call fails.
class OfflineCache {
  OfflineCache({this.maxAge = const Duration(days: 3)});

  static const _prefix = 'tawasul.cache.';

  final Duration maxAge;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _store() async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _key(String signature) =>
      '$_prefix${base64Url.encode(utf8.encode(signature))}';

  Future<void> write(String signature, dynamic decoded) async {
    if (decoded == null) return;
    try {
      final prefs = await _store();
      await prefs.setString(
        _key(signature),
        jsonEncode({
          'at': DateTime.now().toIso8601String(),
          'body': decoded,
        }),
      );
    } catch (_) {
      // Caching must never break a request.
    }
  }

  /// Returns the cached body, or null when nothing usable is stored.
  Future<CachedResponse?> read(String signature) async {
    try {
      final prefs = await _store();
      final raw = prefs.getString(_key(signature));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse('${map['at']}');
      if (at == null || DateTime.now().difference(at) > maxAge) return null;
      return CachedResponse(body: map['body'], storedAt: at);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await _store();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(_prefix)) await prefs.remove(key);
      }
    } catch (_) {
      // ignore
    }
  }
}

class CachedResponse {
  CachedResponse({required this.body, required this.storedAt});

  final dynamic body;
  final DateTime storedAt;
}
