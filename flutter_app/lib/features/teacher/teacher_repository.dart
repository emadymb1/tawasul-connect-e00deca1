import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';

class TeacherRepository {
  TeacherRepository(this.api);
  final ApiClient api;

  // ---------------------------------------------------------------- classes

  /// Classes this teacher is attached to.
  Future<List<Map<String, dynamic>>> myClasses(String personId) =>
      api.getList('/class-enrolments',
          pageSize: 60,
          filters: {
            'gibbonCourseClassPerson.gibbonPersonID': personId,
            'gibbonCourseClassPerson.role': 'Teacher',
          });

  Future<List<Map<String, dynamic>>> classRoster(String courseClassId) =>
      api.getList('/class-enrolments',
          pageSize: 60,
          filters: {
            'gibbonCourseClassPerson.gibbonCourseClassID': courseClassId,
            'gibbonCourseClassPerson.role': 'Student',
          });

  Future<List<Map<String, dynamic>>> lessonsToday(String personId) async {
    final classes = await myClasses(personId);
    final slots = <Map<String, dynamic>>[];
    for (final row in classes) {
      final classId = row['gibbonCourseClassID']?.toString();
      if (classId == null) continue;
      slots.addAll(await api.getList('/timetable-slots',
          pageSize: 20,
          filters: {'gibbonTTDayRowClass.gibbonCourseClassID': classId}));
    }
    slots.sort((a, b) => '${a['timeStart']}'.compareTo('${b['timeStart']}'));
    return slots;
  }

  // ------------------------------------------------- lessons / planning

  /// Planner entries (lessons) for one class, newest first.
  Future<List<Map<String, dynamic>>> classLessons(String courseClassId) =>
      api.getList('/lessons',
          pageSize: 60,
          sort: '-date',
          filters: {'gibbonPlannerEntry.gibbonCourseClassID': courseClassId});

  Future<Map<String, dynamic>> lesson(String lessonId) =>
      api.getObject('/lessons/$lessonId');

  /// Create a lesson (lesson plan). Homework fields are optional.
  Future<Map<String, dynamic>> createLesson({
    required String courseClassId,
    required String name,
    required String date,
    required String timeStart,
    required String timeEnd,
    String? summary,
    String? description,
    String? teachersNotes,
    bool homework = false,
    String? homeworkDetails,
    String? homeworkDueDateTime,
    bool viewableStudents = true,
    bool viewableParents = true,
  }) =>
      api.post('/lessons', {
        'gibbonCourseClassID': courseClassId,
        'name': name,
        'date': date,
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        if (summary != null && summary.isNotEmpty) 'summary': summary,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (teachersNotes != null && teachersNotes.isNotEmpty)
          'teachersNotes': teachersNotes,
        'homework': homework ? 'Y' : 'N',
        if (homework && homeworkDetails != null)
          'homeworkDetails': homeworkDetails,
        if (homework && homeworkDueDateTime != null)
          'homeworkDueDateTime': homeworkDueDateTime,
        'viewableStudents': viewableStudents ? 'Y' : 'N',
        'viewableParents': viewableParents ? 'Y' : 'N',
      });

  Future<Map<String, dynamic>> updateLesson(
    String lessonId,
    Map<String, dynamic> changes,
  ) =>
      api.patch('/lessons/$lessonId', changes);

  // ------------------------------------------------------------- homework

  /// Lessons of a class that carry homework.
  Future<List<Map<String, dynamic>>> classHomework(String courseClassId) =>
      api.getList('/lessons',
          pageSize: 60,
          sort: '-date',
          filters: {
            'gibbonPlannerEntry.gibbonCourseClassID': courseClassId,
            'gibbonPlannerEntry.homework': 'Y',
          });

  /// Per-student homework records (completion flag) for one lesson.
  Future<List<Map<String, dynamic>>> homeworkProgress(String lessonId) =>
      api.getList('/planner-entry-student-homeworks',
          pageSize: 100,
          filters: {
            'gibbonPlannerEntryStudentHomework.gibbonPlannerEntryID': lessonId,
          });

  /// Student uploads / links submitted against one lesson's homework.
  Future<List<Map<String, dynamic>>> homeworkSubmissions(String lessonId) =>
      api.getList('/planner-entry-homeworks',
          pageSize: 100,
          sort: '-timestamp',
          filters: {
            'gibbonPlannerEntryHomework.gibbonPlannerEntryID': lessonId,
          });

  /// Assign or update a personalised homework record for one student.
  Future<Map<String, dynamic>> setStudentHomework({
    required String lessonId,
    required String personId,
    required String dueDateTime,
    required String details,
    bool complete = false,
    String? existingId,
  }) {
    final body = <String, dynamic>{
      'gibbonPlannerEntryID': int.tryParse(lessonId) ?? lessonId,
      'gibbonPersonID': int.tryParse(personId) ?? personId,
      'homeworkDueDateTime': dueDateTime,
      'homeworkDetails': details,
      'homeworkComplete': complete ? 'Y' : 'N',
    };
    return existingId == null
        ? api.post('/planner-entry-student-homeworks', body)
        : api.patch('/planner-entry-student-homeworks/$existingId', body);
  }

  // ------------------------------------------------------------- markbook

  Future<List<Map<String, dynamic>>> markbookColumns(String courseClassId) =>
      api.getList('/markbook-columns',
          pageSize: 60,
          sort: '-date',
          filters: {'gibbonMarkbookColumn.gibbonCourseClassID': courseClassId});

  Future<List<Map<String, dynamic>>> markbookEntries(String columnId) =>
      api.getList('/markbook-entries',
          pageSize: 100,
          filters: {'gibbonMarkbookEntry.gibbonMarkbookColumnID': columnId});

  Future<Map<String, dynamic>> createMarkbookColumn({
    required String courseClassId,
    required String name,
    required String type,
    required String date,
    String? description,
    String attainmentRawMax = '100',
    bool viewableStudents = true,
    bool viewableParents = true,
  }) =>
      api.post('/markbook-columns', {
        'gibbonCourseClassID': courseClassId,
        'name': name,
        'type': type,
        'date': date,
        if (description != null && description.isNotEmpty)
          'description': description,
        'attainment': 'Y',
        'attainmentRawMax': attainmentRawMax,
        'effort': 'N',
        'comment': 'Y',
        'complete': 'N',
        'viewableStudents': viewableStudents ? 'Y' : 'N',
        'viewableParents': viewableParents ? 'Y' : 'N',
      });

  /// Write one student's grade — PATCH when a row already exists, else POST.
  Future<Map<String, dynamic>> saveGrade({
    required String columnId,
    required String studentId,
    String? entryId,
    String? attainmentValueRaw,
    String? comment,
  }) {
    final body = <String, dynamic>{
      'gibbonMarkbookColumnID': columnId,
      'gibbonPersonIDStudent': studentId,
      if (attainmentValueRaw != null) 'attainmentValueRaw': attainmentValueRaw,
      if (attainmentValueRaw != null) 'attainmentValue': attainmentValueRaw,
      if (comment != null) 'comment': comment,
    };
    return entryId == null
        ? api.post('/markbook-entries', body)
        : api.patch('/markbook-entries/$entryId', body);
  }

  Future<Map<String, dynamic>> saveMarkbookEntry(
    String entryId,
    Map<String, dynamic> changes,
  ) =>
      api.patch('/markbook-entries/$entryId', changes);

  // ---------------------------------------------------------- assessments

  /// Internal assessments (tests / exams) of a class.
  Future<List<Map<String, dynamic>>> assessmentColumns(String courseClassId) =>
      api.getList('/internal-assessment-columns',
          pageSize: 60,
          filters: {
            'gibbonInternalAssessmentColumn.gibbonCourseClassID': courseClassId,
          });

  Future<List<Map<String, dynamic>>> assessmentEntries(String columnId) =>
      api.getList('/internal-assessment-entries',
          pageSize: 100,
          filters: {
            'gibbonInternalAssessmentEntry.gibbonInternalAssessmentColumnID':
                columnId,
          });

  Future<Map<String, dynamic>> createAssessment({
    required String courseClassId,
    required String name,
    required String description,
    required String type,
    required String creatorId,
    bool viewableStudents = true,
    bool viewableParents = true,
  }) =>
      api.post('/internal-assessment-columns', {
        'gibbonCourseClassID': int.tryParse(courseClassId) ?? courseClassId,
        'name': name,
        'description': description,
        'type': type,
        'attachment': '',
        'attainment': 'Y',
        'effort': 'N',
        'comment': 'Y',
        'uploadedResponse': 'N',
        'complete': 'N',
        'viewableStudents': viewableStudents ? 'Y' : 'N',
        'viewableParents': viewableParents ? 'Y' : 'N',
        'gibbonPersonIDCreator': int.tryParse(creatorId) ?? creatorId,
        'gibbonPersonIDLastEdit': int.tryParse(creatorId) ?? creatorId,
      });

  Future<Map<String, dynamic>> saveAssessmentEntry({
    required String columnId,
    required String studentId,
    required String editorId,
    String? entryId,
    String? attainmentValue,
    String? comment,
  }) {
    final body = <String, dynamic>{
      'gibbonInternalAssessmentColumnID': int.tryParse(columnId) ?? columnId,
      'gibbonPersonIDStudent': int.tryParse(studentId) ?? studentId,
      'gibbonPersonIDLastEdit': int.tryParse(editorId) ?? editorId,
      if (attainmentValue != null) 'attainmentValue': attainmentValue,
      if (comment != null) 'comment': comment,
    };
    return entryId == null
        ? api.post('/internal-assessment-entries', body)
        : api.patch('/internal-assessment-entries/$entryId', body);
  }

  // ------------------------------------------------------------ attendance

  Future<Map<String, dynamic>> recordAttendance({
    required String personId,
    required String date,
    required String attendanceCodeId,
    String? courseClassId,
    String? reason,
  }) =>
      api.post('/attendance', {
        'gibbonPersonID': personId,
        'date': date,
        'gibbonAttendanceCodeID': attendanceCodeId,
        if (courseClassId != null) 'gibbonCourseClassID': courseClassId,
        if (reason != null) 'reason': reason,
        'context': courseClassId == null ? 'Form Group' : 'Class',
        'direction': 'In',
      });

  // ------------------------------------------------------------- behaviour

  Future<List<Map<String, dynamic>>> studentBehaviour(String personId) =>
      api.getList('/behaviour',
          pageSize: 40,
          sort: '-date',
          filters: {'gibbonBehaviour.gibbonPersonID': personId});

  Future<Map<String, dynamic>> recordBehaviour({
    required String personId,
    required String schoolYearId,
    required String type,
    required String creatorId,
    String? descriptor,
    String? level,
    String? comment,
    String? lessonId,
  }) =>
      api.post('/behaviour', {
        'gibbonSchoolYearID': schoolYearId,
        'gibbonPersonID': personId,
        'gibbonPersonIDCreator': creatorId,
        'type': type,
        if (descriptor != null && descriptor.isNotEmpty)
          'descriptor': descriptor,
        if (level != null && level.isNotEmpty) 'level': level,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (lessonId != null) 'gibbonPlannerEntryID': lessonId,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });
}

final teacherRepositoryProvider = Provider<TeacherRepository>(
    (ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return TeacherRepository(ref.watch(apiClientProvider));
});

final teacherClassesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(teacherRepositoryProvider).myClasses(personId));

final teacherLessonsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(teacherRepositoryProvider).lessonsToday(personId));

final classRosterProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, classId) =>
            ref.watch(teacherRepositoryProvider).classRoster(classId));

final classLessonsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, classId) =>
            ref.watch(teacherRepositoryProvider).classLessons(classId));

final classHomeworkProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, classId) =>
            ref.watch(teacherRepositoryProvider).classHomework(classId));

final homeworkProgressProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, lessonId) =>
            ref.watch(teacherRepositoryProvider).homeworkProgress(lessonId));

final homeworkSubmissionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, lessonId) =>
            ref.watch(teacherRepositoryProvider).homeworkSubmissions(lessonId));

final markbookColumnsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, classId) =>
            ref.watch(teacherRepositoryProvider).markbookColumns(classId));

final markbookEntriesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, columnId) =>
            ref.watch(teacherRepositoryProvider).markbookEntries(columnId));

final assessmentColumnsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, classId) =>
            ref.watch(teacherRepositoryProvider).assessmentColumns(classId));

final assessmentEntriesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, columnId) =>
            ref.watch(teacherRepositoryProvider).assessmentEntries(columnId));

final studentBehaviourProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(teacherRepositoryProvider).studentBehaviour(personId));
