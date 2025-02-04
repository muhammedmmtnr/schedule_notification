import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schedule_notification/main.dart';
import 'package:timezone/timezone.dart' as tz;

class prayerTime extends StatefulWidget {
  const prayerTime({super.key, required this.title});

  final String title;

  @override
  State<prayerTime> createState() => _prayerTimeState();
}

class _prayerTimeState extends State<prayerTime> {
  final Map<String, String> prayerTimes = {
    'Subah': '05:45',
    'Luhar': '12:55',
    'Asar': '15:55',
    'Magrib': '18:18',
    'Ishah': '20:20',
  };

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Updated permission request method
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> schedulePrayerNotification(String prayer, String time) async {
    final timeparts = time.split(':');
    final hour = int.parse(timeparts[0]);
    final minute = int.parse(timeparts[1]);

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      getNotificationId(prayer),
      'Time for $prayer Prayer',
      'It\'s time for $prayer prayer ($time)',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Notifications',
          channelDescription: 'Daily prayer time notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  int getNotificationId(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'subah':
        return 1;
      case 'luhar':
        return 2;
      case 'asar':
        return 3;
      case 'magrib':
        return 4;
      case 'ishah':
        return 5;
      default:
        return 0;
    }
  }

  Future<void> scheduleAllPrayers() async {
    for (var entry in prayerTimes.entries) {
      await schedulePrayerNotification(entry.key, entry.value);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer notifications scheduled')),
      );
    }
  }

  Future<void> cancelAllPrayers() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer notifications cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Prayer Times',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...prayerTimes.entries.map((entry) => Card(
              child: ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value),
              ),
            )),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: scheduleAllPrayers,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Schedule All Notifications'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: cancelAllPrayers,
              icon: const Icon(Icons.notifications_off),
              label: const Text('Cancel All Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}