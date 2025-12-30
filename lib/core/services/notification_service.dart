import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/note_entity.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static const String _channelId = 'note_reminder_channel';
  static const String _channelName = 'Pengingat Catatan';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone setup
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);
    await _requestPermissions();
    await _ensureAndroidChannel();
    _initialized = true;
  }

  Future<void> scheduleReminder(NoteEntity note) async {
    if (note.reminderAt == null) return;
    if (!_initialized) await init();

    final scheduledDate = tz.TZDateTime.from(note.reminderAt!, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifikasi pengingat catatan',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      _notificationId(note.id),
      'Pengingat Catatan',
      note.title,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: note.id,
    );
  }

  Future<void> cancelReminder(String noteId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_notificationId(noteId));
  }

  int _notificationId(String noteId) => noteId.hashCode & 0x7fffffff;

  Future<void> _requestPermissions() async {
    final iosImplementation =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _ensureAndroidChannel() async {
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi pengingat catatan',
      importance: Importance.max,
    ));
  }
}
