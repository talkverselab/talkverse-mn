import 'package:flutter/material.dart';

import '../../data/travel_dating.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ui_kit.dart';
import 'travel_phrase_screen.dart';

/// 여행 데이팅앱 회화 — 테마별 50문장 (몽골어 + 문법 설명, 한국 화자용).
class TravelDatingHomeScreen extends StatelessWidget {
  const TravelDatingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('여행 데이팅 회화', style: AppType.serif(19, weight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        itemCount: travelThemes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == 0) return const _Header();
          final theme = travelThemes[i - 1];
          return _ThemeCard(theme: theme);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('여행 × 데이팅 · 시나리오 회화'),
        const SizedBox(height: 10),
        Text('테마별 50문장 × 5',
            style: AppType.serif(26, weight: FontWeight.w600, height: 1.15)),
        const SizedBox(height: 10),
        Text(
          '몽골 여행에서 사람을 만나고 데이트하는 250문장. '
          '문장마다 한국 화자용 문법 설명(격·모음조화·동사 어미) · 독음 · 발음 듣기.',
          style: AppType.sans(13, color: AppColors.inkSoft, height: 1.5),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme});
  final TravelTheme theme;

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      fill: theme.accent.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TravelPhraseScreen(theme: theme)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline, width: 1.4),
            ),
            child: Icon(theme.icon, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(theme.title, style: AppType.serif(16, weight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Tag(text: '50문장', color: theme.accent),
                  ],
                ),
                const SizedBox(height: 5),
                Text(theme.subtitle,
                    style: AppType.sans(12.5, color: AppColors.inkSoft, height: 1.35)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}
