import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';
import '../auth/auth_controller.dart';
import '../community/community_pages.dart';
import 'student_repository.dart';

String _lessonTitle(Map<String, dynamic> row) =>
    (row['course'] ?? row['courseName'] ?? row['className'] ?? row['name'] ?? '')
        .toString();

String _lessonSubtitle(Map<String, dynamic> row) => [
      row['classNameShort'] ?? row['class'] ?? '',
      row['space'] ?? row['room'] ?? '',
    ].where((e) => '$e'.isNotEmpty).join(' · ');

String _time(Map<String, dynamic> row) {
  final start = '${row['timeStart'] ?? ''}';
  return start.length >= 5 ? start.substring(0, 5) : start;
}

String _shortDate(Object? value) {
  final text = '${value ?? ''}';
  return text.length >= 10 ? text.substring(0, 10) : text;
}

/// Person id whose data is shown: the signed-in student, or the child a parent
/// has selected.
String? _activeId(WidgetRef ref) =>
    ref.watch(activeStudentIdProvider) ??
    ref.watch(currentUserProvider)?.personId;

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final user = ref.watch(currentUserProvider);
    final personId = _activeId(ref);
    if (personId == null) return const SizedBox.shrink();

    final enrolment = ref.watch(studentEnrolmentProvider(personId));
    final rate = ref.watch(studentAttendanceRateProvider(personId));
    final average = ref.watch(studentGradeAverageProvider(personId));
    final tally = ref.watch(studentBehaviourTallyProvider(personId));
    final house = ref.watch(studentHouseProvider(personId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentEnrolmentProvider(personId));
        ref.invalidate(studentAttendanceRateProvider(personId));
        ref.invalidate(studentGradeAverageProvider(personId));
        ref.invalidate(studentLessonsProvider(personId));
        ref.invalidate(studentHomeworkProvider(personId));
        ref.invalidate(studentMarkbookProvider(personId));
        ref.invalidate(studentBehaviourTallyProvider(personId));
        ref.invalidate(studentHouseProvider(personId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(strings.mySchool.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: TawasulColors.muted)),
          const SizedBox(height: 4),
          Text(strings.studentPortal,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: TawasulColors.forest)),
          const SizedBox(height: 16),
          BrandHero(
            eyebrow: strings.hello,
            title: user?.displayName ?? '',
            subtitle: enrolment.maybeWhen(
              data: (row) => row == null
                  ? null
                  : [row['formGroup'], row['yearGroup']]
                      .where((e) => '$e'.isNotEmpty && e != null)
                      .join(' · '),
              orElse: () => null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: strings.attendanceRate,
                  value: rate.maybeWhen(
                    data: (v) => v == null ? '—' : '${v.toStringAsFixed(0)}%',
                    orElse: () => '…',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: strings.gradeAverage,
                  background: TawasulColors.sage,
                  value: average.maybeWhen(
                    data: (v) => v == null ? '—' : v.toStringAsFixed(0),
                    orElse: () => '…',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: strings.housePoints,
                  value: tally.maybeWhen(
                    data: (t) =>
                        '${(t['positive'] ?? 0) - (t['negative'] ?? 0)}',
                    orElse: () => '…',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: strings.house,
                  background: TawasulColors.sage,
                  value: house.maybeWhen(
                    data: (h) => '${h?['name'] ?? '—'}',
                    orElse: () => '…',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.myTimetable,
            value: ref.watch(studentLessonsProvider(personId)),
            onRetry: () => ref.invalidate(studentLessonsProvider(personId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: TimePill(time: _time(row)),
                      title: _lessonTitle(row),
                      subtitle: _lessonSubtitle(row),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.homework,
            value: ref.watch(studentHomeworkProvider(personId)),
            onRetry: () => ref.invalidate(studentHomeworkProvider(personId)),
            builder: (rows) => rows.take(6).map((row) {
              final due = '${row['homeworkDueDateTime'] ?? ''}';
              final overdue = DateTime.tryParse(due)?.isBefore(DateTime.now()) ??
                  false;
              final complete = '${row['homeworkComplete'] ?? ''}' == 'Y';
              return DetailRow(
                title: '${row['name'] ?? row['title'] ?? ''}',
                subtitle: due.isEmpty ? null : '${strings.due} ${_shortDate(due)}',
                trailing: complete
                    ? StatusPill(
                        label: strings.completed, color: TawasulColors.green)
                    : (overdue
                        ? StatusPill(
                            label: strings.overdue, color: TawasulColors.red)
                        : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.markbook,
            value: ref.watch(studentMarkbookProvider(personId)),
            onRetry: () => ref.invalidate(studentMarkbookProvider(personId)),
            builder: (rows) => rows
                .take(8)
                .map((row) => DetailRow(
                      title: [row['course'], row['columnName'] ?? row['name']]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: Text(
                        '${row['attainmentValue'] ?? row['attainment'] ?? '—'}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// The whole timetable cycle, one card per day, today's day expanded first.
class StudentTimetablePage extends ConsumerWidget {
  const StudentTimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = _activeId(ref);
    if (personId == null) return const SizedBox.shrink();

    final week = ref.watch(studentWeeklyTimetableProvider(personId));

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(studentWeeklyTimetableProvider(personId)),
      child: week.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            AsyncCard<List<TimetableDay>>(
              title: strings.weeklyTimetable,
              value: week,
              onRetry: () =>
                  ref.invalidate(studentWeeklyTimetableProvider(personId)),
              builder: (_) => const [],
            ),
          ],
        ),
        data: (days) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (days.isEmpty)
              SectionCard(title: strings.weeklyTimetable, children: const []),
            for (final day in days) ...[
              SectionCard(
                title: day.name,
                children: day.slots
                    .map((row) => DetailRow(
                          leading: TimePill(time: _time(row)),
                          title: _lessonTitle(row),
                          subtitle: _lessonSubtitle(row),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Homework the student can tick off, split into upcoming and past.
class StudentHomeworkPage extends ConsumerStatefulWidget {
  const StudentHomeworkPage({super.key});

  @override
  ConsumerState<StudentHomeworkPage> createState() =>
      _StudentHomeworkPageState();
}

class _StudentHomeworkPageState extends ConsumerState<StudentHomeworkPage> {
  final _saving = <String>{};

  Future<void> _toggle(String id, bool complete, String personId) async {
    final strings = S.of(context);
    setState(() => _saving.add(id));
    try {
      await ref
          .read(studentRepositoryProvider)
          .setHomeworkComplete(id, complete);
      ref.invalidate(studentHomeworkProvider(personId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.couldNotSave)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final personId = _activeId(ref);
    if (personId == null) return const SizedBox.shrink();

    final homework = ref.watch(studentHomeworkProvider(personId));
    final now = DateTime.now();

    List<Widget> rowsFor(List<Map<String, dynamic>> rows) => rows.map((row) {
          final id = '${row['gibbonPlannerEntryStudentHomeworkID'] ?? ''}';
          final due = '${row['homeworkDueDateTime'] ?? ''}';
          final complete = '${row['homeworkComplete'] ?? ''}' == 'Y';
          final busy = _saving.contains(id);
          return DetailRow(
            title: '${row['name'] ?? row['title'] ?? ''}',
            subtitle: [
              if (due.isNotEmpty) '${strings.due} ${_shortDate(due)}',
              if (('${row['course'] ?? ''}').isNotEmpty) '${row['course']}',
            ].join(' · '),
            trailing: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Checkbox(
                    value: complete,
                    onChanged: id.isEmpty
                        ? null
                        : (value) => _toggle(id, value ?? false, personId),
                  ),
          );
        }).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentHomeworkProvider(personId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.upcoming,
            value: homework,
            onRetry: () => ref.invalidate(studentHomeworkProvider(personId)),
            builder: (rows) => rowsFor(rows.where((row) {
              final due =
                  DateTime.tryParse('${row['homeworkDueDateTime'] ?? ''}');
              return due == null || !due.isBefore(now);
            }).toList()),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.past,
            value: homework,
            onRetry: () => ref.invalidate(studentHomeworkProvider(personId)),
            builder: (rows) => rowsFor(rows.where((row) {
              final due =
                  DateTime.tryParse('${row['homeworkDueDateTime'] ?? ''}');
              return due != null && due.isBefore(now);
            }).toList()),
          ),
        ],
      ),
    );
  }
}

/// Markbook grouped by subject, with the school's grade scale descriptors.
class StudentMarkbookPage extends ConsumerWidget {
  const StudentMarkbookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = _activeId(ref);
    if (personId == null) return const SizedBox.shrink();

    final subjects = ref.watch(studentSubjectMarksProvider(personId));
    final scale = ref.watch(gradeScaleProvider).valueOrNull ?? const {};

    String descriptorFor(Map<String, dynamic> row) {
      final id = '${row['gibbonScaleGradeID'] ?? ''}';
      final grade = scale[id];
      if (grade == null) return '${row['comment'] ?? ''}';
      return [grade['value'], grade['descriptor']]
          .where((e) => e != null && '$e'.isNotEmpty)
          .join(' — ');
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentSubjectMarksProvider(personId));
        ref.invalidate(gradeScaleProvider);
      },
      child: subjects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            AsyncCard<List<SubjectMarks>>(
              title: strings.markbook,
              value: subjects,
              onRetry: () =>
                  ref.invalidate(studentSubjectMarksProvider(personId)),
              builder: (_) => const [],
            ),
          ],
        ),
        data: (list) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (list.isEmpty)
              SectionCard(title: strings.markbook, children: const []),
            for (final subject in list) ...[
              SectionCard(
                title: subject.course.isEmpty
                    ? strings.markbook
                    : subject.course,
                children: [
                  if (subject.average != null)
                    DetailRow(
                      title: strings.average,
                      trailing: Text(
                        subject.average!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TawasulColors.forest),
                      ),
                    ),
                  ...subject.entries.map((row) => DetailRow(
                        title: '${row['columnName'] ?? row['name'] ?? ''}',
                        subtitle: descriptorFor(row),
                        trailing: Text(
                          '${row['attainmentValue'] ?? row['attainment'] ?? '—'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Attendance history with the school's own code names and any reason given.
class StudentAttendancePage extends ConsumerWidget {
  const StudentAttendancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = _activeId(ref);
    if (personId == null) return const SizedBox.shrink();

    final codes = ref.watch(attendanceCodesProvider).valueOrNull ?? const {};
    final rate = ref.watch(studentAttendanceRateProvider(personId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentAttendanceProvider(personId));
        ref.invalidate(studentAttendanceRateProvider(personId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          StatCard(
            label: strings.attendanceRate,
            value: rate.maybeWhen(
              data: (v) => v == null ? '—' : '${v.toStringAsFixed(0)}%',
              orElse: () => '…',
            ),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.history,
            value: ref.watch(studentAttendanceProvider(personId)),
            onRetry: () => ref.invalidate(studentAttendanceProvider(personId)),
            builder: (rows) => rows.map((row) {
              final type = '${row['type'] ?? row['code'] ?? ''}';
              final code = codes[type];
              final label = '${code?['name'] ?? type}';
              final direction = '${code?['direction'] ?? ''}'.toLowerCase();
              final present = direction == 'in' ||
                  label.toLowerCase().contains('present') ||
                  label.contains('حاضر');
              final reason = [row['reason'], row['context'], row['comment']]
                  .where((e) => e != null && '$e'.isNotEmpty)
                  .join(' · ');
              return DetailRow(
                title: _shortDate(row['date']),
                subtitle: reason,
                trailing: StatusPill(
                  label: label.isEmpty ? '—' : label,
                  color: present ? TawasulColors.green : TawasulColors.gold,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Behaviour records and the resulting house point balance.
class StudentBehaviourPage extends ConsumerWidget {
  const StudentBehaviourPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = _activeId(ref);
    if (personId == null) return const SizedBox.shrink();

    final tally = ref.watch(studentBehaviourTallyProvider(personId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentBehaviourProvider(personId));
        ref.invalidate(studentBehaviourTallyProvider(personId));
        ref.invalidate(studentHouseProvider(personId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: strings.positive,
                  value: tally.maybeWhen(
                      data: (t) => '${t['positive'] ?? 0}',
                      orElse: () => '…'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: strings.negative,
                  background: TawasulColors.sage,
                  value: tally.maybeWhen(
                      data: (t) => '${t['negative'] ?? 0}',
                      orElse: () => '…'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.behaviour,
            value: ref.watch(studentBehaviourProvider(personId)),
            onRetry: () => ref.invalidate(studentBehaviourProvider(personId)),
            builder: (rows) => rows.map((row) {
              final type = '${row['type'] ?? ''}';
              final positive = type.toLowerCase().contains('positive') ||
                  type.contains('إيجاب');
              return DetailRow(
                title: '${row['descriptor'] ?? type}',
                subtitle: [
                  _shortDate(row['date']),
                  '${row['comment'] ?? row['level'] ?? ''}',
                ].where((e) => e.isNotEmpty).join(' · '),
                trailing: StatusPill(
                  label: positive ? strings.positive : strings.negative,
                  color: positive ? TawasulColors.green : TawasulColors.red,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// School reports released to this student.
class StudentReportsPage extends ConsumerWidget {
  const StudentReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final personId = _activeId(ref);
    if (personId == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentReportsProvider(personId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.reports,
            value: ref.watch(studentReportsProvider(personId)),
            onRetry: () => ref.invalidate(studentReportsProvider(personId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['archiveName'] ?? row['name'] ?? ''}',
                      subtitle:
                          '${strings.issued} ${_shortDate(row['timestampCreated'])}',
                      trailing: StatusPill(
                        label: '${row['status'] ?? row['type'] ?? ''}',
                        color: TawasulColors.forest,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Hub for the screens that do not fit in the bottom bar.
class StudentMorePage extends ConsumerWidget {
  const StudentMorePage({super.key});

  void _open(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: page,
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        SectionCard(
          title: strings.more,
          children: [
            DetailRow(
              leading: const Icon(Icons.fact_check_outlined,
                  color: TawasulColors.forest),
              title: strings.attendance,
              onTap: () => _open(context, strings.attendance,
                  const StudentAttendancePage()),
            ),
            DetailRow(
              leading: const Icon(Icons.emoji_events_outlined,
                  color: TawasulColors.forest),
              title: strings.behaviour,
              subtitle: strings.housePoints,
              onTap: () => _open(
                  context, strings.behaviour, const StudentBehaviourPage()),
            ),
            DetailRow(
              leading: const Icon(Icons.description_outlined,
                  color: TawasulColors.forest),
              title: strings.reports,
              onTap: () =>
                  _open(context, strings.reports, const StudentReportsPage()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: strings.schoolLife,
          children: [
            DetailRow(
              leading: const Icon(Icons.notifications_none_rounded,
                  color: TawasulColors.forest),
              title: strings.notifications,
              onTap: () => _open(
                  context, strings.notifications, const NotificationsPage()),
            ),
            DetailRow(
              leading: const Icon(Icons.forum_outlined,
                  color: TawasulColors.forest),
              title: strings.messages,
              onTap: () =>
                  _open(context, strings.messages, const MessagesPage()),
            ),
            DetailRow(
              leading: const Icon(Icons.event_outlined,
                  color: TawasulColors.forest),
              title: strings.calendar,
              onTap: () =>
                  _open(context, strings.calendar, const CalendarPage()),
            ),
            DetailRow(
              leading: const Icon(Icons.local_library_outlined,
                  color: TawasulColors.forest),
              title: strings.library,
              onTap: () =>
                  _open(context, strings.library, const LibraryPage()),
            ),
            DetailRow(
              leading: const Icon(Icons.sports_soccer_outlined,
                  color: TawasulColors.forest),
              title: strings.activities,
              onTap: () =>
                  _open(context, strings.activities, const ActivitiesPage()),
            ),
            DetailRow(
              leading:
                  const Icon(Icons.apps_rounded, color: TawasulColors.forest),
              title: strings.schoolLife,
              subtitle:
                  '${strings.notices} · ${strings.trips} · ${strings.helpdesk}',
              onTap: () =>
                  _open(context, strings.schoolLife, const CommunityHubPage()),
            ),
          ],
        ),
      ],
    );
  }
}
