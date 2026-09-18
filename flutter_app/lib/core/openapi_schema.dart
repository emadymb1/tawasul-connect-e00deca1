/// Reads the server's `/openapi.json` once per session and answers two
/// questions for any resource path:
///
///  * which fields a POST / PATCH body accepts (name, type, enum, required),
///  * which field is the record's primary key.
///
/// Everything degrades gracefully: when the specification cannot be loaded
/// the admin forms fall back to the keys of an existing record.
class OpenApiField {
  const OpenApiField({
    required this.name,
    required this.type,
    this.format,
    this.enumValues = const [],
    this.required = false,
    this.readOnly = false,
    this.description,
    this.maxLength,
  });

  final String name;

  /// `string`, `integer`, `number`, `boolean`, `array`, `object`.
  final String type;
  final String? format;
  final List<String> enumValues;
  final bool required;
  final bool readOnly;
  final String? description;
  final int? maxLength;

  bool get isDate => format == 'date';
  bool get isDateTime => format == 'date-time';
  bool get isTime => format == 'time';
  bool get isBoolean => type == 'boolean';
  bool get isNumeric => type == 'integer' || type == 'number';
  bool get isLong =>
      type == 'string' && (maxLength == null || maxLength! > 255) &&
      !isDate && !isDateTime && !isTime && enumValues.isEmpty &&
      (name.toLowerCase().contains('description') ||
          name.toLowerCase().contains('comment') ||
          name.toLowerCase().contains('notes') ||
          name.toLowerCase().contains('body') ||
          name.toLowerCase().contains('text'));

  /// Gibbon stores yes/no flags as 'Y' / 'N' enums.
  bool get isYesNo =>
      enumValues.length == 2 &&
      enumValues.contains('Y') &&
      enumValues.contains('N');
}

class OpenApiResourceSchema {
  const OpenApiResourceSchema({
    required this.path,
    required this.idField,
    required this.createFields,
    required this.updateFields,
    required this.methods,
  });

  final String path;
  final String? idField;
  final List<OpenApiField> createFields;
  final List<OpenApiField> updateFields;
  final Set<String> methods;

  bool get hasCreateSchema => createFields.isNotEmpty;
  bool get hasUpdateSchema => updateFields.isNotEmpty;
}

class OpenApiSpec {
  OpenApiSpec(this.raw);

  final Map<String, dynamic> raw;

  Map<String, dynamic> get _paths =>
      (raw['paths'] as Map?)?.cast<String, dynamic>() ?? const {};

  Map<String, dynamic> get _schemas =>
      ((raw['components'] as Map?)?['schemas'] as Map?)
          ?.cast<String, dynamic>() ??
      const {};

  /// Every collection path in the spec (no `{id}` segments).
  List<String> get collectionPaths => _paths.keys
      .where((p) => !p.contains('{') && p != '/openapi.json')
      .map(_stripPrefix)
      .toSet()
      .toList()
    ..sort();

  String _stripPrefix(String path) {
    // Some servers emit '/v2/students'; the app addresses '/students'.
    if (path.startsWith('/v2/')) return path.substring(3);
    return path;
  }

  Map<String, dynamic>? _pathItem(String path) {
    final direct = _paths[path];
    if (direct is Map) return direct.cast<String, dynamic>();
    final prefixed = _paths['/v2$path'];
    if (prefixed is Map) return prefixed.cast<String, dynamic>();
    return null;
  }

  Map<String, dynamic>? _itemPath(String path) {
    for (final key in _paths.keys) {
      final stripped = _stripPrefix(key);
      if (stripped.startsWith('$path/{') && stripped.endsWith('}')) {
        return (_paths[key] as Map).cast<String, dynamic>();
      }
    }
    return null;
  }

  String? _itemPathParamName(String path) {
    for (final key in _paths.keys) {
      final stripped = _stripPrefix(key);
      if (stripped.startsWith('$path/{') && stripped.endsWith('}')) {
        final start = stripped.indexOf('{') + 1;
        return stripped.substring(start, stripped.length - 1);
      }
    }
    return null;
  }

  Map<String, dynamic> _resolve(Map<String, dynamic> schema) {
    final ref = schema[r'$ref'];
    if (ref is String && ref.startsWith('#/components/schemas/')) {
      final name = ref.substring('#/components/schemas/'.length);
      final target = _schemas[name];
      if (target is Map) return _resolve(target.cast<String, dynamic>());
    }
    // allOf: merge the parts.
    final allOf = schema['allOf'];
    if (allOf is List) {
      final merged = <String, dynamic>{'type': 'object', 'properties': {}};
      final required = <String>{};
      for (final part in allOf) {
        if (part is! Map) continue;
        final resolved = _resolve(part.cast<String, dynamic>());
        final props = resolved['properties'];
        if (props is Map) {
          (merged['properties'] as Map).addAll(props);
        }
        final req = resolved['required'];
        if (req is List) required.addAll(req.map((e) => '$e'));
      }
      merged['required'] = required.toList();
      return merged;
    }
    return schema;
  }

  List<OpenApiField> _bodyFields(Map<String, dynamic>? operation) {
    if (operation == null) return const [];
    final body = operation['requestBody'];
    if (body is! Map) return const [];
    final resolvedBody = _resolve(body.cast<String, dynamic>());
    final content = resolvedBody['content'];
    if (content is! Map) return const [];
    Map<String, dynamic>? schema;
    for (final entry in content.entries) {
      if (entry.value is Map && (entry.value as Map)['schema'] is Map) {
        schema = ((entry.value as Map)['schema'] as Map).cast<String, dynamic>();
        if ('${entry.key}'.contains('json')) break;
      }
    }
    if (schema == null) return const [];
    final resolved = _resolve(schema);
    final props = resolved['properties'];
    if (props is! Map) return const [];
    final required = ((resolved['required'] as List?) ?? const [])
        .map((e) => '$e')
        .toSet();

    final fields = <OpenApiField>[];
    props.forEach((key, value) {
      if (value is! Map) return;
      final prop = _resolve(value.cast<String, dynamic>());
      var type = '${prop['type'] ?? 'string'}';
      if (prop['type'] is List) {
        final types = (prop['type'] as List).map((e) => '$e').toList();
        type = types.firstWhere((t) => t != 'null', orElse: () => 'string');
      }
      fields.add(OpenApiField(
        name: '$key',
        type: type,
        format: prop['format']?.toString(),
        enumValues: ((prop['enum'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
        required: required.contains('$key'),
        readOnly: prop['readOnly'] == true,
        description: prop['description']?.toString(),
        maxLength: prop['maxLength'] is num
            ? (prop['maxLength'] as num).toInt()
            : null,
      ));
    });
    return fields;
  }

  OpenApiResourceSchema? schemaFor(String path) {
    final collection = _pathItem(path);
    final item = _itemPath(path);
    if (collection == null && item == null) return null;

    final methods = <String>{};
    for (final m in const ['get', 'post', 'patch', 'put', 'delete']) {
      if (collection?[m] != null || item?[m] != null) {
        methods.add(m.toUpperCase());
      }
    }

    final create = _bodyFields(
        (collection?['post'] as Map?)?.cast<String, dynamic>());
    var update =
        _bodyFields((item?['patch'] as Map?)?.cast<String, dynamic>());
    if (update.isEmpty) {
      update = _bodyFields((item?['put'] as Map?)?.cast<String, dynamic>());
    }
    if (update.isEmpty) update = create;

    return OpenApiResourceSchema(
      path: path,
      idField: _itemPathParamName(path),
      createFields: create,
      updateFields: update,
      methods: methods,
    );
  }
}

/// Best-effort primary key detection from a record when the spec is silent:
/// prefers a key that ends in `ID` and starts with `gibbon`, matching the
/// resource's own table name when known.
String? guessIdField(Map<String, dynamic> record, {String? table}) {
  if (record.isEmpty) return null;
  if (table != null && record.containsKey('${table}ID')) return '${table}ID';
  if (record.containsKey('id')) return 'id';
  for (final key in record.keys) {
    if (key.startsWith('gibbon') && key.endsWith('ID')) return key;
  }
  for (final key in record.keys) {
    if (key.endsWith('ID') || key.endsWith('Id')) return key;
  }
  return record.keys.first;
}
