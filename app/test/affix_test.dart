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

  test('동사 규칙형', () {
    String all(String st) => kVerbMapSlots.map((id) => verbForm(st, id)).join(' ');
    expect(all('уулз'), 'уулзах уулзана уулзсан уулзлаа уулздаг уулзаад уулзвал уулзаарай уулзмаар уулзахгүй');
    expect(all('бай'), 'байх байна байсан байлаа байдаг байгаад байвал байгаарай баймаар байхгүй');
    expect(all('хүлээ'), 'хүлээх хүлээнэ хүлээсэн хүлээлээ хүлээдэг хүлээгээд хүлээвэл хүлээгээрэй хүлээмээр хүлээхгүй');
    expect(all('яв'), 'явах явна явсан явлаа явдаг яваад явбал яваарай явмаар явахгүй');
    expect(all('ир'), 'ирэх ирнэ ирсэн ирлээ ирдэг ирээд ирвэл ирээрэй ирмээр ирэхгүй');
    expect(verbStem('уулза'), 'уулз');
    expect(verbStem('хүлээ'), 'хүлээ');
  });
}
