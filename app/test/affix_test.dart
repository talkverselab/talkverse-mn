import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/data/mn_affixes.dart';

void main() {
  test('접사 자동 분석', () {
    expect(analyzeWord('Солонгосоос')?.affix.id, 'abl');
    expect(analyzeWord('Солонгосоос')?.stem, 'Солонгос');
    expect(analyzeWord('аялмаар')?.affix.id, 'desid');
    expect(analyzeWord('бодоод')?.affix.id, 'conv');
    expect(analyzeWord('байна')?.affix.id, 'pres');
    expect(analyzeWord('Дараа'), isNull);
    expect(analyzeWord('хот'), isNull);
  });

  test('모음조화 열쇠', () {
    expect(harmonyOf('солонгос'), 'o');
    expect(harmonyOf('сөүл'), 'e');
    expect(harmonyOf('өдөр'), 'ö');
    expect(harmonyOf('пусан'), 'a');
  });
}
