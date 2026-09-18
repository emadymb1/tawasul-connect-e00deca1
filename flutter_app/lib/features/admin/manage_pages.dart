import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api_exception.dart';
import '../../core/openapi_schema.dart';
import '../../core/permissions.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';
import 'manage_repository.dart';
import 'module_pages.dart';
import 'resource_catalog.dart';

// ---------------------------------------------------------------------------
// Manage home: every server resource, grouped by category, searchable.
// ---------------------------------------------------------------------------

class AdminManagePage extends ConsumerWidget {
  const AdminManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final grouped = ref.watch(manageCatalogueProvider);
    final denied = ref.watch(permissionRegistryProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(strings.manage,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(strings.manageSubtitle,
            style: const TextStyle(color: TawasulColors.muted)),
        const SizedBox(height: 14),
        TextField(
          decoration: InputDecoration(
            hintText: strings.searchResources,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
          onChanged: (value) =>
              ref.read(manageCatalogueSearchProvider.notifier).state = value,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.widgets_rounded,
                color: TawasulColors.forest),
            title: Text(strings.openModules,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(strings.modulesSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(strings.modules)),
                  body: const AdminModulesPage(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final category in apiResourceCategories)
          if (grouped[category] != null && grouped[category]!.isNotEmpty) ...[
            SectionCard(
              title:
                  '${strings.categoryName(category)} · ${grouped[category]!.length}',
              children: grouped[category]!
                  .where((r) => !denied.contains(r.path))
                  .map((r) => DetailRow(
                        title: r.title,
                        subtitle: r.description,
                        trailing: r.readOnly
                            ? StatusPill(
                                label: strings.readOnly,
                                color: TawasulColors.muted)
                            : const Icon(Icons.chevron_right_rounded,
                                color: TawasulColors.muted),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ResourceListPage(resource: r),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        if (denied.isNotEmpty)
          Text(strings.hiddenByPermissions,
              style: const TextStyle(
                  color: TawasulColors.muted, fontSize: 12)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Resource list: search, filters, paging, add button.
// ---------------------------------------------------------------------------

class ResourceListPage extends ConsumerStatefulWidget {
  const ResourceListPage({super.key, required this.resource});
  final ApiResource resource;

  @override
  ConsumerState<ResourceListPage> createState() => _ResourceListPageState();
}

class _ResourceListPageState extends ConsumerState<ResourceListPage> {
  late ManageQuery _query = ManageQuery(path: widget.resource.path);
  final _search = TextEditingController();

  /// Bulk actions: record ids ticked on the current page.
  bool _selecting = false;
  final Set<String> _selected = {};
  bool _bulkBusy = false;

  void _toggleSelecting() => setState(() {
        _selecting = !_selecting;
        if (!_selecting) _selected.clear();
      });

  Future<void> _deleteSelected() async {
    final strings = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.deleteSelected),
        content: Text(strings.bulkDeleteQuestion),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(strings.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TawasulColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _bulkBusy = true);
    final repo = ref.read(manageRepositoryProvider);
    var done = 0;
    final failed = <String>[];
    for (final id in _selected.toList()) {
      try {
        await repo.remove(widget.resource.path, id);
        done++;
      } catch (_) {
        failed.add(id);
      }
    }
    ref.invalidate(manageListProvider);
    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selected
        ..clear()
        ..addAll(failed);
      _selecting = failed.isNotEmpty;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: failed.isEmpty ? null : TawasulColors.red,
      content: Text(failed.isEmpty
          ? '${strings.bulkDone}: $done'
          : '${strings.bulkDone}: $done · ${failed.length} ${strings.bulkFailed}'),
    ));
  }

  String? _idOf(Map<String, dynamic> row, OpenApiResourceSchema? schema) {
    final field =
        schema?.idField ?? guessIdField(row, table: widget.resource.primaryTable);
    return field == null ? null : row[field]?.toString();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _set(ManageQuery q) => setState(() => _query = q);

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(
        filters: widget.resource.filters,
        current: _query.filters,
      ),
    );
    if (result != null) _set(_query.copyWith(filters: result, page: 1));
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final r = widget.resource;
    final page = ref.watch(manageListProvider(_query));
    final schema = ref.watch(resourceSchemaProvider(r.path));

    return Scaffold(
      appBar: AppBar(
        title: Text(r.title),
        actions: [
          if (r.canDelete)
            IconButton(
              tooltip: _selecting ? strings.clearSelection : strings.select,
              onPressed: _bulkBusy ? null : _toggleSelecting,
              icon: Icon(_selecting
                  ? Icons.close_rounded
                  : Icons.checklist_rounded),
            ),
          IconButton(
            tooltip: strings.exportCsv,
            onPressed: () => exportResourceCsv(context, ref, r.path,
                filters: _query.filters),
            icon: const Icon(Icons.download_rounded),
          ),
          if (r.filters.isNotEmpty)
            IconButton(
              tooltip: strings.filters,
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: _query.filters.isNotEmpty,
                label: Text('${_query.filters.length}'),
                child: const Icon(Icons.filter_list_rounded),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _selecting
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${_selected.length} ${strings.selectedCount}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: TawasulColors.red),
                      onPressed: _selected.isEmpty || _bulkBusy
                          ? null
                          : _deleteSelected,
                      icon: _bulkBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline_rounded),
                      label: Text(strings.deleteSelected),
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButton: r.canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => RecordFormPage(
                      resource: r,
                      schema: schema.valueOrNull,
                    ),
                  ),
                );
                if (created == true) ref.invalidate(manageListProvider);
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.create),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(manageListProvider(_query)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(r.description,
                style: const TextStyle(color: TawasulColors.muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(text: '${strings.module}: ${r.module}'),
                for (final m in r.methods) _Chip(text: m, strong: true),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          _set(_query.copyWith(search: '', page: 1));
                        },
                      ),
              ),
              onSubmitted: (value) =>
                  _set(_query.copyWith(search: value.trim(), page: 1)),
            ),
            const SizedBox(height: 16),
            page.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SectionCard(title: r.title, children: [
                Text(
                  e is ApiException && e.isForbidden
                      ? strings.noPermission
                      : e is ApiException
                          ? e.message
                          : '$e',
                  style: const TextStyle(color: TawasulColors.red),
                ),
                TextButton(
                    onPressed: () =>
                        ref.invalidate(manageListProvider(_query)),
                    child: Text(strings.retry)),
              ]),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: '${strings.records} · ${data.total}',
                    children: data.items.isEmpty
                        ? [Text(strings.nothingHere)]
                        : [
                            if (_selecting)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: TextButton.icon(
                                  onPressed: () => setState(() {
                                    final ids = data.items
                                        .map((row) =>
                                            _idOf(row, schema.valueOrNull))
                                        .whereType<String>()
                                        .toSet();
                                    if (ids.every(_selected.contains)) {
                                      _selected.removeAll(ids);
                                    } else {
                                      _selected.addAll(ids);
                                    }
                                  }),
                                  icon: const Icon(
                                      Icons.select_all_rounded, size: 18),
                                  label: Text(strings.selectAll),
                                ),
                              ),
                            ...data.items.map((row) {
                              final id = _idOf(row, schema.valueOrNull);
                              return _RecordRow(
                                resource: r,
                                record: row,
                                schema: schema.valueOrNull,
                                selecting: _selecting,
                                selected:
                                    id != null && _selected.contains(id),
                                onSelectedChanged: id == null
                                    ? null
                                    : (value) => setState(() {
                                          if (value) {
                                            _selected.add(id);
                                          } else {
                                            _selected.remove(id);
                                          }
                                        }),
                              );
                            }),
                          ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: data.page > 1
                            ? () =>
                                _set(_query.copyWith(page: data.page - 1))
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        label: Text(strings.previousPage),
                      ),
                      Text('${data.page} / ${data.totalPages}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: data.hasMore
                            ? () =>
                                _set(_query.copyWith(page: data.page + 1))
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        label: Text(strings.nextPage),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.strong = false});
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: strong ? TawasulColors.mint : TawasulColors.card,
          border: Border.all(color: TawasulColors.mint),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                color: TawasulColors.forestDeep)),
      );
}

/// Picks a sensible one-line label for an arbitrary record.
String recordTitle(Map<String, dynamic> row) {
  const preferred = [
    'name',
    'title',
    'preferredName',
    'surname',
    'username',
    'nameShort',
    'text',
    'subject',
    'descriptor',
    'date',
    'timestamp',
  ];
  final parts = <String>[];
  if (row['preferredName'] != null || row['surname'] != null) {
    parts.add('${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'.trim());
  }
  for (final key in preferred) {
    final v = row[key];
    if (v != null && '$v'.isNotEmpty && !parts.contains('$v')) {
      parts.add('$v');
      if (parts.length >= 2) break;
    }
  }
  if (parts.isEmpty) {
    final first = row.entries
        .where((e) => e.value != null && e.value is! Map && e.value is! List)
        .take(2)
        .map((e) => '${e.value}');
    parts.addAll(first);
  }
  return parts.where((p) => p.isNotEmpty).join(' · ');
}

String recordSubtitle(Map<String, dynamic> row, String? idField) {
  final skip = {
    'name',
    'title',
    'preferredName',
    'surname',
    'username',
    'nameShort',
    idField ?? '',
  };
  final extras = row.entries
      .where((e) =>
          !skip.contains(e.key) &&
          e.value != null &&
          '${e.value}'.isNotEmpty &&
          e.value is! Map &&
          e.value is! List &&
          !e.key.endsWith('ID'))
      .take(3)
      .map((e) => '${e.value}');
  return extras.join(' · ');
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.resource,
    required this.record,
    required this.schema,
    this.selecting = false,
    this.selected = false,
    this.onSelectedChanged,
  });
  final ApiResource resource;
  final Map<String, dynamic> record;
  final OpenApiResourceSchema? schema;
  final bool selecting;
  final bool selected;
  final void Function(bool value)? onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final idField = schema?.idField ??
        guessIdField(record, table: resource.primaryTable);
    final id = idField == null ? null : record[idField]?.toString();

    if (selecting) {
      return CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: selected,
        onChanged: onSelectedChanged == null
            ? null
            : (value) => onSelectedChanged!(value ?? false),
        title: Text(recordTitle(record)),
        subtitle: Text(
          onSelectedChanged == null
              ? S.of(context).noIdField
              : recordSubtitle(record, idField),
          style: const TextStyle(color: TawasulColors.muted, fontSize: 12),
        ),
      );
    }

    return DetailRow(
      title: recordTitle(record),
      subtitle: recordSubtitle(record, idField),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: TawasulColors.muted),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecordDetailPage(
          resource: resource,
          record: record,
          id: id,
          idField: idField,
        ),
      )),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter sheet: one text field per documented filter.
// ---------------------------------------------------------------------------

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filters, required this.current});
  final List<String> filters;
  final Map<String, String> current;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.filters)
      f: TextEditingController(text: widget.current[f] ?? ''),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(strings.filters,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final f in widget.filters) ...[
            TextField(
              controller: _controllers[f],
              decoration: InputDecoration(
                labelText: f.contains('.') ? f.split('.').last : f,
                helperText: f,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(const {}),
                  child: Text(strings.clearFilters),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final result = <String, String>{};
                    _controllers.forEach((key, c) {
                      if (c.text.trim().isNotEmpty) {
                        result[key] = c.text.trim();
                      }
                    });
                    Navigator.of(context).pop(result);
                  },
                  child: Text(strings.applyFilters),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Record detail: every field, edit and delete.
// ---------------------------------------------------------------------------

class RecordDetailPage extends ConsumerStatefulWidget {
  const RecordDetailPage({
    super.key,
    required this.resource,
    required this.record,
    required this.id,
    required this.idField,
  });

  final ApiResource resource;
  final Map<String, dynamic> record;
  final String? id;
  final String? idField;

  @override
  ConsumerState<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends ConsumerState<RecordDetailPage> {
  late Map<String, dynamic> _record = widget.record;
  bool _busy = false;

  Future<void> _reload() async {
    if (widget.id == null) return;
    try {
      final fresh = await ref
          .read(manageRepositoryProvider)
          .read(widget.resource.path, widget.id!);
      if (mounted) setState(() => _record = fresh);
    } catch (_) {
      // Keep the copy we already have.
    }
  }

  Future<void> _delete() async {
    final strings = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.deleteQuestion),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(strings.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: TawasulColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (ok != true || widget.id == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(manageRepositoryProvider)
          .remove(widget.resource.path, widget.id!);
      ref.invalidate(manageListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.deleted)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : '$e'),
        backgroundColor: TawasulColors.red,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final r = widget.resource;
    final schema = ref.watch(resourceSchemaProvider(r.path));

    final entries = _record.entries.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(recordTitle(_record).isEmpty ? r.title : recordTitle(_record)),
        actions: [
          if (r.canUpdate && widget.id != null)
            IconButton(
              tooltip: strings.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: _busy
                  ? null
                  : () async {
                      final changed =
                          await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => RecordFormPage(
                            resource: r,
                            schema: schema.valueOrNull,
                            existing: _record,
                            id: widget.id,
                          ),
                        ),
                      );
                      if (changed == true) {
                        ref.invalidate(manageListProvider);
                        await _reload();
                      }
                    },
            ),
          if (r.canDelete && widget.id != null)
            IconButton(
              tooltip: strings.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(text: r.title, strong: true),
                if (widget.id != null)
                  _Chip(text: '${widget.idField ?? 'id'} = ${widget.id}'),
                if (r.readOnly) _Chip(text: strings.readOnly),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: strings.record,
              children: entries
                  .map((e) => _FieldLine(name: e.key, value: e.value))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLine extends StatelessWidget {
  const _FieldLine({required this.name, required this.value});
  final String name;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? '—'
        : value is Map || value is List
            ? value.toString()
            : '$value';
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).copied)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 12,
                    color: TawasulColors.muted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            SelectableText(text,
                style: const TextStyle(fontSize: 15, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create / edit form driven by the server schema (or the record's own keys).
// ---------------------------------------------------------------------------

class RecordFormPage extends ConsumerStatefulWidget {
  const RecordFormPage({
    super.key,
    required this.resource,
    required this.schema,
    this.existing,
    this.id,
  });

  final ApiResource resource;
  final OpenApiResourceSchema? schema;
  final Map<String, dynamic>? existing;
  final String? id;

  bool get isEdit => existing != null && id != null;

  @override
  ConsumerState<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends ConsumerState<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<OpenApiField> _fields = _buildFields();
  late final Map<String, TextEditingController> _text = {
    for (final f in _fields)
      if (!f.isBoolean && !f.isYesNo && f.enumValues.isEmpty)
        f.name: TextEditingController(
            text: _initial(f.name)),
  };
  late final Map<String, String?> _choice = {
    for (final f in _fields)
      if (f.enumValues.isNotEmpty || f.isBoolean)
        f.name: _initial(f.name).isEmpty ? null : _initial(f.name),
  };
  final Set<String> _touched = {};
  bool _saving = false;

  String _initial(String name) {
    final v = widget.existing?[name];
    if (v == null) return '';
    if (v is bool) return v ? 'true' : 'false';
    return '$v';
  }

  /// Fields from the spec; otherwise every scalar key of the existing record
  /// (minus the primary key and obvious server-managed stamps).
  List<OpenApiField> _buildFields() {
    final schema = widget.schema;
    final fromSpec =
        widget.isEdit ? schema?.updateFields : schema?.createFields;
    if (fromSpec != null && fromSpec.isNotEmpty) {
      return fromSpec.where((f) => !f.readOnly).toList();
    }
    final source = widget.existing ?? const <String, dynamic>{};
    final idField = schema?.idField ??
        guessIdField(source, table: widget.resource.primaryTable);
    const serverManaged = {
      'timestampCreated',
      'timestampUpdated',
      'timestamp',
      'gibbonPersonIDCreator',
      'gibbonPersonIDUpdate',
    };
    return source.entries
        .where((e) =>
            e.key != idField &&
            !serverManaged.contains(e.key) &&
            e.value is! Map &&
            e.value is! List)
        .map((e) => OpenApiField(
              name: e.key,
              type: e.value is num
                  ? 'number'
                  : e.value is bool
                      ? 'boolean'
                      : 'string',
              enumValues: (e.value == 'Y' || e.value == 'N')
                  ? const ['Y', 'N']
                  : const [],
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _collect() {
    final body = <String, dynamic>{};
    for (final f in _fields) {
      dynamic value;
      if (_choice.containsKey(f.name)) {
        final v = _choice[f.name];
        if (v == null) continue;
        value = f.isBoolean ? (v == 'true' || v == 'Y' || v == '1') : v;
      } else {
        final raw = _text[f.name]!.text;
        if (raw.isEmpty) {
          if (!widget.isEdit) continue;
          if (!_touched.contains(f.name)) continue;
          value = null;
        } else if (f.isNumeric) {
          value = num.tryParse(raw) ?? raw;
        } else {
          value = raw;
        }
      }
      // On edit only send what changed, so PATCH stays minimal.
      if (widget.isEdit) {
        final before = _initial(f.name);
        final after = value == null ? '' : '$value';
        if (before == after && !_touched.contains(f.name)) continue;
      }
      body[f.name] = value;
    }
    return body;
  }

  Future<void> _save() async {
    final strings = S.of(context);
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final body = _collect();
    if (body.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(manageRepositoryProvider);
    try {
      if (widget.isEdit) {
        final usePut = !widget.resource.methods.contains('PATCH') &&
            widget.resource.methods.contains('PUT');
        await repo.update(widget.resource.path, widget.id!, body,
            usePut: usePut);
      } else {
        await repo.create(widget.resource.path, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.saved)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : '$e'),
        backgroundColor: TawasulColors.red,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(OpenApiField f) async {
    final c = _text[f.name]!;
    final initial = DateTime.tryParse(c.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final ymd = '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      c.text = ymd;
      _touched.add(f.name);
    });
  }

  Widget _fieldWidget(OpenApiField f, S strings) {
    final label = f.required ? '${f.name} *' : f.name;

    if (f.isBoolean || f.enumValues.isNotEmpty) {
      final options = f.isBoolean && f.enumValues.isEmpty
          ? const ['true', 'false']
          : f.enumValues;
      return DropdownButtonFormField<String>(
        value: options.contains(_choice[f.name]) ? _choice[f.name] : null,
        decoration: InputDecoration(labelText: label, helperText: f.description),
        items: [
          if (!f.required)
            const DropdownMenuItem<String>(value: null, child: Text('—')),
          for (final o in options)
            DropdownMenuItem<String>(
              value: o,
              child: Text(f.isYesNo
                  ? (o == 'Y' ? strings.yes : strings.no)
                  : o),
            ),
        ],
        validator: (v) =>
            f.required && (v == null || v.isEmpty) ? strings.requiredField : null,
        onChanged: (v) => setState(() {
          _choice[f.name] = v;
          _touched.add(f.name);
        }),
      );
    }

    final controller = _text[f.name]!;
    return TextFormField(
      controller: controller,
      readOnly: f.isDate,
      onTap: f.isDate ? () => _pickDate(f) : null,
      maxLines: f.isLong ? 4 : 1,
      keyboardType: f.isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : f.name.toLowerCase().contains('email')
              ? TextInputType.emailAddress
              : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: f.description ??
            (f.isDate
                ? 'YYYY-MM-DD'
                : f.isDateTime
                    ? 'YYYY-MM-DD HH:MM:SS'
                    : f.isTime
                        ? 'HH:MM:SS'
                        : null),
        suffixIcon: f.isDate ? const Icon(Icons.event_outlined) : null,
      ),
      validator: (v) {
        if (f.required && (v == null || v.trim().isEmpty)) {
          return strings.requiredField;
        }
        if (f.isNumeric && v != null && v.isNotEmpty && num.tryParse(v) == null) {
          return strings.numberExpected;
        }
        return null;
      },
      onChanged: (_) => _touched.add(f.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final title = widget.isEdit
        ? '${strings.edit} · ${widget.resource.title}'
        : '${strings.create} · ${widget.resource.title}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            if (widget.schema == null || _fields.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: TawasulColors.sage,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _fields.isEmpty ? strings.noSchemaNoRecord : strings.noSchema,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            for (final f in _fields) ...[
              _fieldWidget(f, strings),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving || _fields.isEmpty ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(strings.save),
          ),
        ),
      ),
    );
  }
}
