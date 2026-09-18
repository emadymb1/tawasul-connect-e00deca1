import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/local_notifications.dart';
import '../../core/permissions.dart';
import '../../core/providers.dart';
import '../../core/token_store.dart';
import 'models.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.busy = false,
  });

  final AuthStatus status;
  final SessionUser? user;
  final String? error;
  final bool busy;

  AuthState copyWith({
    AuthStatus? status,
    SessionUser? user,
    String? error,
    bool? busy,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        busy: busy ?? this.busy,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api, this._tokens) : super(const AuthState()) {
    _api.onSessionExpired = signOutLocally;
    restore();
  }

  final ApiClient _api;
  final TokenStore _tokens;

  /// Re-use a stored token on app launch.
  Future<void> restore() async {
    final stored = await _tokens.read();
    if (stored == null) {
      state = const AuthState(status: AuthStatus.signedOut);
      return;
    }
    try {
      final me = await _api.getObject('/auth/me');
      final user = SessionUser.fromJson(me);
      _api.schoolYearId = user.schoolYearId;
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } on ApiException {
      await _tokens.clear();
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<bool> signIn(String username, String password) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final result = await _api.login(username.trim(), password);
      final token =
          (result['token'] ?? result['accessToken'])?.toString();
      if (token == null) {
        state = state.copyWith(busy: false, error: 'missing_token');
        return false;
      }
      await _tokens.save(StoredSession(
        token: token,
        refreshToken: result['refreshToken']?.toString(),
        expiresAt: DateTime.tryParse(result['expiresAt']?.toString() ?? ''),
      ));

      SessionUser user;
      if (result['user'] is Map || result['person'] is Map) {
        user = SessionUser.fromJson(result);
      } else {
        user = SessionUser.fromJson(await _api.getObject('/auth/me'));
      }
      _api.schoolYearId = user.schoolYearId;
      state = AuthState(status: AuthStatus.signedIn, user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(busy: false, error: 'network');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout', const {});
    } catch (_) {
      // Signing out locally is enough if the server call fails.
    }
    await signOutLocally();
  }

  Future<void> signOutLocally() async {
    await _tokens.clear();
    // The next user on this device must not see the previous person's data.
    await _api.cache.clear();
    onSignedOut?.call();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  /// Lets the app clear per-user state (permissions, notification history).
  void Function()? onSignedOut;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  );
  controller.onSignedOut = () {
    ref.read(permissionRegistryProvider.notifier).reset();
    ref.read(offlineModeProvider.notifier).state = false;
    LocalNotifications.instance.clearSeen();
  };
  return controller;
});

final currentUserProvider = Provider<SessionUser?>(
    (ref) => ref.watch(authControllerProvider).user);
