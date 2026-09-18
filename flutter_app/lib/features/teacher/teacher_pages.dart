import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';
import '../auth/auth_controller.dart';
import '../school/school_repository.dart';
import 'teacher_repository.dart';

String _time(Map<String, dynamic> row) {
  final start = '${row['timeStart'] ?? ''}';
  return start.length >= 5 ? start.substring(0, 5) : start;
}

String _personName(Map<String, dynamic> row) =>
    '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'.trim();

String _classTitle(Map<String, dynamic> row) =>
    '${row['course'] ?? row['courseName'] ?? ''} ${row['class'] ?? row['className'] ?? ''}'
        .trim();

String _today() => DateTime.now().toIso8601String().substring(0, 10);

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

// ===========================================================================
// Dashboard / timetable
// ===========================================================================

class TeacherDashboardPage extends ConsumerWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final personId = user.personId;

    final lessons = ref.watch(teacherLessonsProvider(personId));
    final classes = ref.watch(teacherClassesProvider(personId));
    final notifications = ref.watch(notificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherLessonsProvider(personId));
        ref.invalidate(teacherClassesProvider(personId));
        ref.invalidate(notificationsProvider);
        ref.invalidate(noticesProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          BrandHero(
            eyebrow: strings.teacherPortal,
            title: user.displayName,
            subtitle: lessons.maybeWhen(
              data: (rows) => '${rows.length} ${strings.lessonsToday}',
              orElse: () => null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: strings.lessonsToday,
                  background: TawasulColors.gold,
                  value: lessons.maybeWhen(
                      data: (rows) => '${rows.length}', orElse: () => '…'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: strings.unreadNotices,
                  value: notifications.maybeWhen(
                      data: (rows) =>
                          '${rows.where((r) => '${r['status']}' == 'New').length}',
                      orElse: () => '…'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.todaysLessons,
            value: lessons,
            onRetry: () => ref.invalidate(teacherLessonsProvider(personId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: TimePill(time: _time(row)),
                      title: '${row['course'] ?? row['courseName'] ?? ''}',
                      subtitle: [
                        row['class'] ?? row['classNameShort'] ?? '',
                        row['space'] ?? ''
                      ]
                          .where((e) => '$e'.isNotEmpty)
                          .join(' · '),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.classes,
            value: classes,
            onRetry: () => ref.invalidate(teacherClassesProvider(personId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _classTitle(row),
                      subtitle: '${row['class'] ?? ''}',
                      onTap: () => _openClass(context, row),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.schoolNotices,
            value: ref.watch(noticesProvider),
            onRetry: () => ref.invalidate(noticesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['title'] ?? row['name'] ?? ''}',
                      subtitle: '${row['timestamp'] ?? ''}',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

void _openClass(BuildContext context, Map<String, dynamic> row) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => TeacherClassHubScreen(
      classId: '${row['gibbonCourseClassID']}',
      title: _classTitle(row),
    ),
  ));
}

class TeacherTimetablePage extends ConsumerWidget {
  const TeacherTimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = ref.watch(currentUserProvider)?.personId;
    if (personId == null) return const SizedBox.shrink();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AsyncCard(
          title: strings.timetable,
          value: ref.watch(teacherLessonsProvider(personId)),
          onRetry: () => ref.invalidate(teacherLessonsProvider(personId)),
          builder: (rows) => rows
              .map((row) => DetailRow(
                    leading: TimePill(time: _time(row)),
                    title: '${row['course'] ?? row['courseName'] ?? ''}',
                    subtitle: '${row['class'] ?? ''}',
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// Class list; every class opens the full teaching hub.
class TeacherClassesPage extends ConsumerWidget {
  const TeacherClassesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = ref.watch(currentUserProvider)?.personId;
    if (personId == null) return const SizedBox.shrink();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AsyncCard(
          title: strings.classes,
          value: ref.watch(teacherClassesProvider(personId)),
          onRetry: () => ref.invalidate(teacherClassesProvider(personId)),
          builder: (rows) => rows
              .map((row) => DetailRow(
                    title: _classTitle(row),
                    subtitle: '${row['class'] ?? ''}',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openClass(context, row),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class TeacherAttendancePage extends ConsumerWidget {
  const TeacherAttendancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = ref.watch(currentUserProvider)?.personId;
    if (personId == null) return const SizedBox.shrink();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AsyncCard(
          title: strings.attendance,
          value: ref.watch(teacherClassesProvider(personId)),
          onRetry: () => ref.invalidate(teacherClassesProvider(personId)),
          builder: (rows) => rows
              .map((row) => DetailRow(
                    title: _classTitle(row),
                    subtitle: '${row['class'] ?? ''}',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TakeAttendanceScreen(
                          classId: '${row['gibbonCourseClassID']}',
                          title: _classTitle(row),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class TeacherMarkbookPage extends ConsumerWidget {
  const TeacherMarkbookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = ref.watch(currentUserProvider)?.personId;
    if (personId == null) return const SizedBox.shrink();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AsyncCard(
          title: strings.markbook,
          value: ref.watch(teacherClassesProvider(personId)),
          onRetry: () => ref.invalidate(teacherClassesProvider(personId)),
          builder: (rows) => rows
              .map((row) => DetailRow(
                    title: _classTitle(row),
                    subtitle: '${row['class'] ?? ''}',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassMarkbookScreen(
                          classId: '${row['gibbonCourseClassID']}',
                          title: _classTitle(row),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ===========================================================================
// Class hub
// ===========================================================================

class TeacherClassHubScreen extends ConsumerWidget {
  const TeacherClassHubScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);

    Widget tile(IconData icon, String label, Widget screen) => DetailRow(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TawasulColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: TawasulColors.forest, size: 20),
          ),
          title: label,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => screen)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SectionCard(
            title: strings.classes,
            children: [
              tile(Icons.menu_book_outlined, strings.lessonPlanner,
                  ClassLessonsScreen(classId: classId, title: title)),
              tile(Icons.assignment_outlined, strings.homework,
                  ClassHomeworkScreen(classId: classId, title: title)),
              tile(Icons.groups_outlined, strings.classRoster,
                  ClassRosterScreen(classId: classId, title: title)),
              tile(Icons.fact_check_outlined, strings.takeAttendance,
                  TakeAttendanceScreen(classId: classId, title: title)),
              tile(Icons.bar_chart_rounded, strings.markbook,
                  ClassMarkbookScreen(classId: classId, title: title)),
              tile(Icons.quiz_outlined, strings.assessments,
                  ClassAssessmentsScreen(classId: classId, title: title)),
              tile(Icons.emoji_events_outlined, strings.behaviour,
                  ClassBehaviourScreen(classId: classId, title: title)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Lessons + lesson planning
// ===========================================================================

class ClassLessonsScreen extends ConsumerWidget {
  const ClassLessonsScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${strings.lessons} · $title')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => LessonEditorScreen(classId: classId),
            ),
          );
          if (created == true) ref.invalidate(classLessonsProvider(classId));
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.newLesson),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          AsyncCard(
            title: strings.lessonPlanner,
            value: ref.watch(classLessonsProvider(classId)),
            onRetry: () => ref.invalidate(classLessonsProvider(classId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: [
                        row['date'] ?? '',
                        '${row['homework']}' == 'Y' ? strings.homework : ''
                      ].where((e) => '$e'.isNotEmpty).join(' · '),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => LessonEditorScreen(
                              classId: classId,
                              lesson: row,
                            ),
                          ),
                        );
                        if (changed == true) {
                          ref.invalidate(classLessonsProvider(classId));
                          ref.invalidate(classHomeworkProvider(classId));
                        }
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Create or edit one lesson plan, including its homework.
class LessonEditorScreen extends ConsumerStatefulWidget {
  const LessonEditorScreen({super.key, required this.classId, this.lesson});

  final String classId;
  final Map<String, dynamic>? lesson;

  @override
  ConsumerState<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends ConsumerState<LessonEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _date;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _summary;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late final TextEditingController _homeworkDetails;
  late final TextEditingController _homeworkDue;
  late bool _homework;
  bool _viewStudents = true;
  bool _viewParents = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    String v(String key) => '${lesson?[key] ?? ''}';
    _name = TextEditingController(text: v('name'));
    _date = TextEditingController(
        text: lesson == null ? _today() : v('date'));
    _start = TextEditingController(
        text: lesson == null ? '08:00' : v('timeStart'));
    _end =
        TextEditingController(text: lesson == null ? '09:00' : v('timeEnd'));
    _summary = TextEditingController(text: v('summary'));
    _description = TextEditingController(text: v('description'));
    _notes = TextEditingController(text: v('teachersNotes'));
    _homeworkDetails = TextEditingController(text: v('homeworkDetails'));
    _homeworkDue = TextEditingController(text: v('homeworkDueDateTime'));
    _homework = '${lesson?['homework'] ?? 'N'}' == 'Y';
    _viewStudents = '${lesson?['viewableStudents'] ?? 'Y'}' == 'Y';
    _viewParents = '${lesson?['viewableParents'] ?? 'Y'}' == 'Y';
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _date,
      _start,
      _end,
      _summary,
      _description,
      _notes,
      _homeworkDetails,
      _homeworkDue,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = S.of(context);
    if (_name.text.trim().isEmpty || _date.text.trim().isEmpty) {
      _toast(context, strings.requiredField);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(teacherRepositoryProvider);
    try {
      if (widget.lesson == null) {
        await repo.createLesson(
          courseClassId: widget.classId,
          name: _name.text.trim(),
          date: _date.text.trim(),
          timeStart: _start.text.trim(),
          timeEnd: _end.text.trim(),
          summary: _summary.text.trim(),
          description: _description.text.trim(),
          teachersNotes: _notes.text.trim(),
          homework: _homework,
          homeworkDetails: _homeworkDetails.text.trim(),
          homeworkDueDateTime: _homeworkDue.text.trim().isEmpty
              ? null
              : _homeworkDue.text.trim(),
          viewableStudents: _viewStudents,
          viewableParents: _viewParents,
        );
      } else {
        await repo.updateLesson('${widget.lesson!['gibbonPlannerEntryID']}', {
          'name': _name.text.trim(),
          'date': _date.text.trim(),
          'timeStart': _start.text.trim(),
          'timeEnd': _end.text.trim(),
          'summary': _summary.text.trim(),
          'description': _description.text.trim(),
          'teachersNotes': _notes.text.trim(),
          'homework': _homework ? 'Y' : 'N',
          'homeworkDetails': _homeworkDetails.text.trim(),
          if (_homeworkDue.text.trim().isNotEmpty)
            'homeworkDueDateTime': _homeworkDue.text.trim(),
          'viewableStudents': _viewStudents ? 'Y' : 'N',
          'viewableParents': _viewParents ? 'Y' : 'N',
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null
            ? strings.newLesson
            : '${strings.lessons} · ${widget.lesson!['name'] ?? ''}'),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          SectionCard(
            title: strings.lessonPlanner,
            children: [
              _field(_name, strings.name),
              _field(_date, '${strings.date} (YYYY-MM-DD)'),
              Row(
                children: [
                  Expanded(child: _field(_start, strings.startTime)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_end, strings.endTime)),
                ],
              ),
              _field(_summary, strings.summary),
              _field(_description, strings.description, lines: 4),
              _field(_notes, strings.teachersNotes, lines: 3),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.homework,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _homework,
                title: Text(strings.hasHomework),
                onChanged: (v) => setState(() => _homework = v),
              ),
              if (_homework) ...[
                _field(_homeworkDetails, strings.homeworkDetails, lines: 3),
                _field(_homeworkDue,
                    '${strings.dueDate} (YYYY-MM-DD HH:MM:SS)'),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.visibleToStudents,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _viewStudents,
                title: Text(strings.visibleToStudents),
                onChanged: (v) => setState(() => _viewStudents = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _viewParents,
                title: Text(strings.visibleToParents),
                onChanged: (v) => setState(() => _viewParents = v),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? strings.saving : strings.save),
        ),
      ),
    );
  }
}

Widget _field(TextEditingController controller, String label, {int lines = 1}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
      ),
    );

// ===========================================================================
// Homework tracking + submissions
// ===========================================================================

class ClassHomeworkScreen extends ConsumerWidget {
  const ClassHomeworkScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${strings.homework} · $title')),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.homework,
            value: ref.watch(classHomeworkProvider(classId)),
            onRetry: () => ref.invalidate(classHomeworkProvider(classId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle:
                          '${strings.dueDate}: ${row['homeworkDueDateTime'] ?? row['date'] ?? ''}',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HomeworkDetailScreen(
                            classId: classId,
                            lesson: row,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class HomeworkDetailScreen extends ConsumerWidget {
  const HomeworkDetailScreen({
    super.key,
    required this.classId,
    required this.lesson,
  });

  final String classId;
  final Map<String, dynamic> lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final lessonId = '${lesson['gibbonPlannerEntryID']}';
    final progress = ref.watch(homeworkProgressProvider(lessonId));
    final submissions = ref.watch(homeworkSubmissionsProvider(lessonId));
    final roster = ref.watch(classRosterProvider(classId));

    return Scaffold(
      appBar: AppBar(title: Text('${lesson['name'] ?? ''}')),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SectionCard(
            title: strings.homeworkDetails,
            children: [
              Text('${lesson['homeworkDetails'] ?? ''}'),
              const SizedBox(height: 8),
              Text(
                '${strings.dueDate}: ${lesson['homeworkDueDateTime'] ?? ''}',
                style: const TextStyle(color: TawasulColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.progress,
            value: progress,
            onRetry: () => ref.invalidate(homeworkProgressProvider(lessonId)),
            builder: (rows) {
              final names = <String, String>{};
              roster.whenData((students) {
                for (final s in students) {
                  names['${s['gibbonPersonID']}'] = _personName(s);
                }
              });
              return rows
                  .map((row) => DetailRow(
                        title: names['${row['gibbonPersonID']}'] ??
                            '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                                .trim(),
                        subtitle: '${row['homeworkDetails'] ?? ''}',
                        trailing: StatusPill(
                          label: '${row['homeworkComplete']}' == 'Y'
                              ? strings.completed
                              : strings.notCompleted,
                          color: '${row['homeworkComplete']}' == 'Y'
                              ? TawasulColors.forest
                              : TawasulColors.red,
                        ),
                      ))
                  .toList();
            },
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.submissions,
            value: submissions,
            onRetry: () =>
                ref.invalidate(homeworkSubmissionsProvider(lessonId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title:
                          '${row['preferredName'] ?? ''} ${row['surname'] ?? row['gibbonPersonID'] ?? ''}'
                              .trim(),
                      subtitle: [
                        row['type'] ?? '',
                        row['version'] ?? '',
                        row['timestamp'] ?? ''
                      ].where((e) => '$e'.isNotEmpty).join(' · '),
                      trailing: StatusPill(
                        label: '${row['status'] ?? ''}',
                        color: '${row['status']}' == 'On Time'
                            ? TawasulColors.forest
                            : TawasulColors.gold,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Roster
// ===========================================================================

class ClassRosterScreen extends ConsumerWidget {
  const ClassRosterScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title.trim())),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.classRoster,
            value: ref.watch(classRosterProvider(classId)),
            onRetry: () => ref.invalidate(classRosterProvider(classId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: _avatar(row),
                      title: _personName(row),
                      subtitle: '${row['formGroup'] ?? ''}',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

Widget _avatar(Map<String, dynamic> row) {
  final label = _personName(row);
  return CircleAvatar(
    backgroundColor: TawasulColors.mint,
    child: Text(
      label.isEmpty ? '?' : label.substring(0, 1),
      style: const TextStyle(
          color: TawasulColors.forest, fontWeight: FontWeight.w700),
    ),
  );
}

// ===========================================================================
// Attendance taking
// ===========================================================================

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  const TakeAttendanceScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  final Map<String, String> _chosen = {};
  bool _saving = false;

  Future<void> _save(List<Map<String, dynamic>> codes) async {
    if (_chosen.isEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(teacherRepositoryProvider);
    final date = _today();
    String? failure;
    for (final entry in _chosen.entries) {
      try {
        await repo.recordAttendance(
          personId: entry.key,
          date: date,
          attendanceCodeId: entry.value,
          courseClassId: widget.classId,
        );
      } catch (e) {
        failure = '$e';
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    _toast(context, failure ?? S.of(context).saved);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final roster = ref.watch(classRosterProvider(widget.classId));
    final codesFuture = ref.watch(attendanceCodesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title.trim())),
      body: roster.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (students) => codesFuture.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (codes) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];
              final id = '${student['gibbonPersonID']}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _personName(student),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: codes.map((code) {
                        final codeId = '${code['gibbonAttendanceCodeID']}';
                        final selected = _chosen[id] == codeId;
                        return ChoiceChip(
                          label: Text('${code['name'] ?? code['nameShort']}'),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _chosen[id] = codeId),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving
              ? null
              : () =>
                  _save(ref.read(attendanceCodesProvider).value ?? const []),
          child: Text(_saving ? strings.saving : strings.save),
        ),
      ),
    );
  }
}

final attendanceCodesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(schoolRepositoryProvider).attendanceCodes());

// ===========================================================================
// Markbook: columns + grade editing
// ===========================================================================

class ClassMarkbookScreen extends ConsumerWidget {
  const ClassMarkbookScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${strings.markbook} · $title')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newColumn(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.newColumn),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          AsyncCard(
            title: strings.markbook,
            value: ref.watch(markbookColumnsProvider(classId)),
            onRetry: () => ref.invalidate(markbookColumnsProvider(classId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: [row['type'] ?? '', row['date'] ?? '']
                          .where((e) => '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GradeEditorScreen(
                            classId: classId,
                            columnId: '${row['gibbonMarkbookColumnID']}',
                            columnName: '${row['name'] ?? ''}',
                            rawMax: '${row['attainmentRawMax'] ?? ''}',
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _newColumn(BuildContext context, WidgetRef ref) async {
    final strings = S.of(context);
    final name = TextEditingController();
    final type = TextEditingController(text: 'Test');
    final date = TextEditingController(text: _today());
    final max = TextEditingController(text: '100');

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.newColumn),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, strings.name),
              _field(type, strings.type),
              _field(date, '${strings.date} (YYYY-MM-DD)'),
              _field(max, strings.outOf),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.retry),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await ref.read(teacherRepositoryProvider).createMarkbookColumn(
            courseClassId: classId,
            name: name.text.trim(),
            type: type.text.trim().isEmpty ? 'Test' : type.text.trim(),
            date: date.text.trim(),
            attainmentRawMax: max.text.trim(),
          );
      ref.invalidate(markbookColumnsProvider(classId));
      if (context.mounted) _toast(context, strings.saved);
    } catch (e) {
      if (context.mounted) _toast(context, '$e');
    }
  }
}

/// Edit every student's grade and comment for one markbook column.
class GradeEditorScreen extends ConsumerStatefulWidget {
  const GradeEditorScreen({
    super.key,
    required this.classId,
    required this.columnId,
    required this.columnName,
    this.rawMax,
  });

  final String classId;
  final String columnId;
  final String columnName;
  final String? rawMax;

  @override
  ConsumerState<GradeEditorScreen> createState() => _GradeEditorScreenState();
}

class _GradeEditorScreenState extends ConsumerState<GradeEditorScreen> {
  final Map<String, TextEditingController> _grades = {};
  final Map<String, TextEditingController> _comments = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [..._grades.values, ..._comments.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(
      Map<String, TextEditingController> store, String id, String initial) {
    return store.putIfAbsent(id, () => TextEditingController(text: initial));
  }

  Future<void> _saveAll(List<Map<String, dynamic>> entries) async {
    setState(() => _saving = true);
    final repo = ref.read(teacherRepositoryProvider);
    final byStudent = <String, Map<String, dynamic>>{
      for (final e in entries) '${e['gibbonPersonIDStudent']}': e
    };
    String? failure;
    for (final id in _grades.keys) {
      final grade = _grades[id]!.text.trim();
      final comment = _comments[id]?.text.trim() ?? '';
      if (grade.isEmpty && comment.isEmpty) continue;
      try {
        await repo.saveGrade(
          columnId: widget.columnId,
          studentId: id,
          entryId: byStudent[id]?['gibbonMarkbookEntryID']?.toString(),
          attainmentValueRaw: grade.isEmpty ? null : grade,
          comment: comment.isEmpty ? null : comment,
        );
      } catch (e) {
        failure = '$e';
      }
    }
    ref.invalidate(markbookEntriesProvider(widget.columnId));
    if (!mounted) return;
    setState(() => _saving = false);
    _toast(context, failure ?? S.of(context).saved);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final roster = ref.watch(classRosterProvider(widget.classId));
    final entries = ref.watch(markbookEntriesProvider(widget.columnId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.columnName)),
      body: roster.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (students) => entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (rows) {
            final byStudent = <String, Map<String, dynamic>>{
              for (final e in rows) '${e['gibbonPersonIDStudent']}': e
            };
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = students[index];
                final id = '${student['gibbonPersonID']}';
                final existing = byStudent[id];
                final gradeController = _controller(_grades, id,
                    '${existing?['attainmentValueRaw'] ?? existing?['attainmentValue'] ?? ''}');
                final commentController =
                    _controller(_comments, id, '${existing?['comment'] ?? ''}');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_personName(student),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              gradeController,
                              widget.rawMax == null || widget.rawMax!.isEmpty
                                  ? strings.grade
                                  : '${strings.grade} / ${widget.rawMax}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _field(commentController, strings.comment),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving
              ? null
              : () => _saveAll(
                  ref.read(markbookEntriesProvider(widget.columnId)).value ??
                      const []),
          child: Text(_saving ? strings.saving : strings.save),
        ),
      ),
    );
  }
}

// ===========================================================================
// Assessments (tests / exams)
// ===========================================================================

class ClassAssessmentsScreen extends ConsumerWidget {
  const ClassAssessmentsScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${strings.assessments} · $title')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newAssessment(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.newAssessment),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          AsyncCard(
            title: strings.assessments,
            value: ref.watch(assessmentColumnsProvider(classId)),
            onRetry: () => ref.invalidate(assessmentColumnsProvider(classId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: [row['type'] ?? '', row['description'] ?? '']
                          .where((e) => '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AssessmentEntriesScreen(
                            classId: classId,
                            columnId:
                                '${row['gibbonInternalAssessmentColumnID']}',
                            columnName: '${row['name'] ?? ''}',
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _newAssessment(BuildContext context, WidgetRef ref) async {
    final strings = S.of(context);
    final creatorId = ref.read(currentUserProvider)?.personId;
    if (creatorId == null) return;
    final name = TextEditingController();
    final type = TextEditingController(text: 'Test');
    final description = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.newAssessment),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, strings.name),
              _field(type, strings.type),
              _field(description, strings.description, lines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.retry),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await ref.read(teacherRepositoryProvider).createAssessment(
            courseClassId: classId,
            name: name.text.trim(),
            description: description.text.trim(),
            type: type.text.trim().isEmpty ? 'Test' : type.text.trim(),
            creatorId: creatorId,
          );
      ref.invalidate(assessmentColumnsProvider(classId));
      if (context.mounted) _toast(context, strings.saved);
    } catch (e) {
      if (context.mounted) _toast(context, '$e');
    }
  }
}

class AssessmentEntriesScreen extends ConsumerStatefulWidget {
  const AssessmentEntriesScreen({
    super.key,
    required this.classId,
    required this.columnId,
    required this.columnName,
  });

  final String classId;
  final String columnId;
  final String columnName;

  @override
  ConsumerState<AssessmentEntriesScreen> createState() =>
      _AssessmentEntriesScreenState();
}

class _AssessmentEntriesScreenState
    extends ConsumerState<AssessmentEntriesScreen> {
  final Map<String, TextEditingController> _values = {};
  final Map<String, TextEditingController> _comments = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [..._values.values, ..._comments.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll(List<Map<String, dynamic>> entries) async {
    final editorId = ref.read(currentUserProvider)?.personId;
    if (editorId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(teacherRepositoryProvider);
    final byStudent = <String, Map<String, dynamic>>{
      for (final e in entries) '${e['gibbonPersonIDStudent']}': e
    };
    String? failure;
    for (final id in _values.keys) {
      final value = _values[id]!.text.trim();
      final comment = _comments[id]?.text.trim() ?? '';
      if (value.isEmpty && comment.isEmpty) continue;
      try {
        await repo.saveAssessmentEntry(
          columnId: widget.columnId,
          studentId: id,
          editorId: editorId,
          entryId:
              byStudent[id]?['gibbonInternalAssessmentEntryID']?.toString(),
          attainmentValue: value.isEmpty ? null : value,
          comment: comment.isEmpty ? null : comment,
        );
      } catch (e) {
        failure = '$e';
      }
    }
    ref.invalidate(assessmentEntriesProvider(widget.columnId));
    if (!mounted) return;
    setState(() => _saving = false);
    _toast(context, failure ?? S.of(context).saved);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final roster = ref.watch(classRosterProvider(widget.classId));
    final entries = ref.watch(assessmentEntriesProvider(widget.columnId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.columnName)),
      body: roster.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (students) => entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (rows) {
            final byStudent = <String, Map<String, dynamic>>{
              for (final e in rows) '${e['gibbonPersonIDStudent']}': e
            };
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = students[index];
                final id = '${student['gibbonPersonID']}';
                final existing = byStudent[id];
                final valueController = _values.putIfAbsent(
                    id,
                    () => TextEditingController(
                        text: '${existing?['attainmentValue'] ?? ''}'));
                final commentController = _comments.putIfAbsent(
                    id,
                    () => TextEditingController(
                        text: '${existing?['comment'] ?? ''}'));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_personName(student),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          Expanded(
                              child: _field(valueController, strings.grade)),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _field(commentController, strings.comment),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving
              ? null
              : () => _saveAll(
                  ref.read(assessmentEntriesProvider(widget.columnId)).value ??
                      const []),
          child: Text(_saving ? strings.saving : strings.save),
        ),
      ),
    );
  }
}

// ===========================================================================
// Behaviour
// ===========================================================================

class ClassBehaviourScreen extends ConsumerWidget {
  const ClassBehaviourScreen({
    super.key,
    required this.classId,
    required this.title,
  });

  final String classId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${strings.behaviour} · $title')),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.selectStudent,
            value: ref.watch(classRosterProvider(classId)),
            onRetry: () => ref.invalidate(classRosterProvider(classId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: _avatar(row),
                      title: _personName(row),
                      subtitle: '${row['formGroup'] ?? ''}',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentBehaviourScreen(
                            personId: '${row['gibbonPersonID']}',
                            name: _personName(row),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class StudentBehaviourScreen extends ConsumerWidget {
  const StudentBehaviourScreen({
    super.key,
    required this.personId,
    required this.name,
  });

  final String personId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _record(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.addBehaviour),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          AsyncCard(
            title: strings.history,
            value: ref.watch(studentBehaviourProvider(personId)),
            onRetry: () => ref.invalidate(studentBehaviourProvider(personId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['descriptor'] ?? row['type'] ?? ''}',
                      subtitle: [row['date'] ?? '', row['comment'] ?? '']
                          .where((e) => '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: StatusPill(
                        label: '${row['type']}' == 'Positive'
                            ? strings.positive
                            : strings.negative,
                        color: '${row['type']}' == 'Positive'
                            ? TawasulColors.forest
                            : TawasulColors.red,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _record(BuildContext context, WidgetRef ref) async {
    final strings = S.of(context);
    final creatorId = ref.read(currentUserProvider)?.personId;
    final schoolYearId = await ref.read(currentSchoolYearIdProvider.future);
    if (creatorId == null || schoolYearId == null) return;
    if (!context.mounted) return;

    final descriptor = TextEditingController();
    final comment = TextEditingController();
    var type = 'Positive';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(strings.addBehaviour),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(strings.positive),
                      selected: type == 'Positive',
                      onSelected: (_) => setLocal(() => type = 'Positive'),
                    ),
                    ChoiceChip(
                      label: Text(strings.negative),
                      selected: type == 'Negative',
                      onSelected: (_) => setLocal(() => type = 'Negative'),
                    ),
                  ],
                ),
                _field(descriptor, strings.descriptor),
                _field(comment, strings.comment, lines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.retry),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teacherRepositoryProvider).recordBehaviour(
            personId: personId,
            schoolYearId: schoolYearId,
            creatorId: creatorId,
            type: type,
            descriptor: descriptor.text.trim(),
            comment: comment.text.trim(),
          );
      ref.invalidate(studentBehaviourProvider(personId));
      if (context.mounted) _toast(context, strings.saved);
    } catch (e) {
      if (context.mounted) _toast(context, '$e');
    }
  }
}
