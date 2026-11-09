import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/mn_letters.dart';
import '../services/tts_service.dart';
import '../core/embed_env.dart';

/// 글자 탭 → 발음 시트(일본어앱 kana_sound_sheet 의 몽골어판). 열리면 1초 뒤 글자 소리 자동 재생, 예시 단어 듣기, 다시 듣기, IPA·소리 나는 곳·한국어 비교.
Future<void> showLetterSoundSheet(BuildContext context, MnLetter l, Color color) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _LetterSheet(l: l, color: color),
    );

class _LetterSheet extends StatefulWidget {
  final MnLetter l;
  final Color color;
  const _LetterSheet({required this.l, required this.color});
  @override
  State<_LetterSheet> createState() => _LetterSheetState();
}

class _LetterSheetState extends State<_LetterSheet> {
  Timer? _auto;
  bool _chart = false;

  @override
  void initState() {
    super.initState();
    // TtsService.speak 는 스스로 1초 지연해서 읽는다
    _auto = Timer(Duration.zero, () => TtsService.instance.speak(widget.l.lower));
  }

  @override
  void dispose() {
    _auto?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l, c = widget.color;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.sumiLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                child: Text('${l.upper}${l.lower}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.washi)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.latin, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
                  const SizedBox(height: 4),
                  Text('IPA [${l.ipa}]', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                ]),
              ),
              IconButton(iconSize: 44, color: c, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: () => TtsService.instance.speak(l.lower)),
            ]),
            const SizedBox(height: 12),
            if (l.example.isNotEmpty) ...[
              InkWell(
                onTap: () => TtsService.instance.speak(l.example),
                borderRadius: BorderRadius.circular(10),
                child: _box(c, tr('🔊 예시 단어 — 누르면 듣기'), '${l.example} — ${l.exampleKo}'),
              ),
              const SizedBox(height: 14),
            ],
            _box(c, tr('👄 소리 나는 곳 · 입 모양'), l.place),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _chart = !_chart),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(_chart ? Icons.expand_less : Icons.expand_more, size: 18, color: c),
                  Text(l.vowel ? tr('모음 위치 그림 보기') : tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
                ]),
              ),
            ),
            if (_chart)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(assetPath(l.vowel ? 'assets/images/ipa/ipa_vowel_chart.png' : 'assets/images/ipa/places_of_articulation.png'), fit: BoxFit.contain),
                ),
              ),
            const SizedBox(height: 14),
            _box(c, tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [l.korSim, l.korDiff])),
          ],
        ),
      ),
    );
  }

  Widget _box(Color c, String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)),
        ]),
      );
}
