import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 문법 커리큘럼 한 단계.
/// 한국어와 같은 SOV·교착어 구조를 살린 선형 커리큘럼.
class GrammarStage {
  final String id; // 'alpha' | 's1' .. 's9'
  final String label; // 카드 좌측 짧은 라벨
  final String title; // 본문 제목
  final String subtitle; // 한 줄 예문 또는 부제
  final String description;
  final TrackKind track;
  final Color accent;
  final IconData icon;
  final bool implemented; // 화면 구현 여부 — false면 SnackBar

  const GrammarStage({
    required this.id,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.track,
    required this.accent,
    required this.icon,
    this.implemented = false,
  });
}

/// 트랙 분리: 토대 → 핵심규칙(모음조화·격) → 패턴(후치사) → 동사 → 확장.
enum TrackKind {
  foundation, // 알파벳·모음조화 토대
  rules, // 핵심 규칙 (모음조화·격)
  patterns, // 격·후치사 패턴
  irregular, // 동사 활용
  aspect, // 양태·확장
}

extension TrackKindKo on TrackKind {
  String get ko {
    switch (this) {
      case TrackKind.foundation:
        return '입문';
      case TrackKind.rules:
        return '핵심 규칙';
      case TrackKind.patterns:
        return '격 · 패턴';
      case TrackKind.irregular:
        return '동사';
      case TrackKind.aspect:
        return '확장';
    }
  }
}

/// 10개 카드 (알파벳 + 9단계). 한국어 조사 ↔ 몽골어 격 1:1, 어순 동일.
const grammarStages = <GrammarStage>[
  GrammarStage(
    id: 'alpha',
    label: '0',
    title: '알파벳 35 + 모음조화',
    subtitle: 'ээж · гэр · найз · сайхан · Ө Ү',
    description:
        '몽골 키릴 35자 = 러시아 키릴 + 몽골 전용 Ө·Ү. '
        '핵심은 모음조화: 모음이 남성(а о у)·여성(э ө ү)·중성(и)으로 갈리고, '
        '뒤에 붙는 모든 어미가 이 색을 따라간다. "대충 읽을 수 있다" 수준에서 졸업.',
    track: TrackKind.foundation,
    accent: AppColors.cobalt,
    icon: Icons.abc_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's1',
    label: '1',
    title: '형용사 + 명사 (어순=한국어)',
    subtitle: 'сайхан өдөр · сайн найз',
    description:
        '형용사가 명사 앞에 온다 — 한국어와 똑같은 어순. '
        '게다가 형용사는 변하지 않는다(성·수 일치 없음). 러시아어 대비 거의 공짜. '
        '명사 주격은 어미 0. 먼저 "변하지 않는다"를 몸에 익힌다.',
    track: TrackKind.rules,
    accent: AppColors.pineDeep,
    icon: Icons.crop_square_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's2',
    label: '2',
    title: '모음조화 — 어미 색의 법칙',
    subtitle: 'ном→номыг · гэр→гэрийг',
    description:
        '같은 격이라도 단어의 모음에 따라 어미 모양이 갈린다. '
        '남성모음(а о у) 단어엔 а형 어미, 여성모음(э ө ү) 단어엔 э형 어미. '
        '한 번 익히면 모든 격·복수·동사 어미에 그대로 적용된다 — 이 앱의 색이 그 라임.',
    track: TrackKind.rules,
    accent: AppColors.amberDeep,
    icon: Icons.palette_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's3',
    label: '3',
    title: '소유격 -ын/-ийн · 목적격 -ыг/-ийг',
    subtitle: 'номын нэр · номыг уншсан',
    description:
        '소유격(-ын/-ийн = ~의)과 목적격(-ыг/-ийг = ~을/를). '
        '한국어 조사와 1:1 — 거의 공짜. 어미 모양만 모음조화로 갈린다.',
    track: TrackKind.patterns,
    accent: AppColors.lilacDeep,
    icon: Icons.compare_arrows_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's4',
    label: '4',
    title: '여처격 -д/-т · 탈격 -аас/-ээс',
    subtitle: 'гэрт байна · гэрээс ирсэн',
    description:
        '여처격(-д/-т = ~에/에게)과 탈격(-аас/-ээс/-оос/-өөс = ~에서/부터). '
        '장소·시간·도착점은 -д, 출발점·비교는 -аас. 모음조화 4형 어미 첫 등장.',
    track: TrackKind.patterns,
    accent: AppColors.cobalt,
    icon: Icons.place_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's5',
    label: '5',
    title: '도구격 -аар/-ээр · 공동격 -тай/-тэй',
    subtitle: 'машинаар · найзтай',
    description:
        '도구격(-аар/-ээр = ~로/으로)과 공동격(-тай/-тэй/-той = ~와/과/랑). '
        '수단·재료는 -аар, 동반은 -тай. -тай는 "~가 있다"(소유)에도 쓰여 아주 흔하다.',
    track: TrackKind.patterns,
    accent: AppColors.amberDeep,
    icon: Icons.handshake_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's6',
    label: '6',
    title: '후치사 (дээр · дотор · хойно)',
    subtitle: 'ширээн дээр · гэрийн дотор',
    description:
        '몽골어엔 전치사가 없고 명사 뒤에 후치사가 온다 — 한국어 "위·안·뒤"와 똑같다. '
        'дээр(위)·доор(아래)·дотор(안)·гадаа(밖)·хойно(뒤)·өмнө(앞). '
        '앞 명사는 보통 소유격/주격으로.',
    track: TrackKind.patterns,
    accent: AppColors.lilacDeep,
    icon: Icons.layers_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's7',
    label: '7',
    title: '동사 시제 — 과거·현재미래',
    subtitle: 'идсэн · иднэ · явсан · явна',
    description:
        '과거 -сан/-сэн/-сон/-сөн (또는 -лаа/-лээ), 현재·미래 -на/-нэ/-но/-нө. '
        '인칭 변화가 없다 — 한국어처럼 주어가 바뀌어도 동사는 그대로. '
        '어미 모양만 모음조화로 갈린다.',
    track: TrackKind.irregular,
    accent: AppColors.pineDeep,
    icon: Icons.history_edu_outlined,
    implemented: true,
  ),
  GrammarStage(
    id: 's8',
    label: '8',
    title: '양태·요청 — -маар · болно · хэрэгтэй',
    subtitle: 'уумаар байна · явж болно',
    description:
        '하고 싶다(-маар/-мээр байна), 해도 된다·가능(болно), 필요하다(хэрэгтэй), '
        '정중한 부탁·명령(-аарай/-ээрэй). 즉시 써먹는 회화 양태.',
    track: TrackKind.aspect,
    accent: AppColors.cobalt,
    icon: Icons.volunteer_activism_outlined,
  ),
  GrammarStage(
    id: 's9',
    label: '9',
    title: '부정·의문 — биш · -гүй · уу/үү',
    subtitle: 'сайн биш · мэдэхгүй · ирэх үү?',
    description:
        '명사 부정 биш, 동사·형용사 부정 -гүй, 판정의문 첨사 уу/үү, '
        '의문사 хэн(누구)·юу(무엇)·хаана(어디)·хэзээ(언제). 회화 한 바퀴 마무리.',
    track: TrackKind.aspect,
    accent: AppColors.amberDeep,
    icon: Icons.help_outline,
  ),
];
