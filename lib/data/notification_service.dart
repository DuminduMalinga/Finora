import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows budget alerts in the phone's notification tray.
abstract class NotificationService {
  /// Called when the user taps one of our notifications while the app runs.
  VoidCallback? onOpen;

  /// True when the app was started by tapping a notification.
  bool launchedFromNotification = false;

  /// Asks the user for permission to show notifications (once is enough; the
  /// system remembers the answer). Returns whether they are allowed.
  Future<bool> requestPermission();

  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

/// Android and iOS notifications through `flutter_local_notifications`.
class LocalNotificationService extends NotificationService {
  LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'budget_alerts',
    'Budget alerts',
    channelDescription:
        'Warnings when you get close to, or go over, a budget or category limit.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<LocalNotificationService> create() async {
    final service = LocalNotificationService._();
    try {
      await service._plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is requested at a sensible moment, not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (_) => service.onOpen?.call(),
      );
      final launch = await service._plugin.getNotificationAppLaunchDetails();
      service.launchedFromNotification =
          launch?.didNotificationLaunchApp ?? false;
      service._ready = true;
    } catch (error) {
      debugPrint('Finora: notifications are unavailable ($error)');
    }
    return service;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (error) {
      debugPrint('Finora: could not ask for notification permission ($error)');
    }
    return false;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'budget_alerts',
      );
    } catch (error) {
      debugPrint('Finora: could not show a notification ($error)');
    }
  }
}
