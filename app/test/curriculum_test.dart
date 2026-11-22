import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/core/theme.dart';
import 'package:mn_app/screens/curriculum_screen.dart';
import 'package:mn_app/services/curriculum.dart';
import 'package:mn_app/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토크버스 커리큘럼(CURRICULUM_SPEC.md) — 점수 80% 경계, 간격 반복 날짜, 저장 형식.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('점수는 소수점 버림, 80% 이상이면 통과', () {
    expect(Curriculum.score(8, 10), 80);
    expect(Curriculum.passed(8, 10), isTrue);
    expect(Curriculum.score(23, 29), 79); // 79.3
    expect(Curriculum.passed(23, 29), isFalse);
    expect(Curriculum.passed(24, 30), isTrue);
    expect(Curriculum.passed(11, 14), isFalse); // 78.5
    expect(Curriculum.passed(12, 15), isTrue);
    expect(Curriculum.score(0, 0), 0);
  });

  test('시험 문제 수: 편당 최소 3, 합 최대 30', () {
    expect(Curriculum.examPerDialogue(3), 10);
    expect(Curriculum.examPerDialogue(5), 6);
    expect(Curriculum.examPerDialogue(10), 3);
  });

  test('간격 반복 1 → 3 → 7일, 틀리면 1일로, 7일 뒤 맞히면 졸업', () {
    final s = CurriculumState();
    s.enqueue(['e#1'], '2026-11-30');
    expect(s.review.single.due, '2026-12-01');
    expect(s.due('2026-11-30'), isEmpty);
    expect(s.due('2026-12-01').length, 1);
    s.answer('e#1', true, '2026-12-01');
    expect((s.review.single.step, s.review.single.due), (1, '2026-12-04'));
    s.answer('e#1', true, '2026-12-04');
    expect((s.review.single.step, s.review.single.due), (2, '2026-12-11'));
    s.answer('e#1', false, '2026-12-11');
    expect((s.review.single.step, s.review.single.due), (0, '2026-12-12'));
    s.answer('e#1', true, '2026-12-12');
    s.answer('e#1', true, '2026-12-15');
    s.answer('e#1', true, '2026-12-22');
    expect(s.review, isEmpty);
    expect(Curriculum.addDays('2026-12-31', 1), '2027-01-01');
    expect(Curriculum.addDays('2028-02-28', 1), '2028-02-29');
  });

  test('하루 분량·연속 일수', () {
    final s = CurriculumState(dailyGoal: 1)..rollDay('2026-11-22');
    expect(s.dayDone('2026-11-22'), isFalse);
    s.todayNew = 1;
    s.touchStreak('2026-11-22');
    expect(s.streakCount, 1);
    s.rollDay('2026-11-23');
    expect(s.newLeft(), 1);
    s.todayNew = 1;
    s.touchStreak('2026-11-23');
    expect(s.streakCount, 2);
    expect(s.streakShown('2026-11-25'), 0);
  });

  test('저장 형식 curriculum_v1 왕복', () {
    final s = CurriculumState(level: 'R1', dailyGoal: 3, course: Course('c1', ['a', 'b'], practiced: ['a'], examScores: [70]))
      ..passedDialogues.add('x')
      ..review.add(ReviewItem('a#2', '2026-11-23', 1))
      ..streakCount = 4
      ..streakLastDay = '2026-11-22';
    final j = s.toJson();
    expect(j.keys.toSet(), {'level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak'});
    final r = CurriculumState.fromJson(j);
    expect(r.course!.practiced, ['a']);
    expect(r.course!.examScores, [70]);
    expect(r.review.single.step, 1);
    expect(r.streakCount, 4);
  });

  test('추천은 주제가 겹치지 않게, 문제는 실제 편으로 만들어진다', () async {
    final svc = DialogueService.instance;
    await svc.ensureLoaded();
    final r1 = svc.list(region: 'R1');
    final rec = CurriculumCatalog.recommend(r1, {}, 5);
    expect(rec.length, 5);
    final isl = rec.map((id) => svc.byId(id)!.island).toSet();
    expect(isl.length, math.min(5, svc.islandsOf('R1').length));
    final d = r1.first;
    final qs = CurriculumQuiz.forDialogue(d, 10, [for (final e in r1) ...e.turns], math.Random(1));
    expect(qs, isNotEmpty);
    for (final q in qs) {
      expect(q.options.length, 4);
      expect(q.answer, inInclusiveRange(0, 3));
      expect(q.options.toSet().length, 4);
    }
    expect(CurriculumCatalog.levels(svc), isNot(contains('L1')));
  });

  testWidgets('커리큘럼 화면: 레벨 고르기 → 코스 만들기가 좁은 칸에서도 넘치지 않는다', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(300, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const CurriculumScreen()));
    for (var i = 0; i < 8; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pump();
    }
    expect(find.text('레벨 고르기'), findsOneWidget);
    await t.tap(find.textContaining('R1 ·').first);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    expect(find.text('추천으로 채우기'), findsOneWidget);
    await t.tap(find.text('추천으로 채우기'));
    await t.pump();
    expect(find.textContaining('(5/5)'), findsOneWidget);
    for (final w in [300.0, 390.0, 744.0]) {
      t.view.physicalSize = Size(w, 900);
      await t.pump();
      expect(t.takeException(), isNull);
    }
  });
}
