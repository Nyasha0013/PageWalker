import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String message,
  }) async {
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1,
      'Time to read, Pagewalker!',
      message,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminder',
          'Reading Reminders',
          channelDescription: 'Daily reading reminders',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF6B1A),
          largeIcon:
              const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> sendStreakWarning() async {
    await _plugin.show(
      2,
      'Your streak is at risk!',
      "You haven't logged a read in a while. Don't break the chain!",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_warning',
          'Streak Warnings',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF6B1A),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> sendMilestone(String title, String body) async {
    await _plugin.show(
      3,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones',
          'Reading Milestones',
          importance: Importance.defaultImportance,
          color: Color(0xFFFF6B1A),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<void> checkAndSendMilestone(int booksRead) async {
    final milestones = <int, (String, String)>{
      1: (
        'First book logged!',
        'Your reading journey with Pagewalker begins!',
      ),
      5: ('5 books read!', "You're on a roll! Keep going!"),
      10: ('10 books!', "Double digits — you're unstoppable!"),
      25: ('25 books!', 'A quarter century of stories. God Tier reader!'),
      50: ('50 books!', 'FIFTY books! You are a true Pagewalker!'),
      100: ('100 books!', 'One hundred books. Legendary.'),
    };

    final milestone = milestones[booksRead];
    if (milestone != null) {
      await sendMilestone(milestone.$1, milestone.$2);
    }
  }
}

