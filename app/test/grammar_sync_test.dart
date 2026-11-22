import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/screens/grammar_lesson_screen.dart';
import 'package:mn_app/screens/sense_course_screen.dart';
import 'package:mn_app/services/script_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 문법 파트 서버 받기(사용자 지시 2026-11-23 「스텝 10 까지 다 미리 만들어놓고 DB 업데이트 하면서 업뎃」):
/// 서버 것이 있으면 서버 것, 없으면 앱 묶음 것 · 빈 스텝 숨김 · 서버에서 빠진 스텝 숨김.
String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late Directory dir;
  final original = ScriptSync.instance;
  setUp(() => dir = Directory.systemTemp.createTempSync('grammar_sync'));
  tearDown(() {
    ScriptSync.instance = original;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final baseline = json.decode(File('assets/data/script_rev.json').readAsStringSync()) as Map<String, dynamic>;
  final baseFiles = (baseline['files'] as Map).map((k, v) => MapEntry('$k', '$v'));
  final senseRaw = File('assets/data/grammar/sense_course.json').readAsStringSync();

  Future<ScriptSync> serverWith(Map<String, String?> changes) async {
    final files = {...baseFiles};
    final bodies = <String, String>{};
    changes.forEach((rel, body) {
      if (body == null) {
        files.remove(rel);
      } else {
        files[rel] = sha(body);
        bodies[rel] = body;
      }
    });
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) return json.encode({'rev': (baseline['rev'] as int) + 1, 'files': files});
      for (final e in bodies.entries) {
        if (url.contains('/${e.key}?')) return e.value;
      }
      return null;
    }

    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: baseline);
    expect(await s.refresh(), isTrue);
    return s;
  }

  test('서버 판이 없으면 앱 묶음 — 문법 스텝 2개, 언어감각 10급', () async {
    final s = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: baseline);
    ScriptSync.instance = s;
    final lessons = await GrammarLesson.loadAll();
    expect(lessons.map((l) => l.number), [1, 2]);
    final sense = await SenseCourse.load();
    expect((sense['levels'] as List).length, 10);
  });

  test('서버에 고친 판·새 스텝이 있으면 그것, 빈 스텝·빠진 스텝은 숨김', () async {
    final l1 = json.decode(File('assets/data/grammar/lesson1.json').readAsStringSync()) as Map<String, dynamic>;
    final sense = json.decode(senseRaw) as Map<String, dynamic>;
    final levels = (sense['levels'] as List).cast<Map<String, dynamic>>();
    levels[0] = {...levels[0], 'title': '서버에서 고친 1급'};
    levels[4] = {...levels[4], 'lessons': <Map<String, dynamic>>[]}; // 5급 내용 비움 → 숨김
    levels.removeAt(9); // 서버에서 10급을 뺌 → 사라짐
    levels.addAll([
      {...levels[0], 'id': 'L11', 'title': '서버에서 더한 11급'},
      {...levels[1], 'id': 'L12', 'title': '서버에서 더한 12급'},
    ]); // 더하면 생김(개수 상한 없음)
    final s = await serverWith({
      'grammar/lesson1.json': json.encode({...l1, 'title': '서버에서 고친 스텝 1'}),
      'grammar/lesson2.json': null, // 서버 판에서 빠짐 → 숨김
      'grammar/lesson3.json': json.encode({
        'lesson': 3,
        'title': '새 스텝 3',
        'patterns': [
          {'id': 'p1', 'label': '-аад', 'examples': [{'tl': 'Би ирээд залгана.', 'rd': '비 이레드 잘간', 'ko': '와서 전화할게.'}]}
        ],
      }),
      'grammar/lesson4.json': json.encode({'lesson': 4, 'title': '빈 스텝', 'patterns': []}), // 비어 있음 → 숨김
      // 상한 없음 — 서버가 16번째 스텝을 더하면 그대로 보인다
      'grammar/lesson16.json': json.encode({
        'lesson': 16,
        'title': '스텝 16',
        'patterns': [
          {'id': 'p1', 'label': '-маар', 'examples': [{'tl': 'Би унтмаар байна.', 'rd': '비 온트마르 벵', 'ko': '자고 싶어.'}]}
        ],
      }),
      'grammar/sense_course.json': json.encode({...sense, 'levels': levels}),
    });
    ScriptSync.instance = s;
    final lessons = await GrammarLesson.loadAll();
    expect(lessons.map((l) => (l.number, l.title)), [(1, '서버에서 고친 스텝 1'), (3, '새 스텝 3'), (16, '스텝 16')]);
    final got = (await SenseCourse.load())['levels'] as List;
    expect(got.map((l) => (l as Map)['id']), ['L1', 'L2', 'L3', 'L4', 'L6', 'L7', 'L8', 'L9', 'L11', 'L12']);
    expect((got.first as Map)['title'], '서버에서 고친 1급');
  });
}
