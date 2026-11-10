import 'package:flutter/material.dart';

import 'courses.dart';
import 'models/course.dart';
import 'pages/language_picker_page.dart';
import 'pages/home_shell.dart';
import 'services/progress_store.dart';
import 'services/settings_store.dart';
import 'study_controller.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  Future<void> _boot() async {
    final settings = await SettingsStore.load();
    _settings = settings;
    _courses = await loadCourses();
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
    );
    await controller.init();
    settings.courseId = course.id;
    SettingsStore.save(settings);
    if (!mounted) return;
    setState(() => _controller = controller);
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
      );
    }
    return MaterialApp(
      navigatorKey: _nav,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
        scaffoldBackgroundColor: kBg,
        sliderTheme: SliderThemeData(
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
      ),
      home: home,
    );
  }
}
