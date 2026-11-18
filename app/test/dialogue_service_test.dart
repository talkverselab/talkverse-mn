import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 안 에셋(진짜 번들)으로 회화 목록 — 옛 L1 2편 + 편 파일 150편(R1·R2·R3). 서버 받기는 시험에서 돌지 않는다(기기 폴더 없음).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('DialogueService 가 L1 + R* 편을 모두 읽는다', () async {
    final svc = DialogueService.instance;
    await svc.ensureLoaded();
    expect(svc.all.length, 152);
    expect(svc.count('L1'), 2);
    expect(svc.count('R1') + svc.count('R2') + svc.count('R3'), 150);
    expect(svc.regions, ['R1', 'R2', 'R3', 'L1']);
    final d = svc.byId('r1_culture_a1')!;
    expect(d.island, 'culture');
    expect(d.turns.first.num, 1);
    expect(d.turns.first.tl, isNotEmpty);
    expect(svc.byId('L1_mn_d01')?.turns.first.tl, isNotEmpty);
    // 편 id 가 겹치지 않는다
    expect(svc.all.map((d) => d.id).toSet().length, 152);
  });
}
