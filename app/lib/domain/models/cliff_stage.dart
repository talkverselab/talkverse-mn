import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 몽골어 cliff 한 구간. lemma rank 누적 빈도 기반.
class CliffStage {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int rankFrom;
  final int rankTo;
  final IconData icon;
  final Color accent;

  const CliffStage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.rankFrom,
    required this.rankTo,
    required this.icon,
    required this.accent,
  });

  int get count => rankTo - rankFrom + 1;
}

/// OpenSubtitles/Tatoeba 기반 몽골어 고빈도 lemma 절벽(근사치).
/// L1 골격(대명사·첨사·후치사·기본동사) → L2 일상 명사·형용사 → L3 여행 → L4 감정.
const cliffStages = <CliffStage>[
  CliffStage(
    id: 'l1',
    title: 'L1 · 골격 120',
    subtitle: 'TOP 1–120 · 회화의 뼈대',
    description:
        'би·чи·энэ·тэр·байх·болох … 대명사·첨사(уу/үү·юм·ч·л)·후치사·기본 동사. '
        '120 lemma만 익혀도 회화 절반이 보인다. 격·모음조화 첫 노출.',
    rankFrom: 1,
    rankTo: 120,
    icon: Icons.bolt,
    accent: AppColors.amberDeep,
  ),
  CliffStage(
    id: 'l2',
    title: 'L2 · 일상 명사·형용사',
    subtitle: 'TOP 121–210 · 수·사물·색·평가',
    description:
        'нэг·хоёр·гэр·хоол·улаан·том·сайхан … 수사·일상 명사·형용사 90 추가. '
        '실제 회화 진입 임계점. 격 지배 다양화.',
    rankFrom: 121,
    rankTo: 210,
    icon: Icons.forum,
    accent: AppColors.pineDeep,
  ),
  CliffStage(
    id: 'l3',
    title: 'L3 · 여행 어휘',
    subtitle: 'TOP 211–230 · 자연·이동·문화',
    description:
        'аялах·онгоц·говь·тал·нуур·наадам … 여행·자연·문화 어휘 20. '
        '몽골 여행 상황 회화로 확장.',
    rankFrom: 211,
    rankTo: 230,
    icon: Icons.travel_explore,
    accent: AppColors.cobalt,
  ),
  CliffStage(
    id: 'l4',
    title: 'L4 · 감정·로맨스',
    subtitle: 'TOP 231–250 · 마음·관계',
    description:
        'хайр·сэтгэл·учрах·болзох·санах·мөрөөдөл … 감정·연애 어휘 20. '
        '데이팅 표현 심화.',
    rankFrom: 231,
    rankTo: 250,
    icon: Icons.favorite,
    accent: AppColors.lilacDeep,
  ),
  CliffStage(
    id: 'l5',
    title: 'L5 · 자유 회화',
    subtitle: '준비 중',
    description:
        '전문어·문화어·고급 표현 — 다음 버전에서 코퍼스 검증 후 추가.',
    rankFrom: 251,
    rankTo: 251,
    icon: Icons.workspace_premium,
    accent: AppColors.amberDeep,
  ),
];
