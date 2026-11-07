import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/core/cliff.dart';
import 'package:mn_app/services/word_lookup.dart';

void main() {
  test('cliff regions follow the official boundaries', () {
    expect([1, 49, 50, 71, 72, 185, 186, 522, 523, 1500].map(regionOf).toList(),
        ['R1', 'R1', 'R2', 'R2', 'R3', 'R3', 'R4', 'R4', 'R5', 'R5']);
  });

  test('lemma candidates reach dictionary forms', () {
    expect(lemmaCandidates('ирсэн'), contains('ирэх'));
    expect(lemmaCandidates('Солонгосоос'), contains('солонгос'));
    expect(lemmaCandidates('явна'), contains('явах'));
  });
}
