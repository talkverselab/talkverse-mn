import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mn_app/core/theme.dart';
import 'package:mn_app/screens/about_screen.dart';
import 'package:mn_app/screens/alphabet_screen.dart';

void main() {
  aboutFits(320);
  aboutFits(744);
  for (final w in [300.0, 390.0, 744.0]) {
    testWidgets('Alphabet screen fits at $w', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(w, 1400);
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const AlphabetScreen()));
      await t.pump();
      expect(find.text('Өө'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Theme builds', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: Text('hola')),
    ));
    expect(find.text('hola'), findsOneWidget);
  });

  test('conjColor maps groups', () {
    expect(conjColor('ar'), AppColors.ar);
    expect(conjColor('irregular'), AppColors.irregular);
    expect(conjColor(null), AppColors.neutral);
  });
}

void aboutFits(double width) => testWidgets('About screen fits at $width', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(width, 900);
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const AboutScreen()));
      await t.pump();
      expect(find.text('R5'), findsOneWidget);
      expect(find.text('523-1500'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
