import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'motivation.dart';
import 'scheduler.dart';

/// Denní připomínka, aby člověk neztratil sérii. Jen Android; jinde (web,
/// ostatní platformy) jsou všechny metody bez efektu a [supported] je false.
///
/// Naplánuje se jedno opakující se oznámení (každý den ve stejný čas). Když je
/// dnešek už do série započítaný, začne se opakovat až od zítřka, takže dnes
/// už nepřijde.
class Reminder {
  static const int _id = 1;
  static const String _channelId = 'streak_reminder';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Volá se jednou při startu aplikace.
  static Future<void> init() async {
    if (!supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('ic_notification'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Inicializace připomínek selhala: $e');
    }
  }

  /// Android 13+ se zeptá na povolení oznámení. Vrací, jestli jsou povolená.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('Žádost o povolení oznámení selhala: $e');
      return false;
    }
  }

  static tz.TZDateTime _nextDay(tz.TZDateTime d) =>
      tz.TZDateTime(tz.local, d.year, d.month, d.day + 1, d.hour, d.minute);

  static String _dni(int n) => n == 1 ? 'den' : (n <= 4 ? 'dny' : 'dní');

  /// Zruší starou připomínku a podle nastavení naplánuje novou.
  /// [lastActiveDay] = poslední studijní den započítaný do série
  /// (viz ProgressStore.lastActiveDay).
  static Future<void> sync({
    required bool enabled,
    required int minutes,
    required int lastActiveDay,
    required int streak,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!when.isAfter(now)) when = _nextDay(when);
      // Studijní den (začíná ve 4:00), který už je v sérii, se přeskočí.
      for (
        var i = 0;
        i < 3 && Scheduler.studyDayNumber(when) <= lastActiveDay;
        i++
      ) {
        when = _nextDay(when);
      }

      await _plugin.zonedSchedule(
        id: _id,
        title:
            streak > 0
                ? 'Už se učíš $streak ${_dni(streak)}!'
                : 'Neztrať svou sérii 🔥',
        body:
            streak > 0
                ? 'Dotáhneš to na ${streak + 1}? Stačí ${Motivation.streakMinCards} slovíček 🔥'
                : 'Stačí ${Motivation.streakMinCards} karet a dnešek se ti započítá do série.',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Připomínka série',
            channelDescription: 'Denní připomínka, aby se neztratila série.',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        // Nepřesný čas (může se opozdit o pár minut) nevyžaduje zvláštní
        // oprávnění pro přesné budíky.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Plánování připomínky selhalo: $e');
    }
  }
}
