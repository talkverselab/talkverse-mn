import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/mn_affixes.dart';
import '../screens/affix_screens.dart';

/// 접사 블록(어간 + 접사) — 접사 칩은 종류별 색, 아래에 같은 색 테두리로 대응 한국어 조사·어미.
class AffixBlock extends StatelessWidget {
  final AffixHit hit;
  final bool showKo;
  const AffixBlock({super.key, required this.hit, this.showKo = true});

  @override
  Widget build(BuildContext context) {
    final c = hit.affix.kind.color;
    return InkWell(
      onTap: () => AffixSheet.show(context, hit.affix, hit: hit),
      borderRadius: BorderRadius.circular(10),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.beni.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            ),
            child: Text(hit.stem, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              border: Border.all(color: c, width: 1.4),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
            ),
            child: Text('-${hit.suffix}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c)),
          ),
        ]),
        if (showKo)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(border: Border.all(color: c, width: 1.2), borderRadius: BorderRadius.circular(8)),
            child: Text(hit.affix.ko.split(' / ').first, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
          ),
      ]),
    );
  }
}

/// 접사 설명 시트 — 이름·대응 한국어·규칙, 모음조화로 형태가 골라지는 연출, 앱 안 예문, 카드 연습.
class AffixSheet extends StatelessWidget {
  final Affix affix;
  final AffixHit? hit;
  const AffixSheet({super.key, required this.affix, this.hit});

  static Future<void> show(BuildContext context, Affix affix, {AffixHit? hit}) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColors.washi,
        builder: (_) => FractionallySizedBox(heightFactor: 0.78, child: AffixSheet(affix: affix, hit: hit)),
      );

  @override
  Widget build(BuildContext context) {
    final c = affix.kind.color;
    return FutureBuilder(
      future: AffixCorpus.instance.ensureLoaded(),
      builder: (context, snap) {
        final ex = snap.connectionState == ConnectionState.done ? AffixCorpus.instance.examplesOf(affix.id) : const <AffixExample>[];
        final sample = hit ?? (ex.isNotEmpty ? ex.first.hit : null);
        return ListView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset(context)),
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(tr(affix.kind.label), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(tr(affix.name), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.sumi))),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: c, width: 1.4), borderRadius: BorderRadius.circular(10)),
              child: Text(trf('한국어로는 {0}', [affix.ko]), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
            ),
            const SizedBox(height: 8),
            Text(affix.rule, style: const TextStyle(fontSize: 13.5, color: AppColors.sumiLight, height: 1.45)),
            const SizedBox(height: 16),
            Text(tr('모음조화로 형태 고르기'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            const SizedBox(height: 8),
            HarmonyPick(affix: affix, stem: sample?.stem),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Text(trf('앱 안 예문 {0}', [ex.length]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              if (ex.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    openFull(context, (_) => AffixQuizScreen(affixId: affix.id));
                  },
                  icon: const Icon(Icons.style_outlined, size: 18),
                  label: Text(tr('접사 카드로 연습')),
                ),
            ]),
            if (snap.connectionState != ConnectionState.done)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (ex.isEmpty)
              Text(tr('아직 앱 문장에는 이 접사가 없어요.'), style: const TextStyle(fontSize: 12.5, color: AppColors.muted))
            else
              for (final e in ex.take(6)) _ExampleRow(e: e),
            const SizedBox(height: 8),
            Text(tr('접사 나누기는 자동 분석이라 틀릴 수 있어요.'), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        );
      },
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final AffixExample e;
  const _ExampleRow({required this.e});

  @override
  Widget build(BuildContext context) {
    final c = e.hit.affix.kind.color;
    final w = e.hit.word;
    final i = e.tl.indexOf(w);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(style: const TextStyle(fontSize: 15, color: AppColors.sumi, fontWeight: FontWeight.w600), children: [
          if (i >= 0) ...[
            TextSpan(text: e.tl.substring(0, i)),
            TextSpan(text: e.hit.stem),
            TextSpan(text: e.hit.suffix, style: TextStyle(color: c, fontWeight: FontWeight.w900, decoration: TextDecoration.underline, decorationColor: c)),
            TextSpan(text: e.tl.substring(i + w.length)),
          ] else
            TextSpan(text: e.tl),
        ])),
        Text(e.ko, style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight)),
      ]),
    );
  }
}

/// 모음조화 연출: 어간의 모음 점이 켜진 뒤(0.4초) 4가지 형태 중 맞는 하나에 불이 들어온다.
class HarmonyPick extends StatefulWidget {
  final Affix affix;
  final String? stem;
  const HarmonyPick({super.key, required this.affix, this.stem});
  @override
  State<HarmonyPick> createState() => _HarmonyPickState();
}

class _HarmonyPickState extends State<HarmonyPick> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _replay();
  }

  void _replay() {
    setState(() => _on = false);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _on = true);
    });
  }

  static const _male = 'аоуАОУ', _female = 'эөүЭӨҮ';

  @override
  Widget build(BuildContext context) {
    final a = widget.affix;
    final c = a.kind.color;
    final stem = widget.stem;
    final key = stem == null ? null : harmonyOf(stem);
    final pick = key == null ? null : (a.forms[key] ?? a.forms[key == 'o' ? 'a' : key == 'ö' ? 'e' : key]);
    return InkWell(
      onTap: _replay,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
          if (stem != null)
            Text.rich(TextSpan(style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi), children: [
              for (final ch in stem.split(''))
                TextSpan(
                  text: ch,
                  style: _on && _male.contains(ch)
                      ? const TextStyle(color: AppColors.beniLight)
                      : _on && _female.contains(ch)
                          ? const TextStyle(color: Color(0xFFE88BB8))
                          : null,
                ),
            ])),
          if (stem != null) const Icon(Icons.arrow_forward, size: 18, color: AppColors.muted),
          for (final f in a.variants)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _on && f == pick ? c : Colors.white,
                border: Border.all(color: _on && f == pick ? c : AppColors.line, width: 1.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('-$f',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _on && f == pick ? Colors.white : AppColors.muted)),
            ),
          if (stem != null)
            Text(tr('탭하면 다시'), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ),
    );
  }
}
