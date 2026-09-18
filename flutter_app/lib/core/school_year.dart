import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// One school year as published by `/school-years`.
class SchoolYear {
  const SchoolYear({
    required this.id,
    required this.name,
    this.status,
    this.firstDay,
    this.lastDay,
  });

  final String id;
  final String name;
  final String? status;
  final String? firstDay;
  final String? lastDay;

  bool get isCurrent => (status ?? '').toLowerCase() == 'current';

  static SchoolYear? fromJson(Map<String, dynamic> json) {
    final id = (json['gibbonSchoolYearID'] ?? json['schoolYearID'] ?? json['id'])
        ?.toString();
    if (id == null || id.isEmpty) return null;
    return SchoolYear(
      id: id,
      name: (json['name'] ?? json['nameShort'] ?? id).toString(),
      status: json['status']?.toString(),
      firstDay: json['firstDay']?.toString(),
      lastDay: json['lastDay']?.toString(),
    );
  }
}

/// The school year the administrator is working in.
///
/// `null` means "the year the signed-in account belongs to", which the API
/// client already holds after sign-in.
final selectedSchoolYearProvider = StateProvider<String?>((ref) => null);

/// Every school year the account may read. Empty when the server refuses.
final apiSchoolYearsProvider = FutureProvider<List<SchoolYear>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final page = await api.getPage('/school-years', pageSize: 50, sort: '-name');
    return page.items
        .map(SchoolYear.fromJson)
        .whereType<SchoolYear>()
        .toList();
  } catch (_) {
    return const [];
  }
});

/// Switches every screen to another school year.
///
/// The API client carries `gibbonSchoolYearID` on every request, and each
/// repository provider watches [selectedSchoolYearProvider], so changing it
/// reloads all open data.
void setSchoolYear(WidgetRef ref, String? id) {
  final api = ref.read(apiClientProvider);
  api.defaultSchoolYearId ??= api.schoolYearId;
  api.schoolYearId = id ?? api.defaultSchoolYearId;
  ref.read(selectedSchoolYearProvider.notifier).state = id;
}
