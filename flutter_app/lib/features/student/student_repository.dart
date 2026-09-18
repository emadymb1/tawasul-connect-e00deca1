import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';
import '../auth/auth_controller.dart';

/// One day of a student's weekly timetable.
class TimetableDay {
  TimetableDay({required this.id, required this.name, required this.slots});
  final String id;
  final String name;
  final List<Map<String, dynamic>> slots;
}

/// A subject's markbook results plus its average.
class SubjectMarks {
  SubjectMarks({required this.course, required this.entries});
  final String course;
  final List<Map<String, dynamic>> entries;

  double? get average {
    final values = entries
        .map((row) =>
            double.tryParse('${row['attainmentValue'] ?? row['attainment'] ?? ''}'))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

/// Everything one student's screens need. Works for the student portal and,
/// with an explicit person id, for the parent portal's selected child.
class StudentRepository {
  StudentRepository(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>?> enrolment(String personId) async {
    final rows = await api.getList('/students',
        pageSize: 1,
        filters: {'gibbonStudentEnrolment.gibbonPersonID': personId});
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> classes(String personId) =>
      api.getList('/class-enrolments',
          pageSize: 60,
          filters: {'gibbonCourseClassPerson.gibbonPersonID': personId});

  /// All scheduled slots for the classes this student is enrolled in.
  Future<List<Map<String, dynamic>>> _slots(String personId) async {
    final enrolments = await classes(personId);
    final names = <String, String>{};
    for (final row in enrolments) {
      final id = row['gibbonCourseClassID']?.toString();
      if (id == null) continue;
      names[id] = [row['course'], row['class'] ?? row['className']]
          .where((e) => e != null && '$e'.isNotEmpty)
          .join(' · ');
    }
    if (names.isEmpty) return const [];

    final slots = <Map<String, dynamic>>[];
    for (final classId in names.keys) {
      final rows = await api.getList('/timetable-slots',
          pageSize: 40,
          filters: {'gibbonTTDayRowClass.gibbonCourseClassID': classId});
      for (final row in rows) {
        slots.add({
          ...row,
          'gibbonCourseClassID': classId,
          if (('${row['course'] ?? ''}').isEmpty) 'course': names[classId],
        });
      }
    }
    return slots;
  }

  /// The full weekly cycle: every day of the active timetable with its lessons.
  Future<List<TimetableDay>> weeklyTimetable(String personId) async {
    final slots = await _slots(personId);
    if (slots.isEmpty) return const [];

    final timetables =
        await api.getList('/timetables', pageSize: 10, filters: {'gibbonTT.active': 'Y'});
    final ttId = timetables.isEmpty
        ? null
        : timetables.first['gibbonTTID']?.toString();

    var days = <Map<String, dynamic>>[];
    if (ttId != null) {
      days = await api.getList('/timetable-days',
          pageSize: 20, filters: {'gibbonTTDay.gibbonTTID': ttId});
    }

    // Fall back to whatever day ids appear on the slots themselves.
    if (days.isEmpty) {
      final ids = slots
          .map((s) => s['gibbonTTDayID']?.toString())
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      days = ids.map((id) => {'gibbonTTDayID': id, 'name': id}).toList();
    }

    final result = <TimetableDay>[];
    for (final day in days) {
      final id = '${day['gibbonTTDayID'] ?? ''}';
      final rows = slots
          .where((s) => '${s['gibbonTTDayID'] ?? ''}' == id)
          .toList()
        ..sort((a, b) => '${a['timeStart']}'.compareTo('${b['timeStart']}'));
      result.add(TimetableDay(
        id: id,
        name: '${day['name'] ?? day['nameShort'] ?? id}',
        slots: rows,
      ));
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> lessonsToday(String personId) async {
    final week = await weeklyTimetable(personId);
    if (week.isEmpty) return const [];
    final today = _weekdayName(DateTime.now().weekday).toLowerCase();
    for (final day in week) {
      final name = day.name.toLowerCase();
      if (name.isNotEmpty && today.startsWith(name.substring(0, 3))) {
        return day.slots;
      }
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> homework(String personId) =>
      api.getList('/planner-entry-student-homeworks',
          pageSize: 40,
          sort: '-homeworkDueDateTime',
          filters: {
            'gibbonPlannerEntryStudentHomework.gibbonPersonID': personId
          });

  /// Tick or untick a homework item for the student.
  Future<void> setHomeworkComplete(String id, bool complete) =>
      api.patch('/planner-entry-student-homeworks/$id',
          {'homeworkComplete': complete ? 'Y' : 'N'});

  Future<List<Map<String, dynamic>>> markbook(String personId) =>
      api.getList('/markbook-entries',
          pageSize: 100,
          filters: {'gibbonMarkbookEntry.gibbonPersonIDStudent': personId});

  /// Markbook entries grouped per subject.
  Future<List<SubjectMarks>> markbookBySubject(String personId) async {
    final rows = await markbook(personId);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final course =
          '${row['course'] ?? row['courseName'] ?? row['className'] ?? ''}';
      grouped.putIfAbsent(course, () => []).add(row);
    }
    final keys = grouped.keys.toList()..sort();
    return keys
        .map((key) => SubjectMarks(course: key, entries: grouped[key]!))
        .toList();
  }

  /// Grade scale grades, keyed by their id, so a mark can show its descriptor.
  Future<Map<String, Map<String, dynamic>>> gradeScale() async {
    final scales = await api.getList('/grade-scales',
        pageSize: 20, filters: {'gibbonScale.active': 'Y'});
    final map = <String, Map<String, dynamic>>{};
    for (final scale in scales) {
      final scaleId = scale['gibbonScaleID']?.toString();
      if (scaleId == null) continue;
      final grades = await api.getList('/grade-scale-grades',
          pageSize: 60, filters: {'gibbonScaleGrade.gibbonScaleID': scaleId});
      for (final grade in grades) {
        final id = grade['gibbonScaleGradeID']?.toString();
        if (id != null) map[id] = grade;
      }
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> attendance(String personId,
          {int pageSize = 60}) =>
      api.getList('/attendance',
          pageSize: pageSize,
          sort: '-date',
          filters: {'gibbonAttendanceLogPerson.gibbonPersonID': personId});

  /// Attendance codes keyed by name and short name, for labels and colours.
  Future<Map<String, Map<String, dynamic>>> attendanceCodes() async {
    final rows = await api.getList('/attendance-codes', pageSize: 60);
    final map = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      for (final key in [row['name'], row['nameShort'], row['type']]) {
        final k = '${key ?? ''}';
        if (k.isNotEmpty) map[k] = row;
      }
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> behaviour(String personId) =>
      api.getList('/behaviour',
          pageSize: 40,
          sort: '-date',
          filters: {'gibbonBehaviour.gibbonPersonID': personId});

  /// Positive minus negative behaviour records — the school's house points view.
  Future<Map<String, int>> behaviourTally(String personId) async {
    final rows = await behaviour(personId);
    var positive = 0;
    var negative = 0;
    for (final row in rows) {
      final type = '${row['type'] ?? ''}'.toLowerCase();
      if (type.contains('positive') || type.contains('إيجاب')) {
        positive++;
      } else if (type.contains('negative') || type.contains('سلب')) {
        negative++;
      }
    }
    return {'positive': positive, 'negative': negative};
  }

  Future<Map<String, dynamic>?> house(String personId) async {
    final row = await enrolment(personId);
    final houseId = row?['gibbonHouseID']?.toString();
    if (houseId == null || houseId.isEmpty) return null;
    final houses = await api.getList('/houses', pageSize: 40);
    for (final h in houses) {
      if ('${h['gibbonHouseID'] ?? ''}' == houseId) return h;
    }
    return null;
  }

  /// Report archive entries belonging to this student, newest first.
  Future<List<Map<String, dynamic>>> reports(String personId) async {
    final entries = await api.getList('/report-archive-entries',
        pageSize: 40,
        sort: '-timestampCreated',
        filters: {'gibbonReportArchiveEntry.gibbonPersonID': personId});
    if (entries.isEmpty) return entries;

    final archives = await api.getList('/report-archives', pageSize: 40);
    final names = {
      for (final a in archives)
        '${a['gibbonReportArchiveID'] ?? ''}': '${a['name'] ?? ''}'
    };
    return entries
        .map((e) => {
              ...e,
              'archiveName':
                  names['${e['gibbonReportArchiveID'] ?? ''}'] ?? '',
            })
        .toList();
  }

  /// Percentage of attendance rows whose code counts as present.
  Future<double?> attendanceRate(String personId) async {
    final rows = await attendance(personId, pageSize: 100);
    if (rows.isEmpty) return null;
    final present = rows.where((row) {
      final type = '${row['type'] ?? row['code'] ?? ''}'.toLowerCase();
      final direction = '${row['direction'] ?? ''}'.toLowerCase();
      return type.contains('present') ||
          type.contains('حاضر') ||
          direction == 'in';
    }).length;
    return present / rows.length * 100;
  }

  /// Mean of all numeric markbook attainment values.
  Future<double?> gradeAverage(String personId) async {
    final rows = await markbook(personId);
    final values = rows
        .map((row) => double.tryParse(
            '${row['attainmentValue'] ?? row['attainment'] ?? ''}'))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static String _weekdayName(int weekday) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][weekday - 1];
}

final studentRepositoryProvider = Provider<StudentRepository>(
    (ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return StudentRepository(ref.watch(apiClientProvider));
});

/// The signed-in student's own person id (or the selected child's).
final activeStudentIdProvider = StateProvider<String?>((ref) {
  return ref.watch(currentUserProvider)?.personId;
});

final studentEnrolmentProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, personId) =>
            ref.watch(studentRepositoryProvider).enrolment(personId));

final studentLessonsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(studentRepositoryProvider).lessonsToday(personId));

final studentWeeklyTimetableProvider =
    FutureProvider.family<List<TimetableDay>, String>((ref, personId) =>
        ref.watch(studentRepositoryProvider).weeklyTimetable(personId));

final studentHomeworkProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(studentRepositoryProvider).homework(personId));

final studentMarkbookProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(studentRepositoryProvider).markbook(personId));

final studentSubjectMarksProvider =
    FutureProvider.family<List<SubjectMarks>, String>((ref, personId) =>
        ref.watch(studentRepositoryProvider).markbookBySubject(personId));

final gradeScaleProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  try {
    return await ref.watch(studentRepositoryProvider).gradeScale();
  } catch (_) {
    return const {};
  }
});

final studentAttendanceProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(studentRepositoryProvider).attendance(personId));

final attendanceCodesProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  try {
    return await ref.watch(studentRepositoryProvider).attendanceCodes();
  } catch (_) {
    return const {};
  }
});

final studentBehaviourProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(studentRepositoryProvider).behaviour(personId));

final studentBehaviourTallyProvider =
    FutureProvider.family<Map<String, int>, String>((ref, personId) =>
        ref.watch(studentRepositoryProvider).behaviourTally(personId));

final studentHouseProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, personId) =>
        ref.watch(studentRepositoryProvider).house(personId));

final studentReportsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(studentRepositoryProvider).reports(personId));

final studentAttendanceRateProvider = FutureProvider.family<double?, String>(
    (ref, personId) =>
        ref.watch(studentRepositoryProvider).attendanceRate(personId));

final studentGradeAverageProvider = FutureProvider.family<double?, String>(
    (ref, personId) =>
        ref.watch(studentRepositoryProvider).gradeAverage(personId));
