import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
    await _requestExactAlarmPermission();
  }

  Future<void> _requestExactAlarmPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // --- FUNGSI LAMA (TETAP ADA) ---
  // Untuk notifikasi pengingat per jadwal
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final scheduledNotificationDateTime =
        scheduledTime.subtract(const Duration(minutes: 15));
    if (scheduledNotificationDateTime.isBefore(DateTime.now())) {
      return;
    }
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'acara_kita_channel_id',
          'AcaraKita Channel',
          channelDescription: 'Channel untuk notifikasi pengingat acara',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // --- FUNGSI BARU ---
  // Untuk notifikasi pengingat harian jam 8 pagi
  Future<void> scheduleDailyReminderNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // ID unik untuk notifikasi harian
        'Selamat Pagi!',
        'Kamu ada jadwal apa hari ini? Ayo agendakan.',
        _nextInstanceOf8AM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel_id',
            'Daily Reminder Channel',
            channelDescription: 'Channel untuk notifikasi pengingat harian',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        // Membuat notifikasi ini berulang setiap hari pada waktu yang sama
        matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Fungsi helper untuk menghitung jadwal jam 8 pagi berikutnya
  tz.TZDateTime _nextInstanceOf8AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8); // Set jam 8 pagi
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}