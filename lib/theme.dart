import 'package:flutter/material.dart';

/// Společné barvy a stíny aplikace.
const Color kBg = Color(0xFFF4F6FA);
const Color kBlue = Color(0xFF2F6FED);
const Color kInk = Color(0xFF1D1B20);
const Color kMuted = Color(0xFF767676);

/// Měkký stín pro bílé karty.
List<BoxShadow> softShadow([double opacity = 0.07]) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
