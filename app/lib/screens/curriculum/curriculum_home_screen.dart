import 'package:flutter/material.dart';

import '../../domain/models/grammar_stage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ui_kit.dart';
import '../alphabet/cyrillic_alphabet_screen.dart';
import 'grammar_stage_screen.dart';

/// 문법 10단계 + 알파벳 선형 커리큘럼 홈 (spec §4).
class CurriculumHomeScreen extends StatelessWidget {
  const CurriculumHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: grammarStages.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == 0) return const _CurriculumHeader();
        final stage = grammarStages[i - 1];
        return _StageCard(
          stage: stage,
          index: i,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => stage.id == 'alpha'
                    ? const CyrillicAlphabetScreen()
                    : GrammarStageScreen(stage: stage),
              ),
            );
          },
        );
      },
    );
  }
}

class _CurriculumHeader extends StatelessWidget {
  const _CurriculumHeader();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('문법 골격 · 선형 커리큘럼'),
        const SizedBox(height: 10),
        Text('알파벳 35 + 문법 9단계',
            style: AppType.serif(26, weight: FontWeight.w600, height: 1.15)),
        const SizedBox(height: 10),
        Text(
          '모음조화 → 격(조사) → 후치사 → 동사 어미 순으로 한 바퀴. '
          '한국어와 같은 어순(SOV)이라 골격만 잡으면 빠르게 닫힌다. 예문은 여행 데이팅 테마.',
          style: AppType.sans(13, weight: FontWeight.w400, color: AppColors.inkSoft, height: 1.5),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  final GrammarStage stage;
  final int index;
  final VoidCallback onTap;
  const _StageCard({required this.stage, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: stage.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline, width: 1.6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline, width: 1.4),
              ),
              alignment: Alignment.center,
              child: Text(
                stage.label,
                style: AppType.serif(18, weight: FontWeight.w700, color: stage.accent),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(stage.title,
                            style: AppType.serif(16, weight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Tag(text: stage.track.ko, color: stage.accent),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(stage.subtitle,
                      style: AppType.sans(12.5,
                          weight: FontWeight.w600, color: stage.accent, height: 1.35)),
                  const SizedBox(height: 7),
                  Text(stage.description,
                      style: AppType.sans(12.5,
                          weight: FontWeight.w400, color: AppColors.inkSoft, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
