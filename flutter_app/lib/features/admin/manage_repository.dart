import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/openapi_schema.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';
import '../../core/server_capabilities.dart';
import 'resource_catalog.dart';

/// Query for one page of a resource in the Manage browser.
class ManageQuery {
  const ManageQuery({
    required this.path,
    this.page = 1,
    this.search = '',
    this.filters = const {},
    this.sort,
  });

  final String path;
  final int page;
  final String search;
  final Map<String, String> filters;
  final String? sort;

  ManageQuery copyWith({
    int? page,
    String? search,
    Map<String, String>? filters,
    String? sort,
    bool clearSort = false,
  }) =>
      ManageQuery(
        path: path,
        page: page ?? this.page,
        search: search ?? this.search,
        filters: filters ?? this.filters,
        sort: clearSort ? null : (sort ?? this.sort),
      );

  @override
  bool operator ==(Object other) =>
      other is ManageQuery &&
      other.path == path &&
      other.page == page &&
      other.search == search &&
      other.sort == sort &&
      _sameMap(other.filters, filters);

  @override
  int get hashCode => Object.hash(path, page, search, sort,
      Object.hashAll(filters.entries.map((e) => '${e.key}=${e.value}')));

  static bool _sameMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

/// Generic create / read / update / delete over any catalogued resource.
///
/// Nothing here is specific to a table: the server's permissions decide what
/// the signed-in administrator may do, and every 403 is surfaced to the
/// permission registry so the UI hides that resource.
class ManageRepository {
  ManageRepository(this.api);
  final ApiClient api;

  OpenApiSpec? _spec;
  bool _specFailed = false;

  /// Loads `/openapi.json` once; returns null when the server does not
  /// publish it (forms then fall back to record keys).
  Future<OpenApiSpec?> spec() async {
    if (_spec != null) return _spec;
    if (_specFailed) return null;
    try {
      final raw = await api.getRaw('/openapi.json');
      if (raw is Map) {
        _spec = OpenApiSpec(raw.cast<String, dynamic>());
        return _spec;
      }
      _specFailed = true;
      return null;
    } catch (_) {
      _specFailed = true;
      return null;
    }
  }

  Future<OpenApiResourceSchema?> schemaFor(String path) async {
    final s = await spec();
    return s?.schemaFor(path);
  }

  Future<Page<Map<String, dynamic>>> list(ManageQuery q,
          {int pageSize = 30}) =>
      api.getPage(
        q.path,
        page: q.page,
        pageSize: pageSize,
        search: q.search.isEmpty ? null : q.search,
        sort: q.sort,
        filters: Map<String, dynamic>.from(q.filters),
      );

  Future<Map<String, dynamic>> read(String path, String id) =>
      api.getObject('$path/$id');

  Future<Map<String, dynamic>> create(
          String path, Map<String, dynamic> body) =>
      api.post(path, body);

  Future<Map<String, dynamic>> update(
      String path, String id, Map<String, dynamic> body,
      {bool usePut = false}) =>
      usePut ? api.put('$path/$id', body) : api.patch('$path/$id', body);

  Future<void> remove(String path, String id) => api.delete('$path/$id');

  /// Total record count for a resource (one tiny request).
  Future<int> count(String path) async {
    final page = await api.getPage(path, pageSize: 1);
    return page.total;
  }
}

final manageRepositoryProvider = Provider<ManageRepository>(
    (ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return ManageRepository(ref.watch(apiClientProvider));
});

/// The resource schema from the server specification, or null.
final resourceSchemaProvider =
    FutureProvider.family<OpenApiResourceSchema?, String>(
        (ref, path) => ref.watch(manageRepositoryProvider).schemaFor(path));

/// One page of records for a given query.
final manageListProvider =
    FutureProvider.family<Page<Map<String, dynamic>>, ManageQuery>(
        (ref, q) => ref.watch(manageRepositoryProvider).list(q));

/// A single record.
final manageRecordProvider = FutureProvider.family<Map<String, dynamic>,
    ({String path, String id})>((ref, key) =>
        ref.watch(manageRepositoryProvider).read(key.path, key.id));

/// Search text typed on the Manage home page, matched against the catalogue.
final manageCatalogueSearchProvider = StateProvider<String>((ref) => '');

/// Catalogue resources matching the search text, grouped by category.
final manageCatalogueProvider =
    Provider<Map<String, List<ApiResource>>>((ref) {
  final term = ref.watch(manageCatalogueSearchProvider).trim().toLowerCase();
  // Prefer the live registry from GET /resources; fall back to the bundled
  // catalogue while it loads or when the endpoint is unavailable.
  final catalogue =
      ref.watch(mergedResourceCatalogProvider).asData?.value ?? apiResources;
  final grouped = <String, List<ApiResource>>{};
  for (final r in catalogue) {
    if (term.isNotEmpty &&
        !r.path.contains(term) &&
        !r.title.toLowerCase().contains(term) &&
        !r.description.toLowerCase().contains(term) &&
        !r.module.toLowerCase().contains(term)) {
      continue;
    }
    grouped.putIfAbsent(r.category, () => []).add(r);
  }
  return grouped;
});
