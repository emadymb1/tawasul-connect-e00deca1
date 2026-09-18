import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api_exception.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';
import '../../widgets/person_avatar.dart';
import 'admin_repository.dart';
import 'people_repository.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

void _toast(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: error ? TawasulColors.red : null,
  ));
}

String _errorText(Object e) => e is ApiException ? e.message : '$e';

const _statuses = ['Full', 'Expected', 'Left', 'Pending Approval'];
const _genders = ['M', 'F', 'Other', 'Unspecified'];
const _titles = ['Mr', 'Ms', 'Mrs', 'Miss', 'Dr'];
const _classRoles = [
  'Student',
  'Teacher',
  'Assistant',
  'Technician',
  'Parent',
  'Student - Left',
  'Teacher - Left',
];

Color _statusColor(String? status) {
  switch (status) {
    case 'Full':
      return TawasulColors.green;
    case 'Left':
      return TawasulColors.red;
    case 'Expected':
      return TawasulColors.gold;
    default:
      return TawasulColors.muted;
  }
}

// ---------------------------------------------------------------------------
// Person detail: record, student enrolments, class enrolments.
// ---------------------------------------------------------------------------

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId, this.initial});

  final String personId;

  /// The list row we already have, shown until the full record arrives.
  final Map<String, dynamic>? initial;

  void _refresh(WidgetRef ref) {
    ref.invalidate(personProvider(personId));
    ref.invalidate(personEnrolmentsProvider(personId));
    ref.invalidate(personClassesProvider(personId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personAsync = ref.watch(personProvider(personId));
    final person = personAsync.valueOrNull ?? initial ?? const {};
    final name = personName(person);

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isEmpty ? strings.personDetails : name),
        actions: [
          IconButton(
            tooltip: strings.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: person.isEmpty
                ? null
                : () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => PersonFormPage(
                            existing: person, personId: personId),
                      ),
                    );
                    if (changed == true) _refresh(ref);
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _PersonHero(person: person),
            const SizedBox(height: 16),
            if (personAsync.hasError && initial == null)
              SectionCard(title: strings.personDetails, children: [
                Text(_errorText(personAsync.error!),
                    style: const TextStyle(color: TawasulColors.red)),
                TextButton(
                    onPressed: () => _refresh(ref),
                    child: Text(strings.retry)),
              ])
            else
              SectionCard(title: strings.accountDetails, children: [
                _InfoLine(label: strings.usernameLabel, value: person['username']),
                _InfoLine(label: strings.email, value: person['email']),
                _InfoLine(label: strings.phone, value: person['phone1']),
                _InfoLine(
                    label: strings.dateOfBirth, value: person['dob']),
                _InfoLine(label: strings.gender, value: person['gender']),
                _InfoLine(
                    label: strings.primaryRole,
                    value: person['primaryRole'] ??
                        person['roleName'] ??
                        person['gibbonRoleIDPrimary']),
                _InfoLine(
                    label: strings.canLogin,
                    value: person['canLogin'] == null
                        ? null
                        : (person['canLogin'] == 'Y'
                            ? strings.yes
                            : strings.no)),
                _InfoLine(
                    label: strings.studentIdLabel, value: person['studentID']),
              ]),
            const SizedBox(height: 16),
            _EnrolmentsCard(personId: personId, person: person),
            const SizedBox(height: 16),
            _ClassesCard(personId: personId, person: person),
          ],
        ),
      ),
    );
  }
}

class _PersonHero extends StatelessWidget {
  const _PersonHero({required this.person});
  final Map<String, dynamic> person;

  @override
  Widget build(BuildContext context) {
    final name = personName(person);
    final status = person['status']?.toString();
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        color: TawasulColors.forest,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            PersonAvatar(
              name: name,
              imageUrl: person['image_240']?.toString(),
              size: 56,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: TawasulColors.cream,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      person['primaryRole'] ?? person['roleName'],
                      person['username'],
                    ].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
                    style: const TextStyle(
                        color: Color(0xDDF6F1E7), fontSize: 13),
                  ),
                ],
              ),
            ),
            if (status != null && status.isNotEmpty)
              StatusPill(label: status, color: _statusColor(status)),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, this.value});
  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final text = value == null || '$value'.isEmpty ? '—' : '$value';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: TawasulColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SelectableText(text,
                style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- enrolments card

class _EnrolmentsCard extends ConsumerWidget {
  const _EnrolmentsCard({required this.personId, required this.person});
  final String personId;
  final Map<String, dynamic> person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final value = ref.watch(personEnrolmentsProvider(personId));

    Future<void> openForm([Map<String, dynamic>? existing]) async {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => StudentEnrolmentFormPage(
            person: {...person, 'gibbonPersonID': personId},
            existing: existing,
          ),
        ),
      );
      if (changed == true) {
        ref.invalidate(personEnrolmentsProvider(personId));
        ref.invalidate(adminStudentsProvider);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AsyncCard(
          title: strings.enrolments,
          value: value,
          onRetry: () => ref.invalidate(personEnrolmentsProvider(personId)),
          builder: (rows) => [
            if (rows.isEmpty) Text(strings.noEnrolments),
            for (final row in rows)
              DetailRow(
                title: [row['yearGroup'], row['formGroup']]
                    .where((e) => e != null && '$e'.isNotEmpty)
                    .join(' · '),
                subtitle: [
                  row['schoolYear'] ?? row['schoolYearName'],
                  if (row['rollOrder'] != null &&
                      '${row['rollOrder']}'.isNotEmpty)
                    '${strings.rollOrder} ${row['rollOrder']}',
                ].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: TawasulColors.muted),
                onTap: () => openForm(row),
              ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => openForm(),
              icon: const Icon(Icons.school_outlined),
              label: Text(strings.enrolStudent),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- classes card

class _ClassesCard extends ConsumerWidget {
  const _ClassesCard({required this.personId, required this.person});
  final String personId;
  final Map<String, dynamic> person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final value = ref.watch(personClassesProvider(personId));
    final repo = ref.read(peopleRepositoryProvider);

    Future<void> add() async {
      final result = await showModalBottomSheet<({String classId, String role})>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const ClassPickerSheet(),
      );
      if (result == null) return;
      try {
        await repo.addToClass(
            classId: result.classId, personId: personId, role: result.role);
        ref.invalidate(personClassesProvider(personId));
        ref.invalidate(classMembersProvider(result.classId));
        if (context.mounted) _toast(context, strings.saved);
      } catch (e) {
        if (context.mounted) _toast(context, _errorText(e), error: true);
      }
    }

    Future<void> remove(Map<String, dynamic> row) async {
      final id = row['gibbonCourseClassPersonID']?.toString();
      if (id == null) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(strings.removeFromClass),
          content: Text(strings.removeQuestion),
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
      try {
        await repo.removeFromClass(id);
        ref.invalidate(personClassesProvider(personId));
        if (context.mounted) _toast(context, strings.removed);
      } catch (e) {
        if (context.mounted) _toast(context, _errorText(e), error: true);
      }
    }

    return AsyncCard(
      title: strings.classEnrolments,
      value: value,
      onRetry: () => ref.invalidate(personClassesProvider(personId)),
      builder: (rows) => [
        if (rows.isEmpty) Text(strings.noClassEnrolments),
        for (final row in rows)
          DetailRow(
            title: className(row),
            subtitle: '${row['role'] ?? ''}',
            trailing: IconButton(
              tooltip: strings.removeFromClass,
              icon: const Icon(Icons.remove_circle_outline,
                  color: TawasulColors.red),
              onPressed: () => remove(row),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: add,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.addToClass),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Person form: create or edit a `/users` record with a role picker.
// ---------------------------------------------------------------------------

class PersonFormPage extends ConsumerStatefulWidget {
  const PersonFormPage({super.key, this.existing, this.personId});

  final Map<String, dynamic>? existing;
  final String? personId;

  bool get isEdit => existing != null && personId != null;

  @override
  ConsumerState<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends ConsumerState<PersonFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final _surname = _controller('surname');
  late final _firstName = _controller('firstName');
  late final _preferredName = _controller('preferredName');
  late final _officialName = _controller('officialName');
  late final _username = _controller('username');
  late final _password = TextEditingController();
  late final _email = _controller('email');
  late final _phone = _controller('phone1');
  late final _dob = _controller('dob');
  late final _studentId = _controller('studentID');

  String? _title;
  String? _gender;
  String? _status;
  String? _roleId;
  String? _houseId;
  bool _canLogin = true;
  bool _saving = false;

  TextEditingController _controller(String key) =>
      TextEditingController(text: '${widget.existing?[key] ?? ''}');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = _pick(e?['title'], _titles);
    _gender = _pick(e?['gender'], _genders);
    _status = _pick(e?['status'], _statuses) ?? (widget.isEdit ? null : 'Full');
    _roleId = e?['gibbonRoleIDPrimary']?.toString();
    _houseId = e?['gibbonHouseID']?.toString();
    _canLogin = e == null ? true : e['canLogin'] != 'N';
  }

  String? _pick(dynamic value, List<String> options) {
    final v = value?.toString();
    return v != null && options.contains(v) ? v : null;
  }

  @override
  void dispose() {
    for (final c in [
      _surname,
      _firstName,
      _preferredName,
      _officialName,
      _username,
      _password,
      _email,
      _phone,
      _dob,
      _studentId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _body() {
    final first = _firstName.text.trim();
    final surname = _surname.text.trim();
    final preferred =
        _preferredName.text.trim().isEmpty ? first : _preferredName.text.trim();
    final official = _officialName.text.trim().isEmpty
        ? '$first $surname'.trim()
        : _officialName.text.trim();

    final body = <String, dynamic>{
      'surname': surname,
      'firstName': first,
      'preferredName': preferred,
      'officialName': official,
      'username': _username.text.trim(),
      'email': _email.text.trim(),
      'phone1': _phone.text.trim(),
      'dob': _dob.text.trim(),
      'studentID': _studentId.text.trim(),
      'canLogin': _canLogin ? 'Y' : 'N',
      if (_title != null) 'title': _title,
      if (_gender != null) 'gender': _gender,
      if (_status != null) 'status': _status,
      if (_roleId != null) 'gibbonRoleIDPrimary': _roleId,
      if (_houseId != null) 'gibbonHouseID': _houseId,
      if (_password.text.isNotEmpty) 'password': _password.text,
    };

    if (!widget.isEdit) {
      body.removeWhere((_, v) => v == null || v == '');
      return body;
    }

    // Edit: send only what changed so PATCH stays minimal.
    final before = widget.existing!;
    body.removeWhere((key, value) {
      if (key == 'password') return false;
      final old = before[key]?.toString() ?? '';
      return old == '${value ?? ''}';
    });
    return body;
  }

  Future<void> _save() async {
    final strings = S.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final body = _body();
    if (body.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(peopleRepositoryProvider);
    try {
      if (widget.isEdit) {
        await repo.updatePerson(widget.personId!, body);
      } else {
        await repo.createPerson(body);
      }
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminStaffProvider);
      ref.invalidate(adminStudentsProvider);
      if (!mounted) return;
      _toast(context, widget.isEdit ? strings.saved : strings.userCreated);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_dob.text) ?? DateTime(2012, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dob.text = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final roles = ref.watch(peopleRolesProvider);
    final houses = ref.watch(peopleHousesProvider);

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isEdit ? strings.editUser : strings.newUser)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _GroupTitle(strings.personalDetails),
            DropdownButtonFormField<String>(
              value: _title,
              decoration: InputDecoration(labelText: strings.titleLabel),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('—')),
                for (final t in _titles)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _title = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstName,
              decoration: InputDecoration(labelText: '${strings.firstName} *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? strings.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _surname,
              decoration: InputDecoration(labelText: '${strings.surname} *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? strings.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _preferredName,
              decoration: InputDecoration(labelText: strings.preferredName),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _officialName,
              decoration: InputDecoration(labelText: strings.officialName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(labelText: strings.gender),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('—')),
                DropdownMenuItem(value: 'M', child: Text(strings.male)),
                DropdownMenuItem(value: 'F', child: Text(strings.female)),
                DropdownMenuItem(value: 'Other', child: Text(strings.other)),
                DropdownMenuItem(
                    value: 'Unspecified', child: Text(strings.unspecified)),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dob,
              readOnly: true,
              onTap: _pickDob,
              decoration: InputDecoration(
                labelText: strings.dateOfBirth,
                helperText: 'YYYY-MM-DD',
                suffixIcon: const Icon(Icons.event_outlined),
              ),
            ),
            const SizedBox(height: 20),
            _GroupTitle(strings.accountDetails),
            TextFormField(
              controller: _username,
              decoration:
                  InputDecoration(labelText: '${strings.usernameLabel} *'),
              autocorrect: false,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? strings.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: widget.isEdit
                    ? strings.passwordLabel
                    : '${strings.passwordLabel} *',
                helperText: widget.isEdit ? strings.passwordKeepHint : null,
              ),
              validator: (v) => !widget.isEdit && (v == null || v.isEmpty)
                  ? strings.requiredField
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: strings.email),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: strings.phone),
            ),
            const SizedBox(height: 12),
            roles.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => TextFormField(
                initialValue: _roleId,
                decoration: InputDecoration(
                    labelText: strings.primaryRole,
                    helperText: 'gibbonRoleIDPrimary'),
                onChanged: (v) => _roleId = v.trim().isEmpty ? null : v.trim(),
              ),
              data: (rows) {
                final ids = rows
                    .map((r) => r['gibbonRoleID']?.toString())
                    .whereType<String>()
                    .toSet();
                return DropdownButtonFormField<String>(
                  value: ids.contains(_roleId) ? _roleId : null,
                  decoration: InputDecoration(
                      labelText: widget.isEdit
                          ? strings.primaryRole
                          : '${strings.primaryRole} *'),
                  items: [
                    for (final r in rows)
                      if (r['gibbonRoleID'] != null)
                        DropdownMenuItem(
                          value: r['gibbonRoleID'].toString(),
                          child: Text(
                              '${r['name'] ?? ''} · ${r['category'] ?? ''}'),
                        ),
                  ],
                  validator: (v) => !widget.isEdit && v == null
                      ? strings.requiredField
                      : null,
                  onChanged: (v) => setState(() => _roleId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: strings.status),
              items: [
                for (final s in _statuses)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.canLogin),
              value: _canLogin,
              onChanged: (v) => setState(() => _canLogin = v),
            ),
            const SizedBox(height: 8),
            _GroupTitle(strings.students),
            TextFormField(
              controller: _studentId,
              decoration: InputDecoration(labelText: strings.studentIdLabel),
            ),
            const SizedBox(height: 12),
            houses.maybeWhen(
              data: (rows) => rows.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<String>(
                      value: rows.any(
                              (r) => r['gibbonHouseID']?.toString() == _houseId)
                          ? _houseId
                          : null,
                      decoration: InputDecoration(labelText: strings.house),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('—')),
                        for (final r in rows)
                          if (r['gibbonHouseID'] != null)
                            DropdownMenuItem(
                              value: r['gibbonHouseID'].toString(),
                              child: Text('${r['name'] ?? ''}'),
                            ),
                      ],
                      onChanged: (v) => setState(() => _houseId = v),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
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

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: TawasulColors.forest)),
      );
}

// ---------------------------------------------------------------------------
// Student enrolment form: `/students` create or edit with pickers.
// ---------------------------------------------------------------------------

class StudentEnrolmentFormPage extends ConsumerStatefulWidget {
  const StudentEnrolmentFormPage({super.key, this.person, this.existing});

  /// Fixed person when opened from a person page; otherwise picked here.
  final Map<String, dynamic>? person;
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<StudentEnrolmentFormPage> createState() =>
      _StudentEnrolmentFormPageState();
}

class _StudentEnrolmentFormPageState
    extends ConsumerState<StudentEnrolmentFormPage> {
  Map<String, dynamic>? _person;
  String? _yearGroupId;
  String? _formGroupId;
  late final _rollOrder =
      TextEditingController(text: '${widget.existing?['rollOrder'] ?? ''}');
  bool _saving = false;

  bool get isEdit =>
      widget.existing != null &&
      widget.existing!['gibbonStudentEnrolmentID'] != null;

  @override
  void initState() {
    super.initState();
    _person = widget.person ?? widget.existing;
    _yearGroupId = widget.existing?['gibbonYearGroupID']?.toString();
    _formGroupId = widget.existing?['gibbonFormGroupID']?.toString();
  }

  @override
  void dispose() {
    _rollOrder.dispose();
    super.dispose();
  }

  Future<void> _pickPerson() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PersonPickerSheet(),
    );
    if (picked != null) setState(() => _person = picked);
  }

  Future<void> _save() async {
    final strings = S.of(context);
    final pid = _person == null ? null : personId(_person!);
    if (pid == null || _yearGroupId == null || _formGroupId == null) {
      _toast(context, strings.requiredField, error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(peopleRepositoryProvider);
    try {
      final body = <String, dynamic>{
        'gibbonYearGroupID': _yearGroupId,
        'gibbonFormGroupID': _formGroupId,
        if (_rollOrder.text.trim().isNotEmpty)
          'rollOrder': _rollOrder.text.trim(),
      };
      if (isEdit) {
        await repo.updateEnrolment(
            widget.existing!['gibbonStudentEnrolmentID'].toString(), body);
      } else {
        final year = await repo.workingSchoolYearId();
        await repo.createEnrolment({
          'gibbonPersonID': pid,
          if (year != null) 'gibbonSchoolYearID': year,
          ...body,
        });
      }
      ref.invalidate(adminStudentsProvider);
      ref.invalidate(personEnrolmentsProvider(pid));
      if (!mounted) return;
      _toast(context, strings.enrolmentSaved);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final strings = S.of(context);
    final id = widget.existing?['gibbonStudentEnrolmentID']?.toString();
    if (id == null) return;
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
            style: FilledButton.styleFrom(backgroundColor: TawasulColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(peopleRepositoryProvider).deleteEnrolment(id);
      ref.invalidate(adminStudentsProvider);
      final pid = _person == null ? null : personId(_person!);
      if (pid != null) ref.invalidate(personEnrolmentsProvider(pid));
      if (!mounted) return;
      _toast(context, strings.deleted);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final yearGroups = ref.watch(peopleYearGroupsProvider);
    final formGroups = ref.watch(peopleFormGroupsProvider);
    final personLocked = widget.person != null || isEdit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? strings.editEnrolment : strings.enrolStudent),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: strings.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Card(
            child: ListTile(
              leading: PersonAvatar(
                  name: _person == null ? '?' : personName(_person!)),
              title: Text(_person == null
                  ? strings.pickPerson
                  : personName(_person!)),
              subtitle: _person == null
                  ? null
                  : Text('${_person!['username'] ?? personId(_person!) ?? ''}'),
              trailing: personLocked
                  ? null
                  : const Icon(Icons.search_rounded),
              onTap: personLocked ? null : _pickPerson,
            ),
          ),
          const SizedBox(height: 16),
          yearGroups.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(_errorText(e),
                style: const TextStyle(color: TawasulColors.red)),
            data: (rows) => DropdownButtonFormField<String>(
              value: rows.any(
                      (r) => r['gibbonYearGroupID']?.toString() == _yearGroupId)
                  ? _yearGroupId
                  : null,
              decoration:
                  InputDecoration(labelText: '${strings.yearGroups} *'),
              items: [
                for (final r in rows)
                  if (r['gibbonYearGroupID'] != null)
                    DropdownMenuItem(
                      value: r['gibbonYearGroupID'].toString(),
                      child: Text('${r['name'] ?? ''}'),
                    ),
              ],
              onChanged: (v) => setState(() => _yearGroupId = v),
            ),
          ),
          const SizedBox(height: 12),
          formGroups.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(_errorText(e),
                style: const TextStyle(color: TawasulColors.red)),
            data: (rows) => DropdownButtonFormField<String>(
              isExpanded: true,
              value: rows.any(
                      (r) => r['gibbonFormGroupID']?.toString() == _formGroupId)
                  ? _formGroupId
                  : null,
              decoration:
                  InputDecoration(labelText: '${strings.formGroups} *'),
              items: [
                for (final r in rows)
                  if (r['gibbonFormGroupID'] != null)
                    DropdownMenuItem(
                      value: r['gibbonFormGroupID'].toString(),
                      child: Text(
                        [r['name'], r['tutor']]
                            .where((e) => e != null && '$e'.isNotEmpty)
                            .join(' · '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
              onChanged: (v) => setState(() => _formGroupId = v),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rollOrder,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.rollOrder),
          ),
          if (!isEdit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TawasulColors.sage,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(strings.enrolmentYearHint,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
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

// ---------------------------------------------------------------------------
// Pickers: search a person / a class from the server.
// ---------------------------------------------------------------------------

class PersonPickerSheet extends ConsumerStatefulWidget {
  const PersonPickerSheet({super.key});

  @override
  ConsumerState<PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends ConsumerState<PersonPickerSheet> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(String term) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows =
          await ref.read(peopleRepositoryProvider).searchPeople(term.trim());
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = _errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: strings.searchPeople,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onSubmitted: _run,
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: const TextStyle(color: TawasulColors.red)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final row = _rows[i];
                  return ListTile(
                    leading: PersonAvatar(name: personName(row)),
                    title: Text(personName(row)),
                    subtitle: Text([
                      row['username'],
                      row['primaryRole'] ?? row['roleName'],
                      row['status'],
                    ].where((e) => e != null && '$e'.isNotEmpty).join(' · ')),
                    onTap: () => Navigator.of(context).pop(row),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks a class and the role the person will have in it.
class ClassPickerSheet extends ConsumerStatefulWidget {
  const ClassPickerSheet({super.key, this.initialRole = 'Student'});
  final String initialRole;

  @override
  ConsumerState<ClassPickerSheet> createState() => _ClassPickerSheetState();
}

class _ClassPickerSheetState extends ConsumerState<ClassPickerSheet> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = false;
  String? _error;
  late String _role = widget.initialRole;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(String term) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows =
          await ref.read(peopleRepositoryProvider).searchClasses(term.trim());
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = _errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(labelText: strings.roleInClass),
              items: [
                for (final r in _classRoles)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: strings.searchClasses,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onSubmitted: _run,
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: const TextStyle(color: TawasulColors.red)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final row = _rows[i];
                  final id = row['gibbonCourseClassID']?.toString();
                  return ListTile(
                    leading: const Icon(Icons.class_outlined,
                        color: TawasulColors.forest),
                    title: Text(className(row)),
                    subtitle: row['enrolmentCount'] != null ||
                            row['students'] != null
                        ? Text(
                            '${strings.students}: ${row['enrolmentCount'] ?? row['students']}')
                        : null,
                    enabled: id != null,
                    onTap: id == null
                        ? null
                        : () => Navigator.of(context)
                            .pop((classId: id, role: _role)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Class members: everyone in a class, add / remove.
// ---------------------------------------------------------------------------

class ClassMembersPage extends ConsumerWidget {
  const ClassMembersPage({super.key, required this.classRow});
  final Map<String, dynamic> classRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final classId = classRow['gibbonCourseClassID'].toString();
    final value = ref.watch(classMembersProvider(classId));
    final repo = ref.read(peopleRepositoryProvider);

    Future<void> add() async {
      final person = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const PersonPickerSheet(),
      );
      if (person == null || !context.mounted) return;
      final pid = personId(person);
      if (pid == null) return;
      final role = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(strings.roleInClass),
          children: [
            for (final r in _classRoles)
              SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(r),
                child: Text(r),
              ),
          ],
        ),
      );
      if (role == null) return;
      try {
        await repo.addToClass(classId: classId, personId: pid, role: role);
        ref.invalidate(classMembersProvider(classId));
        ref.invalidate(personClassesProvider(pid));
        if (context.mounted) _toast(context, strings.saved);
      } catch (e) {
        if (context.mounted) _toast(context, _errorText(e), error: true);
      }
    }

    Future<void> remove(Map<String, dynamic> row) async {
      final id = row['gibbonCourseClassPersonID']?.toString();
      if (id == null) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(strings.removeFromClass),
          content: Text(strings.removeQuestion),
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
      try {
        await repo.removeFromClass(id);
        ref.invalidate(classMembersProvider(classId));
        if (context.mounted) _toast(context, strings.removed);
      } catch (e) {
        if (context.mounted) _toast(context, _errorText(e), error: true);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(className(classRow))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(strings.addToClass),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(classMembersProvider(classId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            AsyncCard(
              title: strings.classEnrolments,
              value: value,
              onRetry: () => ref.invalidate(classMembersProvider(classId)),
              builder: (rows) {
                final sorted = [...rows]..sort((a, b) {
                    final ra = '${a['role'] ?? ''}';
                    final rb = '${b['role'] ?? ''}';
                    if (ra != rb) return ra.compareTo(rb);
                    return '${a['surname'] ?? ''}'
                        .compareTo('${b['surname'] ?? ''}');
                  });
                return [
                  if (sorted.isEmpty) Text(strings.noClassEnrolments),
                  for (final row in sorted)
                    DetailRow(
                      leading: PersonAvatar(name: personName(row)),
                      title: personName(row),
                      subtitle: '${row['role'] ?? ''}',
                      trailing: IconButton(
                        tooltip: strings.removeFromClass,
                        icon: const Icon(Icons.remove_circle_outline,
                            color: TawasulColors.red),
                        onPressed: () => remove(row),
                      ),
                      onTap: () {
                        final pid = personId(row);
                        if (pid == null) return;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              PersonDetailPage(personId: pid, initial: row),
                        ));
                      },
                    ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
