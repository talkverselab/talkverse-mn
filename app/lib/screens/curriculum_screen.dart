import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/curriculum.dart';
import '../services/dialogue_audio.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../widgets/spanish_decor.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`, 2026-11-22) — 기존 화면은 건드리지 않는 새 메뉴.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

String _levelName(String r) => '$r · ${tr(DialogueService.levelKo[r] ?? r)}';

/// 회화 한 줄 소리 — 서버 녹음(지금 대사와 같을 때) → 없으면 앱 음성(번들 mp3 → 실시간 합성).
Future<void> _say(Dialogue d, DialogueTurn t) async {
  if (await DialogueAudio.instance.play(d.id, t.num, script: t.tl)) return;
  final text = t.tl.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\{[a-z_]+\}'), '').trim();
  await TtsService.instance.speakAs(text, gender: d.voiceGender(t.speaker));
}

Future<void> _stopAudio() async {
  await DialogueAudio.instance.stop();
  await TtsService.instance.stop();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final _svc = DialogueService.instance;
  CurriculumState? _s;
  bool _pickLevel = false;
  // 코스 만들기
  int _size = 5;
  final List<String> _picked = [];
  // 화면 안 확인(새 코스·레벨 바꾸기 때 지금 코스 버리기)
  VoidCallback? _confirm;
  String _confirmText = '';

  String get _today => CurriculumStore.today();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _svc.ensureLoaded();
    final s = await CurriculumStore.instance.load();
    s.rollDay(_today);
    if (!mounted) return;
    setState(() {
      _s = s;
      _pickLevel = s.level == null || !CurriculumCatalog.levels(_svc).contains(s.level);
    });
  }

  Future<void> _save() async {
    await CurriculumStore.instance.save();
    if (mounted) setState(() {});
  }

  List<Dialogue> _levelEps(String l) => _svc.list(region: l);
  bool get _courseActive => _s?.course != null && _s!.course!.passedAt == null;

  void _ask(String text, VoidCallback onYes) => setState(() {
        _confirmText = text;
        _confirm = onYes;
      });

  void _chooseLevel(String l) {
    final s = _s!;
    void go() {
      s.level = l;
      if (s.course != null && !(s.course!.dialogueIds.every((id) => _levelEps(l).any((d) => d.id == id)))) s.course = null;
      _picked.clear();
      _pickLevel = false;
      _confirm = null;
      _save();
    }

    if (_courseActive && s.level != l) {
      _ask(tr('지금 코스를 버리고 레벨을 바꿀까요?'), go);
    } else {
      go();
    }
  }

  void _startCourse() {
    final s = _s!;
    s.course = Course('c${DateTime.now().millisecondsSinceEpoch}', List.of(_picked));
    _picked.clear();
    _save();
  }

  void _newCourse() {
    void go() {
      _s!.course = null;
      _picked.clear();
      _confirm = null;
      _save();
    }

    if (_courseActive) {
      _ask(tr('지금 코스를 버리고 새 코스를 만들까요?'), go);
    } else {
      go();
    }
  }

  List<DialogueTurn> _levelPool(String level, math.Random rnd) {
    final all = [for (final d in _levelEps(level)) ...d.turns]..shuffle(rnd);
    return all.take(60).toList();
  }

  Future<void> _practice(Dialogue d) async {
    final s = _s!;
    final rnd = math.Random();
    final qs = CurriculumQuiz.forDialogue(d, math.min(Curriculum.practiceMax, d.turns.length), _levelPool(d.region, rnd), rnd);
    final res = await Navigator.of(context).push<List<bool>>(
      MaterialPageRoute(builder: (_) => _PracticeScreen(dialogue: d, questions: qs)),
    );
    if (res == null) return;
    final today = _today;
    s.rollDay(today);
    s.enqueue([for (final t in d.turns) CurriculumQuiz.lineId(d.id, t.num)], today);
    for (var i = 0; i < qs.length && i < res.length; i++) {
      if (!res[i]) s.answer(qs[i].lineId, false, today);
    }
    final c = s.course;
    if (c != null && c.dialogueIds.contains(d.id) && !c.practiced.contains(d.id)) {
      c.practiced.add(d.id);
      s.todayNew++;
    }
    await _save();
  }

  Future<void> _review() async {
    final s = _s!;
    final today = _today;
    final rnd = math.Random();
    final items = s.due(today)..shuffle(rnd);
    final qs = <CurriculumQuestion>[];
    for (final r in items.take(20)) {
      final p = CurriculumQuiz.parse(r.lineId);
      final d = p == null ? null : _svc.byId(p.$1);
      final t = d?.turns.where((t) => t.num == p!.$2).firstOrNull;
      if (d == null || t == null) {
        s.review.remove(r); // 원고에서 사라진 줄
        continue;
      }
      final q = CurriculumQuiz.make(d, t, [...d.turns, ..._levelPool(d.region, rnd)], rnd, blank: rnd.nextBool());
      if (q != null) qs.add(q);
    }
    if (qs.isEmpty) {
      await _save();
      return;
    }
    final res = await Navigator.of(context).push<List<bool>>(
      MaterialPageRoute(builder: (_) => _QuizScreen(title: tr('오늘 복습'), questions: qs)),
    );
    if (res == null) return;
    s.rollDay(_today);
    for (var i = 0; i < qs.length && i < res.length; i++) {
      s.answer(qs[i].lineId, res[i], _today);
    }
    s.todayReview += res.length;
    await _save();
  }

  Future<void> _exam() async {
    final s = _s!;
    final c = s.course!;
    final rnd = math.Random();
    final eps = c.dialogueIds.map(_svc.byId).whereType<Dialogue>().toList();
    final per = Curriculum.examPerDialogue(eps.length);
    final qs = <CurriculumQuestion>[];
    for (final d in eps) {
      qs.addAll(CurriculumQuiz.forDialogue(d, per, _levelPool(d.region, rnd), rnd));
    }
    qs.shuffle(rnd);
    if (qs.length > Curriculum.examMax) qs.removeRange(Curriculum.examMax, qs.length);
    if (qs.isEmpty) return;
    final res = await Navigator.of(context).push<List<bool>>(
      MaterialPageRoute(builder: (_) => _QuizScreen(title: tr('코스 시험'), questions: qs, exam: true)),
    );
    if (res == null || res.length < qs.length) return;
    final today = _today;
    final ok = res.where((e) => e).length;
    final sc = Curriculum.score(ok, qs.length);
    c.examScores.add(sc);
    if (Curriculum.passed(ok, qs.length)) {
      c.passedAt = today;
      for (final id in c.dialogueIds) {
        if (!s.passedDialogues.contains(id)) s.passedDialogues.add(id);
      }
      // 레벨 편을 다 통과하면 다음 레벨을 연다
      final lv = s.level!;
      final levels = CurriculumCatalog.levels(_svc);
      if (_levelEps(lv).every((d) => s.passedDialogues.contains(d.id))) {
        final i = levels.indexOf(lv);
        if (i >= 0 && i + 1 < levels.length) s.level = levels[i + 1];
      }
    } else {
      // 틀린 편만 다시 연습
      final wrongEps = <String>{};
      for (var i = 0; i < qs.length; i++) {
        if (!res[i]) {
          wrongEps.add(qs[i].dialogueId);
          s.answer(qs[i].lineId, false, today);
        }
      }
      c.practiced.removeWhere(wrongEps.contains);
    }
    await _save();
  }

  void _setGoal(int g) {
    _s!.dailyGoal = g;
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text(tr('토크버스 커리큘럼')),
        actions: [
          if (s != null && !_pickLevel)
            TextButton(onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨'))),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_confirm != null) _confirmCard(),
                _todayCard(s),
                const SizedBox(height: 16),
                if (_pickLevel) ..._levelPicker(s) else if (s.course == null) ..._courseBuilder(s) else ..._courseView(s),
              ],
            ),
    );
  }

  Widget _confirmCard() => Card(
        color: AppColors.calDeep,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_confirmText, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(tr('연습한 기록과 복습 대기열은 그대로 남습니다.'), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => setState(() => _confirm = null), child: Text(tr('취소'))),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _confirm, child: Text(tr('버리기'))),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _todayCard(CurriculumState s) {
    final due = s.due(_today).length;
    final newLeft = s.newLeft();
    final done = s.dayDone(_today);
    final total = s.dailyGoal + s.todayReview + due;
    final got = math.min(s.todayNew, s.dailyGoal) + s.todayReview;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    done ? tr('오늘 분량 끝') : '${tr('오늘')}: ${tr('복습')} $due · ${tr('새 편')} $newLeft',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.tinta),
                  ),
                ),
                Text('🔥 ${s.streakShown(_today)}${tr('일')}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: total == 0 ? 1 : (got / total).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.calDeep,
                color: done ? AppColors.oliva : AppColors.rojo,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(tr('하루 목표'), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
                for (final (g, label) in [(1, tr('가볍게')), (2, tr('보통')), (3, tr('집중'))])
                  ChoiceChip(
                    label: Text('$label · ${tr('새 편')} $g'),
                    selected: s.dailyGoal == g,
                    onSelected: (_) => _setGoal(g),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (due > 0) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _review,
                  icon: const Icon(Icons.replay),
                  label: Text('${tr('오늘 복습')} $due'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _levelPicker(CurriculumState s) {
    final levels = CurriculumCatalog.levels(_svc);
    final rec = levels.where((l) => _levelEps(l).any((d) => !s.passedDialogues.contains(d.id))).firstOrNull ?? levels.firstOrNull;
    return [
      Text(tr('레벨 고르기'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 4),
      Text(tr('회화 레벨입니다. 처음이라면 가장 낮은 레벨부터 권합니다.'), style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
      const SizedBox(height: 10),
      for (final l in levels)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: TileBadge(text: l, size: 34),
            title: Text(_levelName(l), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
                '${tr('통과')} ${_levelEps(l).where((d) => s.passedDialogues.contains(d.id)).length} / ${_levelEps(l).length}${tr('편')}'),
            trailing: l == rec
                ? Chip(label: Text(tr('추천')), visualDensity: VisualDensity.compact)
                : (l == s.level ? const Icon(Icons.check) : const Icon(Icons.chevron_right)),
            onTap: () => _chooseLevel(l),
          ),
        ),
    ];
  }

  List<Widget> _courseBuilder(CurriculumState s) {
    final eps = _levelEps(s.level!);
    final passed = s.passedDialogues.toSet();
    return [
      Text('${_levelName(s.level!)} · ${tr('코스 만들기')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 4),
      Text(tr('연습할 다이얼로그를 고르세요. 코스 시험 80% 이상이면 다음 코스로 넘어갑니다.'),
          style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final n in Curriculum.courseSizes)
            ChoiceChip(
              label: Text('$n${tr('편')}'),
              selected: _size == n,
              onSelected: (_) => setState(() {
                _size = n;
                if (_picked.length > n) _picked.removeRange(n, _picked.length);
              }),
              visualDensity: VisualDensity.compact,
            ),
          OutlinedButton(
            onPressed: () => setState(() {
              final r = CurriculumCatalog.recommend(eps, passed, _size, keep: _picked);
              _picked
                ..clear()
                ..addAll(r);
            }),
            child: Text(tr('추천으로 채우기')),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _picked.length == _size ? _startCourse : null,
          child: Text('${tr('코스 시작')} (${_picked.length}/$_size)'),
        ),
      ),
      const SizedBox(height: 10),
      for (final d in eps)
        CheckboxListTile(
          value: _picked.contains(d.id),
          onChanged: (v) => setState(() {
            if (v == true && _picked.length < _size) {
              _picked.add(d.id);
            } else {
              _picked.remove(d.id);
            }
          }),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          secondary: Text(d.emoji, style: const TextStyle(fontSize: 20)),
          title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${d.turns.length}${tr('줄')}${passed.contains(d.id) ? ' · ${tr('통과')} ✓' : ''}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
    ];
  }

  List<Widget> _courseView(CurriculumState s) {
    final c = s.course!;
    final eps = c.dialogueIds.map(_svc.byId).whereType<Dialogue>().toList();
    final done = c.passedAt != null;
    return [
      Row(
        children: [
          Expanded(
            child: Text('${_levelName(s.level!)} · ${tr('코스')} (${c.practiced.where(c.dialogueIds.contains).length}/${c.dialogueIds.length})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          TextButton(onPressed: _newCourse, child: Text(tr('새 코스'))),
        ],
      ),
      if (c.examScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('${tr('시험 점수')}: ${c.examScores.map((e) => '$e%').join(' → ')}',
              style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
        ),
      if (done)
        Card(
          color: AppColors.calDeep,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎉 ${tr('코스 통과')} — ${c.examScores.last}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                FilledButton(onPressed: _newCourse, child: Text(tr('다음 코스 만들기'))),
              ],
            ),
          ),
        ),
      for (final d in eps)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(c.practiced.contains(d.id) ? '${tr('연습 끝')} ✓' : tr('연습 전'), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.play_circle_outline),
            onTap: () => _practice(d),
          ),
        ),
      const SizedBox(height: 8),
      if (!done)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: c.allPracticed ? _exam : null,
            icon: const Icon(Icons.task_alt),
            label: Text(c.allPracticed ? tr('코스 시험 보기') : tr('모든 편을 연습하면 코스 시험이 열립니다')),
          ),
        ),
    ];
  }
}

/// 편 연습: 1) 듣기·읽기(줄마다 뜻) 2) 따라 말하기(줄 반복 듣기) 3) 확인 문제 → 결과(맞음·틀림 목록)를 돌려준다.
class _PracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  final List<CurriculumQuestion> questions;
  const _PracticeScreen({required this.dialogue, required this.questions});

  @override
  State<_PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<_PracticeScreen> {
  bool _showKo = true;
  int _playing = -1;
  int _gen = 0;

  Dialogue get d => widget.dialogue;

  @override
  void dispose() {
    _gen++;
    _stopAudio();
    super.dispose();
  }

  Future<void> _playAll() async {
    final my = ++_gen;
    await _stopAudio();
    for (var i = 0; i < d.turns.length; i++) {
      if (my != _gen || !mounted) return;
      setState(() => _playing = i);
      await _say(d, d.turns[i]);
    }
    if (my == _gen && mounted) setState(() => _playing = -1);
  }

  Future<void> _playOne(int i) async {
    final my = ++_gen;
    await _stopAudio();
    if (!mounted) return;
    setState(() => _playing = i);
    await _say(d, d.turns[i]);
    if (my == _gen && mounted) setState(() => _playing = -1);
  }

  Future<void> _quiz() async {
    _gen++;
    await _stopAudio();
    if (!mounted) return;
    if (widget.questions.isEmpty) {
      Navigator.of(context).pop(<bool>[]);
      return;
    }
    final res = await Navigator.of(context).push<List<bool>>(
      MaterialPageRoute(builder: (_) => _QuizScreen(title: d.title, questions: widget.questions)),
    );
    if (res != null && mounted) Navigator.of(context).pop(res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(
        title: Text(d.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: tr('뜻 보기'),
            icon: Icon(_showKo ? Icons.translate : Icons.translate_outlined, color: _showKo ? AppColors.rojo : null),
            onPressed: () => setState(() => _showKo = !_showKo),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text('1. ${tr('듣기·읽기')}  ·  2. ${tr('따라 말하기: 줄을 눌러 반복해 들으세요')}',
              style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _playAll, icon: const Icon(Icons.play_arrow), label: Text(tr('전체 듣기'))),
          const SizedBox(height: 8),
          for (var i = 0; i < d.turns.length; i++)
            Card(
              color: _playing == i ? AppColors.calDeep : null,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                onTap: () => _playOne(i),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: d.turns[i].speaker == 'A' ? AppColors.rojo : AppColors.oliva,
                  child: Text(d.turns[i].speaker, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text(CurriculumQuiz.clean(d.turns[i].tl.replaceAll('{name}', d.speakerName('A')))),
                subtitle: _showKo && d.turns[i].ko.isNotEmpty ? Text(d.turns[i].ko) : null,
                trailing: Icon(_playing == i ? Icons.volume_up : Icons.volume_up_outlined, size: 18),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _quiz,
            icon: const Icon(Icons.quiz_outlined),
            label: Text('3. ${tr('확인 문제')} (${widget.questions.length})'),
          ),
        ),
      ),
    );
  }
}

/// 문제 풀기(연습·복습·코스 시험 공용) — 끝나면 문제마다 맞음/틀림 목록을 돌려준다.
class _QuizScreen extends StatefulWidget {
  final String title;
  final List<CurriculumQuestion> questions;
  final bool exam;
  const _QuizScreen({required this.title, required this.questions, this.exam = false});

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  int _i = 0;
  int? _chosen;
  final List<bool> _res = [];

  CurriculumQuestion get q => widget.questions[_i];
  bool get _finished => _res.length == widget.questions.length;

  void _choose(int k) {
    if (_chosen != null) return;
    setState(() {
      _chosen = k;
      _res.add(k == q.answer);
    });
  }

  void _next() => setState(() {
        if (_i + 1 < widget.questions.length) _i++;
        _chosen = null;
      });

  @override
  Widget build(BuildContext context) {
    final n = widget.questions.length;
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: _finished && _chosen == null ? _result() : _question(n),
    );
  }

  Widget _question(int n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(value: (_i + 1) / n, backgroundColor: AppColors.calDeep),
        const SizedBox(height: 6),
        Text('${_i + 1} / $n · ${q.blank ? tr('빈칸에 맞는 낱말') : tr('알맞은 뜻')}',
            style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
        const SizedBox(height: 14),
        Text(q.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.tinta)),
        if (q.hint.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(q.hint, style: const TextStyle(fontSize: 14, color: AppColors.tintaLight)),
        ],
        const SizedBox(height: 18),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                backgroundColor: _chosen == null
                    ? null
                    : k == q.answer
                        ? const Color(0x2243A047)
                        : (k == _chosen ? const Color(0x22E53935) : null),
              ),
              onPressed: () => _choose(k),
              child: Text(q.options[k], style: const TextStyle(fontSize: 15, color: AppColors.tinta)),
            ),
          ),
        if (_chosen != null) ...[
          const SizedBox(height: 6),
          Text(_chosen == q.answer ? tr('정답!') : tr('아쉬워요 — 초록색이 정답'),
              style: TextStyle(fontWeight: FontWeight.w700, color: _chosen == q.answer ? AppColors.ir : AppColors.fem)),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _next,
            child: Text(_i + 1 < n ? tr('다음') : tr('결과 보기')),
          ),
        ],
      ],
    );
  }

  Widget _result() {
    final ok = _res.where((e) => e).length;
    final n = _res.length;
    final sc = Curriculum.score(ok, n);
    final pass = sc >= Curriculum.passPercent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$sc%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: pass ? AppColors.oliva : AppColors.rojo)),
            Text('$ok / $n', style: const TextStyle(color: AppColors.tintaLight)),
            const SizedBox(height: 12),
            if (widget.exam)
              Text(pass ? tr('80% 이상 — 코스 통과!') : tr('80% 미만 — 틀린 편만 다시 연습하고 다시 시험을 봅니다'),
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.of(context).pop(List<bool>.of(_res)), child: Text(tr('확인'))),
          ],
        ),
      ),
    );
  }
}

/// 홈 카드 — 「오늘: 복습 N · 새 편 N」 + 진행 막대, 누르면 커리큘럼.
class CurriculumHomeCard extends StatefulWidget {
  const CurriculumHomeCard({super.key});

  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  CurriculumState? _s;

  @override
  void initState() {
    super.initState();
    CurriculumStore.instance.load().then((s) {
      if (mounted) setState(() => _s = s);
    });
    CurriculumStore.instance.changes.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CurriculumStore.instance.changes.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final today = CurriculumStore.today();
    s?.rollDay(today);
    final due = s?.due(today).length ?? 0;
    final done = s?.dayDone(today) ?? false;
    final total = s == null ? 1 : s.dailyGoal + s.todayReview + due;
    final got = s == null ? 0 : math.min(s.todayNew, s.dailyGoal) + s.todayReview;
    final line = s == null
        ? ''
        : s.level == null
            ? tr('레벨을 고르고 다이얼로그 코스를 시작하세요')
            : done
                ? '${tr('오늘 분량 끝')} · 🔥 ${s.streakShown(today)}${tr('일')}'
                : '${tr('오늘')}: ${tr('복습')} $due · ${tr('새 편')} ${s.newLeft()}';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openPane(context, (_) => const CurriculumScreen()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gualda),
        ),
        child: Row(
          children: [
            const TileBadge(text: 'TV', size: 44, color: AppColors.rojoDeep),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tinta)),
                  const SizedBox(height: 2),
                  Text(line, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
                  if (s?.level != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 1 : (got / total).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.calDeep,
                        color: done ? AppColors.oliva : AppColors.rojo,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
