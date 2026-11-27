import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../study_controller.dart';
import '../theme.dart';
import '../widgets/card_status.dart';
import '../models/card_progress.dart';
import '../widgets/multi_form_text.dart';
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
  void initState() {
    super.initState();
    widget.controller.openWord.addListener(_onOpenWord);
  }

  /// Ikonka úprav na kartě: najede na slovo v seznamu a otevře jeho detail.
  void _onOpenWord() {
    final c = widget.controller;
    final key = c.openWord.value;
    if (key == null) return;
    c.openWord.value = null;
    final pos = c.order.indexOf(key);
    if (pos < 0) return;
    _jumpTo(pos);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showDetail(key);
    });
  }

  /// Ruční změna stavu slova.
  Future<void> _pickKind(int idx) async {
    final c = widget.controller;
    final CardKind? cur = c.isExcluded(idx) ? null : c.infoOf(idx).kind;
    final options = <(CardKind?, String, String)>[
      (CardKind.newCard, 'Nové', 'Zatím neznám, přijde na řadu mezi novými.'),
      (CardKind.learning, 'Učím se', 'Zařadí se do učení od začátku.'),
      (CardKind.review, 'Umím', 'Půjde rovnou do opakování.'),
      (null, 'Neučit', 'Slovo se nebude zobrazovat ani počítat. Půjde vrátit.'),
    ];
    final picked = await showModalBottomSheet<(CardKind?, String, String)>(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      'Změnit stav slova',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final o in options)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(ctx, o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child:
                                  cur == o.$1
                                      ? Icon(
                                        Icons.check_rounded,
                                        color: kToneBlue.accent,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.$2,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    o.$3,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
    if (picked == null || picked.$1 == cur) return;
    final kind = picked.$1;
    if (kind == null) {
      c.excludeWord(idx);
    } else {
      c.setWordKind(idx, kind);
    }
  }

  @override
  void dispose() {
    widget.controller.openWord.removeListener(_onOpenWord);
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
      final target =
          (start * _rowHeight)
              .clamp(0.0, _scroll.position.maxScrollExtent)
              .toDouble();
      _scroll.jumpTo(target);
    });
  }

  /// Detail slova v dolním panelu: slovo + výslovnost, pořadí, stav, překlad.
  /// Vpravo nahoře ikonka "učit přednostně" (jen u nových slov).
  void _showDetail(int idx) {
    final c = widget.controller;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => ListenableBuilder(
            listenable: c,
            builder: (_, _) {
              final course = c.course;
              final back = course.back(idx);
              final pron = course.pronunciation(idx);
              final info = c.infoOf(idx);
              final prio = c.isPrioritized(idx);
              final size = 28 * MultiFormText.scaleFor(back.length);
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 12, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: back,
                                      style: TextStyle(
                                        fontSize: size,
                                        fontWeight: FontWeight.w600,
                                        color: kInk,
                                      ),
                                    ),
                                    if (pron.isNotEmpty)
                                      TextSpan(
                                        text: '   $pron',
                                        style: TextStyle(
                                          fontSize: math.max(16, size * 0.64),
                                          color: kMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (c.canPrioritize(idx))
                            IconButton(
                              tooltip:
                                  prio
                                      ? 'Zrušit přednostní učení'
                                      : 'Učit přednostně',
                              iconSize: 28,
                              color: prio ? kPriorityColor : kMuted,
                              onPressed: () => c.togglePriority(idx),
                              icon: Icon(
                                prio
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                              ),
                            ),
                        ],
                      ),
                      if (prio)
                        Padding(
                          padding: EdgeInsets.only(top: 4, right: 12),
                          child: Text(
                            'Přijde na řadu hned v dalším učení.',
                            style: TextStyle(fontSize: 13, color: kMuted),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      _DetailRow(
                        label: 'Pořadí',
                        child: Text(
                          '${c.numberOf(idx)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        label: 'Stav',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pickKind(idx),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              c.isExcluded(idx)
                                  ? const _ExcludedChip()
                                  : CardStatus(
                                    info: info,
                                    reserveIndicator: false,
                                  ),
                              if (info.kind == CardKind.review) ...[
                                const SizedBox(width: 10),
                                Text(
                                  'jistota ${(info.confidence * 100).round()} %',
                                  style: TextStyle(fontSize: 14, color: kMuted),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: kMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 12),
                          child: _DetailRow(
                            label: 'Překlad',
                            child: Text(
                              course.front(idx),
                              style: const TextStyle(fontSize: 18, height: 1.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: c,
        builder:
            (context, _) => Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Slova',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
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
                  child:
                      _map
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
    final q = _search.trim().toLowerCase();
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 20,
              ),
              suffixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: kSurface,
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        Expanded(
          child:
              filtered.isEmpty
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
                        final pron = course.pronunciation(
                          idx,
                        ); // patří k učené straně (back)
                        // Vlastní řádek místo ListTile: všechno je svisle na středu
                        // řádku (Row + center) a vlna po klepnutí kryje celý řádek.
                        return InkWell(
                          onTap: () => _showDetail(idx),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: c.isPrioritized(idx) ? 8 : 24,
                              right: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (c.isPrioritized(idx))
                                  Icon(
                                    Icons.star_rounded,
                                    size: 22,
                                    color: kPriorityColor,
                                  ),
                                SizedBox(width: 6),
                                Container(
                                  width: 44,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: kSurface,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        '${c.numberOf(idx)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        flipped
                                            ? course.front(idx)
                                            : course.back(idx),
                                        maxLines:
                                            flipped || pron.isEmpty ? 2 : 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              flipped
                                                  ? FontWeight.normal
                                                  : FontWeight.w600,
                                        ),
                                      ),
                                      // Výslovnost patří k učenému slovu (před otočením).
                                      if (!flipped && pron.isNotEmpty)
                                        Text(
                                          pron,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: kMuted,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child:
                                      c.isExcluded(idx)
                                          ? const Center(child: _ExcludedChip())
                                          : CardStatus(
                                            info: c.infoOf(idx),
                                            reserveIndicator: false,
                                          ),
                                ),
                                const SizedBox(width: 6),
                                Transform.rotate(
                                  angle: 270 * math.pi / 180,
                                  child: IconButton(
                                    icon: const Icon(Icons.flip),
                                    color: kFaint,
                                    tooltip: 'Otočit',
                                    onPressed:
                                        () => setState(() {
                                          if (!_flipped.add(idx)) {
                                            _flipped.remove(idx);
                                          }
                                        }),
                                  ),
                                ),
                              ],
                            ),
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
    Widget item(
      String text,
      IconData icon,
      bool selected,
      VoidCallback onTap,
    ) => Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? kSurface : kTrack,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? softShadow(0.08) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? kInk : kMuted),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? kInk : kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          item(
            'Seznam',
            Icons.format_list_bulleted_rounded,
            !map,
            () => onChanged(false),
          ),
          item(
            'Mapa slov',
            Icons.grid_view_rounded,
            map,
            () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

/// Barva značky "učit přednostně".
Color get kPriorityColor => kBlue;

/// Řádek detailu: popisek vlevo, hodnota zarovnaná doleva vedle něj.
class _DetailRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: TextStyle(fontSize: 14, color: kMuted)),
        ),
        Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
      ],
    );
  }
}


/// Štítek u slova vyřazeného tlačítkem "Neučit".
class _ExcludedChip extends StatelessWidget {
  const _ExcludedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: kFaint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'vyřazeno',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kMuted,
        ),
      ),
    );
  }
}
