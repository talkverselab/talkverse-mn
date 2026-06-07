import 'package:flutter/material.dart';

import '../../data/content_words.dart';
import '../../data/cyrillic_alphabet_data.dart';
import '../../domain/models/cyrillic_letter.dart';
import '../../domain/models/flashcard.dart';
import '../../domain/models/lemma_entry.dart';
import '../../services/alpha_examples_repository.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ui_kit.dart';
import '../conversation/flashcard_session_screen.dart';

/// 몽골 키릴 알파벳 학습.
///
/// 4단계 메뉴: 1 모음(+모음조화·Ө Ү) → 2 영어 가짜친구 자음 → 3 몽골 키릴 자음 → 4 나머지.
/// 각 글자엔 L1·L2 기능어·부사어 예시(대명사·동사 제외)를 첫 글자별로 붙인다.
class CyrillicAlphabetScreen extends StatefulWidget {
  const CyrillicAlphabetScreen({super.key});

  @override
  State<CyrillicAlphabetScreen> createState() => _CyrillicAlphabetScreenState();
}

class _CyrillicAlphabetScreenState extends State<CyrillicAlphabetScreen> {
  AlphaStage _stage = AlphaStage.vowel;
  int _selected = 0; // cyrillicAlphabet 전역 인덱스
  Map<String, List<LemmaEntry>> _examples = const {};

  @override
  void initState() {
    super.initState();
    AlphaExamplesRepository.instance.byInitial().then((m) {
      if (mounted) setState(() => _examples = m);
    });
  }

  CyrillicLetter get _l => cyrillicAlphabet[_selected];

  List<int> _indicesFor(AlphaStage s) {
    final out = <int>[];
    for (var i = 0; i < cyrillicAlphabet.length; i++) {
      if (cyrillicAlphabet[i].stage == s) out.add(i);
    }
    return out;
  }

  void _selectStage(AlphaStage s) {
    setState(() {
      _stage = s;
      _selected = _indicesFor(s).first;
    });
    TtsService.instance.speak(_l.lower);
  }

  void _selectLetter(int globalIndex) {
    setState(() => _selected = globalIndex);
    TtsService.instance.speak(cyrillicAlphabet[globalIndex].lower);
  }

  @override
  Widget build(BuildContext context) {
    // 아랍어 화면은 Directionality.rtl — 여기선 LTR(기본)로 좌우반전.
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('몽골 키릴 35자', style: AppType.serif(19, weight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stageMenu(),
            _letterBar(),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                children: [
                  _wordPracticeCta(context),
                  const SizedBox(height: 14),
                  _header(),
                  const SizedBox(height: 14),
                  _fourCells(),
                  const SizedBox(height: 16),
                  _examplesCard(),
                  const SizedBox(height: 12),
                  _tipCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 4단계 메뉴 ----------
  Widget _stageMenu() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          for (final s in AlphaStage.values) ...[
            Expanded(child: _stageTab(s)),
            if (s != AlphaStage.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _stageTab(AlphaStage s) {
    final sel = s == _stage;
    final c = s.color;
    final n = AlphaStage.values.indexOf(s) + 1;
    return GestureDetector(
      onTap: () => _selectStage(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: sel ? c.withValues(alpha: 0.12) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? c : AppColors.line, width: sel ? 1.4 : 1),
        ),
        child: Column(
          children: [
            Text('$n',
                style: AppType.serif(15,
                    weight: FontWeight.w700, color: sel ? c : AppColors.inkFaint)),
            const SizedBox(height: 1),
            Text(s.tab,
                textAlign: TextAlign.center,
                style: AppType.sans(10,
                    weight: FontWeight.w700, color: sel ? c : AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  // ---------- 글자바 (현재 단계만) ----------
  Widget _letterBar() {
    final indices = _indicesFor(_stage);
    return Container(
      height: 80,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: indices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final gi = indices[i];
          final sel = gi == _selected;
          final l = cyrillicAlphabet[gi];
          final c = _stage.color;
          return GestureDetector(
            onTap: () => _selectLetter(gi),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: sel ? c : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: c.withValues(alpha: sel ? 1 : 0.35),
                  width: sel ? 2 : 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${l.upper}${l.lower}',
                style: AppType.serif(22,
                    weight: FontWeight.w700, color: sel ? Colors.white : c),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- 50 내용어 단어 연습 진입 ----------
  Widget _wordPracticeCta(BuildContext context) {
    return OutlineCard(
      fill: AppColors.mint,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FlashcardSessionScreen(
            title: '50 내용어 연습',
            fill: AppColors.mint,
            items: [
              for (final w in contentWords) FlashItem.word(w.mn, ko: w.ko),
            ],
          ),
        ));
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline, width: 1.4),
            ),
            child: const Icon(Icons.style_rounded, color: AppColors.ink, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('50 내용어 단어 연습', style: AppType.serif(15)),
                const SizedBox(height: 2),
                Text('플래시카드로 읽기·뜻·발음',
                    style: AppType.sans(12, color: AppColors.inkSoft)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }

  // ---------- 헤더 ----------
  Widget _header() {
    final c = _stage.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_l.upper}${_l.lower} · ${_l.name}',
                    style: AppType.serif(18, weight: FontWeight.w700, color: c)),
                const SizedBox(height: 3),
                Text('roman · ${_l.roman}   |   소리 [${_l.sound}]',
                    style: AppType.sans(12,
                        weight: FontWeight.w500, color: AppColors.inkSoft)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => TtsService.instance.speak(_l.lower),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(Icons.volume_up_rounded, color: c, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 4 셀 ----------
  Widget _fourCells() {
    const cellH = 108.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _glyphCell('대문자', _l.upper, cellH)),
            const SizedBox(width: 8),
            Expanded(child: _glyphCell('소문자', _l.lower, cellH)),
            const SizedBox(width: 8),
            Expanded(child: _glyphCell('이탤릭', _l.lower, cellH, italic: true)),
          ],
        ),
        const SizedBox(height: 8),
        _soundCell('소리', _l.sound, cellH),
      ],
    );
  }

  Widget _glyphCell(String label, String glyph, double h, {bool italic = false}) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 10,
            child: Text(label,
                style: AppType.sans(11, weight: FontWeight.w700, color: AppColors.inkFaint)),
          ),
          Center(
            child: Text(
              glyph,
              style: AppType.serif(46, weight: FontWeight.w600, color: AppColors.ink).copyWith(
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _soundCell(String label, String sound, double h) {
    final c = _stage.color;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.5), width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 10,
            child: Text(label, style: AppType.sans(11, weight: FontWeight.w700, color: c)),
          ),
          Center(
            child: Text('[$sound]',
                style: AppType.serif(36, weight: FontWeight.w700, color: c)),
          ),
        ],
      ),
    );
  }

  // ---------- 예시어 카드 (L1·L2 기능어·부사어) ----------
  Widget _examplesCard() {
    final c = _stage.color;
    final words = _examples[_l.upper] ?? const [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_border_rounded, size: 16, color: c),
              const SizedBox(width: 6),
              Text('이 글자로 시작하는 L1·L2 기능어·부사',
                  style: AppType.sans(13, weight: FontWeight.w700, color: c)),
            ],
          ),
          const SizedBox(height: 10),
          if (words.isEmpty)
            Text(
              _examples.isEmpty ? '불러오는 중…' : '이 글자로 시작하는 고빈도 기능어·부사가 없어요.',
              style: AppType.sans(12.5, weight: FontWeight.w400, color: AppColors.inkFaint),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final w in words) _wordChip(w, c)],
            ),
        ],
      ),
    );
  }

  Widget _wordChip(LemmaEntry e, Color c) {
    return GestureDetector(
      onTap: () => TtsService.instance.speak(e.lemma),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.lemma, style: AppType.serif(16, weight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(width: 6),
            Text(posKo[e.pos] ?? e.pos,
                style: AppType.sans(9.5, weight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }

  // ---------- 팁 카드 ----------
  Widget _tipCard() {
    final c = _stage.color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: c),
              const SizedBox(width: 6),
              Text(_stage.ko, style: AppType.sans(13, weight: FontWeight.w700, color: c)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_l.tip,
              style: AppType.sans(13.5,
                  weight: FontWeight.w500, color: AppColors.ink, height: 1.45)),
        ],
      ),
    );
  }
}
