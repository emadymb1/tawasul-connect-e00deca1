import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';

/// Hand-designed people workflows on top of the generic Manage engine:
/// person records (`/users`), student enrolments (`/students`) and class
/// enrolments (`/class-enrolments`). Every call is live; the server's own
/// permissions decide what the signed-in administrator may do.
class PeopleRepository {
  PeopleRepository(this.api);
  final ApiClient api;

  // ---------------------------------------------------------------- lookups

  Future<List<Map<String, dynamic>>> roles() =>
      api.getList('/roles', pageSize: 60, sort: 'name');

  Future<List<Map<String, dynamic>>> houses() =>
      api.getList('/houses', pageSize: 60, sort: 'name');

  Future<List<Map<String, dynamic>>> yearGroups() =>
      api.getList('/year-groups', pageSize: 60, sort: 'sequenceNumber');

  Future<List<Map<String, dynamic>>> formGroups() =>
      api.getList('/form-groups', pageSize: 100, sort: 'name');

  Future<List<Map<String, dynamic>>> searchPeople(String search) =>
      api.getList('/users',
          pageSize: 25, sort: 'surname', search: search.isEmpty ? null : search);

  Future<List<Map<String, dynamic>>> searchClasses(String search) =>
      api.getList('/classes',
          pageSize: 25, search: search.isEmpty ? null : search);

  /// The id of the school year the app is working in: the selected year, the
  /// account's own year, or the year flagged Current by the server.
  Future<String?> workingSchoolYearId() async {
    if (api.schoolYearId != null) return api.schoolYearId;
    try {
      final rows = await api.getList('/school-years',
          pageSize: 5, filters: {'gibbonSchoolYear.status': 'Current'});
      if (rows.isNotEmpty) {
        return rows.first['gibbonSchoolYearID']?.toString();
      }
    } catch (_) {}
    return null;
  }

  // ----------------------------------------------------------------- people

  Future<Map<String, dynamic>> person(String personId) =>
      api.getObject('/users/$personId');

  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> body) =>
      api.post('/users', body);

  Future<Map<String, dynamic>> updatePerson(
          String personId, Map<String, dynamic> body) =>
      api.patch('/users/$personId', body);

  // ---------------------------------------------------- student enrolments

  Future<List<Map<String, dynamic>>> studentEnrolments(String personId) =>
      api.getList('/students',
          pageSize: 20,
          filters: {'gibbonStudentEnrolment.gibbonPersonID': personId});

  Future<Map<String, dynamic>> createEnrolment(Map<String, dynamic> body) =>
      api.post('/students', body);

  Future<Map<String, dynamic>> updateEnrolment(
          String enrolmentId, Map<String, dynamic> body) =>
      api.patch('/students/$enrolmentId', body);

  Future<void> deleteEnrolment(String enrolmentId) =>
      api.delete('/students/$enrolmentId');

  // ------------------------------------------------------ class enrolments

  Future<List<Map<String, dynamic>>> classEnrolmentsFor(String personId) =>
      api.getList('/class-enrolments',
          pageSize: 100,
          filters: {'gibbonCourseClassPerson.gibbonPersonID': personId});

  Future<List<Map<String, dynamic>>> classMembers(String classId) =>
      api.getList('/class-enrolments',
          pageSize: 200,
          filters: {'gibbonCourseClassPerson.gibbonCourseClassID': classId});

  Future<Map<String, dynamic>> addToClass({
    required String classId,
    required String personId,
    required String role,
  }) =>
      api.post('/class-enrolments', {
        'gibbonCourseClassID': classId,
        'gibbonPersonID': personId,
        'role': role,
      });

  Future<Map<String, dynamic>> changeClassRole(
          String enrolmentId, String role) =>
      api.patch('/class-enrolments/$enrolmentId', {'role': role});

  Future<void> removeFromClass(String enrolmentId) =>
      api.delete('/class-enrolments/$enrolmentId');
}

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return PeopleRepository(ref.watch(apiClientProvider));
});

final peopleRolesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(peopleRepositoryProvider).roles());

final peopleHousesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(peopleRepositoryProvider).houses());

final peopleYearGroupsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(peopleRepositoryProvider).yearGroups());

final peopleFormGroupsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(peopleRepositoryProvider).formGroups());

/// A full person record by id.
final personProvider = FutureProvider.family<Map<String, dynamic>, String>(
    (ref, id) => ref.watch(peopleRepositoryProvider).person(id));

/// The student enrolments of one person (one per school year).
final personEnrolmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, id) => ref.watch(peopleRepositoryProvider).studentEnrolments(id));

/// The classes one person is attached to.
final personClassesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, id) => ref.watch(peopleRepositoryProvider).classEnrolmentsFor(id));

/// Everyone attached to one class.
final classMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, id) => ref.watch(peopleRepositoryProvider).classMembers(id));

/// Display helpers shared by the people screens.
String personName(Map<String, dynamic> row) {
  final preferred = '${row['preferredName'] ?? row['firstName'] ?? ''}'.trim();
  final surname = '${row['surname'] ?? ''}'.trim();
  final name = '$preferred $surname'.trim();
  if (name.isNotEmpty) return name;
  return '${row['officialName'] ?? row['username'] ?? row['name'] ?? ''}';
}

String? personId(Map<String, dynamic> row) =>
    (row['gibbonPersonID'] ?? row['personID'])?.toString();

String className(Map<String, dynamic> row) {
  final course = '${row['course'] ?? row['courseName'] ?? row['courseNameShort'] ?? ''}'
      .trim();
  final name = '${row['name'] ?? row['class'] ?? row['nameShort'] ?? ''}'.trim();
  if (course.isNotEmpty && name.isNotEmpty && course != name) {
    return '$course · $name';
  }
  return name.isNotEmpty ? name : course;
}
