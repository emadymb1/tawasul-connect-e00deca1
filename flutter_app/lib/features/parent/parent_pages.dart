import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';
import '../auth/auth_controller.dart';
import '../community/community_pages.dart';
import '../student/student_pages.dart';
import '../student/student_repository.dart';
import 'parent_repository.dart';

/// Chips to switch between the parent's children; the selection drives every
/// child-scoped provider.
class ChildSwitcher extends ConsumerWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(currentUserProvider)?.personId;
    if (parentId == null) return const SizedBox.shrink();
    final children = ref.watch(parentChildrenProvider(parentId));

    return children.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('$e', style: const TextStyle(color: TawasulColors.red)),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(S.of(context).nothingHere),
          );
        }
        final firstId = '${rows.first['gibbonPersonID']}';
        final selected = ref.watch(selectedChildProvider) ?? firstId;

        // Make sure the child-scoped providers point at a child, not the adult.
        final active = ref.watch(activeStudentIdProvider);
        if (active == null || active == parentId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedChildProvider.notifier).state = selected;
            ref.read(activeStudentIdProvider.notifier).state = selected;
          });
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: rows.map((row) {
              final id = '${row['gibbonPersonID']}';
              final name =
                  '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'.trim();
              final isSelected = id == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(name.isEmpty ? id : name),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(selectedChildProvider.notifier).state = id;
                    ref.read(activeStudentIdProvider.notifier).state = id;
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// The id of the child currently being viewed, or null while none is chosen.
String? _childId(WidgetRef ref) {
  final parentId = ref.watch(currentUserProvider)?.personId;
  final childId = ref.watch(activeStudentIdProvider);
  if (childId == null || childId == parentId) return null;
  return childId;
}

class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        final parentId = ref.read(currentUserProvider)?.personId;
        if (parentId != null) ref.invalidate(parentChildrenProvider(parentId));
        final childId = ref.read(activeStudentIdProvider);
        if (childId != null) {
          ref.invalidate(studentLessonsProvider(childId));
          ref.invalidate(studentMarkbookProvider(childId));
          ref.invalidate(studentAttendanceRateProvider(childId));
          ref.invalidate(studentGradeAverageProvider(childId));
          ref.invalidate(studentBehaviourTallyProvider(childId));
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(strings.myChildren.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: TawasulColors.muted)),
          const SizedBox(height: 4),
          Text(strings.parentPortal,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: TawasulColors.forest)),
          const SizedBox(height: 12),
          const ChildSwitcher(),
          const SizedBox(height: 12),
          const _SelectedChildBody(),
        ],
      ),
    );
  }
}

class _SelectedChildBody extends ConsumerWidget {
  const _SelectedChildBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final childId = _childId(ref);
    if (childId == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(strings.noChildSelected),
      );
    }
    final rate = ref.watch(studentAttendanceRateProvider(childId));
    final average = ref.watch(studentGradeAverageProvider(childId));
    final tally = ref.watch(studentBehaviourTallyProvider(childId));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: strings.attendanceRate,
                value: rate.maybeWhen(
                    data: (v) => v == null ? '—' : '${v.toStringAsFixed(0)}%',
                    orElse: () => '…'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: strings.gradeAverage,
                background: TawasulColors.sage,
                value: average.maybeWhen(
                    data: (v) => v == null ? '—' : v.toStringAsFixed(0),
                    orElse: () => '…'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: strings.positive,
                background: TawasulColors.mint,
                value: tally.maybeWhen(
                    data: (v) => '${v['positive'] ?? 0}', orElse: () => '…'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: strings.negative,
                background: TawasulColors.sage,
                value: tally.maybeWhen(
                    data: (v) => '${v['negative'] ?? 0}', orElse: () => '…'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AsyncCard(
          title: strings.todaysLessons,
          value: ref.watch(studentLessonsProvider(childId)),
          onRetry: () => ref.invalidate(studentLessonsProvider(childId)),
          builder: (rows) => rows
              .map((row) => DetailRow(
                    leading: TimePill(time: _time(row['timeStart'])),
                    title: '${row['course'] ?? row['courseName'] ?? ''}',
                    subtitle: '${row['class'] ?? ''}',
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        AsyncCard(
          title: strings.homework,
          value: ref.watch(studentHomeworkProvider(childId)),
          onRetry: () => ref.invalidate(studentHomeworkProvider(childId)),
          builder: (rows) => rows
              .take(6)
              .map((row) => DetailRow(
                    title: '${row['name'] ?? row['homeworkName'] ?? ''}',
                    subtitle:
                        '${row['course'] ?? ''} · ${row['homeworkDueDateTime'] ?? ''}',
                    trailing: StatusPill(
                      label: '${row['homeworkComplete'] ?? ''}' == 'Y'
                          ? strings.completed
                          : strings.notCompleted,
                      color: '${row['homeworkComplete'] ?? ''}' == 'Y'
                          ? TawasulColors.green
                          : TawasulColors.red,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        AsyncCard(
          title: strings.markbook,
          value: ref.watch(studentMarkbookProvider(childId)),
          onRetry: () => ref.invalidate(studentMarkbookProvider(childId)),
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
    );
  }
}

String _time(Object? value) {
  final text = '$value';
  return text.length >= 5 ? text.substring(0, 5) : text;
}

/// List of children; tapping one opens the child's full record.
class ParentChildrenPage extends ConsumerWidget {
  const ParentChildrenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final parentId = ref.watch(currentUserProvider)?.personId;
    if (parentId == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(parentChildrenProvider(parentId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.myChildren,
            value: ref.watch(parentChildrenProvider(parentId)),
            onRetry: () => ref.invalidate(parentChildrenProvider(parentId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title:
                          '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                              .trim(),
                      subtitle: '${row['formGroup'] ?? row['yearGroup'] ?? ''}',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        final id = '${row['gibbonPersonID']}';
                        ref.read(selectedChildProvider.notifier).state = id;
                        ref.read(activeStudentIdProvider.notifier).state = id;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ParentChildRecordPage(
                            name:
                                '${row['preferredName'] ?? ''} ${row['surname'] ?? ''}'
                                    .trim(),
                          ),
                        ));
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Everything the school holds for one child, reusing the student screens.
class ParentChildRecordPage extends ConsumerWidget {
  const ParentChildRecordPage({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final items = <(IconData, String, Widget)>[
      (Icons.calendar_today_outlined, strings.weeklyTimetable,
          const StudentTimetablePage()),
      (Icons.assignment_outlined, strings.homework, const StudentHomeworkPage()),
      (Icons.bar_chart_rounded, strings.markbook, const StudentMarkbookPage()),
      (Icons.fact_check_outlined, strings.attendance,
          const StudentAttendancePage()),
      (Icons.emoji_events_outlined, strings.behaviour,
          const StudentBehaviourPage()),
      (Icons.description_outlined, strings.reports, const StudentReportsPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(name.isEmpty ? strings.childOverview : name)),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const _SelectedChildBody(),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.childOverview,
            children: items
                .map((item) => DetailRow(
                      leading: Icon(item.$1, color: TawasulColors.green),
                      title: item.$2,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: Text(item.$2)),
                            body: item.$3,
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

/// Invoices, their line items, and recorded payments.
class ParentFinancePage extends ConsumerWidget {
  const ParentFinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final childId = _childId(ref);

    return RefreshIndicator(
      onRefresh: () async {
        if (childId != null) {
          ref.invalidate(parentInvoicesProvider(childId));
          ref.invalidate(parentPaymentsProvider(childId));
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const ChildSwitcher(),
          const SizedBox(height: 12),
          if (childId == null)
            SectionCard(
              title: strings.finance,
              children: [Text(strings.noChildSelected)],
            )
          else ...[
            AsyncCard(
              title: strings.invoices,
              value: ref.watch(parentInvoicesProvider(childId)),
              onRetry: () => ref.invalidate(parentInvoicesProvider(childId)),
              builder: (rows) => rows
                  .map((row) => DetailRow(
                        title: '${row['name'] ?? row['invoiceID'] ?? ''}',
                        subtitle:
                            '${strings.dueDate}: ${row['invoiceDueDate'] ?? '—'}',
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${row['feeTotal'] ?? row['total'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            StatusPill(
                              label: '${row['status'] ?? ''}',
                              color: '${row['status'] ?? ''}'
                                      .toLowerCase()
                                      .contains('paid')
                                  ? TawasulColors.green
                                  : TawasulColors.gold,
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ParentInvoiceDetailPage(invoice: row),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            AsyncCard(
              title: strings.payments,
              value: ref.watch(parentPaymentsProvider(childId)),
              onRetry: () => ref.invalidate(parentPaymentsProvider(childId)),
              builder: (rows) => rows
                  .map((row) => DetailRow(
                        title: '${row['type'] ?? strings.payments}',
                        subtitle: '${row['timestamp'] ?? ''}',
                        trailing: Text(
                          '${row['amount'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class ParentInvoiceDetailPage extends ConsumerWidget {
  const ParentInvoiceDetailPage({super.key, required this.invoice});
  final Map<String, dynamic> invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final invoiceId = '${invoice['gibbonFinanceInvoiceID'] ?? ''}';

    return Scaffold(
      appBar: AppBar(title: Text(strings.invoiceDetails)),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SectionCard(
            title: '${invoice['name'] ?? strings.invoices}',
            children: [
              DetailRow(
                  title: strings.status,
                  trailing: Text('${invoice['status'] ?? '—'}')),
              DetailRow(
                  title: strings.dueDate,
                  trailing: Text('${invoice['invoiceDueDate'] ?? '—'}')),
              DetailRow(
                  title: strings.total,
                  trailing: Text(
                      '${invoice['feeTotal'] ?? invoice['total'] ?? '—'}',
                      style: const TextStyle(fontWeight: FontWeight.w800))),
              if (invoice['paidAmount'] != null)
                DetailRow(
                    title: strings.balance,
                    trailing: Text('${invoice['paidAmount']}')),
            ],
          ),
          const SizedBox(height: 16),
          if (invoiceId.isNotEmpty)
            AsyncCard(
              title: strings.feeItems,
              value: ref.watch(parentInvoiceFeesProvider(invoiceId)),
              onRetry: () => ref.invalidate(parentInvoiceFeesProvider(invoiceId)),
              builder: (rows) => rows
                  .map((row) => DetailRow(
                        title: '${row['name'] ?? ''}',
                        subtitle: '${row['description'] ?? ''}',
                        trailing: Text('${row['fee'] ?? row['amount'] ?? ''}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

/// Meet-the-teacher bookings for the selected child.
class ParentBookingsPage extends ConsumerWidget {
  const ParentBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final parentId = ref.watch(currentUserProvider)?.personId;
    final childId = _childId(ref);

    return RefreshIndicator(
      onRefresh: () async {
        if (childId != null && parentId != null) {
          ref.invalidate(parentBookingsProvider((childId, parentId)));
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const ChildSwitcher(),
          const SizedBox(height: 12),
          if (childId == null || parentId == null)
            SectionCard(
              title: strings.meetTheTeacher,
              children: [Text(strings.noChildSelected)],
            )
          else
            AsyncCard(
              title: strings.meetTheTeacher,
              value: ref.watch(parentBookingsProvider((childId, parentId))),
              onRetry: () =>
                  ref.invalidate(parentBookingsProvider((childId, parentId))),
              builder: (rows) => rows
                  .map((row) => DetailRow(
                        leading: TimePill(time: _time(row['timeStart'])),
                        title:
                            '${row['teacher'] ?? row['gibbonPersonIDTeacher'] ?? ''}',
                        subtitle: '${row['date'] ?? row['timestamp'] ?? ''}',
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

/// Family and personal details, plus data update requests to the school.
class ParentMorePage extends ConsumerWidget {
  const ParentMorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final parentId = ref.watch(currentUserProvider)?.personId;
    if (parentId == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(parentFamiliesProvider(parentId));
        ref.invalidate(parentPersonUpdatesProvider(parentId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard(
            title: strings.familyDetails,
            value: ref.watch(parentFamiliesProvider(parentId)),
            onRetry: () => ref.invalidate(parentFamiliesProvider(parentId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['name'] ?? ''}',
                      subtitle: [
                        row['homeAddress'],
                        row['homeAddressDistrict'],
                        row['homeAddressCountry'],
                      ]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: TextButton(
                        onPressed: () => _openFamilyForm(
                            context, ref, '${row['gibbonFamilyID'] ?? ''}'),
                        child: Text(strings.requestChange),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.myDetails,
            children: [
              DetailRow(
                title: strings.requestChange,
                subtitle: strings.updateRequests,
                leading: const Icon(Icons.edit_outlined,
                    color: TawasulColors.green),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openPersonForm(context, ref, parentId),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.schoolLife,
            children: [
              DetailRow(
                title: strings.notifications,
                leading: const Icon(Icons.notifications_none_rounded,
                    color: TawasulColors.forest),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(strings.notifications)),
                    body: const NotificationsPage(),
                  ),
                )),
              ),
              DetailRow(
                title: strings.schoolLife,
                subtitle:
                    '${strings.messages} · ${strings.calendar} · ${strings.activities} · ${strings.trips}',
                leading: const Icon(Icons.apps_rounded,
                    color: TawasulColors.forest),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(strings.schoolLife)),
                    body: const CommunityHubPage(),
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AsyncCard(
            title: strings.updateRequests,
            value: ref.watch(parentPersonUpdatesProvider(parentId)),
            onRetry: () => ref.invalidate(parentPersonUpdatesProvider(parentId)),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: '${row['timestamp'] ?? ''}',
                      subtitle: [row['phone1'], row['email'], row['address1']]
                          .where((e) => e != null && '$e'.isNotEmpty)
                          .join(' · '),
                      trailing: StatusPill(
                        label: '${row['status'] ?? strings.pending}',
                        color: '${row['status'] ?? ''}'
                                .toLowerCase()
                                .contains('approv')
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

  Future<void> _openPersonForm(
      BuildContext context, WidgetRef ref, String personId) async {
    final strings = S.of(context);
    await _showUpdateSheet(
      context: context,
      title: strings.myDetails,
      fields: {
        'phone1': strings.phone,
        'email': strings.email,
        'address1': strings.address,
      },
      onSubmit: (values) async {
        await ref
            .read(parentRepositoryProvider)
            .requestPersonUpdate(personId, values);
        ref.invalidate(parentPersonUpdatesProvider(personId));
      },
    );
  }

  Future<void> _openFamilyForm(
      BuildContext context, WidgetRef ref, String familyId) async {
    if (familyId.isEmpty) return;
    final strings = S.of(context);
    await _showUpdateSheet(
      context: context,
      title: strings.familyDetails,
      fields: {
        'homeAddress': strings.address,
        'homeAddressDistrict': strings.address,
      },
      onSubmit: (values) async {
        await ref
            .read(parentRepositoryProvider)
            .requestFamilyUpdate(familyId, values);
        ref.invalidate(parentFamilyUpdatesProvider(familyId));
      },
    );
  }
}

/// A small sheet that collects a few fields and sends them as an update request.
Future<void> _showUpdateSheet({
  required BuildContext context,
  required String title,
  required Map<String, String> fields,
  required Future<void> Function(Map<String, dynamic> values) onSubmit,
}) async {
  final strings = S.of(context);
  final controllers = {
    for (final key in fields.keys) key: TextEditingController(),
  };
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...fields.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[entry.key],
                    decoration: InputDecoration(labelText: entry.value),
                  ),
                )),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final values = <String, dynamic>{};
                      controllers.forEach((key, controller) {
                        if (controller.text.trim().isNotEmpty) {
                          values[key] = controller.text.trim();
                        }
                      });
                      if (values.isEmpty) return;
                      setState(() => saving = true);
                      try {
                        await onSubmit(values);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(strings.requestSent)),
                          );
                        }
                      } catch (_) {
                        setState(() => saving = false);
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(strings.couldNotSave)),
                          );
                        }
                      }
                    },
              child: Text(saving ? strings.saving : strings.sendRequest),
            ),
          ],
        ),
      ),
    ),
  );

  for (final controller in controllers.values) {
    controller.dispose();
  }
}

/// Kept for the existing bottom bar entry: finance is the invoices screen.
class ParentInvoicesPage extends ParentFinancePage {
  const ParentInvoicesPage({super.key});
}
