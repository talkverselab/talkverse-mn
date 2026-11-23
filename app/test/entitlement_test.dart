import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/data/entitlement.dart';
import 'package:mn_app/data/purchase.dart';
import 'package:mn_app/services/curriculum_service.dart';
import 'package:mn_app/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC §2·§5): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  tearDown(() => Purchase.owned.value = const {});

  test('묶음 커리큘럼 rev 2: 1단계만 무료, 문법 2스텝·언어감각 1급 무료', () async {
    await DialogueService.instance.ensureLoaded();
    final raw = json.decode(File('assets/data/curriculum_mn.json').readAsStringSync()) as Map<String, dynamic>;
    expect(raw['rev'], greaterThanOrEqualTo(2));
    CurriculumStages.instance.setForTest(raw);
    final svc = CurriculumService.instance;
    expect(svc.levelFree('1'), isTrue);
    expect(svc.levelFree('2'), isFalse);
    expect(svc.levelFree('3'), isFalse);
    expect(Entitlement.grammarStepFree(1), isTrue);
    expect(Entitlement.grammarStepFree(2), isFalse);
    expect(Entitlement.senseLevelFree(0), isTrue);
    expect(Entitlement.senseLevelFree(1), isFalse);
    final r1 = DialogueService.instance.list(region: 'R1').first, r2 = DialogueService.instance.list(region: 'R2').first;
    expect(Entitlement.dialogueFree(r1), isTrue);
    expect(Entitlement.dialogueFree(r2), isFalse);
  });

  test('이용권: 몽골어·종합은 열림, 다른 언어·기한 지난 구독은 안 열림', () {
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_kk_life': 0};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_mn_1m': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_mn_life': 0};
    expect(Entitlement.premium, isTrue);
    Purchase.owned.value = {'all_1y': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch};
    expect(Entitlement.premium, isTrue);
  });

  test('서버 free 값을 따른다(없으면 1단계만)', () {
    CurriculumStages.instance.setForTest({
      'rev': 3,
      'freeSteps': 3,
      'freeSenseLevels': 2,
      'stages': [
        {'n': 1, 'dialogueIds': <String>[]},
        {'n': 2, 'free': true, 'dialogueIds': <String>[]},
        {'n': 3, 'dialogueIds': <String>[]},
      ],
    });
    final svc = CurriculumService.instance;
    expect([svc.levelFree('1'), svc.levelFree('2'), svc.levelFree('3')], [true, true, false]);
    expect(Entitlement.grammarStepFree(2), isTrue);
    expect(Entitlement.senseLevelFree(1), isTrue);
    CurriculumStages.instance.setForTest(json.decode(File('assets/data/curriculum_mn.json').readAsStringSync()) as Map<String, dynamic>);
  });
}
