import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../models/course.dart';

/// Vlajka kurzu (vektorová, balíček country_flags; funguje offline).
/// Bez flagCode se ukáže obecná ikona jazyka.
class CourseFlag extends StatelessWidget {
  final Course course;
  final double width;
  final double height;

  const CourseFlag({
    super.key,
    required this.course,
    this.width = 32,
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    final code = course.flagCode;
    if (code == null) {
      return SizedBox(
        width: width,
        height: height,
        child: Icon(Icons.language, size: height),
      );
    }
    return CountryFlag.fromCountryCode(
      code,
      theme: ImageTheme(
        width: width,
        height: height,
        shape: const RoundedRectangle(4),
      ),
    );
  }
}
