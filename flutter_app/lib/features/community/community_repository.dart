import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';
import '../auth/auth_controller.dart';

/// Cross-cutting school life: messages, notifications, the stream, the
/// calendar, the library, activities, trips and the help desk.
/// Every read and write goes straight to the server.
class CommunityRepository {
  CommunityRepository(this.api);
  final ApiClient api;

  // ---------------------------------------------------------------- messages

  /// Message wall broadcasts, newest first.
  Future<List<Map<String, dynamic>>> messages({int pageSize = 30}) =>
      api.getList('/messages', pageSize: pageSize, sort: '-timestamp');

  /// Delivery / read receipts for one message.
  Future<List<Map<String, dynamic>>> messageReceipts(String messageId) =>
      api.getList('/message-receipts',
          pageSize: 100,
          filters: {'gibbonMessengerReceipt.gibbonMessengerID': messageId});

  /// Who a message was aimed at (year groups, roles, form groups).
  Future<List<Map<String, dynamic>>> messageTargets(String messageId) =>
      api.getList('/messenger-targets',
          pageSize: 50,
          filters: {'gibbonMessengerTarget.gibbonMessengerID': messageId});

  /// Mark a message read for this person, when the server allows it.
  Future<void> confirmMessage(String receiptId) async {
    await api.patch('/message-receipts/$receiptId', {'confirmed': 'Y'});
  }

  // ----------------------------------------------------------- notifications

  Future<List<Map<String, dynamic>>> notifications(
      {String? personId, int pageSize = 40}) {
    return api.getList('/notifications',
        pageSize: pageSize,
        sort: '-timestamp',
        filters: {
          if (personId != null) 'gibbonNotification.gibbonPersonID': personId,
        });
  }

  Future<void> archiveNotification(String id) async {
    await api.patch('/notifications/$id', {'status': 'Archived'});
  }

  // ------------------------------------------------------------------ stream

  Future<List<Map<String, dynamic>>> streamPosts({int pageSize = 30}) =>
      api.getList('/stream-posts', pageSize: pageSize, sort: '-timestamp');

  // ---------------------------------------------------------------- calendar

  /// Calendar events from today onwards, soonest first.
  Future<List<Map<String, dynamic>>> upcomingEvents({int pageSize = 50}) async {
    final rows =
        await api.getList('/calendar-events', pageSize: pageSize, sort: 'dateStart');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final future = rows
        .where((row) => '${row['dateStart'] ?? ''}'.compareTo(today) >= 0)
        .toList();
    return future.isEmpty ? rows : future;
  }

  Future<List<Map<String, dynamic>>> specialDays({int pageSize = 60}) =>
      api.getList('/special-days', pageSize: pageSize, sort: 'date');

  // ----------------------------------------------------------------- library

  Future<List<Map<String, dynamic>>> libraryItems(
          {String? search, int pageSize = 40}) =>
      api.getList('/library-items',
          pageSize: pageSize, search: search, sort: 'name');

  /// Items currently signed out to this person.
  Future<List<Map<String, dynamic>>> myLoans(String personId) =>
      api.getList('/library-items', pageSize: 40, filters: {
        'gibbonLibraryItem.gibbonPersonIDStatusResponsible': personId,
      });

  Future<List<Map<String, dynamic>>> libraryEvents(String itemId) =>
      api.getList('/library-events',
          pageSize: 30,
          filters: {'gibbonLibraryItemEvent.gibbonLibraryItemID': itemId});

  // -------------------------------------------------------------- activities

  Future<List<Map<String, dynamic>>> activities({int pageSize = 50}) =>
      api.getList('/activities',
          pageSize: pageSize, filters: {'gibbonActivity.active': 'Y'});

  Future<List<Map<String, dynamic>>> mySignUps(String personId) =>
      api.getList('/activity-students', pageSize: 60, filters: {
        'gibbonActivityStudent.gibbonPersonID': personId,
      });

  Future<void> signUpForActivity({
    required String activityId,
    required String personId,
  }) async {
    await api.post('/activity-students', {
      'gibbonActivityID': activityId,
      'gibbonPersonID': personId,
      'status': 'Pending',
    });
  }

  // ------------------------------------------------------------------- trips

  Future<List<Map<String, dynamic>>> trips({int pageSize = 30}) =>
      api.getList('/trips', pageSize: pageSize);

  Future<List<Map<String, dynamic>>> tripDays(String tripId) =>
      api.getList('/trip-days',
          pageSize: 30,
          sort: 'startDate',
          filters: {'tripPlannerRequestDays.tripPlannerRequestID': tripId});

  // ---------------------------------------------------------------- helpdesk

  Future<List<Map<String, dynamic>>> helpdeskIssues(
          {String? personId, int pageSize = 30}) =>
      api.getList('/helpdesk-issues', pageSize: pageSize, sort: '-date', filters: {
        if (personId != null) 'helpDeskIssue.gibbonPersonID': personId,
      });

  Future<void> createHelpdeskIssue({
    required String personId,
    required String title,
    required String description,
    String? schoolYearId,
  }) async {
    await api.post('/helpdesk-issues', {
      'gibbonPersonID': personId,
      'createdByID': personId,
      'title': title,
      'description': description,
      'status': 'Unassigned',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      if (schoolYearId != null) 'gibbonSchoolYearID': schoolYearId,
    });
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>(
    (ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return CommunityRepository(ref.watch(apiClientProvider));
});

final communityMessagesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(communityRepositoryProvider).messages();
});

final messageReceiptsProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, messageId) {
  return ref.watch(communityRepositoryProvider).messageReceipts(messageId);
});

final myNotificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final personId = ref.watch(currentUserProvider)?.personId;
  return ref
      .watch(communityRepositoryProvider)
      .notifications(personId: personId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final value = ref.watch(myNotificationsProvider);
  return value.maybeWhen(
    data: (rows) => rows
        .where((row) => '${row['status'] ?? 'New'}'.toLowerCase() != 'archived')
        .length,
    orElse: () => 0,
  );
});

final streamPostsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(communityRepositoryProvider).streamPosts());

final upcomingEventsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(communityRepositoryProvider).upcomingEvents());

final specialDaysProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(communityRepositoryProvider).specialDays());

final librarySearchProvider = StateProvider<String>((ref) => '');

final libraryItemsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final search = ref.watch(librarySearchProvider);
  return ref.watch(communityRepositoryProvider).libraryItems(search: search);
});

final myLoansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final personId = ref.watch(currentUserProvider)?.personId;
  if (personId == null) return Future.value(const []);
  return ref.watch(communityRepositoryProvider).myLoans(personId);
});

final activitiesProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(communityRepositoryProvider).activities());

final mySignUpsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final personId = ref.watch(currentUserProvider)?.personId;
  if (personId == null) return Future.value(const []);
  return ref.watch(communityRepositoryProvider).mySignUps(personId);
});

final tripsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(communityRepositoryProvider).trips());

final myHelpdeskIssuesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final personId = ref.watch(currentUserProvider)?.personId;
  return ref
      .watch(communityRepositoryProvider)
      .helpdeskIssues(personId: personId);
});
