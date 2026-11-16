import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Person;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Schedules one local notification per transaction that has a due date.
/// Notification id = transaction id. Fires at [hour]:00 on the due day.
abstract class Reminders {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> schedule(Txn txn, Person person);
  Future<void> cancel(int txnId);
}

class NoReminders implements Reminders {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> schedule(Txn txn, Person person) async {}
  @override
  Future<void> cancel(int txnId) async {}
}

class LocalReminders implements Reminders {
  LocalReminders({this.hour = 9});

  final int hour;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Reminders init failed: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return (await android?.requestNotificationsPermission()) ?? false;
  }

  @override
  Future<void> schedule(Txn txn, Person person) async {
    await cancel(txn.id);
    final due = txn.due;
    if (!_ready || due == null) return;
    final when = tz.TZDateTime(tz.local, due.year, due.month, due.day, hour);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    final amount = formatMoney(txn.paise);
    final title = txn.gave ? '${person.name} owes you $amount' : 'You owe ${person.name} $amount';
    try {
      await _plugin.zonedSchedule(
        id: txn.id,
        scheduledDate: when,
        title: title,
        body: txn.note.isEmpty ? 'Due today.' : 'Due today: ${txn.note}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'due',
            'Due dates',
            channelDescription: 'Reminders on the day a payment is due',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Reminder schedule failed: $e');
    }
  }

  @override
  Future<void> cancel(int txnId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: txnId);
    } catch (e) {
      debugPrint('Reminder cancel failed: $e');
    }
  }
}
