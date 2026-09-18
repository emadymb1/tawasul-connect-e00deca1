import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';

/// Shared school-wide reads used by several portals.
class SchoolRepository {
  SchoolRepository(this.api);
  final ApiClient api;

  Future<List<Map<String, dynamic>>> schoolYears() =>
      api.getList('/school-years', pageSize: 20, sort: 'sequenceNumber');

  Future<List<Map<String, dynamic>>> notifications({int pageSize = 20}) =>
      api.getList('/notifications', pageSize: pageSize, sort: '-timestamp');

  Future<List<Map<String, dynamic>>> notices({int pageSize = 10}) =>
      api.getList('/stream-posts', pageSize: pageSize, sort: '-timestamp');

  Future<List<Map<String, dynamic>>> calendarEvents({int pageSize = 10}) =>
      api.getList('/calendar-events', pageSize: pageSize);

  Future<List<Map<String, dynamic>>> attendanceCodes() =>
      api.getList('/attendance-codes', pageSize: 50);

  Future<List<Map<String, dynamic>>> gradeScaleGrades(String scaleId) =>
      api.getList('/grade-scale-grades',
          pageSize: 60, filters: {'gibbonScaleGrade.gibbonScaleID': scaleId});

  Future<int> countOf(String path,
      {Map<String, dynamic> filters = const {}}) async {
    final page = await api.getPage(path, pageSize: 1, filters: filters);
    return page.total;
  }
}

final schoolRepositoryProvider = Provider<SchoolRepository>(
    (ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return SchoolRepository(ref.watch(apiClientProvider));
});

final schoolYearsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(schoolRepositoryProvider).schoolYears());

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(schoolRepositoryProvider).notifications());

final noticesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(schoolRepositoryProvider).notices());

/// ID of the school year the server marks as current.
final currentSchoolYearIdProvider = FutureProvider<String?>((ref) async {
  final years = await ref.watch(schoolRepositoryProvider).schoolYears();
  for (final year in years) {
    if ('${year['status']}'.toLowerCase() == 'current') {
      return '${year['gibbonSchoolYearID']}';
    }
  }
  return years.isEmpty ? null : '${years.first['gibbonSchoolYearID']}';
});
