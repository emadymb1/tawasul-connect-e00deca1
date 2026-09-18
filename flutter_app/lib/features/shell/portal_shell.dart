import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/locale_controller.dart';
import '../../core/providers.dart';
import '../../widgets/refreshable.dart';
import '../../widgets/school_year_switcher.dart';
import '../../l10n/strings.dart';
import '../admin/admin_pages.dart';
import '../admin/manage_pages.dart';
import '../admin/system_pages.dart';
import '../auth/auth_controller.dart';
import '../auth/models.dart';
import '../community/community_pages.dart';
import '../community/community_repository.dart';
import '../parent/parent_pages.dart';
import '../student/student_pages.dart';
import '../teacher/teacher_pages.dart';

class PortalTab {
  const PortalTab({required this.icon, required this.label, required this.page});
  final IconData icon;
  final String label;
  final Widget page;
}

class PortalShell extends ConsumerStatefulWidget {
  const PortalShell({super.key});

  @override
  ConsumerState<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends ConsumerState<PortalShell> {
  int _index = 0;
  final List<int> _tabHistory = [0];

  void _selectTab(int value) {
    if (value == _index) return;
    setState(() {
      _index = value;
      if (value == 0) {
        _tabHistory
          ..clear()
          ..add(0);
      } else {
        _tabHistory.add(value);
      }
    });
  }

  Future<void> _handleBack() async {
    if (_index != 0) {
      setState(() {
        if (_tabHistory.length > 1) _tabHistory.removeLast();
        _index = _tabHistory.isEmpty ? 0 : _tabHistory.last;
      });
      return;
    }

    final strings = S.of(context);
    final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.exitApp),
            content: Text(strings.exitAppQuestion),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.no),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.yes),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldExit) await SystemNavigator.pop();
  }

  List<PortalTab> _tabs(Portal portal, S strings) {
    switch (portal) {
      case Portal.student:
        return [
          PortalTab(
              icon: Icons.grid_view_rounded,
              label: strings.dashboard,
              page: const StudentDashboardPage()),
          PortalTab(
              icon: Icons.calendar_today_outlined,
              label: strings.timetable,
              page: const StudentTimetablePage()),
          PortalTab(
              icon: Icons.assignment_outlined,
              label: strings.homework,
              page: const StudentHomeworkPage()),
          PortalTab(
              icon: Icons.bar_chart_rounded,
              label: strings.markbook,
              page: const StudentMarkbookPage()),
          PortalTab(
              icon: Icons.more_horiz_rounded,
              label: strings.more,
              page: const StudentMorePage()),
        ];
      case Portal.parent:
        return [
          PortalTab(
              icon: Icons.grid_view_rounded,
              label: strings.dashboard,
              page: const ParentDashboardPage()),
          PortalTab(
              icon: Icons.family_restroom_rounded,
              label: strings.myChildren,
              page: const ParentChildrenPage()),
          PortalTab(
              icon: Icons.receipt_long_outlined,
              label: strings.finance,
              page: const ParentFinancePage()),
          PortalTab(
              icon: Icons.event_available_outlined,
              label: strings.bookings,
              page: const ParentBookingsPage()),
          PortalTab(
              icon: Icons.more_horiz_rounded,
              label: strings.more,
              page: const ParentMorePage()),
        ];
      case Portal.teacher:
        return [
          PortalTab(
              icon: Icons.grid_view_rounded,
              label: strings.dashboard,
              page: const TeacherDashboardPage()),
          PortalTab(
              icon: Icons.calendar_today_outlined,
              label: strings.timetable,
              page: const TeacherTimetablePage()),
          PortalTab(
              icon: Icons.class_outlined,
              label: strings.classes,
              page: const TeacherClassesPage()),
          PortalTab(
              icon: Icons.fact_check_outlined,
              label: strings.attendance,
              page: const TeacherAttendancePage()),
          PortalTab(
              icon: Icons.bar_chart_rounded,
              label: strings.markbook,
              page: const TeacherMarkbookPage()),
        ];
      case Portal.admin:
        return [
          PortalTab(
              icon: Icons.grid_view_rounded,
              label: strings.dashboard,
              page: const AdminDashboardPage()),
          PortalTab(
              icon: Icons.groups_outlined,
              label: strings.people,
              page: const AdminPeoplePage()),
          PortalTab(
              icon: Icons.school_outlined,
              label: strings.school,
              page: const AdminSchoolPage()),
          PortalTab(
              icon: Icons.account_balance_wallet_outlined,
              label: strings.finance,
              page: const AdminFinancePage()),
          PortalTab(
              icon: Icons.tune_rounded,
              label: strings.operations,
              page: const AdminOperationsPage()),
          PortalTab(
              icon: Icons.dataset_outlined,
              label: strings.manage,
              page: const AdminManagePage()),
        ];
    }
  }

  void _push(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          Scaffold(appBar: AppBar(title: Text(title)), body: page),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final tabs = _tabs(user.portal, strings);
    final index = _index.clamp(0, tabs.length - 1);
    final unread = ref.watch(unreadNotificationCountProvider);


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TawasulColors.forest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('ت',
                  style: TextStyle(
                      color: TawasulColors.cream,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                strings.appName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (user.portal == Portal.admin) const SchoolYearSwitcher(),
          IconButton(
            tooltip: strings.notifications,
            onPressed: () => _push(
                context, strings.notifications, const NotificationsPage()),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              backgroundColor: TawasulColors.red,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          IconButton(
            tooltip: strings.schoolLife,
            onPressed: () =>
                _push(context, strings.schoolLife, const CommunityHubPage()),
            icon: const Icon(Icons.apps_rounded),
          ),
          IconButton(
            tooltip: strings.language,
            onPressed: () =>
                ref.read(localeControllerProvider.notifier).toggle(),
            icon: Text(
              strings.isArabic ? 'EN' : 'ع',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: TawasulColors.forest),
            ),
          ),
          IconButton(
            tooltip: strings.signOut,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ref.watch(servingFromCacheProvider))
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OfflineBanner(),
            ),
          Expanded(
            child: IndexedStack(
              index: index,
              children: tabs.map((tab) => tab.page).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selectTab,
        destinations: tabs
            .map((tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  label: tab.label,
                ))
            .toList(),
      ),
      ),
    );
  }
}
