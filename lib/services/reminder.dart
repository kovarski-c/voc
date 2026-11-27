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
/// Naplánuje se řada jednorázových oznámení počítaná od posledního dne
/// započítaného do (společné) série: týden každý den, pak jednou týdně
/// a po měsíci už nic. Po každé změně (otevření aplikace, den započítaný do
/// série) se plánuje znovu, takže po splnění série dnešní oznámení nepřijde.
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

  static String _dni(int n) => n == 1 ? 'den' : (n <= 4 ? 'dny' : 'dní');
  static String _slovicek(int n) =>
      n == 1 ? 'slovíčko' : (n <= 4 ? 'slovíčka' : 'slovíček');

  /// Kolik oznámení se nejvíc plánuje předem (ID 1 až [_maxIds]).
  static const int _maxIds = 12;

  /// Dny po posledním započítaném dni, kdy přijde oznámení: nejdřív týden
  /// každý den, pak jednou týdně a po měsíci už nic.
  static const List<int> _offsets = [1, 2, 3, 4, 5, 6, 7, 8, 15, 22, 29];

  /// Poslední den s denním oznámením (dál jen týdenní "vraťte se").
  static const int _dailyUntil = 8;

  /// Zruší staré připomínky a podle nastavení naplánuje novou řadu.
  /// [lastActiveDay] = poslední studijní den započítaný do série
  /// (viz StreakStore.lastActiveDay). Oznámení jsou jednorázová a plánují se
  /// předem, takže řada doběhne i bez spuštěné aplikace.
  static Future<void> sync({
    required bool enabled,
    required int minutes,
    required int lastActiveDay,
    required int streak,
  }) async {
    if (!_ready) return;
    try {
      for (var id = 1; id <= _maxIds; id++) {
        await _plugin.cancel(id: id);
      }
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      // Čas připomínky dnes (může být už v minulosti) a jeho studijní den.
      final first = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      final firstDay = Scheduler.studyDayNumber(first);
      // Kdo ještě nikdy nestudoval, počítá se od dneška.
      final base = lastActiveDay == 0 ? firstDay - 1 : lastActiveDay;

      var id = 1;
      for (final offset in _offsets) {
        final targetDay = base + offset;
        final when = tz.TZDateTime(
          tz.local,
          first.year,
          first.month,
          first.day + (targetDay - firstDay),
          first.hour,
          first.minute,
        );
        if (!when.isAfter(now)) continue; // dnešek po čase nebo už splněné dny

        final String title, body;
        if (offset > _dailyUntil) {
          title = 'Tvé budoucí já doporučuje:';
          body =
              'zopakuj si ${Motivation.streakMinCards} ${_slovicek(Motivation.streakMinCards)} a nastartuj novou sérii';
        } else if (offset == 1 && streak > 0) {
          // Série ještě žije jen do konce tohoto dne.
          title = 'Je čas na procvičování';
          body =
              'Zopakuj si ${Motivation.streakMinCards} ${_slovicek(Motivation.streakMinCards)} a tvá série bude $streak ${_dni(streak)} dlooouuuhá';
        } else {
          title = 'Jak zesílit svou slovní zásobu?';
          body =
              'Tím, že si dnes projdeš ${Motivation.streakMinCards} ${_slovicek(Motivation.streakMinCards)}!';
        }

        await _plugin.zonedSchedule(
          id: id++,
          title: title,
          body: body,
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
          // oprávnění pro přesné budíky. Oznámení se neopakují (bez
          // matchDateTimeComponents), řadu plánuje tato metoda.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Plánování připomínky selhalo: $e');
    }
  }
}
