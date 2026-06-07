import 'package:flutter/material.dart';

import '../domain/models/sentence.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 문장 카드 — 색칠된 러시아어 + 한국어 뜻 + TTS.
///
/// 어간은 잉크, 어미는 성(色)·동사(굵게), 격은 작은 조사 라벨.
/// 단어를 탭하면 그 단어만, 스피커를 누르면 문장 전체를 읽는다.
class SentenceCard extends StatelessWidget {
  const SentenceCard({super.key, required this.sentence, this.accent = AppColors.amber});
  final Sentence sentence;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline, width: 1.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SentenceText(tokens: sentence.tokens),
                const SizedBox(height: 8),
                SentenceReading(tokens: sentence.tokens),
                const SizedBox(height: 10),
                Text(
                  sentence.ko,
                  style: AppType.sans(13.5,
                      weight: FontWeight.w500, color: AppColors.inkSoft, height: 1.4),
                ),
                if (sentence.note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sentence.note!,
                    style: AppType.sans(11.5, weight: FontWeight.w600, color: accent),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          _SpeakerButton(text: sentence.plain, accent: accent),
        ],
      ),
    );
  }
}

/// 색칠된 문장 텍스트만 (어간 잉크 / 어미 성색·동사굵게 / 격 조사칩). 재사용용.
/// [emphasize] 인덱스의 단어는 점선 밑줄(성별에 따라 바뀌는 어미 표시).
class SentenceText extends StatelessWidget {
  const SentenceText({super.key, required this.tokens, this.size = 20, this.emphasize = const {}});
  final List<Tok> tokens;
  final double size;
  final Set<int> emphasize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 7,
      runSpacing: 10,
      children: [
        for (var i = 0; i < tokens.length; i++)
          _Word(tok: tokens[i], size: size, emphasize: emphasize.contains(i)),
      ],
    );
  }
}

/// 한국어 독음 줄 — 어간(잉크) + 어미(성색/동사 굵게)로 라임을 한국어로 색칠.
class SentenceReading extends StatelessWidget {
  const SentenceReading({super.key, required this.tokens, this.size = 14, this.emphasize = const {}});
  final List<Tok> tokens;
  final double size;
  final Set<int> emphasize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < tokens.length; i++)
          if ((tokens[i].stemKo ?? '').isNotEmpty || (tokens[i].inflKo ?? '').isNotEmpty)
            Builder(builder: (_) {
              final t = tokens[i];
              final emp = emphasize.contains(i);
              final deco = emp ? TextDecoration.underline : TextDecoration.none;
              return GestureDetector(
                onTap: () => TtsService.instance.speak(t.surface),
                child: Text.rich(TextSpan(children: [
                  if ((t.stemKo ?? '').isNotEmpty)
                    TextSpan(
                      text: t.stemKo,
                      style: AppType.sans(size, weight: FontWeight.w500, color: AppColors.inkSoft)
                          .copyWith(decoration: deco, decorationStyle: TextDecorationStyle.dotted, decorationColor: AppColors.amberDeep),
                    ),
                  if ((t.inflKo ?? '').isNotEmpty)
                    TextSpan(
                      text: t.inflKo,
                      style: AppType.sans(size,
                          weight: t.verb ? FontWeight.w800 : FontWeight.w700,
                          color: t.gender == Gender.none ? AppColors.ink : t.gender.color)
                          .copyWith(decoration: deco, decorationStyle: TextDecorationStyle.dotted, decorationColor: AppColors.amberDeep),
                    ),
                ])),
              );
            }),
      ],
    );
  }
}

class _Word extends StatelessWidget {
  const _Word({required this.tok, this.size = 20, this.emphasize = false});
  final Tok tok;
  final double size;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    // 성별에 따라 바뀌는 단어 → 점선 밑줄.
    final deco = emphasize ? TextDecoration.underline : TextDecoration.none;
    var stemStyle = AppType.sans(size, weight: FontWeight.w600, color: AppColors.ink, height: 1.2)
        .copyWith(decoration: deco, decorationStyle: TextDecorationStyle.dotted, decorationColor: AppColors.amberDeep, decorationThickness: 2);
    // 어미 스타일: 동사 → 굵게, 성 → 색. 과거형은 둘 다.
    final inflColor = tok.gender == Gender.none ? AppColors.ink : tok.gender.color;
    final inflWeight = tok.verb ? FontWeight.w800 : FontWeight.w700;
    final inflStyle = AppType.sans(size,
        weight: inflWeight, color: inflColor, height: 1.2)
        .copyWith(decoration: deco, decorationStyle: TextDecorationStyle.dotted, decorationColor: AppColors.amberDeep, decorationThickness: 2);

    return GestureDetector(
      onTap: () => TtsService.instance.speak(tok.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: tok.stem, style: stemStyle),
              if (tok.infl.isNotEmpty) TextSpan(text: tok.infl, style: inflStyle),
            ]),
          ),
          if (tok.josa != null)
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(tok.josa!,
                  style: AppType.sans(9.5, weight: FontWeight.w700, color: AppColors.inkFaint)),
            ),
        ],
      ),
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TtsService.instance.speak(text),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.volume_up_rounded, color: accent, size: 21),
      ),
    );
  }
}

/// 색칠 규칙 범례 — 단계 화면 상단.
class RhymeLegend extends StatelessWidget {
  const RhymeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: const [
              _Swatch(color: AppColors.cobalt, label: '남성모음 а о у'),
              _Swatch(color: AppColors.amberDeep, label: '여성모음 э ө ү'),
              _Swatch(color: AppColors.pineDeep, label: '중성 и'),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '색 = ', style: _meta),
              TextSpan(text: '모음조화로 변하는 어미', style: _metaInk),
              TextSpan(text: '  ·  ', style: _meta),
              TextSpan(
                  text: '굵게',
                  style: _metaInk.copyWith(fontWeight: FontWeight.w800)),
              TextSpan(text: ' = 동사 활용', style: _meta),
              TextSpan(text: '\n어미 밑 ', style: _meta),
              TextSpan(text: '한글 = 소리(라임)', style: _metaInk),
              TextSpan(text: '  ·  회색칩 = 격(조사)', style: _meta),
            ]),
          ),
        ],
      ),
    );
  }

  static final TextStyle _meta =
      AppType.sans(11.5, weight: FontWeight.w500, color: AppColors.inkFaint);
  static final TextStyle _metaInk =
      AppType.sans(11.5, weight: FontWeight.w600, color: AppColors.inkSoft);
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 11, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: AppType.sans(11.5, weight: FontWeight.w700, color: color)),
      ],
    );
  }
}
