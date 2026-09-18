import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/community/community_repository.dart';
import 'local_notifications.dart';

/// Wraps the portal and, while the app is open, re-checks the server's
/// notification list every few minutes, raising a device notification for
/// anything new. All content comes from the server.
class NotificationWatcher extends ConsumerStatefulWidget {
  const NotificationWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationWatcher> createState() =>
      _NotificationWatcherState();
}

class _NotificationWatcherState extends ConsumerState<NotificationWatcher>
    with WidgetsBindingObserver {
  static const _interval = Duration(minutes: 3);

  Timer? _timer;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalNotifications.instance.init();
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      // ignore: unused_result
      ref.invalidate(myNotificationsProvider);
      final rows = await ref.read(myNotificationsProvider.future);
      final unread = rows.where(
          (row) => '${row['status'] ?? 'New'}'.toLowerCase() != 'archived');
      if (!_seeded) {
        LocalNotifications.instance
            .seed(unread.map((row) => '${row['gibbonNotificationID']}'));
        _seeded = true;
        return;
      }
      for (final row in unread) {
        await LocalNotifications.instance.show(
          id: '${row['gibbonNotificationID']}',
          title: '${row['moduleName'] ?? row['actionName'] ?? ''}'.trim(),
          body: '${row['text'] ?? ''}'.trim(),
        );
      }
    } catch (_) {
      // Offline or refused: stay quiet until the next tick.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
