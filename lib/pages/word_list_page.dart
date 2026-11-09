import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../study_controller.dart';
import '../theme.dart';
import '../widgets/card_status.dart';
import 'word_map_view.dart';

/// Záložka "Slova": seznam všech slov s vyhledáváním, nebo mapa slov s odznaky.
class WordListPage extends StatefulWidget {
  final StudyController controller;
  const WordListPage({super.key, required this.controller});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  static const double _rowHeight = 80;

  String _search = '';
  bool _map = false;
  final Set<int> _flipped = {};
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  void _jumpTo(int start) {
    setState(() {
      _map = false;
      _search = '';
      _searchCtl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (start * _rowHeight)
          .clamp(0.0, _scroll.position.maxScrollExtent)
          .toDouble();
      _scroll.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Slova',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Toggle(
                map: _map,
                onChanged: (m) => setState(() => _map = m),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _map
                  ? WordMapView(controller: c, onJump: _jumpTo)
                  : _buildList(c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(StudyController c) {
    final course = c.course;
    final q = _search.toLowerCase();
    final filtered = <int>[
      for (final i in c.order)
        if (q.isEmpty ||
            course.front(i).toLowerCase().contains(q) ||
            course.back(i).toLowerCase().contains(q))
          i,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            controller: _searchCtl,
            decoration: InputDecoration(
              hintText: 'Hledat slovo nebo překlad',
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              suffixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Nic nenalezeno'))
              : Scrollbar(
                  controller: _scroll,
                  interactive: true,
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: filtered.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    itemExtent: _rowHeight,
                    itemBuilder: (context, row) {
                      final idx = filtered[row];
                      final flipped = _flipped.contains(idx);
                      final pron = course.pronunciation(idx); // patří k učené straně (back)
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 24, right: 8),
                        leading: Container(
                          width: 44,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Text('${c.numberOf(idx)}',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              flipped ? course.front(idx) : course.back(idx),
                              maxLines: flipped || pron.isEmpty ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    flipped ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            // Výslovnost patří k učenému slovu (před otočením).
                            if (!flipped && pron.isNotEmpty)
                              Text(pron,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: kMuted, fontSize: 14)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 100,
                              child: CardStatus(info: c.infoOf(idx)),
                            ),
                            const SizedBox(width: 6),
                            Transform.rotate(
                              angle: 270 * math.pi / 180,
                              child: IconButton(
                                icon: const Icon(Icons.flip),
                                color: const Color(0xFFBFBFBF),
                                tooltip: 'Otočit',
                                onPressed: () => setState(() {
                                  if (!_flipped.add(idx)) _flipped.remove(idx);
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Přepínač Seznam / Mapa.
class _Toggle extends StatelessWidget {
  final bool map;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.map, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget item(String text, IconData icon, bool selected, VoidCallback onTap) =>
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 40,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected ? softShadow(0.08) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: selected ? kInk : kMuted),
                  const SizedBox(width: 6),
                  Text(text,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? kInk : kMuted)),
                ],
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          item('Seznam', Icons.format_list_bulleted_rounded, !map,
              () => onChanged(false)),
          item('Mapa slov', Icons.grid_view_rounded, map, () => onChanged(true)),
        ],
      ),
    );
  }
}
