import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';

class SchoolTotals {
  SchoolTotals({
    required this.students,
    required this.staff,
    required this.classes,
    required this.formGroups,
  });

  final int students;
  final int staff;
  final int classes;
  final int formGroups;
}

/// Today's attendance picture: which classes were registered and which were not.
class AttendanceOverview {
  AttendanceOverview({required this.taken, required this.missing});
  final List<Map<String, dynamic>> taken;
  final List<Map<String, dynamic>> missing;

  int get total => taken.length + missing.length;
  double? get rate => total == 0 ? null : taken.length / total * 100;
}

class AdminRepository {
  AdminRepository(this.api);
  final ApiClient api;

  Future<int> _total(String path) async {
    final page = await api.getPage(path, pageSize: 1);
    return page.total;
  }

  Future<SchoolTotals> totals() async => SchoolTotals(
        students: await _total('/students'),
        staff: await _total('/staff'),
        classes: await _total('/classes'),
        formGroups: await _total('/form-groups'),
      );

  // ---------------------------------------------------------------- people

  Future<List<Map<String, dynamic>>> users({String? search}) =>
      api.getList('/users', pageSize: 40, sort: 'surname', search: search);

  Future<List<Map<String, dynamic>>> students({String? search}) =>
      api.getList('/students', pageSize: 40, sort: 'surname', search: search);

  Future<List<Map<String, dynamic>>> staff({String? search}) =>
      api.getList('/staff', pageSize: 40, search: search);

  Future<List<Map<String, dynamic>>> roles() =>
      api.getList('/roles', pageSize: 40);

  Future<List<Map<String, dynamic>>> classes({String? search}) =>
      api.getList('/classes', pageSize: 60, search: search);

  // ------------------------------------------------------ school structure

  Future<List<Map<String, dynamic>>> schoolYears() =>
      api.getList('/school-years', pageSize: 30, sort: '-firstDay');

  Future<List<Map<String, dynamic>>> yearGroups() =>
      api.getList('/year-groups', pageSize: 40);

  Future<List<Map<String, dynamic>>> formGroups() =>
      api.getList('/form-groups', pageSize: 60);

  Future<List<Map<String, dynamic>>> departments() =>
      api.getList('/departments', pageSize: 60);

  Future<List<Map<String, dynamic>>> spaces() =>
      api.getList('/spaces', pageSize: 60, filters: {'gibbonSpace.active': 'Y'});

  // ----------------------------------------------------------- attendance

  static String today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Classes with and without a register for today.
  Future<AttendanceOverview> attendanceOverview() async {
    final logs = await api.getList('/attendance-class-logs',
        pageSize: 200,
        filters: {'gibbonAttendanceLogCourseClass.date': today()});
    final loggedIds = logs
        .map((row) => '${row['gibbonCourseClassID'] ?? ''}')
        .where((id) => id.isNotEmpty)
        .toSet();

    final classes = await api.getList('/classes', pageSize: 200);
    final taken = <Map<String, dynamic>>[];
    final missing = <Map<String, dynamic>>[];
    for (final row in classes) {
      final id = '${row['gibbonCourseClassID'] ?? ''}';
      if (loggedIds.contains(id)) {
        taken.add(row);
      } else {
        missing.add(row);
      }
    }
    return AttendanceOverview(taken: taken, missing: missing);
  }

  // -------------------------------------------------------------- finance

  Future<List<Map<String, dynamic>>> fees() =>
      api.getList('/fees', pageSize: 60, filters: {'gibbonFinanceFee.active': 'Y'});

  Future<List<Map<String, dynamic>>> budgets() => api.getList('/budgets',
      pageSize: 60, filters: {'gibbonFinanceBudget.active': 'Y'});

  Future<List<Map<String, dynamic>>> expenses() =>
      api.getList('/expenses', pageSize: 60);

  // ---------------------------------------------------------------- staff

  Future<List<Map<String, dynamic>>> staffAbsences() =>
      api.getList('/staff-absences', pageSize: 60);

  Future<List<Map<String, dynamic>>> staffCoverage() =>
      api.getList('/staff-coverage', pageSize: 60);

  Future<List<Map<String, dynamic>>> substitutes() =>
      api.getList('/substitutes', pageSize: 60);

  // ----------------------------------------------------------------- logs

  Future<List<Map<String, dynamic>>> logs() =>
      api.getList('/logs', pageSize: 40, sort: '-timestamp');

  Future<List<Map<String, dynamic>>> apiLogs() =>
      api.getList('/api-logs', pageSize: 40, sort: '-timestamp');
}

final adminRepositoryProvider = Provider<AdminRepository>(
    (ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return AdminRepository(ref.watch(apiClientProvider));
});

final schoolTotalsProvider = FutureProvider<SchoolTotals>(
    (ref) => ref.watch(adminRepositoryProvider).totals());

final adminStudentSearchProvider = StateProvider<String>((ref) => '');
final adminStaffSearchProvider = StateProvider<String>((ref) => '');
final adminUserSearchProvider = StateProvider<String>((ref) => '');
final adminClassSearchProvider = StateProvider<String>((ref) => '');

final adminClassesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final search = ref.watch(adminClassSearchProvider);
  return ref
      .watch(adminRepositoryProvider)
      .classes(search: search.isEmpty ? null : search);
});

final adminStudentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final search = ref.watch(adminStudentSearchProvider);
  return ref
      .watch(adminRepositoryProvider)
      .students(search: search.isEmpty ? null : search);
});

final adminStaffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final search = ref.watch(adminStaffSearchProvider);
  return ref
      .watch(adminRepositoryProvider)
      .staff(search: search.isEmpty ? null : search);
});

final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final search = ref.watch(adminUserSearchProvider);
  return ref
      .watch(adminRepositoryProvider)
      .users(search: search.isEmpty ? null : search);
});

final adminRolesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).roles());

final adminSchoolYearsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).schoolYears());

final adminYearGroupsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).yearGroups());

final adminFormGroupsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).formGroups());

final adminDepartmentsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).departments());

final adminSpacesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).spaces());

final adminAttendanceOverviewProvider = FutureProvider<AttendanceOverview>(
    (ref) => ref.watch(adminRepositoryProvider).attendanceOverview());

final adminFeesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).fees());

final adminBudgetsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).budgets());

final adminExpensesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).expenses());

final adminStaffAbsencesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).staffAbsences());

final adminStaffCoverageProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).staffCoverage());

final adminSubstitutesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).substitutes());

final adminLogsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).logs());

final adminApiLogsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(adminRepositoryProvider).apiLogs());
