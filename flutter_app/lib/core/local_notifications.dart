import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Device notifications for new items coming from the school server.
///
/// The app polls the server's own notification list while it is open and
/// raises a device notification for anything it has not shown before. No
/// third-party push service is involved, so nothing leaves the school server.
class LocalNotifications {
  LocalNotifications._();

  static final LocalNotifications instance = LocalNotifications._();

  static const _channelId = 'tawasul_school';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<String> _shown = <String>{};
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  /// Marks the notifications already on screen at sign-in so the user is not
  /// buzzed for history.
  void seed(Iterable<String> ids) => _shown.addAll(ids);

  Future<void> show({
    required String id,
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    if (_shown.contains(id)) return;
    _shown.add(id);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'School notifications',
        channelDescription: 'Messages and alerts from the school',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id.hashCode & 0x7fffffff, title, body, details);
  }

  Future<void> clearSeen() async => _shown.clear();
}
