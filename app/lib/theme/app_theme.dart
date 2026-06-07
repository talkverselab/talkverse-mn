import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      primary: AppColors.ink, // daydream: 검정 알약 버튼
      secondary: AppColors.cobalt,
      surface: AppColors.surface,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: AppType.build(base.textTheme),
      splashFactory: InkRipple.splashFactory,
      dividerColor: AppColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.ink, size: 22),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: AppColors.inkOnDark),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sky,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF1E1E1C),
      textTheme: AppType.build(base.textTheme),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
