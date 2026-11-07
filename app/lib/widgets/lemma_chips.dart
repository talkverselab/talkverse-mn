import 'package:flutter/material.dart';

import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../services/word_lookup.dart';

/// 문장의 내용어(레마) 칩 — 단어장에 있는 말은 누르면 단어 시트, 없는 말은 회색(사용자 지시 2026-11-04 "문장 레마별로 단어장이랑 연결").
/// 단어장에 없는 말은 회화 작업 때 빈도순으로 모아 uk 세션에 단어·그림 제작을 맡긴다.
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<LemmaHit>>(
        key: ValueKey('${turn.num}:${turn.tl}'),
        future: lemmasForTurn(turn),
        builder: (context, snap) {
          final hits = snap.data ?? const <LemmaHit>[];
          if (hits.isEmpty) return const SizedBox.shrink();
          return Wrap(spacing: 6, runSpacing: 6, children: [
            for (final h in hits)
              _Chip(
                label: h.word?.word ?? h.surface,
                gloss: h.word?.meaningKo,
                compact: compact,
                onTap: h.word == null ? null : () => showWordSheet(context, h.word!),
              ),
            if (hits.every((h) => h.word == null))
              Padding(padding: const EdgeInsets.only(top: 2), child: Text(tr('단어장에 없는 말'), style: const TextStyle(fontSize: 10, color: AppColors.muted))),
          ]);
        },
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: on ? AppColors.washi : AppColors.washiDeep,
          border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted)),
          if (gloss != null && gloss!.isNotEmpty) ...[
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(gloss!.split(RegExp(r'[,;·/]')).first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// 단어 시트 — 표제어·독음·뜻·품사·절벽 레벨·그림·🔊.
Future<void> showWordSheet(BuildContext context, WordRow w) => showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.washi,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(w.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.beni))),
              IconButton(onPressed: () => TtsService.instance.speak(w.word), icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 28)),
            ]),
            if ((w.cefr ?? '').isNotEmpty) Text(w.cefr!, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 8),
            Text(w.meaningKo ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            const SizedBox(height: 6),
            Text([if (w.pos != null) w.pos!, regionOf(w.rank), trf('빈도 {0}위', [w.rank])].join(' · '),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            FutureBuilder<String?>(
              future: ArtService.instance.urlFor(w.word, rank: w.rank),
              builder: (_, s) => s.data == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image(image: artProvider(s.data!), height: 180, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                        ),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
