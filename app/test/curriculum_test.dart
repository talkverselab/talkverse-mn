import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_app/screens/curriculum_screen.dart';
import 'package:mn_app/services/curriculum_service.dart';
import 'package:mn_app/services/dialogue_service.dart';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'tl': 'Б$i', 'ko': '뜻$id$i'}
      ],
    });

/// 일본어앱 기준 시험(ja ceb91c3 test/curriculum_test.dart)을 옮기고, 몽골어 실제 편으로 보는 시험을 더함.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(7, 9), 77);
      expect(scorePercent(2, 3), 66);
      expect(scorePercent(0, 0), 0);
    });
    test('80% 이상만 통과', () {
      expect(isPass(8, 10), isTrue);
      expect(isPass(79, 100), isFalse);
      expect(isPass(4, 5), isTrue);
      expect(isPass(23, 29), isFalse); // 79.3 → 79
      expect(isPass(24, 30), isTrue);
    });
    test('시험 기록 — 통과면 편 통과, 아니면 틀린 편 연습 다시', () {
      final st = CurriculumState(course: Course('c', ['a', 'b'], practiced: ['a', 'b']));
      expect(st.recordExam(7, 10, {'b'}, '2026-11-22'), isFalse);
      expect(st.course!.practiced, ['a']);
      expect(st.passedDialogues, isEmpty);
      st.course!.practiced.add('b');
      expect(st.recordExam(8, 10, {}, '2026-11-23'), isTrue);
      expect(st.course!.passedAt, '2026-11-23');
      expect(st.passedDialogues, ['a', 'b']);
      expect(st.course!.examScores, [70, 80]);
    });
  });

  group('간격 반복 날짜', () {
    test('1일 → 3일 → 7일 → 졸업', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      expect(st.review.single.due, '2026-11-23');
      st.grade('x#1', true, '2026-11-23');
      expect(st.review.single.due, '2026-11-26');
      st.grade('x#1', true, '2026-11-26');
      expect(st.review.single.due, '2026-12-03');
      st.grade('x#1', true, '2026-12-03');
      expect(st.review, isEmpty);
    });
    test('틀리면 1일 뒤 처음 간격으로', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      st.grade('x#1', true, '2026-11-23');
      st.grade('x#1', false, '2026-11-26');
      expect(st.review.single.step, 0);
      expect(st.review.single.due, '2026-11-27');
    });
    test('달·해 넘김', () {
      expect(addDays('2026-12-30', 3), '2027-01-02');
      expect(addDays('2028-02-28', 1), '2028-02-29');
    });
  });

  group('하루 분량·연속', () {
    test('새 편 목표를 채우고 복습이 없으면 끝, 연속 일수', () {
      final st = CurriculumState(dailyGoal: 1, course: Course('c', ['a', 'b']));
      expect(st.dayDone('2026-11-22'), isFalse);
      st.markPracticed('a', [1, 2], '2026-11-22');
      expect(st.dayDone('2026-11-22'), isTrue);
      expect(st.streakShown('2026-11-22'), 1);
      // 다음 날: 복습 2줄 + 새 편 1
      expect(st.dueReview('2026-11-23').length, 2);
      st.grade('a#1', true, '2026-11-23');
      st.grade('a#2', true, '2026-11-23');
      st.markPracticed('b', [1], '2026-11-23');
      expect(st.todayReview, 2);
      expect(st.streakShown('2026-11-23'), 2);
      expect(st.streakShown('2026-11-25'), 0);
    });
    test('저장 형식 왕복', () {
      final st = CurriculumState(level: 'R1', course: Course('c', ['a']));
      st.markPracticed('a', [1], '2026-11-22');
      final back = CurriculumState.fromJson(st.toJson());
      expect(back.toJson(), st.toJson());
      expect(st.toJson().keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    });
  });

  group('문제·추천', () {
    test('편마다 줄 수만큼, 최대 10, 보기 4개 중 정답 1', () {
      final a = _d('a', 'friends', 12), b = _d('b', 'life', 4);
      final qs = buildQuestions(a, limit: 10, pool: [b]);
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        expect(q.choices[q.answer], '뜻a${q.turn}');
      }
      expect(buildQuestions(b, limit: 10, pool: [a]).length, 4);
    });
    test('시험 문제 수: 편당 최소 3, 전체 최대 30', () {
      expect(examPerDialogue(3), 10);
      expect(examPerDialogue(5), 6);
      expect(examPerDialogue(10), 3);
    });
    test('추천 = 안 한 편, 주제 겹치지 않게', () {
      final list = [_d('f1', 'friends', 2), _d('f2', 'friends', 2), _d('l1', 'life', 2), _d('w1', 'work', 2)];
      final r = recommend(list, {'l1'}, {}, 3);
      expect(r, ['f1', 'w1', 'f2']);
    });
  });

  testWidgets('시험 화면 — 고르고 결과까지', (t) async {
    final a = _d('a', 'friends', 5);
    final qs = buildQuestions(a, limit: 2);
    await t.pumpWidget(MaterialApp(home: CurriculumQuizScreen(title: 'T', questions: qs, mode: QuizMode.exam)));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(qs[i].choices[qs[i].answer]));
      await t.pump();
      await t.tap(find.byType(FilledButton).last);
      await t.pump();
    }
    expect(find.textContaining('100'), findsOneWidget);
  });

  test('몽골어 실제 편: 빈칸은 줄의 낱말로, 오답은 같은 레벨 다른 편에서, 레벨에 L1 없음', () async {
    await DialogueService.instance.ensureLoaded();
    final r1 = DialogueService.instance.list(region: 'R1');
    final d = r1.first;
    final qs = buildQuestions(d, limit: 10, pool: r1, seed: 1);
    expect(qs, isNotEmpty);
    expect(qs.any((q) => q.kind == 'blank'), isTrue);
    for (final q in qs) {
      expect(q.choices.length, 4);
      expect(q.choices.toSet().length, 4);
      if (q.kind == 'blank') expect(q.prompt, contains('＿＿'));
    }
    // JSON 없으면 옛 동작(회화 레벨 R*, L1 제외)
    CurriculumStages.instance.setForTest(null);
    expect(curriculumLevels, ['R1', 'R2', 'R3']);
    expect(CurriculumService.instance.nextLevel('R1'), 'R2');
    expect(CurriculumService.instance.nextLevel('R3'), isNull);
  });

  test('§12 단계: 묶음 JSON 1~3단계, 앱에 없는 편 건너뜀, 편 0개 단계 숨김, 옛 R 값 → 단계', () async {
    await DialogueService.instance.ensureLoaded();
    final raw = json.decode(File('assets/data/curriculum_mn.json').readAsStringSync()) as Map<String, dynamic>;
    CurriculumStages.instance.setForTest(raw);
    expect(curriculumLevels, ['1', '2', '3']);
    expect(CurriculumService.instance.levelList('1').length, 90);
    expect(CurriculumService.instance.levelTitle('2'), '2단계');
    expect(CurriculumService.instance.nextLevel('3'), isNull);
    // 서버 판: 4단계는 앱에 없는 편만 → 숨김, 1단계에 없는 id 섞임 → 건너뜀
    final st = (raw['stages'] as List).cast<Map<String, dynamic>>();
    CurriculumStages.instance.setForTest({
      'rev': 9,
      'stages': [
        {...st[0], 'dialogueIds': ['nope_x', ...st[0]['dialogueIds'] as List]},
        st[1],
        {'n': 4, 'title': '4단계', 'dialogueIds': ['nope_y']},
      ],
    });
    expect(curriculumLevels, ['1', '2']);
    expect(CurriculumService.instance.levelList('1').length, 90);
    expect(levelFromOld('R0'), '1');
    expect(levelFromOld('R1'), '1');
    expect(levelFromOld('R3'), '3');
    expect(levelFromOld('2'), '2');
    // 저장은 문자열, 읽기는 숫자·문자 둘 다
    expect(CurriculumState(level: '2').toJson()['level'], '2');
    expect(CurriculumState.fromJson({'level': 3}).level, '3');
    expect(CurriculumState.fromJson({'level': '3'}).level, '3');
    // pass·daily·pick 도 JSON 에서(없으면 80 / 1·2·3 / 3·5·10)
    CurriculumStages.instance.setForTest({
      'rev': 10,
      'stages': [
        {...st[0], 'pass': 70, 'pick': [4, 6], 'daily': {'light': 2, 'normal': 4, 'focus': 6}},
        {'n': 2, 'dialogueIds': st[1]['dialogueIds']},
      ],
    });
    final svc = CurriculumService.instance;
    expect(svc.passFor('1'), 70);
    expect(svc.passFor('2'), 80);
    expect(svc.pickSizes('1'), [4, 6]);
    expect(svc.pickSizes('2'), [3, 5, 10]);
    svc.state.level = '1';
    svc.state.dailyGoal = 2;
    svc.applyStage();
    expect(svc.state.newLeft('2026-11-23'), 4);
    svc.state.level = '2';
    svc.applyStage();
    expect(svc.state.newLeft('2026-11-23'), 2);
    final st70 = CurriculumState(course: Course('c', ['a'], practiced: ['a']));
    expect(st70.recordExam(7, 10, {}, '2026-11-23', pass: 70), isTrue);
    CurriculumStages.instance.setForTest(raw);
    svc.state = CurriculumState(); // 다음 시험(화면)에 상태가 새지 않게
  });

  testWidgets('커리큘럼 화면: 레벨 → 추천으로 채우기, 좁은 칸에서도 넘치지 않음', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(300, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const CurriculumScreen()));
    for (var i = 0; i < 8; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pump();
    }
    expect(find.text('회화 레벨을 골라요'), findsOneWidget);
    await t.tap(find.text('1단계'));
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
    }
    await t.tap(find.text('추천으로 채우기'));
    await t.pump();
    expect(find.text('5/5편으로 코스 시작'), findsOneWidget);
    for (final w in [300.0, 390.0, 744.0]) {
      t.view.physicalSize = Size(w, 900);
      await t.pump();
      expect(t.takeException(), isNull);
    }
  });
}
