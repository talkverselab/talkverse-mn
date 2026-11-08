import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/mn_letters.dart';
import '../widgets/letter_sound_sheet.dart';

/// 키릴 문자와 발음 — 35자 격자 + 묶음 칩(모음조화 남성·여성·중성 …) + 로마자 토글. 글자 탭 = 발음 시트(사용자 지시 2026-11-08).
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});
  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  String _group = 'all';
  bool _latin = true;

  static const colors = {
    'male': AppColors.ai,
    'female': AppColors.beni,
    'neutral': AppColors.matcha,
    'iotated': AppColors.kinDeep,
    'consonant': AppColors.sumi,
    'loan': AppColors.muted,
    'sign': AppColors.sumiLight,
  };

  static Map<String, String> get labels => {
        'all': tr('전체 35'),
        'male': tr('남성 모음'),
        'female': tr('여성 모음'),
        'neutral': tr('중성 모음'),
        'iotated': tr('이 + 모음'),
        'consonant': tr('자음'),
        'loan': tr('외래어 글자'),
        'sign': tr('부호'),
      };

  static String get _note => tr('모음조화 — 한 단어 안에는 남성 모음(а о у)끼리, 또는 여성 모음(э ө ү)끼리 모입니다. и 는 양쪽에 다 들어갑니다. 접사 모양도 이 짝에 맞춰 바뀝니다.');

  @override
  Widget build(BuildContext context) {
    final shown = _group == 'all' ? kMnLetters : kMnLetters.where((l) => l.group == _group).toList();
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('키릴 문자와 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('35자 · 글자를 누르면 발음'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          TextButton(
            onPressed: () => setState(() => _latin = !_latin),
            child: Text(_latin ? tr('로마자 끄기') : tr('로마자 켜기'), style: const TextStyle(fontSize: 12, color: AppColors.ai, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 24 + bottomInset(context)),
        children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in labels.entries)
              ChoiceChip(
                label: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _group == e.key ? AppColors.washi : (colors[e.key] ?? AppColors.sumi))),
                selected: _group == e.key,
                selectedColor: colors[e.key] ?? AppColors.sumi,
                backgroundColor: AppColors.washi,
                side: BorderSide(color: colors[e.key] ?? AppColors.sumi),
                showCheckmark: false,
                onSelected: (_) => setState(() => _group = e.key),
              ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
            child: Text(_note, style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.sumi)),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: (c.maxWidth / 84).floor().clamp(4, 9), mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: shown.length,
              itemBuilder: (context, i) => _Cell(l: shown[i], color: colors[shown[i].group]!, latin: _latin),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final MnLetter l;
  final Color color;
  final bool latin;
  const _Cell({required this.l, required this.color, required this.latin});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => showLetterSoundSheet(context, l, color),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border.all(color: color.withValues(alpha: 0.6)), borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(child: Text('${l.upper}${l.lower}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color))),
            if (latin) Text(l.latin, style: const TextStyle(fontSize: 11, color: AppColors.sumiLight)),
          ]),
        ),
      );
}
