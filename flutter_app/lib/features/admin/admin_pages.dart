import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';
import '../auth/auth_controller.dart';
import '../school/school_repository.dart';
import 'admin_repository.dart';
import 'module_pages.dart';
import 'people_pages.dart';
import 'people_repository.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final user = ref.watch(currentUserProvider);
    final totals = ref.watch(schoolTotalsProvider);
    final overview = ref.watch(adminAttendanceOverviewProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(schoolTotalsProvider);
        ref.invalidate(adminAttendanceOverviewProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(schoolYearsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          BrandHero(
            eyebrow: strings.adminPortal,
            title: user?.displayName ?? '',
            subtitle: user?.roleName,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: strings.students,
                  value: totals.maybeWhen(
                      data: (t) => '${t.students}', orElse: () => '…'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: strings.staff,
                  background: TawasulColors.sage,
                  value: totals.maybeWhen(
                      data: (t) => '${t.staff}', orElse: () => '…'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: strings.classes,
                  background: TawasulColors.gold,
                  value: totals.maybeWhen(
                      data: (t) => '${t.classes}', orElse: () => '…'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: strings.registersTaken,
                  background: TawasulColors.mint,
                  value: overview.maybeWhen(
                      data: (o) => o.rate == null
                          ? '—'
                          : '${o.rate!.toStringAsFixed(0)}%',
                      orElse: () => '…'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.widgets_rounded, color: TawasulColors.forest),
              title: Text(strings.openModules,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(strings.modulesSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(strings.modules)),
                    body: const AdminModulesPage(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: '${strings.missingRegisters} · ${strings.today}',
            value: overview,
            onRetry: () => ref.invalidate(adminAttendanceOverviewProvider),
            builder: (o) => o.missing.isEmpty
                ? [Text(strings.nothingHere)]
                : o.missing
                    .take(15)
                    .map((row) => DetailRow(
                          title: [row['course'], row['name'] ?? row['class']]
                              .where((e) => e != null && '$e'.isNotEmpty)
                              .join(' · '),
                          trailing: StatusPill(
                              label: strings.missingRegisters,
                              color: TawasulColors.red),
                        ))
                    .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.schoolYear,
            value: ref.watch(schoolYearsProvider),
            onRetry: () => ref.invalidate(schoolYearsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle:
                          '${row['firstDay'] ?? ''} → ${row['lastDay'] ?? ''}',
                      trailing: '${row['status']}' == 'Current'
                          ? StatusPill(
                              label: '${row['status']}',
                              color: TawasulColors.green)
                          : null,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.notices,
            value: ref.watch(notificationsProvider),
            onRetry: () => ref.invalidate(notificationsProvider),
            builder: (rows) => rows
                .take(8)
                .map((row) => DetailRow(
                      title: '${row['text'] ?? ''}',
                      subtitle:
                          '${row['moduleName'] ?? ''} · ${row['timestamp'] ?? ''}',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// People: students, staff, all users and the school's roles.
class AdminPeoplePage extends ConsumerWidget {
  const AdminPeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: strings.students),
              Tab(text: strings.staff),
              Tab(text: strings.users),
              Tab(text: strings.classes),
              Tab(text: strings.roles),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const AdminStudentsPage(),
                const AdminStaffPage(),
                const AdminUsersPage(),
                const AdminClassesPage(),
                _RolesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminRolesProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.roles,
            value: ref.watch(adminRolesProvider),
            onRetry: () => ref.invalidate(adminRolesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: [row['category'], row['type']]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class AdminStudentsPage extends ConsumerWidget {
  const AdminStudentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStudentsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: strings.search,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (value) =>
                ref.read(adminStudentSearchProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.students,
            value: ref.watch(adminStudentsProvider),
            onRetry: () => ref.invalidate(adminStudentsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: _Avatar(name: '${row['preferredName'] ?? ''}'),
                      title:
                          '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                              .trim(),
                      subtitle: [row['formGroup'], row['yearGroup']]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: TawasulColors.muted),
                      onTap: () => _openPerson(context, row),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (_) => const StudentEnrolmentFormPage()),
              );
              if (changed == true) ref.invalidate(adminStudentsProvider);
            },
            icon: const Icon(Icons.school_outlined),
            label: Text(strings.enrolStudent),
          ),
        ],
      ),
    );
  }
}

/// Opens the person behind any list row that carries a gibbonPersonID.
void _openPerson(BuildContext context, Map<String, dynamic> row) {
  final id = personId(row);
  if (id == null) return;
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PersonDetailPage(personId: id, initial: row),
  ));
}

class AdminStaffPage extends ConsumerWidget {
  const AdminStaffPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStaffProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: strings.search,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (value) =>
                ref.read(adminStaffSearchProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.staff,
            value: ref.watch(adminStaffProvider),
            onRetry: () => ref.invalidate(adminStaffProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: _Avatar(name: '${row['preferredName'] ?? ''}'),
                      title:
                          '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                              .trim(),
                      subtitle: '${row['jobTitle'] ?? row['type'] ?? ''}',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: TawasulColors.muted),
                      onTap: () => _openPerson(context, row),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminUsersProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: strings.search,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (value) =>
                ref.read(adminUserSearchProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.users,
            value: ref.watch(adminUsersProvider),
            onRetry: () => ref.invalidate(adminUsersProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: _Avatar(name: '${row['preferredName'] ?? ''}'),
                      title:
                          '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                              .trim(),
                      subtitle: [row['username'], row['email'], row['status']]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: TawasulColors.muted),
                      onTap: () => _openPerson(context, row),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const PersonFormPage()),
              );
              if (changed == true) ref.invalidate(adminUsersProvider);
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(strings.newUser),
          ),
        ],
      ),
    );
  }
}

/// Classes: search, then open a class to see and change its members.
class AdminClassesPage extends ConsumerWidget {
  const AdminClassesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminClassesProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: strings.searchClasses,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (value) =>
                ref.read(adminClassSearchProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.classes,
            value: ref.watch(adminClassesProvider),
            onRetry: () => ref.invalidate(adminClassesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      leading: const Icon(Icons.class_outlined,
                          color: TawasulColors.forest),
                      title: className(row),
                      subtitle: [
                        row['department'],
                        if (row['enrolmentCount'] != null ||
                            row['students'] != null)
                          '${strings.students}: ${row['enrolmentCount'] ?? row['students']}',
                      ].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: TawasulColors.muted),
                      onTap: row['gibbonCourseClassID'] == null
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ClassMembersPage(classRow: row),
                              )),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// School structure: years, year groups, form groups, departments, spaces.
class AdminSchoolPage extends ConsumerWidget {
  const AdminSchoolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminSchoolYearsProvider);
        ref.invalidate(adminYearGroupsProvider);
        ref.invalidate(adminFormGroupsProvider);
        ref.invalidate(adminDepartmentsProvider);
        ref.invalidate(adminSpacesProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.schoolYear,
            value: ref.watch(adminSchoolYearsProvider),
            onRetry: () => ref.invalidate(adminSchoolYearsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle:
                          '${row['firstDay'] ?? ''} → ${row['lastDay'] ?? ''}',
                      trailing: '${row['status']}' == 'Current'
                          ? StatusPill(
                              label: '${row['status']}',
                              color: TawasulColors.green)
                          : null,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.yearGroups,
            value: ref.watch(adminYearGroupsProvider),
            onRetry: () => ref.invalidate(adminYearGroupsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: '${row['nameShort'] ?? ''}',
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.formGroups,
            value: ref.watch(adminFormGroupsProvider),
            onRetry: () => ref.invalidate(adminFormGroupsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: '${row['tutor'] ?? row['space'] ?? ''}',
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.departments,
            value: ref.watch(adminDepartmentsProvider),
            onRetry: () => ref.invalidate(adminDepartmentsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: '${row['type'] ?? ''}',
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.spaces,
            value: ref.watch(adminSpacesProvider),
            onRetry: () => ref.invalidate(adminSpacesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: [row['type'], row['capacity']]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Finance overview: fees, budgets and expenses.
class AdminFinancePage extends ConsumerWidget {
  const AdminFinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminFeesProvider);
        ref.invalidate(adminBudgetsProvider);
        ref.invalidate(adminExpensesProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.fees,
            value: ref.watch(adminFeesProvider),
            onRetry: () => ref.invalidate(adminFeesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: '${row['category'] ?? ''}',
                      trailing: Text('${row['fee'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.budgets,
            value: ref.watch(adminBudgetsProvider),
            onRetry: () => ref.invalidate(adminBudgetsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: '${row['category'] ?? ''}',
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.expenses,
            value: ref.watch(adminExpensesProvider),
            onRetry: () => ref.invalidate(adminExpensesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['title'] ?? row['name'] ?? ''}',
                      subtitle: '${row['budget'] ?? ''}',
                      trailing: StatusPill(
                        label: '${row['status'] ?? ''}',
                        color: '${row['status'] ?? ''}'
                                .toLowerCase()
                                .contains('paid')
                            ? TawasulColors.green
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

/// Operations: attendance registers, staff absence and cover, system logs.
class AdminOperationsPage extends ConsumerWidget {
  const AdminOperationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminAttendanceOverviewProvider);
        ref.invalidate(adminStaffAbsencesProvider);
        ref.invalidate(adminStaffCoverageProvider);
        ref.invalidate(adminSubstitutesProvider);
        ref.invalidate(adminLogsProvider);
        ref.invalidate(adminApiLogsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: '${strings.registersTaken} · ${strings.today}',
            value: ref.watch(adminAttendanceOverviewProvider),
            onRetry: () => ref.invalidate(adminAttendanceOverviewProvider),
            builder: (o) => [
              DetailRow(
                title: strings.registersTaken,
                trailing: Text('${o.taken.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              DetailRow(
                title: strings.missingRegisters,
                trailing: Text('${o.missing.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: TawasulColors.red)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.staffAbsence,
            value: ref.watch(adminStaffAbsencesProvider),
            onRetry: () => ref.invalidate(adminStaffAbsencesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title:
                          '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                              .trim(),
                      subtitle: [row['type'], row['dateStart'], row['dateEnd']]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: StatusPill(
                        label: '${row['status'] ?? ''}',
                        color: '${row['coverageRequired'] ?? ''}' == 'Y'
                            ? TawasulColors.red
                            : TawasulColors.green,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.cover,
            value: ref.watch(adminStaffCoverageProvider),
            onRetry: () => ref.invalidate(adminStaffCoverageProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['coverage'] ?? row['status'] ?? ''}',
                      subtitle: '${row['notesStatus'] ?? ''}',
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.substitutes,
            value: ref.watch(adminSubstitutesProvider),
            onRetry: () => ref.invalidate(adminSubstitutesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title:
                          '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                              .trim(),
                      subtitle: '${row['type'] ?? ''}',
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.systemLogs,
            value: ref.watch(adminLogsProvider),
            onRetry: () => ref.invalidate(adminLogsProvider),
            builder: (rows) => rows
                .take(20)
                .map((row) => DetailRow(
                      title: '${row['title'] ?? row['gibbonLogID'] ?? ''}',
                      subtitle: '${row['timestamp'] ?? ''}',
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.apiLogs,
            value: ref.watch(adminApiLogsProvider),
            onRetry: () => ref.invalidate(adminApiLogsProvider),
            builder: (rows) => rows
                .take(20)
                .map((row) => DetailRow(
                      title:
                          '${row['method'] ?? ''} ${row['resource'] ?? ''}'.trim(),
                      subtitle: '${row['timestamp'] ?? ''}',
                      trailing: StatusPill(
                        label: '${row['statusCode'] ?? ''}',
                        color: '${row['statusCode'] ?? ''}'.startsWith('2')
                            ? TawasulColors.green
                            : TawasulColors.red,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().substring(0, 1);
    return CircleAvatar(
      backgroundColor: TawasulColors.mint,
      child: Text(
        initial,
        style: const TextStyle(
            color: TawasulColors.forest, fontWeight: FontWeight.w700),
      ),
    );
  }
}
