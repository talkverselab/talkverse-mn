import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/screens/sense_course_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 언어감각 익히기(2026-11-22, Claude 로 씀) — 형식 검사 + 목록·회차 화면 넘침.
Future<void> settle(WidgetTester t, Finder until) async {
  for (var i = 0; i < 100 && until.evaluate().isEmpty; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump();
  }
  await t.pump(const Duration(milliseconds: 300));
}

final _mark = RegExp(r'\{([^|}]+)\|(\d+)\}');
Set<String> marks(String s) => {for (final m in _mark.allMatches(s)) m.group(2)!};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('10급 · 급마다 외울 대화 10줄 + 참고, 표시 번호는 몽골어·한국어 짝이 같다', () {
    final d = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    final levels = (d['levels'] as List).cast<Map<String, dynamic>>();
    expect(levels.length, 10);
    final ids = <String>{};
    for (var i = 0; i < levels.length; i++) {
      final lv = levels[i];
      expect(lv['id'], 'L${i + 1}');
      final lessons = (lv['lessons'] as List).cast<Map<String, dynamic>>();
      expect(lessons.map((l) => l['kind']).toList(), ['memorize', 'ref'], reason: lv['id'] as String);
      for (final ls in lessons) {
        expect(ids.add(ls['id'] as String), isTrue, reason: '회차 id 겹침 ${ls['id']}');
      }
      final talk = (lessons[0]['sentences'] as List).cast<Map<String, dynamic>>();
      expect(talk.length, 10, reason: lv['id'] as String);
      expect((lessons[0]['note'] as String).isNotEmpty, isTrue);
      for (final s in talk) {
        for (final k in ['who', 'tl', 'rd', 'ko']) {
          expect((s[k] as String?)?.trim().isNotEmpty ?? false, isTrue, reason: '${lv['id']} $k $s');
        }
        expect(RegExp(r'[А-Яа-яЁёӨөҮү]').hasMatch(s['tl'] as String), isTrue);
        expect(s['tl'], isNot(contains('{name}')));
        expect(marks(s['tl'] as String), marks(s['ko'] as String), reason: '${lv['id']} ${s['tl']}');
        // 표시 꼴이 깨지지 않았다(남은 중괄호 없음)
        expect((s['tl'] as String).replaceAll(_mark, ''), isNot(contains(RegExp(r'[{}|]'))));
        expect((s['ko'] as String).replaceAll(_mark, ''), isNot(contains(RegExp(r'[{}|]'))));
      }
      expect(talk.where((s) => marks(s['tl'] as String).isNotEmpty).length, greaterThanOrEqualTo(6), reason: '${lv['id']} 익힐 자리가 너무 적음');
      final points = (lessons[1]['points'] as List).cast<Map<String, dynamic>>();
      expect(points, isNotEmpty);
      for (final p in points) {
        expect((p['head'] as String).isNotEmpty && (p['tip'] as String).isNotEmpty, isTrue);
        final ex = (p['sentences'] as List).cast<Map<String, dynamic>>();
        expect(ex, isNotEmpty);
        for (final s in ex) {
          expect(marks(s['tl'] as String), isEmpty);
          expect((s['rd'] as String).isNotEmpty && (s['ko'] as String).isNotEmpty, isTrue);
        }
      }
    }
  });

  test('표시를 떼면 듣기용 본문', () {
    expect(plainMarked('Их дэлгүүр{т|1} очно.'), 'Их дэлгүүрт очно.');
  });

  for (final w in const [300.0, 390.0, 900.0]) {
    testWidgets('목록 폭 $w — 10급, 회차를 열고 마침', (t) async {
      t.view.physicalSize = Size(w, 5000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: SenseCourseScreen()));
      await settle(t, find.byKey(const ValueKey('sense-L1-talk')));
      expect(t.takeException(), isNull);
      for (var i = 1; i <= 10; i++) {
        expect(find.byKey(ValueKey('sense-L$i-talk')), findsOneWidget);
        expect(find.byKey(ValueKey('sense-L$i-ref')), findsOneWidget);
      }
      await t.tap(find.byKey(const ValueKey('sense-L1-talk')));
      await settle(t, find.byKey(const ValueKey('sense-finish')));
      expect(t.takeException(), isNull);
      expect(find.textContaining('Уучлаарай', findRichText: true), findsWidgets);
      await t.tap(find.byKey(const ValueKey('sense-finish')));
      await settle(t, find.textContaining('L2 ·'));
      expect(t.takeException(), isNull);
    });
  }
}
