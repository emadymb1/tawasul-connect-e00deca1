import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'offline_cache.dart';
import 'permissions.dart';
import 'token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final offlineCacheProvider = Provider<OfflineCache>((ref) => OfflineCache());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    tokens: ref.watch(tokenStoreProvider),
    cache: ref.watch(offlineCacheProvider),
  );
  client.onForbidden = (path) {
    ref.read(permissionRegistryProvider.notifier).deny(path);
  };
  client.onCacheStateChanged = (fromCache) {
    ref.read(offlineModeProvider.notifier).state = fromCache;
  };
  return client;
});

/// True when the last screen data was served from the offline cache.
final offlineModeProvider = StateProvider<bool>((ref) => false);

final servingFromCacheProvider = Provider<bool>((ref) {
  ref.watch(apiClientProvider);
  return ref.watch(offlineModeProvider);
});
