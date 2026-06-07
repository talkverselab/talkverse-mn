import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography — daydream의 굵은 grotesque 산세리프 톤.
///
/// 세리프 없이 Manrope 한 패밀리로 무게만 바꿔 쓴다(키릴 지원, 한글은 폴백).
/// 헤딩은 굵고 살짝 좁게(트래킹 -), 본문은 14 기준.
class AppType {
  AppType._();

  static const List<String> _krFallback = [
    'Noto Sans KR',
    'Apple SD Gothic Neo',
    'Malgun Gothic',
  ];

  static TextTheme build(TextTheme base) {
    final body = GoogleFonts.manropeTextTheme(base);
    return body.copyWith(
      displaySmall: _h(30, FontWeight.w800, height: 1.08, spacing: -0.6),
      headlineSmall: _h(23, FontWeight.w800, height: 1.12, spacing: -0.4),
      titleLarge: _h(19, FontWeight.w800, height: 1.16, spacing: -0.3),
      titleMedium: _h(16.5, FontWeight.w700, height: 1.2, spacing: -0.2),
      titleSmall: _h(13.5, FontWeight.w700, height: 1.3),
      bodyLarge: _h(14.5, FontWeight.w500, color: AppColors.ink, height: 1.45),
      bodyMedium: _h(14, FontWeight.w400, color: AppColors.inkSoft, height: 1.5),
      bodySmall: _h(12.5, FontWeight.w400, color: AppColors.inkSoft, height: 1.45),
      labelLarge: _h(13.5, FontWeight.w700, spacing: 0.1),
      labelMedium: _h(12, FontWeight.w600, color: AppColors.inkSoft, spacing: 0.2),
      labelSmall: _h(11, FontWeight.w600, color: AppColors.inkFaint, spacing: 0.3),
    );
  }

  static TextStyle _h(
    double size,
    FontWeight weight, {
    Color color = AppColors.ink,
    double? height,
    double spacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      ).copyWith(fontFamilyFallback: _krFallback);

  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    double spacing = 0,
  }) =>
      _h(size, weight, color: color, height: height, spacing: spacing);

  /// 과거 호출 호환 — 이제 세리프가 아니라 *굵은 산세리프 디스플레이*.
  static TextStyle serif(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.ink,
    double? height,
    double spacing = -0.3,
  }) =>
      _h(size, weight, color: color, height: height, spacing: spacing);

  static TextStyle micro = GoogleFonts.manrope(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: AppColors.inkFaint,
  ).copyWith(fontFamilyFallback: _krFallback);

  static TextStyle eyebrow = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    color: AppColors.inkFaint,
  ).copyWith(fontFamilyFallback: _krFallback);
}
