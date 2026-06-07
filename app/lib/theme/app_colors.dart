import 'package:flutter/material.dart';

/// Russian Talk — daydream 톤.
///
/// 크림 배경 위 캔디 파스텔 블록(하늘·민트·피치·라일락) + 얇은 검정 아웃라인 +
/// 차콜 굵은 타입. (withdaydream.com 레퍼런스 / 앱 아이콘과 동일 팔레트)
class AppColors {
  AppColors._();

  // Neutrals — 크림 + 차콜 + 헤어라인.
  static const Color bg = Color(0xFFFCFCF8); // 크림 캔버스
  static const Color cream = Color(0xFFFCFCF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF5F4EC);
  static const Color line = Color(0xFFE7E6DD); // 부드러운 구분선
  static const Color lineSoft = Color(0xFFF0EFE7);
  static const Color outline = Color(0xFF1A1A1A); // 시그니처 검정 아웃라인

  // Ink — text (차콜).
  static const Color ink = Color(0xFF232323);
  static const Color inkSoft = Color(0xFF5F5E57);
  static const Color inkFaint = Color(0xFF9C9B91);
  static const Color inkOnDark = Color(0xFFFCFCF8);

  // ── 캔디 파스텔 (블록 채움) ───────────────────────────────
  static const Color sky = Color(0xFFB7EBFF); // 하늘 (러시아 = 메인)
  static const Color skyLight = Color(0xFFE3F6FF);
  static const Color mint = Color(0xFFC7FFD6);
  static const Color mintLight = Color(0xFFE6FBEC);
  static const Color peach = Color(0xFFFEE3CC);
  static const Color peachLight = Color(0xFFFFF1E4);
  static const Color lilac = Color(0xFFEED1FF);
  static const Color lilacLight = Color(0xFFF5E3FF);

  // 파스텔 위/크림 위에서 읽히는 deep 톤 (텍스트·아이콘·아웃라인).
  static const Color cobalt = Color(0xFF2E6E8F); // sky deep
  static const Color cobaltSoft = sky;
  static const Color pine = Color(0xFF3E8E68); // mint deep
  static const Color pineDeep = Color(0xFF2F6F50);
  static const Color pineSoft = mint;
  static const Color amber = Color(0xFFE7A35C); // peach deep (따뜻 강조)
  static const Color amberDeep = Color(0xFFC77B33);
  static const Color amberSoft = peach;
  static const Color lilacDeep = Color(0xFF7A4F9E);

  // Status.
  static const Color online = Color(0xFF46A86B);
  static const Color warn = Color(0xFFE0A23C);
  static const Color danger = Color(0xFFE0563E);

  // 그라데이션 (대부분 평면 파스텔로 대체했으나 호환 위해 유지).
  static const List<Color> nightDusk = [
    Color(0xFF241C16),
    Color(0xFF3A2A20),
    Color(0xFF52372A),
  ];
  static const List<Color> amberSunset = [peachLight, peach, Color(0xFFFAD0A8)];
  static const List<Color> learnGradient = [mintLight, mint, Color(0xFFA8EFC0)];

  // 그림자 — daydream은 평면+아웃라인. 아주 옅게만.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF232323).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF232323).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];
}
