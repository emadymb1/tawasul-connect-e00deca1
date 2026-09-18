import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  StoredSession({
    required this.token,
    this.refreshToken,
    this.expiresAt,
  });

  final String token;
  final String? refreshToken;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
        'token': token,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  static StoredSession? fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    if (token == null || token.isEmpty) return null;
    final expires = json['expiresAt'] as String?;
    return StoredSession(
      token: token,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: expires == null ? null : DateTime.tryParse(expires),
    );
  }
}

/// Keeps the per-user token in the device keychain / keystore.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'tawasul.session';

  final FlutterSecureStorage _storage;
  StoredSession? _cached;

  StoredSession? get current => _cached;

  Future<StoredSession?> read() async {
    if (_cached != null) return _cached;
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      _cached = StoredSession.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clear();
    }
    return _cached;
  }

  Future<void> save(StoredSession session) async {
    _cached = session;
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
