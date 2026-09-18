import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/permissions.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';
import '../auth/auth_controller.dart';
import '../school/school_repository.dart';
import 'community_repository.dart';

String _text(Map<String, dynamic> row, List<String> keys,
    [String fallback = '']) {
  for (final key in keys) {
    final value = row[key];
    if (value != null && '$value'.trim().isNotEmpty) return '$value'.trim();
  }
  return fallback;
}

String _shortDate(Object? value) {
  final text = '${value ?? ''}';
  return text.length >= 10 ? text.substring(0, 10) : text;
}

void _openPage(BuildContext context, String title, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: page),
  ));
}

/// Entry point for everything shared between the portals.
class CommunityHubPage extends ConsumerWidget {
  const CommunityHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final unread = ref.watch(unreadNotificationCountProvider);

    // Anything the server has already refused for this user is left out.
    final denied = ref.watch(permissionRegistryProvider);
    Widget row(IconData icon, String title, String? subtitle, Widget page,
            {required String endpoint}) =>
        denied.contains(endpoint)
            ? const SizedBox.shrink()
            : DetailRow(
                leading: Icon(icon, color: TawasulColors.forest),
                title: title,
                subtitle: subtitle,
                onTap: () => _openPage(context, title, page),
              );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        SectionCard(
          title: strings.schoolLife,
          children: [
            row(
              Icons.notifications_none_rounded,
              strings.notifications,
              unread > 0 ? '$unread' : null,
              const NotificationsPage(),
              endpoint: '/notifications',
            ),
            row(Icons.forum_outlined, strings.messages, null,
                const MessagesPage(),
                endpoint: '/messages'),
            row(Icons.campaign_outlined, strings.notices, null,
                const StreamPage(),
                endpoint: '/stream-posts'),
            row(Icons.event_outlined, strings.calendar, null,
                const CalendarPage(),
                endpoint: '/calendar-events'),
            row(Icons.local_library_outlined, strings.library, null,
                const LibraryPage(),
                endpoint: '/library-items'),
            row(Icons.sports_soccer_outlined, strings.activities, null,
                const ActivitiesPage(),
                endpoint: '/activities'),
            row(Icons.directions_bus_outlined, strings.trips, null,
                const TripsPage(),
                endpoint: '/trips'),
            row(Icons.support_agent_outlined, strings.helpdesk, null,
                const HelpdeskPage(),
                endpoint: '/helpdesk-issues'),
          ],
        ),
        if (denied.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              strings.hiddenByPermissions,
              style: const TextStyle(fontSize: 12, color: TawasulColors.muted),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------- notifications

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final value = ref.watch(myNotificationsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myNotificationsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.notifications,
            value: value,
            onRetry: () => ref.invalidate(myNotificationsProvider),
            builder: (rows) => rows.map((row) {
              final id = _text(row, ['gibbonNotificationID', 'id']);
              final unread =
                  _text(row, ['status'], 'New').toLowerCase() != 'archived';
              return DetailRow(
                title: _text(row, ['text', 'body', 'title'], '—'),
                subtitle: _text(row, ['timestamp', 'moduleName']),
                leading: Icon(
                  unread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: unread ? TawasulColors.gold : TawasulColors.muted,
                ),
                trailing: unread && id.isNotEmpty
                    ? TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(communityRepositoryProvider)
                                .archiveNotification(id);
                            ref.invalidate(myNotificationsProvider);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(strings.couldNotSave)),
                              );
                            }
                          }
                        },
                        child: Text(strings.markRead),
                      )
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ messages

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final value = ref.watch(communityMessagesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(communityMessagesProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.messages,
            value: value,
            onRetry: () => ref.invalidate(communityMessagesProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _text(row, ['subject', 'title'], '—'),
                      subtitle: [
                        _shortDate(row['timestamp']),
                        _text(row, ['status']),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      leading: const Icon(Icons.mail_outline_rounded,
                          color: TawasulColors.forest),
                      onTap: () => _openPage(
                        context,
                        strings.messages,
                        MessageDetailPage(message: row),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class MessageDetailPage extends ConsumerWidget {
  const MessageDetailPage({super.key, required this.message});
  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final id = _text(message, ['gibbonMessengerID', 'id']);
    final receipts = id.isEmpty
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(messageReceiptsProvider(id));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        SectionCard(
          title: _text(message, ['subject', 'title'], strings.messages),
          children: [
            Text(
              _text(message, ['body', 'text'], strings.nothingHere),
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              _shortDate(message['timestamp']),
              style: const TextStyle(color: TawasulColors.muted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncCard<List<Map<String, dynamic>>>(
          title: strings.readReceipts,
          value: receipts,
          onRetry: id.isEmpty
              ? null
              : () => ref.invalidate(messageReceiptsProvider(id)),
          builder: (rows) => rows
              .map((row) => DetailRow(
                    title: _text(
                        row, ['preferredName', 'surname', 'gibbonPersonID'], '—'),
                    subtitle: _text(row, ['confirmed']) == 'Y'
                        ? strings.completed
                        : strings.pending,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------- stream

class StreamPage extends ConsumerWidget {
  const StreamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final value = ref.watch(streamPostsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(streamPostsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.notices,
            value: value,
            onRetry: () => ref.invalidate(streamPostsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _text(row, ['title', 'subject', 'content'], '—'),
                      subtitle: [
                        _text(row, ['content', 'body']),
                        _shortDate(row['timestamp']),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      leading: const Icon(Icons.campaign_outlined,
                          color: TawasulColors.forest),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ calendar

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final events = ref.watch(upcomingEventsProvider);
    final days = ref.watch(specialDaysProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingEventsProvider);
        ref.invalidate(specialDaysProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.upcomingEvents,
            value: events,
            onRetry: () => ref.invalidate(upcomingEventsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _text(row, ['name', 'title'], '—'),
                      subtitle: [
                        _text(row, ['description']),
                        _text(row, ['spaceName', 'location']),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      leading: TimePill(time: _shortDate(row['dateStart'])),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.specialDays,
            value: days,
            onRetry: () => ref.invalidate(specialDaysProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _text(row, ['name', 'type'], '—'),
                      subtitle: _text(row, ['type']),
                      leading: TimePill(time: _shortDate(row['date'])),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- library

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final items = ref.watch(libraryItemsProvider);
    final loans = ref.watch(myLoansProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(libraryItemsProvider);
        ref.invalidate(myLoansProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.myLoans,
            value: loans,
            onRetry: () => ref.invalidate(myLoansProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _text(row, ['name', 'id'], '—'),
                      subtitle: _text(row, ['status', 'producer']),
                      leading: const Icon(Icons.menu_book_outlined,
                          color: TawasulColors.forest),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: strings.search,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (value) =>
                ref.read(librarySearchProvider.notifier).state = value.trim(),
          ),
          const SizedBox(height: 12),
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.catalogue,
            value: items,
            onRetry: () => ref.invalidate(libraryItemsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _text(row, ['name', 'id'], '—'),
                      subtitle: [
                        _text(row, ['producer', 'type']),
                        _text(row, ['status']),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      trailing: _text(row, ['borrowable']) == 'Y'
                          ? StatusPill(
                              label: strings.available,
                              color: TawasulColors.forest)
                          : null,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- activities

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final activities = ref.watch(activitiesProvider);
    final signUps = ref.watch(mySignUpsProvider);
    final personId = ref.watch(currentUserProvider)?.personId;

    final mine = signUps.maybeWhen(
      data: (rows) => {
        for (final row in rows)
          '${row['gibbonActivityID']}': _text(row, ['status'], 'Pending')
      },
      orElse: () => <String, String>{},
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activitiesProvider);
        ref.invalidate(mySignUpsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.activities,
            value: activities,
            onRetry: () => ref.invalidate(activitiesProvider),
            builder: (rows) => rows.map((row) {
              final id = _text(row, ['gibbonActivityID', 'id']);
              final status = mine[id];
              return DetailRow(
                title: _text(row, ['name'], '—'),
                subtitle: [
                  _text(row, ['type', 'provider']),
                  [_shortDate(row['programStart'] ?? row['dateStart']),
                          _shortDate(row['programEnd'] ?? row['dateEnd'])]
                      .where((e) => e.isNotEmpty)
                      .join(' → '),
                ].where((e) => e.isNotEmpty).join(' · '),
                leading: const Icon(Icons.sports_soccer_outlined,
                    color: TawasulColors.forest),
                trailing: status != null
                    ? StatusPill(label: status, color: TawasulColors.forest)
                    : (personId == null || id.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(communityRepositoryProvider)
                                    .signUpForActivity(
                                        activityId: id, personId: personId);
                                ref.invalidate(mySignUpsProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(strings.signUpSent)),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(strings.couldNotSave)),
                                  );
                                }
                              }
                            },
                            child: Text(strings.signUp),
                          )),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------- trips

class TripsPage extends ConsumerWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final value = ref.watch(tripsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(tripsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.trips,
            value: value,
            onRetry: () => ref.invalidate(tripsProvider),
            builder: (rows) => rows
                .map((row) => DetailRow(
                      title: _text(row, ['title', 'name'], '—'),
                      subtitle: _text(row, ['description', 'location']),
                      leading: const Icon(Icons.directions_bus_outlined,
                          color: TawasulColors.forest),
                      trailing: _text(row, ['status']).isEmpty
                          ? null
                          : StatusPill(
                              label: _text(row, ['status']),
                              color: TawasulColors.sage),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ helpdesk

class HelpdeskPage extends ConsumerWidget {
  const HelpdeskPage({super.key});

  Future<void> _newTicket(BuildContext context, WidgetRef ref) async {
    final strings = S.of(context);
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final personId = ref.read(currentUserProvider)?.personId;
    if (personId == null) return;
    final schoolYearId = ref.read(currentSchoolYearIdProvider).valueOrNull;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.newTicket,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TawasulColors.forest)),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: strings.subject),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 4,
              decoration: InputDecoration(labelText: strings.description),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                try {
                  await ref
                      .read(communityRepositoryProvider)
                      .createHelpdeskIssue(
                        personId: personId,
                        title: title,
                        description: bodyController.text.trim(),
                        schoolYearId: schoolYearId,
                      );
                  ref.invalidate(myHelpdeskIssuesProvider);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.ticketCreated)),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.couldNotSave)),
                    );
                  }
                }
              },
              child: Text(strings.sendRequest),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final value = ref.watch(myHelpdeskIssuesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newTicket(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.newTicket),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myHelpdeskIssuesProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            AsyncCard<List<Map<String, dynamic>>>(
              title: strings.helpdesk,
              value: value,
              onRetry: () => ref.invalidate(myHelpdeskIssuesProvider),
              builder: (rows) => rows
                  .map((row) => DetailRow(
                        title: _text(row, ['title', 'description'], '—'),
                        subtitle: [
                          _shortDate(row['date']),
                          _text(row, ['category']),
                        ].where((e) => e.isNotEmpty).join(' · '),
                        leading: const Icon(Icons.support_agent_outlined,
                            color: TawasulColors.forest),
                        trailing: _text(row, ['status']).isEmpty
                            ? null
                            : StatusPill(
                                label: _text(row, ['status']),
                                color: TawasulColors.sage),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
