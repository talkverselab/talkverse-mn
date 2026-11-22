import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼 — 전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`(2026-11-22, uk).
///
/// 회화 레벨(R0~R5)에서 다이얼로그를 3·5·10편 고른 코스 → 편마다 듣기·확인 문제 → 틀린 줄·연습한 줄은 간격 반복(1·3·7일)
/// → 코스 시험 80% 이상이면 통과 → 같은 레벨의 다음 코스, 레벨을 다 통과하면 다음 레벨. 하루 목표 = 새 편 1·2·3 + 복습.
/// 저장 = 기기(`curriculum_v1`, 형식은 문서 §7 그대로). 하루 진행 수는 따로 `curriculum_day_v1`.
class Curriculum {
  static const passPercent = 80;
  static const intervals = [1, 3, 7]; // 복습 간격(일) — step 0·1·2
  static const courseSizes = [3, 5, 10];
  static const practiceMax = 10;
  static const examPerMin = 3;
  static const examMax = 30;

  /// 점수 = 정답 수 / 문제 수, 소수점 버림.
  static int score(int correct, int total) => total <= 0 ? 0 : (correct * 100) ~/ total;
  static bool passed(int correct, int total) => score(correct, total) >= passPercent;

  static String day(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  static String addDays(String d, int n) {
    final p = d.split('-').map(int.parse).toList();
    return day(DateTime(p[0], p[1], p[2] + n));
  }

  /// 시험 편당 문제 수 — 편당 최소 3, 합 최대 30.
  static int examPerDialogue(int n) => n <= 0 ? 0 : math.max(examPerMin, examMax ~/ n);
}

class ReviewItem {
  final String lineId; // '<편id>#<턴>'
  String due; // YYYY-MM-DD
  int step; // 0=1일 · 1=3일 · 2=7일
  ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map<String, dynamic> j) =>
      ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  String? passedAt;
  Course(this.id, this.dialogueIds, {List<String>? practiced, List<int>? examScores, this.passedAt})
      : practiced = practiced ?? [],
        examScores = examScores ?? [];
  bool get allPracticed => dialogueIds.every(practiced.contains);
  Map<String, dynamic> toJson() =>
      {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        '${j['id']}',
        [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        practiced: [for (final e in (j['practiced'] as List? ?? const [])) '$e'],
        examScores: [for (final e in (j['examScores'] as List? ?? const [])) (e as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

/// `curriculum_v1` 전체.
class CurriculumState {
  String? level;
  int dailyGoal; // 새 편 1·2·3
  Course? course;
  final List<String> passedDialogues;
  final List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  // 하루 진행(따로 저장)
  String todayDay;
  int todayNew;
  int todayReview;

  CurriculumState({
    this.level,
    this.dailyGoal = 2,
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay = '',
    this.todayNew = 0,
    this.todayReview = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
      };

  factory CurriculumState.fromJson(Map<String, dynamic> j) {
    final s = (j['streak'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: ((j['dailyGoal'] as num?)?.toInt() ?? 2).clamp(1, 3),
      course: j['course'] is Map ? Course.fromJson((j['course'] as Map).cast<String, dynamic>()) : null,
      passedDialogues: [for (final e in (j['passedDialogues'] as List? ?? const [])) '$e'],
      review: [
        for (final e in (j['review'] as List? ?? const []))
          if (e is Map) ReviewItem.fromJson(e.cast<String, dynamic>())
      ],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
    );
  }

  /// 날이 바뀌었으면 하루 진행을 0 으로.
  void rollDay(String today) {
    if (todayDay == today) return;
    todayDay = today;
    todayNew = 0;
    todayReview = 0;
  }

  List<ReviewItem> due(String today) => review.where((r) => r.due.compareTo(today) <= 0).toList();

  /// 연습·복습에서 한 줄을 풀었다 — 맞히면 다음 간격(7일 뒤 맞히면 졸업), 틀리면 1일로.
  void answer(String lineId, bool correct, String today) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    if (i < 0) {
      review.add(ReviewItem(lineId, Curriculum.addDays(today, Curriculum.intervals[0]), 0));
      return;
    }
    final r = review[i];
    if (!correct) {
      r
        ..step = 0
        ..due = Curriculum.addDays(today, Curriculum.intervals[0]);
    } else if (r.step + 1 >= Curriculum.intervals.length) {
      review.removeAt(i);
    } else {
      r
        ..step += 1
        ..due = Curriculum.addDays(today, Curriculum.intervals[r.step]);
    }
  }

  /// 연습을 마친 편의 줄을 복습 대기열에 넣는다(없는 줄만, 1일 뒤). 틀린 줄은 [answer] 로 1일 뒤가 된다.
  void enqueue(Iterable<String> lineIds, String today) {
    for (final id in lineIds) {
      if (!review.any((r) => r.lineId == id)) review.add(ReviewItem(id, Curriculum.addDays(today, 1), 0));
    }
  }

  int newLeft() => math.max(0, dailyGoal - todayNew);

  /// 오늘 분량을 다 했는가 — 복습 대기 0 + 새 편 목표 달성.
  bool dayDone(String today) => due(today).isEmpty && todayNew >= dailyGoal;

  /// 오늘 분량을 막 끝냈으면 연속 일수를 올린다(하루 한 번).
  void touchStreak(String today) {
    if (!dayDone(today) || streakLastDay == today) return;
    streakCount = streakLastDay == Curriculum.addDays(today, -1) ? streakCount + 1 : 1;
    streakLastDay = today;
  }

  /// 연속 일수 표시값 — 어제·오늘 끝냈으면 이어지고, 그 전이면 0.
  int streakShown(String today) =>
      (streakLastDay == today || streakLastDay == Curriculum.addDays(today, -1)) ? streakCount : 0;
}

/// 문제 하나. 꼴: 뜻 고르기(몽골어 줄 → 한국어 뜻 4지선다) · 빈칸 낱말 고르기.
class CurriculumQuestion {
  final String lineId;
  final String dialogueId;
  final int turn;
  final String prompt; // 몽골어(빈칸이면 ＿＿ 넣은 줄)
  final String hint; // 빈칸 문제의 한국어 뜻
  final List<String> options;
  final int answer;
  final bool blank;
  const CurriculumQuestion({
    required this.lineId,
    required this.dialogueId,
    required this.turn,
    required this.prompt,
    required this.hint,
    required this.options,
    required this.answer,
    required this.blank,
  });
}

class CurriculumQuiz {
  static String lineId(String dialogueId, int turn) => '$dialogueId#$turn';
  static (String, int)? parse(String lineId) {
    final i = lineId.lastIndexOf('#');
    if (i <= 0) return null;
    final n = int.tryParse(lineId.substring(i + 1));
    return n == null ? null : (lineId.substring(0, i), n);
  }

  static String clean(String s) => s.replaceAll(RegExp(r'\{name\}'), '…').replaceAll(RegExp(r'\s+'), ' ').trim();
  static final _word = RegExp(r'[\p{L}\p{M}-]+', unicode: true);

  /// 한 줄로 문제를 만든다. [pool] = 오답 후보로 쓸 다른 줄들(같은 편 먼저, 모자라면 같은 레벨).
  static CurriculumQuestion? make(Dialogue d, DialogueTurn t, List<DialogueTurn> pool, math.Random rnd, {bool blank = false}) {
    final tl = clean(t.tl), ko = clean(t.ko);
    if (tl.isEmpty || ko.isEmpty) return null;
    if (blank) {
      final words = [for (final m in _word.allMatches(tl)) m.group(0)!].where((w) => w.runes.length >= 3).toList();
      final others = <String>{
        for (final p in pool)
          for (final m in _word.allMatches(clean(p.tl)))
            if (m.group(0)!.runes.length >= 3) m.group(0)!.toLowerCase(),
      };
      if (words.isNotEmpty) {
        final w = words[rnd.nextInt(words.length)];
        final wrong = (others..removeAll(words.map((e) => e.toLowerCase()))).toList()..shuffle(rnd);
        if (wrong.length >= 3) {
          final opts = [w, ...wrong.take(3)]..shuffle(rnd);
          return CurriculumQuestion(
            lineId: lineId(d.id, t.num),
            dialogueId: d.id,
            turn: t.num,
            prompt: tl.replaceFirst(w, '＿＿＿'),
            hint: ko,
            options: opts,
            answer: opts.indexOf(w),
            blank: true,
          );
        }
      }
    }
    final wrong = {for (final p in pool) clean(p.ko)}..removeWhere((e) => e.isEmpty || e == ko);
    final w = wrong.toList()..shuffle(rnd);
    if (w.length < 3) return null;
    final opts = [ko, ...w.take(3)]..shuffle(rnd);
    return CurriculumQuestion(
      lineId: lineId(d.id, t.num),
      dialogueId: d.id,
      turn: t.num,
      prompt: tl,
      hint: '',
      options: opts,
      answer: opts.indexOf(ko),
      blank: false,
    );
  }

  /// 한 편에서 [count] 문제(줄을 고르게, 뜻·빈칸 번갈아). [levelPool] 은 오답 후보 보충용.
  static List<CurriculumQuestion> forDialogue(Dialogue d, int count, List<DialogueTurn> levelPool, math.Random rnd) {
    final turns = d.turns.where((t) => clean(t.tl).isNotEmpty && clean(t.ko).isNotEmpty).toList()..shuffle(rnd);
    final pool = [...d.turns, ...levelPool];
    final out = <CurriculumQuestion>[];
    for (var i = 0; i < turns.length && out.length < count; i++) {
      final q = make(d, turns[i], pool, rnd, blank: out.length.isOdd);
      if (q != null) out.add(q);
    }
    return out;
  }
}

/// 기기 저장 + 바뀜 알림.
class CurriculumStore {
  CurriculumStore._();
  static final CurriculumStore instance = CurriculumStore._();
  static const key = 'curriculum_v1';
  static const dayKey = 'curriculum_day_v1';

  final ValueNotifier<int> changes = ValueNotifier(0);
  CurriculumState? _s;
  Future<CurriculumState>? _loading;

  static String today() => Curriculum.day(DateTime.now());

  Future<CurriculumState> load() => _loading ??= _read();

  Future<CurriculumState> _read() async {
    final p = await Prefs.getInstance();
    CurriculumState s;
    try {
      final raw = p.getString(key);
      s = raw == null ? CurriculumState() : CurriculumState.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      s = CurriculumState();
    }
    try {
      final d = json.decode(p.getString(dayKey) ?? '{}') as Map<String, dynamic>;
      s
        ..todayDay = '${d['day'] ?? ''}'
        ..todayNew = (d['new'] as num?)?.toInt() ?? 0
        ..todayReview = (d['review'] as num?)?.toInt() ?? 0;
    } catch (_) {}
    s.rollDay(today());
    return _s = s;
  }

  Future<void> save() async {
    final s = _s;
    if (s == null) return;
    s.touchStreak(today());
    final p = await Prefs.getInstance();
    await p.setString(key, json.encode(s.toJson()));
    await p.setString(dayKey, json.encode({'day': s.todayDay, 'new': s.todayNew, 'review': s.todayReview}));
    changes.value++;
  }

  /// 시험용: 저장 상태를 잊는다.
  @visibleForTesting
  void reset() {
    _s = null;
    _loading = null;
  }
}

/// 레벨·편 고르기 도우미(회화 목록에 기대는 것).
class CurriculumCatalog {
  /// 커리큘럼 레벨 = 회화 레벨(R*)만, 편이 있는 것만. 옛 이야기(L1)는 넣지 않는다.
  static List<String> levels(DialogueService svc) => svc.regions.where((r) => r.startsWith('R')).toList();

  /// 「추천으로 채우기」 — 아직 통과 안 한 편에서 주제가 겹치지 않게 돌아가며 [n] 편. [keep] 은 이미 고른 것.
  static List<String> recommend(List<Dialogue> level, Set<String> passed, int n, {List<String> keep = const []}) {
    final out = [...keep];
    final left = level.where((d) => !passed.contains(d.id) && !out.contains(d.id)).toList();
    final byIsland = <String, List<Dialogue>>{};
    for (final d in left) {
      (byIsland[d.island] ??= []).add(d);
    }
    final used = {for (final id in out) level.where((d) => d.id == id).firstOrNull?.island};
    // 아직 안 쓴 주제부터 한 편씩, 다 돌면 다시
    while (out.length < n && byIsland.values.any((l) => l.isNotEmpty)) {
      var added = false;
      for (final isl in byIsland.keys.toList()) {
        if (out.length >= n) break;
        final l = byIsland[isl]!;
        if (l.isEmpty || used.contains(isl)) continue;
        out.add(l.removeAt(0).id);
        used.add(isl);
        added = true;
      }
      if (!added) used.clear();
    }
    return out;
  }
}
