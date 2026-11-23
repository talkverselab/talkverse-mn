import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/script_sync.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../data/entitlement.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/selectable_mn_text.dart';

/// 언어감각 익히기 — 카자흐어앱 화면(일본어앱 빌드 96~112 꼴)을 옮김(2026-11-22, uk 전달 「언어감각 10급은 클로드로만」). 문장은 Claude 가 씀(tools/build_sense_course.py).
/// 영상 칸: 몽골어앱엔 video_player 가 없어 주소가 있어도 「영상 준비 중」 칸만(영상이 생기면 그때 의존성을 더한다). 정규과정(2026-11-11 사용자 지시). L1~L10, 급마다 외울 대화 1회 + 참고(2026-11-17 전면 수정).
/// 회차 = 문법 짧은 설명(points.tip) → 감 익히는 문장(points.sentences). 데이터 `assets/data/grammar/sense_course.json`.
/// 내용은 간단하게 시작해 차차 늘린다 — 회차를 늘리려면 JSON 에 lessons 만 더하면 된다.
const _kDoneKey = 'sense_course_done'; // Prefs 가 언어 접두(mn_)를 붙인다
/// 메뉴에 보일지 — 형식 시험(test/sense_course_test.dart)·몽골어 검토·12+ 점검 통과(2026-11-22) → true.
const bool kSenseCourseLive = true;

const _kAsset = 'assets/data/grammar/sense_course.json';

class SenseCourse {
  /// 급(스텝) 목록·개수·제목·순서·문장은 모두 데이터 — 앱 묶음이 기본, 서버 원고에 고친 판이 있으면 그것(사용자 지시 2026-11-23).
  /// 개수를 코드에 박지 않는다: 서버 파일에서 급을 더하면 생기고 빼면 사라진다.
  static Map<String, dynamic>? _cache;
  static Object? _cacheKey;

  /// 서버 원고가 바뀌면(rev·인스턴스) 다시 읽는다. 내용이 빈 급은 뺀다(서버에 내용이 생기면 저절로 나타남).
  static Future<Map<String, dynamic>> load() async {
    final sync = ScriptSync.instance;
    await sync.init();
    final key = (identityHashCode(sync), sync.shownRev, sync.overlayCount);
    if (_cache != null && _cacheKey == key) return _cache!;
    // loadString 은 큰 파일을 다른 isolate 에서 풀어 위젯 테스트가 멈춘다 — ScriptSync 가 바이트로 읽어 여기서 푼다.
    final d = json.decode(await sync.load(_kAsset.substring('assets/data/'.length))) as Map<String, dynamic>;
    final levels = [
      for (final lv in ((d['levels'] as List?) ?? const []).cast<Map<String, dynamic>>())
        if (_hasContent(lv)) lv,
    ];
    _cacheKey = key;
    return _cache = {...d, 'levels': levels};
  }

  static bool _hasContent(Map<String, dynamic> lv) => ((lv['lessons'] as List?) ?? const []).cast<Map<String, dynamic>>().any((ls) =>
      ((ls['sentences'] as List?)?.isNotEmpty ?? false) || ((ls['points'] as List?)?.isNotEmpty ?? false) || ls['open'] != null);

  static Future<Set<String>> done() async => ((await Prefs.getInstance()).getStringList(_kDoneKey) ?? const []).toSet();

  static Future<void> markDone(String id) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kDoneKey) ?? <String>[]).toSet()..add(id);
    await p.setStringList(_kDoneKey, s.toList());
  }

  /// 회차 순번 → 그 회차의 급 순번(0부터, 잠금 판정용).
  static int levelIndexOf(Map<String, dynamic>? d, int index, {List<(Map<String, dynamic>, Map<String, dynamic>)>? all}) {
    final f = all ?? flat(d!);
    final lv = f[index].$1;
    final seen = <Map<String, dynamic>>[];
    for (final e in f) {
      if (!seen.contains(e.$1)) seen.add(e.$1);
      if (identical(e.$1, lv)) break;
    }
    return seen.length - 1;
  }

  /// 모든 회차를 순서대로 (레벨, 회차) 쌍으로.
  static List<(Map<String, dynamic>, Map<String, dynamic>)> flat(Map<String, dynamic> d) => [
        for (final lv in (d['levels'] as List).cast<Map<String, dynamic>>())
          for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>()) (lv, ls),
      ];
}

class SenseCourseScreen extends StatefulWidget {
  const SenseCourseScreen({super.key});

  @override
  State<SenseCourseScreen> createState() => _SenseCourseScreenState();
}

class _SenseCourseScreenState extends State<SenseCourseScreen> {
  Map<String, dynamic>? _data;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SenseCourse.load();
    final done = await SenseCourse.done();
    if (!mounted) return;
    setState(() {
      _data = d;
      _done = done;
    });
  }

  Future<void> _open(int index) async {
    // 언어감각 앞 N급만 무료(PAYWALL_SPEC §2, 서버 freeSenseLevels) — 잠긴 급은 결제 화면 먼저
    await Entitlement.guard(context, Entitlement.senseLevelFree(SenseCourse.levelIndexOf(_data!, index)), () => openFull(context, (_) => SenseLessonScreen(index: index)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('언어감각 익히기'))),
      body: d == null ? const Center(child: CircularProgressIndicator()) : _body(d),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final all = SenseCourse.flat(d);
    bool isRef(Map<String, dynamic> l) => l['kind'] == 'ref';
    final next = all.indexWhere((e) => !isRef(e.$2) && !_done.contains(e.$2['id']));
    final real = all.where((e) => !isRef(e.$2)).toList();
    final children = <Widget>[
      Text(tr('영상을 보고, 대화를 통째로 외워요. 규칙은 참고에만 있어요.'),
          style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
      const SizedBox(height: 4),
      Text(trf('{0}/{1}회 마침', [real.where((e) => _done.contains(e.$2['id'])).length, real.length]),
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ];
    var i = 0;
    for (final lv in (d['levels'] as List).cast<Map<String, dynamic>>()) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Row(children: [
          Expanded(
            child: Text('${lv['id']}  ${lv['title']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          ),
          if (!Entitlement.premium && !Entitlement.senseLevelFree((d['levels'] as List).indexOf(lv))) const LockBadge(),
        ]),
      ));
      var n = 1;
      for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>()) {
        final idx = i;
        final isDone = _done.contains(ls['id']);
        final isNext = idx == next;
        if (ls['open'] != null) {
          // 다른 메뉴로 가는 버튼(회차 아님)
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              key: ValueKey('sense-${ls['id']}'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ai, side: const BorderSide(color: AppColors.ai), minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _open(idx),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(tr(ls['title'] as String), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ));
          i++;
          continue;
        }
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isNext ? AppColors.washiDeep : AppColors.washi,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isNext ? AppColors.ai : AppColors.line, width: isNext ? 1.4 : 1),
            ),
            child: InkWell(
              key: ValueKey('sense-${ls['id']}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _open(idx),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(children: [
                  SizedBox(
                    width: 44,
                    child: Text(isRef(ls) ? tr('참고') : trf('{0}회', [n]),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ai)),
                  ),
                  Expanded(
                    child: Text(ls['title'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                  ),
                  if (isDone)
                    const Icon(Icons.check_circle, color: AppColors.matcha, size: 20)
                  else if (isNext)
                    Text(tr('다음'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ai)),
                ]),
              ),
            ),
          ),
        ));
        i++;
        if (!isRef(ls)) n++;
      }
    }
    return ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)), children: children);
  }
}

/// 한 회차 — 문법 설명 → 문장. 아래 「마침 · 다음 회」 버튼.
class SenseLessonScreen extends StatefulWidget {
  final int index;
  const SenseLessonScreen({super.key, required this.index});

  @override
  State<SenseLessonScreen> createState() => _SenseLessonScreenState();
}

class _SenseLessonScreenState extends State<SenseLessonScreen> {
  List<(Map<String, dynamic>, Map<String, dynamic>)>? _all;

  @override
  void initState() {
    super.initState();
    SenseCourse.load().then((d) {
      if (mounted) setState(() => _all = SenseCourse.flat(d));
    });
  }

  Future<void> _finish() async {
    final all = _all!;
    if (all[widget.index].$2['kind'] == 'ref') {
      Navigator.of(context).pop(); // 참고는 기록하지 않는다
      return;
    }
    await SenseCourse.markDone(all[widget.index].$2['id'] as String);
    if (!mounted) return;
    var nextIdx = widget.index + 1;
    while (nextIdx < all.length && all[nextIdx].$2['kind'] == 'ref') {
      nextIdx++;
    }
    if (nextIdx < all.length && (Entitlement.premium || Entitlement.senseLevelFree(SenseCourse.levelIndexOf(null, nextIdx, all: all)))) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SenseLessonScreen(index: nextIdx)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    if (all == null) {
      return const Scaffold(backgroundColor: AppColors.washi, body: Center(child: CircularProgressIndicator()));
    }
    final (lv, ls) = all[widget.index];
    final lessons = (lv['lessons'] as List);
    final isRef = ls['kind'] == 'ref';
    final n = lessons.take(lessons.indexOf(ls) + 1).where((l) => (l as Map)['kind'] != 'ref').length;
    final points = ((ls['points'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final memorize = ls['kind'] == 'memorize';
    final last = !all.skip(widget.index + 1).any((e) => e.$2['kind'] != 'ref');
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text('${lv['id']} · ${isRef ? tr('참고') : trf('{0}회', [n])}  ${ls['title']}', overflow: TextOverflow.ellipsis),
        actions: const [KoReadingToggleAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: memorize ? [_Memorize(lesson: ls)] : [for (final p in points) _Point(point: p)],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: FilledButton(
          key: const ValueKey('sense-finish'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.ai, minimumSize: const Size.fromHeight(48)),
          onPressed: _finish,
          child: Text(isRef ? tr('닫기') : (last ? tr('마침') : tr('마침 · 다음 회'))),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final Map<String, dynamic> point;
  const _Point({required this.point});

  @override
  Widget build(BuildContext context) {
    final sentences = (point['sentences'] as List).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.washi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: kCardShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(point['head'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ai)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(8)),
          child: Text('💡 ${point['tip']}', style: const TextStyle(fontSize: 13, color: AppColors.sumi, height: 1.45)),
        ),
        const SizedBox(height: 6),
        for (final s in sentences)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableMnText(
                    text: s['tl'] as String,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.35),
                  ),
                  if (s['rd'] != null)
                    KoReadingText(s['rd'] as String, style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight)),
                  Text(s['ko'] as String,
                      style: const TextStyle(fontSize: 13, color: AppColors.ai, fontWeight: FontWeight.w600)),
                ]),
              ),
              IconButton(
                tooltip: tr('듣기'),
                icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 22),
                onPressed: () => TtsService.instance.speak(s['tl'] as String),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// 「5문장을 암기하세요」 회차 — 영상 → 안내 한 줄 → 문장만(조사 설명 없음).
/// 문장 표시 `{글자|번호}` = 조사·て형 자리. 같은 번호는 일본어·한국어에서 같은 색 — 두 말의 조사를 견줘 보게(사용자 지시 2026-11-11).
const _kMarkColors = [
  Color(0xFFD83A3A), Color(0xFF2F6FDB), Color(0xFF1E9E5A), Color(0xFFE08A00), Color(0xFF8E44AD),
  Color(0xFF00897B), Color(0xFFC2185B), Color(0xFF5D4037), Color(0xFF3949AB), Color(0xFF7CB342),
];

final _kMark = RegExp(r'\{([^|}]+)\|(\d+)\}');

/// 표시 없앤 본문(듣기용).
String plainMarked(String s) => s.replaceAllMapped(_kMark, (m) => m.group(1)!);

List<InlineSpan> markedSpans(String s, TextStyle base) {
  final out = <InlineSpan>[];
  var i = 0;
  for (final m in _kMark.allMatches(s)) {
    if (m.start > i) out.add(TextSpan(text: s.substring(i, m.start)));
    final c = _kMarkColors[(int.parse(m.group(2)!) - 1) % _kMarkColors.length];
    out.add(TextSpan(
        text: m.group(1),
        style: TextStyle(color: c, fontWeight: FontWeight.w900, decoration: TextDecoration.underline, decorationColor: c.withValues(alpha: 0.5), decorationThickness: 2)));
    i = m.end;
  }
  if (i < s.length) out.add(TextSpan(text: s.substring(i)));
  return out;
}

class _Memorize extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _Memorize({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final sentences = (lesson['sentences'] as List).cast<Map<String, dynamic>>();
    final video = (lesson['video'] as String?) ?? '';
    const jaStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.45);
    const koStyle = TextStyle(fontSize: 14, color: AppColors.sumi, height: 1.45);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (video.isNotEmpty) ...[LessonVideo(url: video), const SizedBox(height: 12)],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10)),
        child: Text('💡 ${lesson['note'] ?? ''}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.45)),
      ),
      const SizedBox(height: 6),
      for (var i = 0; i < sentences.length; i++)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${i + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ai)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (sentences[i]['who'] != null) Text(sentences[i]['who'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
                Text.rich(TextSpan(style: jaStyle, children: markedSpans(sentences[i]['tl'] as String, jaStyle))),
                if (sentences[i]['rd'] != null)
                  KoReadingText(sentences[i]['rd'] as String, style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight)),
                const SizedBox(height: 4),
                Text.rich(TextSpan(style: koStyle, children: markedSpans(sentences[i]['ko'] as String, koStyle))),
              ]),
            ),
            IconButton(
              tooltip: tr('듣기'),
              icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 22),
              onPressed: () => TtsService.instance.speak(plainMarked(sentences[i]['tl'] as String)),
            ),
          ]),
        ),
      if ((lesson['footnotes'] as List?)?.isNotEmpty ?? false) ...[
        const SizedBox(height: 16),
        Text(tr('한국어와 다른 곳만 잠깐'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
        const SizedBox(height: 4),
        for (final f in (lesson['footnotes'] as List).cast<String>())
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('· $f', style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight, height: 1.45)),
          ),
      ],
    ]);
  }
}

/// 회차 영상 자리 — 몽골어앱은 아직 영상이 없어 「영상 준비 중」 칸만 보인다(주소가 있을 때만 그려짐).
class LessonVideo extends StatelessWidget {
  final String url;
  const LessonVideo({super.key, required this.url});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          key: const ValueKey('memorize-video'),
          decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎬', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(tr('영상 준비 중'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
          ]),
        ),
      );
}
