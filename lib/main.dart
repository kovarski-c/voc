import 'package:material_ui/material_ui.dart';

import 'courses.dart';
import 'models/course.dart';
import 'pages/language_picker_page.dart';
import 'pages/home_shell.dart';
import 'services/progress_store.dart';
import 'services/reminder.dart';
import 'services/settings_store.dart';
import 'services/streak_store.dart';
import 'study_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Reminder.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _nav = GlobalKey<NavigatorState>();
  AppSettings? _settings;
  List<Course> _courses = const [];
  StudyController? _controller;
  StreakStore? _streak; // série společná pro všechny kurzy

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Uložení pokroku při odchodu z aplikace (ukládání je jinak odložené o 0,5 s).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.flush();
  }

  /// Paleta podle schématu, režimu a jasu systému.
  AppPalette _resolvePalette(AppSettings s) => paletteFor(
    s.theme,
    dark: resolveDark(
      s.appearance,
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    ),
  );

  void _syncTheme() {
    final s = _settings;
    if (s == null) return;
    final p = _resolvePalette(s);
    if (!identical(p, palette)) setState(() => palette = p);
  }

  // Přepnutí jasu systému (při režimu "Podle systému").
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _syncTheme();
  }

  Future<void> _boot() async {
    final settings = await SettingsStore.load();
    _settings = settings;
    palette = _resolvePalette(settings);
    _courses = await loadCourses();
    final ids = _courses.map((c) => c.id).toList();
    // Každý kurz má vlastní nastavení; při přechodu ze starého souboru se všem
    // zkopírují dosavadní společné hodnoty.
    settings.ensureCourses(ids);
    SettingsStore.save(settings);
    _streak = await StreakStore.load(ids);
    Course? course;
    for (final c in _courses) {
      if (c.id == settings.courseId) course = c;
    }
    // S jediným kurzem se výběr jazyka přeskočí.
    course ??= _courses.length == 1 ? _courses.first : null;
    if (course != null) {
      await _open(course);
    } else {
      setState(() {});
    }
  }

  Future<void> _open(Course course) async {
    final settings = _settings!;
    final old = _controller;
    await old?.flush();
    final controller = StudyController(
      course,
      ProgressStore(course.id),
      settings,
      _streak!,
    );
    await controller.init();
    // Jazyk se pamatuje až po výběru úrovně / testu; do té doby se po
    // restartu znovu ukáže výběr jazyka.
    if (!controller.needsPlacement) {
      settings.courseId = course.id;
      SettingsStore.save(settings);
    }
    if (!mounted) return;
    controller.addListener(_syncTheme);
    controller.addListener(_persistCourse);
    setState(() => _controller = controller);
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  void _persistCourse() {
    final c = _controller;
    final st = _settings;
    if (c == null || st == null || c.needsPlacement) return;
    if (st.courseId != c.course.id) {
      st.courseId = c.course.id;
      SettingsStore.save(st);
    }
  }

  /// Z úvodního výběru úrovně zpět na výběr jazyka (omylem zvolený jazyk).
  Future<void> _backToLanguage() async {
    final old = _controller;
    await old?.flush();
    if (!mounted) return;
    old?.removeListener(_persistCourse);
    setState(() => _controller = null);
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  void _showPicker() {
    final current = _controller?.course.id;
    _nav.currentState!.push(
      MaterialPageRoute(
        builder:
            (_) => LanguagePickerPage(
              courses: _courses,
              currentId: current,
              onSelected: (c) {
                _nav.currentState!.pop();
                if (c.id != current) _open(c);
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget home;
    if (_settings == null) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_controller == null) {
      home = LanguagePickerPage(
        courses: _courses,
        firstRun: true,
        onSelected: _open,
      );
    } else {
      home = HomeShell(
        key: ValueKey(_controller!.course.id),
        controller: _controller!,
        onChangeCourse: _showPicker,
        onBackToLanguage: _backToLanguage,
      );
    }
    return MaterialApp(
      navigatorKey: _nav,
      title: 'Voc | Learn words from most useful',
      theme: ThemeData(
        useMaterial3: true,
        brightness: palette.dark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBlue,
          brightness: palette.dark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: kBg,
        sliderTheme: SliderThemeData(
          tickMarkShape: SliderTickMarkShape.noTickMark,
          activeTrackColor: kToneBlue.a,
          thumbColor: kBlue,
          valueIndicatorColor: kBlue,
          trackHeight: 7,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(kBlue),
          trackColor: WidgetStateProperty.all(kToneBlue.a),
          trackOutlineColor: WidgetStateProperty.all(kToneBlue.a),
        ),
      ),
      home: home,
    );
  }
}
