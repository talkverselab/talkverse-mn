import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../services/word_lookup.dart';
import '../widgets/lemma_chips.dart';
import '../widgets/spanish_decor.dart';
import '../widgets/word_art_thumb.dart';

/// 절벽 단어 — 1~1,500위를 절벽구간(R1~R5)별 **20어 단원**, 단어는 **네모 타일**(일본어앱과 같은 구조, 사용자 지시 2026-11-07).
/// 「회화 단어 포함」이면 회화에 나오지만 목록 밖인 단어가 「회화」 구간으로 뒤에 붙는다. DB 는 합치지 않고 화면에서만 합친다.
/// 탭 = 발음, 길게 누르기 = 단어 시트.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _Entry {
  final int rank;
  final String word, reading, ko, region; // region: R1~R5 · C(회화 단어)
  final WordRow? row;
  const _Entry(this.rank, this.word, this.reading, this.ko, this.region, this.row);
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<_Entry> _words = const [];
  List<_Entry> _conv = const [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';
  String _query = '';

  static const _colors = {
    'R1': AppColors.beni,
    'R2': AppColors.beniLight,
    'R3': AppColors.kinDeep,
    'R4': AppColors.matcha,
    'R5': AppColors.muted,
    'C': AppColors.ai,
  };

  Map<String, String> get _labels {
    final out = {'ALL': tr('전체')};
    var from = 1;
    for (var i = 0; i < kCliffs.length; i++) {
      out['R${i + 1}'] = 'R${i + 1} · $from-${kCliffs[i]}';
      from = kCliffs[i] + 1;
    }
    out['R5'] = 'R5 · $from-$kWordCap';
    if (_withConv) out['C'] = tr('회화');
    return out;
  }

  @override
  void initState() {
    super.initState();
    KoReadingPrefs.show.addListener(_redraw);
    _load();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    KoReadingPrefs.show.removeListener(_redraw);
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await (appDb.select(appDb.words)..orderBy([(w) => OrderingTerm.asc(w.rank)])).get();
    final conv = await convExtraWords();
    if (!mounted) return;
    setState(() {
      _words = [
        for (final w in rows)
          if (w.rank <= kWordCap) _Entry(w.rank, w.word, w.cefr ?? '', w.meaningKo ?? '', regionOf(w.rank), w),
      ];
      var n = 0;
      _conv = [for (final c in conv) _Entry(++n, c.word, c.reading, c.ko, 'C', null)];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = [..._words, if (_withConv) ..._conv]
        .where((w) => (_filter == 'ALL' || w.region == _filter) && (q.isEmpty || w.word.toLowerCase().contains(q) || w.ko.contains(q)))
        .toList();
    final units = <List<_Entry>>[
      for (var i = 0; i < filtered.length; i += kUnit) filtered.sublist(i, (i + kUnit).clamp(0, filtered.length)),
    ];
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trf('빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['1,500', kUnit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: const [KoReadingToggleAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(children: [
                  Row(children: [
                    _ModeButton(
                      label: tr('절벽구간 단어만'),
                      selected: !_withConv,
                      onTap: () => setState(() {
                        _withConv = false;
                        if (_filter == 'C') _filter = 'ALL';
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => setState(() => _withConv = true)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final e in _labels.entries)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _RegionChip(
                              label: e.value,
                              color: _colors[e.key] ?? AppColors.sumi,
                              selected: _filter == e.key,
                              onTap: () => setState(() => _filter = e.key),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('단어 / 뜻 검색'),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.washi,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ]),
              ),
              const AsanohaDivider(),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                  itemCount: units.length,
                  itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], colors: _colors),
                ),
              ),
            ]),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _RegionChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: selected ? color : AppColors.washi, border: Border.all(color: color, width: selected ? 1.5 : 0.8)),
          child: Text(label, style: TextStyle(color: selected ? AppColors.washi : color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      );
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자. 칸 수 = 화면 너비 ÷ 112(3~8칸, 좁은 칸은 그 칸 너비로).
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<_Entry> words;
  final Map<String, Color> colors;
  const _UnitBlock({required this.index, required this.words, required this.colors});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final conv = first.region == 'C';
    final color = colors[first.region] ?? AppColors.sumi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
          child: Row(children: [
            Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text(conv ? trf('회화 {0}-{1}', [first.rank, words.last.rank]) : '#${first.rank}-${words.last.rank}', style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              child: Text(conv ? tr('회화') : first.region, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        LayoutBuilder(
          builder: (context, c) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: (c.maxWidth / 112).floor().clamp(3, 8), mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.8),
            itemCount: words.length,
            itemBuilder: (context, i) => _WordTile(w: words[i], color: colors[words[i].region] ?? AppColors.sumi),
          ),
        ),
      ]),
    );
  }
}

/// 네모 타일 — 순위·독음 · 그림(있으면) · 단어 · 뜻 한 줄.
class _WordTile extends StatelessWidget {
  final _Entry w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    final conv = w.region == 'C';
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word),
      onLongPress: w.row == null ? null : () => showWordSheet(context, w.row!),
      child: Container(
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8), boxShadow: kCardShadow),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(builder: (context, c) {
          final art = (c.maxHeight * 0.36).clamp(24.0, 72.0);
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              Text(conv ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Expanded(
                child: KoReadingText(w.reading, textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: AppColors.sumiLight, overflow: TextOverflow.ellipsis)),
              ),
            ]),
            const SizedBox(height: 2),
            WordArtThumb(word: w.word, rank: conv ? null : w.rank, size: art),
            const SizedBox(height: 3),
            FittedBox(fit: BoxFit.scaleDown, child: Text(w.word, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi))),
            if (w.ko.isNotEmpty) Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
          ]);
        }),
      ),
    );
  }
}
