import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 모음조화 그룹 — 형태소 색칠의 기준. 같은 색 = 같은 모음조화 어미(라임).
///
/// 몽골어엔 문법적 성(性)이 없다. 대신 **모음조화**가 접미사 모양을 결정한다:
///   masc = 남성(후설) 모음 어미  а·о·у  (예: -ыг·-аас·-аар·-тай·-сан·-на)
///   fem  = 여성(전설) 모음 어미  э·ө·ү  (예: -ийг·-ээс·-ээр·-тэй·-сэн·-нэ)
///   neut = 중성/무변 어미        и·-г·-д
/// (러시아어판의 성 일치 색을 몽골어 모음조화 색으로 재해석.)
enum Gender { masc, fem, neut, none }

extension GenderStyle on Gender {
  /// 차분한 팔레트 3색 (원색 회피).
  Color get color {
    switch (this) {
      case Gender.masc:
        return AppColors.cobalt; // 남성모음 а о у
      case Gender.fem:
        return AppColors.amberDeep; // 여성모음 э ө ү
      case Gender.neut:
        return AppColors.pineDeep; // 중성 и
      case Gender.none:
        return AppColors.ink;
    }
  }

  String get ko {
    switch (this) {
      case Gender.masc:
        return '남성모음 (а о у)';
      case Gender.fem:
        return '여성모음 (э ө ү)';
      case Gender.neut:
        return '중성 (и)';
      case Gender.none:
        return '';
    }
  }
}

/// 한 단어(토큰) = 차분한 어간 + 변하는 어미.
///
/// 색칠 규칙:
///  - [gender] != none  → 어미를 모음조화 색으로 (격·복수 어미의 а/э 라임)
///  - [verb] == true     → 어미를 굵게 (동사 활용 엔진)
///  - [josa] != null     → 어미 뒤 작은 회색 라벨 (격 = 한국어 조사)
class Tok {
  final String stem; // 잉크색 어간 (키릴)
  final String infl; // 강조되는 어미 (키릴, 없으면 '')
  final String? stemKo; // 어간의 한글 독음 (잉크)
  final String? inflKo; // 어미의 한글 독음 (라임 = 성색)
  final Gender gender; // 성 일치 색
  final bool verb; // 동사 활용 → 굵게
  final String? josa; // 격 조사 라벨 (예: '을/를')

  const Tok(
    this.stem, {
    this.infl = '',
    this.stemKo,
    this.inflKo,
    this.gender = Gender.none,
    this.verb = false,
    this.josa,
  });

  /// TTS·복사용 표면형 (강세 기호 포함).
  String get surface => '$stem$infl';
}

/// 커리큘럼 한 문장.
class Sentence {
  final List<Tok> tokens;
  final String ko; // 한국어 뜻
  final String? note; // 한 줄 학습 포인트 (선택)

  const Sentence(this.tokens, {required this.ko, this.note});

  /// TTS에 넘길 평문 (강세 기호 제거 — 합성기 호환).
  String get plain =>
      tokens.map((t) => t.surface).join(' ').replaceAll('́', '');
}
