import 'package:flutter/material.dart';

import '../../domain/models/cliff_stage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ui_kit.dart';
import 'cliff_stage_screen.dart';

/// 격변화·cliff 단계 홈 — L1~L5 5단계 메뉴.
class CasesHomeScreen extends StatelessWidget {
  const CasesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('격변화 학습', style: AppType.serif(19, weight: FontWeight.w600)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: cliffStages.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == 0) return const _CliffHeader();
          final stage = cliffStages[i - 1];
          return _StageCard(
            stage: stage,
            onTap: () {
              if (stage.id == 'l5') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('L5 데이터는 준비 중'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CliffStageScreen(stage: stage)),
              );
            },
          );
        },
      ),
    );
  }
}

class _CliffHeader extends StatelessWidget {
  const _CliffHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('어휘 절벽 · cliff'),
        const SizedBox(height: 10),
        Text('몽골어 cliff 단계',
            style: AppType.serif(24, weight: FontWeight.w600, height: 1.15)),
        const SizedBox(height: 10),
        Text(
          '120 → 210 → 230 → 250 lemma. '
          '공개 말뭉치 기반 고빈도 절벽구간 — 빈도순으로 익힌다.',
          style: AppType.sans(13, weight: FontWeight.w400, color: AppColors.inkSoft, height: 1.5),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  final CliffStage stage;
  final VoidCallback onTap;
  const _StageCard({required this.stage, required this.onTap});

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
              child: Icon(stage.icon, color: stage.accent),
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
                      Tag(text: '${stage.count}어', color: stage.accent),
                    ],
                  ),
                  const SizedBox(height: 4),
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
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 6),
              child: Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}
