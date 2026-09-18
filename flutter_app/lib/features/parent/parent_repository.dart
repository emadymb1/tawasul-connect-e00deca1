import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/school_year.dart';

/// An invoice together with its line items.
class InvoiceDetail {
  InvoiceDetail({required this.invoice, required this.fees});
  final Map<String, dynamic> invoice;
  final List<Map<String, dynamic>> fees;
}

class ParentRepository {
  ParentRepository(this.api);
  final ApiClient api;

  /// Family ids the signed-in adult belongs to.
  Future<List<String>> familyIds(String personId) async {
    final adultRows = await api.getList('/family-adults',
        pageSize: 30,
        filters: {'gibbonFamilyAdult.gibbonPersonID': personId});
    return adultRows
        .map((row) => row['gibbonFamilyID']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
  }

  /// The families themselves (name, address, contact details).
  Future<List<Map<String, dynamic>>> families(String personId) async {
    final ids = await familyIds(personId);
    if (ids.isEmpty) return const [];
    final all = await api.getList('/families', pageSize: 100);
    return all
        .where((row) => ids.contains('${row['gibbonFamilyID'] ?? ''}'))
        .toList();
  }

  /// Children in the adult's families, each tagged with its family id.
  Future<List<Map<String, dynamic>>> children(String personId) async {
    final ids = await familyIds(personId);
    final children = <String, Map<String, dynamic>>{};
    for (final familyId in ids) {
      final rows = await api.getList('/family-children',
          pageSize: 30,
          filters: {'gibbonFamilyChild.gibbonFamilyID': familyId});
      for (final row in rows) {
        final childId = '${row['gibbonPersonID'] ?? ''}';
        if (childId.isEmpty) continue;
        children[childId] = {...row, 'gibbonFamilyID': familyId};
      }
    }
    return children.values.toList();
  }

  /// Invoices raised for one child (the invoicee is the student).
  Future<List<Map<String, dynamic>>> invoices(String studentId) =>
      api.getList('/invoices',
          pageSize: 40,
          sort: '-invoiceDueDate',
          filters: {'gibbonFinanceInvoicee.gibbonPersonID': studentId});

  Future<List<Map<String, dynamic>>> invoiceFees(String invoiceId) =>
      api.getList('/invoice-fees',
          pageSize: 60,
          filters: {'gibbonFinanceInvoiceFee.gibbonFinanceInvoiceID': invoiceId});

  Future<InvoiceDetail> invoiceDetail(Map<String, dynamic> invoice) async {
    final id = '${invoice['gibbonFinanceInvoiceID'] ?? ''}';
    final fees = id.isEmpty ? <Map<String, dynamic>>[] : await invoiceFees(id);
    return InvoiceDetail(invoice: invoice, fees: fees);
  }

  /// Recorded payments for a person (student or the paying adult).
  Future<List<Map<String, dynamic>>> payments(String personId) =>
      api.getList('/payments',
          pageSize: 40,
          sort: '-timestamp',
          filters: {'gibbonPayment.gibbonPersonID': personId});

  /// Meet-the-teacher bookings; the endpoint has no person filter, so the
  /// rows are narrowed here to the selected child and the signed-in adult.
  Future<List<Map<String, dynamic>>> bookings(
      String studentId, String parentId) async {
    final rows = await api.getList('/meet-the-teacher-bookings', pageSize: 100);
    return rows.where((row) {
      final values = row.values.map((v) => '$v').toSet();
      return values.contains(studentId) || values.contains(parentId);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> personUpdates(String personId) =>
      api.getList('/person-updates',
          pageSize: 30,
          sort: '-timestamp',
          filters: {'gibbonPersonUpdate.gibbonPersonID': personId});

  Future<List<Map<String, dynamic>>> familyUpdates(String familyId) =>
      api.getList('/family-updates',
          pageSize: 30,
          sort: '-timestamp',
          filters: {'gibbonFamilyUpdate.gibbonFamilyID': familyId});

  /// Ask the school to change a person's contact details.
  Future<void> requestPersonUpdate(
      String personId, Map<String, dynamic> fields) async {
    await api.post('/person-updates', {
      'gibbonPersonID': personId,
      'status': 'Pending',
      ...fields,
    });
  }

  /// Ask the school to change the family's address or contact details.
  Future<void> requestFamilyUpdate(
      String familyId, Map<String, dynamic> fields) async {
    await api.post('/family-updates', {
      'gibbonFamilyID': familyId,
      'status': 'Pending',
      ...fields,
    });
  }
}

final parentRepositoryProvider = Provider<ParentRepository>(
    (ref) {
  ref.watch(selectedSchoolYearProvider); // reload when the year switches
  return ParentRepository(ref.watch(apiClientProvider));
});

final parentChildrenProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(parentRepositoryProvider).children(personId));

final parentFamiliesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(parentRepositoryProvider).families(personId));

final parentInvoicesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, studentId) =>
            ref.watch(parentRepositoryProvider).invoices(studentId));

final parentInvoiceFeesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, invoiceId) =>
            ref.watch(parentRepositoryProvider).invoiceFees(invoiceId));

final parentPaymentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(parentRepositoryProvider).payments(personId));

/// (childId, parentId) pair for bookings.
final parentBookingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, (String, String)>(
        (ref, ids) =>
            ref.watch(parentRepositoryProvider).bookings(ids.$1, ids.$2));

final parentPersonUpdatesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, personId) =>
            ref.watch(parentRepositoryProvider).personUpdates(personId));

final parentFamilyUpdatesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, familyId) =>
            ref.watch(parentRepositoryProvider).familyUpdates(familyId));

/// Which child's data the parent portal is showing.
final selectedChildProvider = StateProvider<String?>((ref) => null);
