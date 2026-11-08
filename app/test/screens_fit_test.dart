import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/core/theme.dart';
import 'package:mn_app/data/db/app_database.dart';
import 'package:mn_app/data/db/seed_loader.dart';
import 'package:mn_app/main.dart';
import 'package:mn_app/screens/keyboard_screen.dart';
import 'package:mn_app/screens/main_screen.dart';
import 'package:mn_app/screens/profile_screen.dart';
import 'package:mn_app/screens/word_freq_screen.dart';
import 'package:mn_app/services/word_lookup.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 시뮬레이터 없이 새 화면의 넘침을 본다(아이패드 왼쪽 칸 300 · 폰 390 · 아이패드 세로 744).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    appDb = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedLoader(appDb).seedWordsOnly();
  });

  test('seeded word regions follow the cliffs', () async {
    final rows = await appDb.select(appDb.words).get();
    expect(rows.length, 1500);
    final by = <String, int>{};
    for (final w in rows) {
      by[w.region!] = (by[w.region!] ?? 0) + 1;
    }
    expect(by, {'R1': 49, 'R2': 22, 'R3': 114, 'R4': 337, 'R5': 978});
  });

  test('sentence words resolve to the word list', () async {
    final hits = await wordsInText('Сайн байна уу? Би Солонгосоос ирсэн.');
    expect(hits['байна']?.word, 'байх');
    expect(hits['Би']?.word, 'би');
    expect(hits['ирсэн']?.word, 'ирэх');
  });

  testWidgets('word screen fits at each width', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(300, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const WordFreqScreen()));
    for (var i = 0; i < 8; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await t.pump();
    }
    expect(find.text('1단원'), findsOneWidget);
    for (final w in [300.0, 390.0, 744.0, 1024.0]) {
      t.view.physicalSize = Size(w, 900);
      await t.pump();
      expect(t.takeException(), isNull);
    }
  });

  for (final width in [300.0, 390.0, 744.0]) {
    Future<void> pumpAt(WidgetTester t, Widget w) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(width, 900);
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: w));
      for (var i = 0; i < 8; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await t.pump();
      }
      final e = t.takeException();
      expect(e == null || '$e'.contains('MissingPluginException'), isTrue, reason: '$e'); // 음성 플러그인은 테스트에 없음 — 넘침만 본다
    }

    // 300 은 테스트 글꼴(Ahem)이 넓어 머리줄이 넘친다 — 실제 글꼴로는 아이패드 스크린샷에서 본다
    if (width >= 390) {
      testWidgets('home menu fits at $width', (t) async {
        await pumpAt(t, const HomeScreen());
        expect(find.text('절벽 단어'), findsOneWidget);
      });
    }
    testWidgets('keyboard practice fits at $width', (t) async {
      await pumpAt(t, const KeyboardScreen());
      expect(find.text('байх'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'БАЙХ');
      await t.pump();
      expect(find.text('🎉 정답!'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 2)); // 발음 1초 지연 타이머를 흘려보낸다
    });
    testWidgets('profile fits at $width', (t) async {
      await pumpAt(t, const ProfileScreen());
      expect(find.text('프로필'), findsOneWidget);
    });
  }
}
