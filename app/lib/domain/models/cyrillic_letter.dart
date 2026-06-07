import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 몽골 키릴 학습 4단계 — 난이도·혼동 기준 재배열.
///   1 모음(+ 모음조화, 몽골 전용 Ө Ү) → 2 영어 가짜친구 자음
///   → 3 몽골 키릴 자음 → 4 나머지(친구 자음·반모음·부호)
enum AlphaStage { vowel, falseFriend, mongolOnly, rest }

extension AlphaStageStyle on AlphaStage {
  Color get color {
    switch (this) {
      case AlphaStage.vowel:
        return AppColors.amberDeep; // 모음 (기초·따뜻)
      case AlphaStage.falseFriend:
        return AppColors.danger; // 가짜친구 (경고)
      case AlphaStage.mongolOnly:
        return AppColors.cobalt; // 몽골 키릴 자음 (새 글자)
      case AlphaStage.rest:
        return AppColors.pineDeep; // 나머지 (쉬움)
    }
  }

  /// 메뉴 짧은 라벨.
  String get tab {
    switch (this) {
      case AlphaStage.vowel:
        return '모음';
      case AlphaStage.falseFriend:
        return '가짜친구';
      case AlphaStage.mongolOnly:
        return '몽골 자음';
      case AlphaStage.rest:
        return '나머지';
    }
  }

  /// 본문 설명 라벨.
  String get ko {
    switch (this) {
      case AlphaStage.vowel:
        return '1단계 · 모음 + 모음조화';
      case AlphaStage.falseFriend:
        return '2단계 · 영어 가짜친구 자음';
      case AlphaStage.mongolOnly:
        return '3단계 · 몽골 키릴 자음';
      case AlphaStage.rest:
        return '4단계 · 나머지 · 부호';
    }
  }
}

/// 키릴 한 글자.
class CyrillicLetter {
  final String upper; // 대문자 А
  final String lower; // 소문자 а
  final String name; // 글자 이름 (예: '아', '베')
  final String roman; // 로마자 근사
  final String sound; // 한글 근사음 (소리만 노출)
  final AlphaStage stage;
  final String tip; // 한 줄 학습 포인트

  const CyrillicLetter({
    required this.upper,
    required this.lower,
    required this.name,
    required this.roman,
    required this.sound,
    required this.stage,
    required this.tip,
  });
}
