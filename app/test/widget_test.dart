// 몽골어유니버스 스모크 테스트 — 앱이 빌드되고 하단 내비가 뜨는지 확인.
import 'package:flutter_test/flutter_test.dart';

import 'package:mn_app/main.dart';

void main() {
  testWidgets('App boots and shows home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const MongolianUniverseApp());
    await tester.pump();

    // 하단 내비 라벨이 보이면 메인 화면이 뜬 것.
    expect(find.text('홈'), findsWidgets);
    expect(find.text('회화'), findsWidgets);
  });
}
