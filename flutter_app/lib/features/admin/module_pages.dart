import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/permissions.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import 'manage_repository.dart';
import 'manage_pages.dart';
import 'resource_catalog.dart';

// ---------------------------------------------------------------------------
// Administrator portal: one page per server module.
//
// The module hub mirrors the modules the Tawasul server exposes, so an
// administrator can walk the platform the same way they would in the browser
// menu, then open any resource inside a module with full create / edit /
// delete support from the shared Manage engine.
// ---------------------------------------------------------------------------

/// Every module in the catalogue with its resources, filtered by the search
/// text typed on the module hub.
final adminModuleSearchProvider = StateProvider<String>((ref) => '');

final adminModulesProvider = Provider<Map<String, List<ApiResource>>>((ref) {
  final term = ref.watch(adminModuleSearchProvider).trim().toLowerCase();
  final grouped = <String, List<ApiResource>>{};
  for (final r in apiResources) {
    if (term.isNotEmpty &&
        !r.module.toLowerCase().contains(term) &&
        !r.title.toLowerCase().contains(term) &&
        !r.path.contains(term) &&
        !r.description.toLowerCase().contains(term)) {
      continue;
    }
    grouped.putIfAbsent(r.module, () => []).add(r);
  }
  return grouped;
});

/// Record count for a single resource, used as a badge on module pages.
final adminResourceCountProvider =
    FutureProvider.family<int, String>((ref, path) async {
  return ref.watch(manageRepositoryProvider).count(path);
});

/// Arabic names for the server modules; English falls back to the module name.
const _moduleAr = <String, String>{
  'Activities': 'الأنشطة',
  'Admissions': 'القبول والتسجيل',
  'Alumni': 'الخريجون',
  'ATL': 'مهارات التعلم',
  'Attendance': 'الحضور والغياب',
  'Badges': 'الأوسمة',
  'Behaviour': 'السلوك',
  'Calendar': 'التقويم',
  'CFA': 'التقويم التكويني',
  'Clinics': 'العيادات',
  'Credentials': 'بيانات الدخول',
  'Crowd Assessment': 'التقييم الجماعي',
  'Data Updater': 'تحديث البيانات',
  'Deep Learning': 'التعلم العميق',
  'Departments': 'الأقسام',
  'Finance': 'المالية',
  'Flexible Learning': 'التعلم المرن',
  'Form Builder': 'منشئ النماذج',
  'Formal Assessment': 'التقييم الرسمي',
  'Free Learning': 'التعلم الحر',
  'Help Desk': 'الدعم الفني',
  'Higher Education': 'التعليم العالي',
  'House Points': 'نقاط البيوت',
  'IB Diploma': 'دبلوم البكالوريا',
  'IB PYP': 'برنامج السنوات الابتدائية',
  'Individual Needs': 'الاحتياجات الفردية',
  'Info Grid': 'لوحة المعلومات',
  'Library': 'المكتبة',
  'Markbook': 'سجل الدرجات',
  'Mastery Transcript': 'سجل الإتقان',
  'Medical': 'السجل الطبي',
  'Meet The Teacher': 'لقاء المعلمين',
  'Messenger': 'الرسائل',
  'Planner': 'الخطة الدراسية',
  'Policies': 'السياسات',
  'Professional Development': 'التطوير المهني',
  'Query Builder': 'منشئ الاستعلامات',
  'Reports': 'التقارير',
  'Rest API': 'واجهة البرمجة',
  'Rubrics': 'معايير التقييم',
  'School Admin': 'إدارة المدرسة',
  'Staff': 'الموظفون',
  'Stream': 'البث',
  'Students': 'الطلاب',
  'System Admin': 'إدارة النظام',
  'Timetable': 'الجدول الدراسي',
  'Timetable Admin': 'إدارة الجداول',
  'Tracking': 'المتابعة',
  'Trip Planner': 'الرحلات',
  'User Admin': 'إدارة المستخدمين',
  'Visual Assessment': 'التقييم المرئي',
};

const _moduleIcons = <String, IconData>{
  'Activities': Icons.sports_soccer_rounded,
  'Admissions': Icons.how_to_reg_rounded,
  'Alumni': Icons.school_rounded,
  'ATL': Icons.psychology_rounded,
  'Attendance': Icons.fact_check_rounded,
  'Badges': Icons.military_tech_rounded,
  'Behaviour': Icons.emoji_people_rounded,
  'Calendar': Icons.calendar_month_rounded,
  'CFA': Icons.rule_rounded,
  'Clinics': Icons.local_hospital_rounded,
  'Credentials': Icons.key_rounded,
  'Crowd Assessment': Icons.groups_rounded,
  'Data Updater': Icons.sync_rounded,
  'Deep Learning': Icons.auto_awesome_rounded,
  'Departments': Icons.account_tree_rounded,
  'Finance': Icons.payments_rounded,
  'Flexible Learning': Icons.dashboard_customize_rounded,
  'Form Builder': Icons.dynamic_form_rounded,
  'Formal Assessment': Icons.assignment_turned_in_rounded,
  'Free Learning': Icons.explore_rounded,
  'Help Desk': Icons.support_agent_rounded,
  'Higher Education': Icons.account_balance_rounded,
  'House Points': Icons.star_rounded,
  'IB Diploma': Icons.workspace_premium_rounded,
  'IB PYP': Icons.child_care_rounded,
  'Individual Needs': Icons.accessibility_new_rounded,
  'Info Grid': Icons.grid_view_rounded,
  'Library': Icons.menu_book_rounded,
  'Markbook': Icons.grading_rounded,
  'Mastery Transcript': Icons.verified_rounded,
  'Medical': Icons.medical_services_rounded,
  'Meet The Teacher': Icons.handshake_rounded,
  'Messenger': Icons.forum_rounded,
  'Planner': Icons.event_note_rounded,
  'Policies': Icons.policy_rounded,
  'Professional Development': Icons.trending_up_rounded,
  'Query Builder': Icons.query_stats_rounded,
  'Reports': Icons.description_rounded,
  'Rest API': Icons.api_rounded,
  'Rubrics': Icons.checklist_rounded,
  'School Admin': Icons.apartment_rounded,
  'Staff': Icons.badge_rounded,
  'Stream': Icons.podcasts_rounded,
  'Students': Icons.groups_2_rounded,
  'System Admin': Icons.settings_rounded,
  'Timetable': Icons.schedule_rounded,
  'Timetable Admin': Icons.edit_calendar_rounded,
  'Tracking': Icons.timeline_rounded,
  'Trip Planner': Icons.directions_bus_rounded,
  'User Admin': Icons.manage_accounts_rounded,
  'Visual Assessment': Icons.image_search_rounded,
};

String moduleLabel(BuildContext context, String module) =>
    S.of(context).isArabic ? (_moduleAr[module] ?? module) : module;

IconData moduleIcon(String module) =>
    _moduleIcons[module] ?? Icons.widgets_rounded;

// ---------------------------------------------------------------------------
// Module hub
// ---------------------------------------------------------------------------

class AdminModulesPage extends ConsumerWidget {
  const AdminModulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final grouped = ref.watch(adminModulesProvider);
    final denied = ref.watch(permissionRegistryProvider);

    final modules = grouped.keys.toList()
      ..sort((a, b) =>
          moduleLabel(context, a).compareTo(moduleLabel(context, b)));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(strings.modules,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(strings.modulesSubtitle,
            style: const TextStyle(color: TawasulColors.muted)),
        const SizedBox(height: 14),
        TextField(
          decoration: InputDecoration(
            hintText: strings.searchModules,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
          onChanged: (value) =>
              ref.read(adminModuleSearchProvider.notifier).state = value,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            for (final module in modules)
              _ModuleTile(
                module: module,
                count: grouped[module]!
                    .where((r) => !denied.contains(r.path))
                    .length,
              ),
          ],
        ),
        if (modules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(strings.nothingHere,
                style: const TextStyle(color: TawasulColors.muted)),
          ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, required this.count});
  final String module;
  final int count;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminModulePage(module: module)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: TawasulColors.mint,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: TawasulColors.forest,
                shape: BoxShape.circle,
              ),
              child: Icon(moduleIcon(module),
                  color: TawasulColors.cream, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleLabel(context, module),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TawasulColors.forestDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$count ${strings.resources}',
                    style: const TextStyle(
                        color: TawasulColors.muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One module: every page (resource) it offers
// ---------------------------------------------------------------------------

class AdminModulePage extends ConsumerWidget {
  const AdminModulePage({super.key, required this.module});
  final String module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final denied = ref.watch(permissionRegistryProvider);
    final resources = apiResources
        .where((r) => r.module == module && !denied.contains(r.path))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    final writable = resources.where((r) => !r.readOnly).length;

    return Scaffold(
      appBar: AppBar(title: Text(moduleLabel(context, module))),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: strings.resources,
                  value: '${resources.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: strings.editable,
                  background: TawasulColors.sage,
                  value: '$writable',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: strings.pages,
            children: [
              for (final r in resources)
                _ResourceRow(resource: r),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceRow extends ConsumerWidget {
  const _ResourceRow({required this.resource});
  final ApiResource resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final count = ref.watch(adminResourceCountProvider(resource.path));

    return DetailRow(
      title: resource.title,
      subtitle: resource.description,
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TawasulColors.mint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: count.when(
          data: (value) => Text(
            value > 999 ? '999+' : '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: TawasulColors.forestDeep,
            ),
          ),
          loading: () => const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.remove_rounded,
              size: 16, color: TawasulColors.muted),
        ),
      ),
      trailing: resource.readOnly
          ? StatusPill(label: strings.readOnly, color: TawasulColors.muted)
          : const Icon(Icons.chevron_right_rounded,
              color: TawasulColors.muted),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResourceListPage(resource: resource)),
      ),
    );
  }
}
