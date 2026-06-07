import 'package:flutter/material.dart';

import '../../data/curriculum_sentences.dart';
import '../../data/l2_dialogues.dart';
import '../../data/travel_dating.dart';
import '../../domain/models/dialogue.dart';
import '../../domain/models/flashcard.dart';
import '../../domain/models/grammar_stage.dart';
import '../../domain/models/sentence.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ui_kit.dart';
import '../travel/travel_phrase_screen.dart';
import 'dialogue_chat_screen.dart';
import 'flashcard_session_screen.dart';

/// 회화 탭 — 문법 문장을 플래시카드로 굴려 익히는 덱 목록.
class FlashcardsHomeScreen extends StatelessWidget {
  const FlashcardsHomeScreen({super.key});

  static const _fills = [AppColors.sky, AppColors.mint, AppColors.peach, AppColors.lilac];

  @override
  Widget build(BuildContext context) {
    // 시드 문장이 있는 단계만 덱으로.
    final decks = <_Deck>[];
    var c = 0;
    for (final stage in grammarStages) {
      final s = curriculumSentences[stage.id];
      if (s == null || s.isEmpty) continue;
      decks.add(_Deck(stage.title, s, _fills[c % _fills.length]));
      c++;
    }
    final all = <Sentence>[for (final d in decks) ...d.sentences];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('회화', style: AppType.serif(26)),
        const SizedBox(height: 6),
        Text('여행 데이팅 시나리오 250문장 — 문장마다 한국 화자용 문법 설명.',
            style: AppType.sans(13, color: AppColors.inkSoft)),
        const SizedBox(height: 18),
        const Eyebrow('여행 데이팅 회화 · 테마별 50문장'),
        const SizedBox(height: 10),
        for (final t in travelThemes) ...[
          OutlineCard(
            fill: t.accent.withValues(alpha: 0.12),
            padding: const EdgeInsets.all(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TravelPhraseScreen(theme: t)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.outline, width: 1.4),
                  ),
                  child: Icon(t.icon, color: AppColors.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: AppType.serif(16)),
                      const SizedBox(height: 2),
                      Text('${t.subtitle}  ·  50문장',
                          style: AppType.sans(12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        const Eyebrow('다이얼로그 · L2 챗'),
        const SizedBox(height: 10),
        for (final d in l2Dialogues) ...[
          OutlineCard(
            fill: AppColors.sky,
            padding: const EdgeInsets.all(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DialogueChatScreen(dialogue: d)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.outline, width: 1.4),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.title, style: AppType.serif(16)),
                      const SizedBox(height: 2),
                      Text('${d.turns.length}턴 · ${d.tone.ko} · 반전 ${d.twistLabel}',
                          style: AppType.sans(12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        const Eyebrow('플래시카드 · 문법 문장'),
        const SizedBox(height: 10),
        _DeckCard(
          title: '전체 섞기',
          subtitle: '${all.length}장 · 모든 단계',
          fill: AppColors.surface,
          icon: Icons.shuffle_rounded,
          onTap: () => _open(context, '전체 섞기', all, AppColors.sky),
        ),
        const SizedBox(height: 12),
        for (final d in decks) ...[
          _DeckCard(
            title: d.title,
            subtitle: '${d.sentences.length}장',
            fill: d.fill,
            icon: Icons.style_rounded,
            onTap: () => _open(context, d.title, d.sentences, d.fill),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _open(BuildContext context, String title, List<Sentence> s, Color fill) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FlashcardSessionScreen(
        title: title,
        fill: fill,
        items: [for (final x in s) FlashItem.fromSentence(x)],
      ),
    ));
  }
}

class _Deck {
  final String title;
  final List<Sentence> sentences;
  final Color fill;
  _Deck(this.title, this.sentences, this.fill);
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.title,
    required this.subtitle,
    required this.fill,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final Color fill;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      fill: fill,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.outline, width: 1.4),
            ),
            child: Icon(icon, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.serif(16)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppType.sans(12.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
