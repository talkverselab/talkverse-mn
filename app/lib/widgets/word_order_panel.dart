import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/mn_affixes.dart';
import '../services/dialogue_service.dart';
import 'affix_sheet.dart';

/// 「어순 맞대기」 — 몽골어 UX 시안 01(사용자 통과 2026-11-03)의 몽골어 칸.
/// 현재 문장의 낱말을 칩으로 늘어놓고, 낱말마다 모음조화 점(남성 모음 а о у = 하늘 파랑, 여성 모음 э ө ү = 분홍, и = 회색)을 찍는다.
/// 턴에 낱말 대응 데이터(`align`: [[몽골어, 한국어], …])가 있으면 한국어 낱말을 아래에 맞대어 보인다 — 대응표는 회화 작업 때 채운다(지금은 없음).
/// 2026-11-03: 접사가 붙은 낱말은 어간 + 접사 블록(종류별 색)으로 나누고, 대응 한국어 조사를 같은 색 테두리로 묶는다. 접사를 누르면 설명 시트.
class WordOrderPanel extends StatelessWidget {
  final DialogueTurn turn;
  const WordOrderPanel({super.key, required this.turn});

  static const _male = 'аоуАОУ';
  static const _female = 'эөүЭӨҮ';
  static const _neutral = 'иИ';
  static const _maleColor = AppColors.beniLight;
  static const _femaleColor = Color(0xFFE88BB8);

  static List<String> _words(String s) =>
      s.split(RegExp(r'[^\p{L}\p{M}-]+', unicode: true)).where((w) => w.isNotEmpty).toList();

  static List<Color> _dots(String w) => [
        for (final ch in w.split(''))
          if (_male.contains(ch))
            _maleColor
          else if (_female.contains(ch))
            _femaleColor
          else if (_neutral.contains(ch))
            AppColors.line,
      ];

  @override
  Widget build(BuildContext context) {
    final pairs = turn.align.isNotEmpty ? turn.align : [for (final w in _words(turn.tl)) (w, '')];
    if (pairs.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.washi,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Icon(Icons.swap_vert, size: 16, color: AppColors.beni),
          const SizedBox(width: 6),
          Text(tr('어순 맞대기'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const Spacer(),
          _legend(_maleColor, tr('남성 모음')),
          const SizedBox(width: 10),
          _legend(_femaleColor, tr('여성 모음')),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (tl, ko) in pairs) _pair(tl, ko),
        ]),
      ]),
    );
  }

  Widget _legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ]);

  Widget _pair(String tl, String ko) {
    final dots = _dots(tl);
    final hit = analyzeWord(tl);
    // 한국어 낱말에 이 접사의 조사가 들어 있으면 같은 색 테두리로 묶는다
    final koColor = hit != null && ko.isNotEmpty && hit.affix.koMarkers.any(ko.contains) ? hit.affix.kind.color : null;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hit != null)
        AffixBlock(hit: hit, showKo: ko.isEmpty)
      else
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.beni.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Text(tl, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
      ),
      if (dots.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 3, left: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final c in dots.take(6))
              Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          ]),
        ),
      if (ko.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFDEFF6),
            borderRadius: BorderRadius.circular(10),
            border: koColor == null ? null : Border.all(color: koColor, width: 1.4),
          ),
          child: Text(ko, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}
