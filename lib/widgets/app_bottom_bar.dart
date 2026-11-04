import 'package:flutter/material.dart';

import '../theme.dart';

/// Spodní lišta se čtyřmi ikonami: domů, karty, seznam slov, nastavení.
class AppBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const AppBottomBar({super.key, required this.index, required this.onTap});

  static const _icons = [
    Icons.home_rounded,
    Icons.style_rounded,
    Icons.format_list_bulleted_rounded,
    Icons.settings_rounded,
  ];
  static const _labels = ['Domů', 'Karty', 'Seznam slov', 'Nastavení'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _icons[i],
                    label: _labels[i],
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? kBlue.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? kBlue.withValues(alpha: 0.55) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: selected ? kBlue : const Color(0xFF9AA0A6),
          ),
        ),
      ),
    );
  }
}
