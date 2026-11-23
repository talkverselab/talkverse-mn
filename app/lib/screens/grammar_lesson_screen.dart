import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/entitlement.dart';
import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/script_sync.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';
import 'grammar_test_screen.dart';
import '../core/platform.dart';
import '../core/l10n.dart';

/// 문법 강의 자산 — `assets/data/grammar/lessonN.json`
/// `{lesson, title, subtitle, stages:[{stage,title}],
///   patterns:[{id,key,label,explanation,stage,examples:[{tl,rd,ko}]}]}`
class GrammarLesson {
  final int number;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> stages;
  final List<Map<String, dynamic>> patterns;
  const GrammarLesson(this.number, this.title, this.subtitle, this.stages, this.patterns);

  int get exampleCount =>
      patterns.fold(0, (n, p) => n + ((p['examples'] as List?)?.length ?? 0));

  /// 문법 스텝 = 서버 원고 목록에 있는 `grammar/lessonN.json` 전부(번호 순). 개수·순서·제목을 코드에 박지 않는다 —
  /// 서버에서 스텝을 더하면 생기고 빼면 사라진다(앱 빌드 없이). 서버 목록을 못 받았으면 앱에 묶은 기준표 목록.
  /// 내용(패턴)이 빈 스텝은 숨긴다(「준비 중」 칸 없음). 사용자 지시 2026-11-23(스텝 10 → 15 → 「늘어날 수도 줄어들 수도」).
  static final _rel = RegExp(r'^grammar/lesson(\d+)\.json$');

  static Future<List<GrammarLesson>> loadAll() async {
    final sync = ScriptSync.instance;
    await sync.init();
    final rels = [for (final p in sync.files) if (_rel.hasMatch(p)) p]
      ..sort((a, b) => int.parse(_rel.firstMatch(a)!.group(1)!).compareTo(int.parse(_rel.firstMatch(b)!.group(1)!)));
    final out = <GrammarLesson>[];
    for (final rel in rels) {
      final i = int.parse(_rel.firstMatch(rel)!.group(1)!);
      try {
        final raw = await sync.load(rel); // 서버에 고친 판이 있으면 그것(원고 덮어쓰기)
        final d = json.decode(raw) as Map<String, dynamic>;
        final patterns = [for (final p in (d['patterns'] as List? ?? const [])) Map<String, dynamic>.from(p as Map)];
        if (patterns.isEmpty) continue;
        out.add(GrammarLesson(
          (d['lesson'] as num?)?.toInt() ?? i,
          d['title'] as String? ?? trf('문법 {0}', [i]),
          d['subtitle'] as String? ?? '',
          [for (final s in (d['stages'] as List? ?? const [])) Map<String, dynamic>.from(s as Map)],
          patterns,
        ));
      } catch (_) {
        continue; // 읽지 못한 스텝은 숨김
      }
    }
    return out;
  }
}

/// 문법 — 강의 목록.
class GrammarHubScreen extends StatefulWidget {
  const GrammarHubScreen({super.key});

  @override
  State<GrammarHubScreen> createState() => _GrammarHubScreenState();
}

class _GrammarHubScreenState extends State<GrammarHubScreen> {
  List<GrammarLesson>? _lessons;

  @override
  void initState() {
    super.initState();
    GrammarLesson.loadAll().then((l) {
      if (mounted) setState(() => _lessons = l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('문법'))),
      body: lessons == null
          ? const Center(child: CircularProgressIndicator())
          : lessons.isEmpty
              ? Center(
                  child: Text(tr('아직 문법 강의가 없습니다.'),
                      style: TextStyle(color: AppColors.tintaLight)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final (i, l) in lessons.indexed)
                      Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          leading: Entitlement.grammarStepFree(i) || Entitlement.premium ? TileBadge(text: '${l.number}', size: 40) : const SizedBox(width: 40, child: LockBadge(size: 24)),
                          title: Text(l.title,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                              '${l.subtitle.isEmpty ? '' : '${l.subtitle}\n'}${trf('패턴 {0} · 예문 {1}', [l.patterns.length, l.exampleCount])}',
                              style: const TextStyle(fontSize: 12, height: 1.4)),
                          trailing: IconButton(
                            tooltip: tr('테스트'),
                            icon: const Icon(Icons.quiz, color: AppColors.rojo),
                            onPressed: () => Entitlement.guard(context, Entitlement.grammarStepFree(i), () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GrammarTestScreen(lesson: l)),
                            )),
                          ),
                          onTap: () => Entitlement.guard(context, Entitlement.grammarStepFree(i), () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => GrammarLessonScreen(lesson: l)),
                          )),
                        ),
                      ),
                  ],
                ),
    );
  }
}

/// 문법 강의 — 단계별 패턴 카드 + 예문(대상어·독음·뜻, 탭하면 발음).
class GrammarLessonScreen extends StatelessWidget {
  final GrammarLesson lesson;
  const GrammarLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final stages = lesson.stages.isEmpty
        ? [<String, dynamic>{'stage': null, 'title': ''}]
        : lesson.stages;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text(lesson.title),
        actions: [
          const KoReadingToggleAction(),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GrammarTestScreen(lesson: lesson)),
            ),
            icon: const Icon(Icons.quiz, color: Colors.white),
            label: Text(tr('테스트'),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + bottomInset(context)),
        children: [
          for (final st in stages) ...[
            if ((st['title'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TileBadge(text: '${st['stage']}', size: 26, color: AppColors.gualdaDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(st['title'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: AppColors.tinta)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            for (final p in lesson.patterns)
              if (st['stage'] == null || p['stage'] == st['stage']) _PatternCard(p: p),
          ],
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final Map<String, dynamic> p;
  const _PatternCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final examples = (p['examples'] as List? ?? const []).whereType<Map>().toList();
    final expl = p['explanation'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gualda.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p['key'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.rojoDeep)),
          if ((p['label'] as String? ?? '').isNotEmpty)
            Text(p['label'] as String,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.tinta)),
          if (expl != null && expl.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(expl,
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.tintaLight)),
          ],
          const SizedBox(height: 8),
          const BandDivider(height: 3),
          for (final ex in examples)
            InkWell(
              onTap: () => TtsService.instance.speak('${ex['tl'] ?? ''}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(Icons.volume_up, size: 18, color: AppColors.rojo),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText('${ex['tl'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tinta)),
                          if ('${ex['rd'] ?? ''}'.isNotEmpty)
                            KoReadingText('${ex['rd']}',
                                style: const TextStyle(fontSize: 13, color: AppColors.rojoDeep)),
                          Text('${ex['ko'] ?? ''}',
                              style: const TextStyle(fontSize: 13, color: AppColors.tintaLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
