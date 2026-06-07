import 'package:flutter/material.dart';

class AppTheme {
  // 러시아어유니버스 brand — 따뜻한 자작나무·계피·앰버 톤.
  // 강렬한 러시아 적색 대신, 사모바르 차 한 잔의 따뜻함을 모티프로.
  static const brand = Color(0xFFC58B5B); // cinnamon-amber

  // Surface 보조 톤 (페일 자작나무 / 따뜻한 미백)
  static const _bgLight = Color(0xFFFAF6F0); // birch ivory
  static const _bgDark = Color(0xFF1E1612);  // warm dark espresso

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _bgLight,
      fontFamilyFallback: const [
        'Noto Sans',
        'Noto Sans KR',
        'PT Sans',
        'Malgun Gothic',
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: _bgLight,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bgDark,
    );
  }
}
