import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../study_controller.dart';
import '../widgets/card_status.dart';

/// Seznam všech slov s vyhledáváním a otočením položky.
class WordListPage extends StatefulWidget {
  final StudyController controller;
  const WordListPage({super.key, required this.controller});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  String _search = '';
  final Set<int> _flipped = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.controller.course;
    final q = _search.toLowerCase();
    final filtered = <int>[
      for (var i = 0; i < course.length; i++)
        if (q.isEmpty ||
            course.front(i).toLowerCase().contains(q) ||
            course.back(i).toLowerCase().contains(q))
          i,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Seznam slov',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search for a word or its translation',
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFEDEDED),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No results'))
                : Scrollbar(
                    controller: _scrollController,
                    interactive: true,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filtered.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      itemExtent: 80,
                      itemBuilder: (context, row) {
                        final idx = filtered[row];
                        final flipped = _flipped.contains(idx);
                        final pron = course.pronunciation(idx);
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 27, right: 8),
                          leading: Container(
                            width: 40,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              color: const Color(0xFFF0F1EF),
                            ),
                            child: Text('${idx + 1}'),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                flipped ? course.back(idx) : course.front(idx),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      flipped ? FontWeight.normal : FontWeight.w500,
                                ),
                              ),
                              if (!flipped && pron.isNotEmpty)
                                Text(
                                  pron,
                                  style: const TextStyle(
                                    color: Color(0xFF767676),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 100,
                                child: CardStatus(info: widget.controller.infoOf(idx)),
                              ),
                              const SizedBox(width: 6),
                              Transform.rotate(
                                angle: 270 * math.pi / 180,
                                child: IconButton(
                                  icon: const Icon(Icons.flip),
                                  color: const Color(0xFFBFBFBF),
                                  tooltip: 'Flip',
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
      ),
    );
  }
}
