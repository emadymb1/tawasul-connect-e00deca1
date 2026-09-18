import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remembers every endpoint the server answered with 403 for the signed-in
/// user, so the UI can hide those areas instead of showing an error.
class PermissionRegistry extends StateNotifier<Set<String>> {
  PermissionRegistry() : super(const {});

  void deny(String path) {
    final normalised = _normalise(path);
    if (state.contains(normalised)) return;
    state = {...state, normalised};
  }

  void allow(String path) {
    final normalised = _normalise(path);
    if (!state.contains(normalised)) return;
    state = {...state}..remove(normalised);
  }

  void reset() => state = const {};

  bool isDenied(String path) => state.contains(_normalise(path));

  static String _normalise(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    final parts = clean.split('/').where((p) => p.isNotEmpty).toList();
    // Keep the collection name only: /messages/42 -> /messages
    return parts.isEmpty ? '/' : '/${parts.first}';
  }
}

final permissionRegistryProvider =
    StateNotifierProvider<PermissionRegistry, Set<String>>(
        (ref) => PermissionRegistry());

/// True when the signed-in user has already been refused this endpoint.
final endpointDeniedProvider = Provider.family<bool, String>((ref, path) {
  ref.watch(permissionRegistryProvider);
  return ref.read(permissionRegistryProvider.notifier).isDenied(path);
});

/// True when at least one of the endpoints has been refused.
final anyEndpointDeniedProvider =
    Provider.family<bool, List<String>>((ref, paths) {
  ref.watch(permissionRegistryProvider);
  final registry = ref.read(permissionRegistryProvider.notifier);
  return paths.any(registry.isDenied);
});
