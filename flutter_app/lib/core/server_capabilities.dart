import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/admin/resource_catalog.dart';
import 'providers.dart';

/// Live server capabilities, read from the API v2 meta endpoints
/// (`/resources`, `/permissions`, `/stats`, `/analytics`, `/health`,
/// `/scopes`, `/events`). Nothing here is hard-coded: the static catalog in
/// resource_catalog.dart is only used as a fallback and for descriptions.

/// One resource exactly as the live server registry reports it.
class LiveResource {
  const LiveResource({
    required this.path,
    required this.title,
    required this.module,
    required this.category,
    required this.description,
    required this.methods,
    required this.filters,
    required this.readScope,
    required this.writeScope,
  });

  final String path;
  final String title;
  final String module;
  final String category;
  final String description;
  final List<String> methods;
  final List<String> filters;
  final String? readScope;
  final String? writeScope;

  bool get canRead => methods.contains('GET');
  bool get canCreate => methods.contains('POST');
  bool get canReplace => methods.contains('PUT');
  bool get canUpdate => methods.contains('PATCH') || canReplace;
  bool get canDelete => methods.contains('DELETE');
  bool get readOnly => !canCreate && !canUpdate && !canDelete;

  ApiResource toApiResource() => ApiResource(
        path: path,
        description: description,
        module: module,
        category: category,
        methods: methods,
        filters: filters,
      );

  static LiveResource fromJson(Map<String, dynamic> json) {
    String text(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && '$value'.isNotEmpty) return '$value';
      }
      return fallback;
    }

    List<String> list(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is List) return value.map((e) => '$e').toList();
        if (value is String && value.isNotEmpty) {
          return value.split(RegExp(r'[,\s]+')).where((e) => e.isNotEmpty).toList();
        }
      }
      return const [];
    }

    final raw = text(['path', 'resource', 'name', 'endpoint']);
    final path = raw.startsWith('/') ? raw : '/$raw';
    final fallback = apiResourceFor(path);

    return LiveResource(
      path: path,
      title: text(['title', 'label'], fallback?.title ?? path),
      module: text(['module'], fallback?.module ?? ''),
      category: text(['category', 'area', 'group'], fallback?.category ?? 'System'),
      description: text(['description', 'summary'], fallback?.description ?? ''),
      methods: list(['methods', 'httpMethods']).isEmpty
          ? (fallback?.methods ?? const ['GET'])
          : list(['methods', 'httpMethods'])
              .map((m) => m.toUpperCase())
              .toList(),
      filters: list(['filters']).isEmpty
          ? (fallback?.filters ?? const [])
          : list(['filters']),
      readScope: json['readScope']?.toString() ?? json['scopeRead']?.toString(),
      writeScope:
          json['writeScope']?.toString() ?? json['scopeWrite']?.toString(),
    );
  }
}

/// Every resource the server exposes right now. Falls back to the bundled
/// catalog when the meta endpoint is unavailable.
final liveResourcesProvider =
    FutureProvider<List<LiveResource>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final rows = await api.resources();
    if (rows.isEmpty) throw StateError('empty');
    final live = rows.map(LiveResource.fromJson).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return live;
  } catch (_) {
    return apiResources
        .map((r) => LiveResource(
              path: r.path,
              title: r.title,
              module: r.module,
              category: r.category,
              description: r.description,
              methods: r.methods,
              filters: r.filters,
              readScope: null,
              writeScope: null,
            ))
        .toList();
  }
});

/// The catalog the Manage browser consumes, merged from live + bundled data.
final mergedResourceCatalogProvider =
    FutureProvider<List<ApiResource>>((ref) async {
  final live = await ref.watch(liveResourcesProvider.future);
  final byPath = <String, ApiResource>{
    for (final r in apiResources) r.path: r,
  };
  for (final r in live) {
    final existing = byPath[r.path];
    byPath[r.path] = ApiResource(
      path: r.path,
      description:
          r.description.isNotEmpty ? r.description : existing?.description ?? '',
      module: r.module.isNotEmpty ? r.module : existing?.module ?? '',
      category: r.category.isNotEmpty ? r.category : existing?.category ?? 'System',
      methods: r.methods,
      filters: r.filters.isNotEmpty ? r.filters : existing?.filters ?? const [],
    );
  }
  final all = byPath.values.toList()..sort((a, b) => a.path.compareTo(b.path));
  return all;
});

/// Actions the signed-in user may perform, straight from `/permissions`.
final serverPermissionsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiClientProvider).permissions();
});

/// School-wide counts and API usage.
final serverStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiClientProvider).stats();
});

/// The server's own dashboard payload for the signed-in user.
final serverDashboardProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiClientProvider).dashboard();
});

/// Service health (no authentication required).
final serverHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiClientProvider).health();
});

/// Request analytics for the last [days] days.
final serverAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, days) async {
  return ref.watch(apiClientProvider).analytics(days: days);
});

/// Scopes an API key can hold.
final serverScopesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(apiClientProvider).scopes();
});

/// Webhook event types the server can emit.
final webhookEventsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(apiClientProvider).webhookEvents();
});

/// The credential behind the current session (`/auth/me`).
final currentCredentialProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiClientProvider).me();
});
