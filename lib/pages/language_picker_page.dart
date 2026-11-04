import 'package:flutter/material.dart';

import '../models/course.dart';
import '../widgets/course_flag.dart';

/// Výběr jazyka: při prvním spuštění (bez tlačítka zpět) i z domovské stránky.
class LanguagePickerPage extends StatelessWidget {
  final List<Course> courses;
  final String? currentId;
  final bool firstRun;
  final void Function(Course course) onSelected;

  const LanguagePickerPage({
    super.key,
    required this.courses,
    required this.onSelected,
    this.currentId,
    this.firstRun = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        automaticallyImplyLeading: !firstRun,
        centerTitle: true,
        title: Text(
          firstRun ? 'Co se chceš učit?' : 'Vyber jazyk',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final c in courses)
            Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CourseFlag(course: c, width: 44, height: 30),
                title: Text(c.backLabel,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500)),
                subtitle: Text('${c.frontLabel} → ${c.backLabel} · ${c.length} slov'),
                trailing: c.id == currentId
                    ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                    : null,
                onTap: () => onSelected(c),
              ),
            ),
        ],
      ),
    );
  }
}
