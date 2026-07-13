import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local "time to watch" reminders.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if the device timezone can't be resolved.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  /// Asks for notification permission (required on Android 13+ / iOS).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? true;
    }
    return true;
  }

  /// Schedules a reminder notification for [movieTitle] at [when].
  /// Uses the movie id as notification id, so re-scheduling replaces the
  /// previous reminder for the same movie.
  Future<void> scheduleWatchReminder({
    required int movieId,
    required String movieTitle,
    required DateTime when,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'watch_reminders',
        'Watch reminders',
        channelDescription: 'Reminders to watch a movie at a chosen time',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final scheduledAt = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: movieId,
        title: 'Time to watch 🎬',
        body: movieTitle,
        scheduledDate: scheduledAt,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException {
      // Exact alarms can be blocked by the OS; fall back to inexact, which
      // may deliver a few minutes late but needs no special permission.
      await _plugin.zonedSchedule(
        id: movieId,
        title: 'Time to watch 🎬',
        body: movieTitle,
        scheduledDate: scheduledAt,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
