import 'package:flutter/material.dart';

import '../../data/curriculum_sentences.dart';
import '../../domain/models/grammar_stage.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/sentence_view.dart';
import '../../widgets/ui_kit.dart';

/// 한 문법 단계 상세 — 배너 + 핵심 포인트 + 한 줄 요약(TTS) + 색칠 예문.
class GrammarStageScreen extends StatelessWidget {
  final GrammarStage stage;
  const GrammarStageScreen({super.key, required this.stage});

  Color get _fill => stage.accent.withValues(alpha: 0.14);

  @override
  Widget build(BuildContext context) {
    final sentences = curriculumSentences[stage.id];
    final points = grammarPoints[stage.id];
    return Scaffold(
      appBar: AppBar(title: Text(stage.title, style: AppType.serif(18))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _banner(),
          const SizedBox(height: 18),

          // 한 줄 요약 (탭 → TTS)
          const Eyebrow('한 줄 요약 · 탭하면 들려요'),
          const SizedBox(height: 8),
          OutlineCard(
            fill: _fill,
            onTap: () => TtsService.instance.speak(stage.subtitle),
            child: Row(
              children: [
                Expanded(
                  child: Text(stage.subtitle,
                      style: AppType.serif(17, color: AppColors.ink)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.volume_up_rounded, color: AppColors.ink, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 핵심 포인트
          if (points != null && points.isNotEmpty) ...[
            const Eyebrow('핵심 포인트'),
            const SizedBox(height: 8),
            OutlineCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < points.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5, right: 10),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: stage.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.outline, width: 1),
                          ),
                        ),
                        Expanded(
                          child: Text(points[i],
                              style: AppType.sans(13.5, weight: FontWeight.w500, color: AppColors.ink, height: 1.45)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 더 자세히 (원문 설명)
          const Eyebrow('설명'),
          const SizedBox(height: 8),
          Text(stage.description,
              style: AppType.sans(13.5, weight: FontWeight.w400, color: AppColors.inkSoft, height: 1.55)),
          const SizedBox(height: 20),

          // 색칠 예문
          if (sentences != null && sentences.isNotEmpty) ...[
            const Eyebrow('일상 문장 · 탭하면 들려요'),
            const SizedBox(height: 8),
            const RhymeLegend(),
            const SizedBox(height: 12),
            for (final s in sentences) ...[
              SentenceCard(sentence: s, accent: stage.accent),
              const SizedBox(height: 10),
            ],
          ] else
            _comingSoon(),
        ],
      ),
    );
  }

  Widget _banner() {
    return OutlineCard(
      fill: _fill,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.outline, width: 1.6),
            ),
            child: Text(stage.label, style: AppType.serif(22, color: AppColors.ink)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.title, style: AppType.serif(18)),
                const SizedBox(height: 4),
                Text(stage.track.ko,
                    style: AppType.sans(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comingSoon() {
    return OutlineCard(
      fill: AppColors.surfaceAlt,
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '이 단계의 색칠 예문·드릴은 다음 버전에서 — 코어 40 단어로 닳도록 반복.',
              style: AppType.sans(12.5, weight: FontWeight.w500, color: AppColors.inkSoft, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
