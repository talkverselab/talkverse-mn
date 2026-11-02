import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/mn_affixes.dart';
import '../services/tts_service.dart';
import '../widgets/affix_sheet.dart';

/// 동사 형태 맵 — 2026-11-03 사용자 지시(Grok UX 글 시안 MN-UX02 ③ 「동사 어간 하나에서 갈라지는 형태」).
/// 앱 문장에 나온 동사를 어간으로 모아, 가운데 어간 + 둘레에 형태 10가지(부정사·현재·과거·습관·연결·조건·명령·바람·부정).
/// 앱 문장에 실제로 나온 형태는 예문과 함께(진하게), 나오지 않은 형태는 규칙으로 만든 「규칙형」(흐리게).
class VerbListScreen extends StatelessWidget {
  const VerbListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(title: Text(tr('동사 형태 맵'))),
        body: FutureBuilder(
          future: AffixCorpus.instance.ensureLoaded(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            final verbs = AffixCorpus.instance.verbs();
            return ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
              children: [
                Text(tr('어간 하나에 어미를 바꿔 붙이면 뜻이 갈라집니다. 앱 문장에 나온 동사만 모았어요.'),
                    style: const TextStyle(fontSize: 13.5, color: AppColors.sumiLight, height: 1.45)),
                const SizedBox(height: 12),
                for (final v in verbs)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.washi,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                      boxShadow: kCardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => openPane(context, (_) => VerbMapScreen(entry: v)),
                        title: Text(v.title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                        subtitle: Text(
                            v.seen.keys.map((id) => tr(affixById(id)?.name ?? id)).join(' · '),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        trailing: Text(trf('형태 {0}', [v.seen.length]),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.beni)),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}

class VerbMapScreen extends StatelessWidget {
  final VerbEntry entry;
  const VerbMapScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final stem = entry.stem;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(entry.title)),
      body: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        final w = (c.maxWidth - 32 - (cols - 1) * 10) / cols;
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)),
          children: [
            // 가운데 어간
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.wordmark,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: kCardShadow,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(trf('어간 {0}-', [stem]), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(tr('모양은 어간의 모음에 맞춰 골라요'), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final id in kVerbMapSlots)
                SizedBox(width: w, child: _FormCard(stem: stem, affix: affixById(id)!, seen: entry.seen[id] ?? const [])),
            ]),
            const SizedBox(height: 14),
            Text(tr('진한 칸 = 앱 문장에 나온 형태 · 흐린 칸 = 규칙으로 만든 형태(확인용)'),
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
        );
      }),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String stem;
  final Affix affix;
  final List<AffixExample> seen;
  const _FormCard({required this.stem, required this.affix, required this.seen});

  @override
  Widget build(BuildContext context) {
    final c = affix.kind.color;
    final real = seen.isNotEmpty;
    final form = real ? seen.first.hit.word.toLowerCase() : (verbForm(stem, affix.id) ?? '');
    final ex = real ? seen.first : null;
    return InkWell(
      onTap: () => AffixSheet.show(context, affix, hit: ex?.hit),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: real ? c.withValues(alpha: 0.06) : AppColors.washiDeep,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: real ? c : AppColors.line, width: real ? 1.4 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(tr(affix.name), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
            const SizedBox(width: 6),
            Expanded(child: Text(affix.ko, style: const TextStyle(fontSize: 11.5, color: AppColors.muted), overflow: TextOverflow.ellipsis)),
            if (!real)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(6)),
                child: Text(tr('규칙형'), style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ),
          ]),
          const SizedBox(height: 6),
          Text.rich(TextSpan(style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: real ? AppColors.sumi : AppColors.muted), children: [
            TextSpan(text: form.length > stem.length && form.startsWith(stem) ? stem : form),
            if (form.length > stem.length && form.startsWith(stem))
              TextSpan(text: form.substring(stem.length), style: TextStyle(color: real ? c : AppColors.muted)),
          ])),
          if (ex != null) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.tl, style: const TextStyle(fontSize: 13.5, color: AppColors.sumi, fontWeight: FontWeight.w600)),
                  Text(ex.ko, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
                ]),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => TtsService.instance.speak(ex.tl),
                icon: Icon(Icons.volume_up, color: c, size: 20),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
