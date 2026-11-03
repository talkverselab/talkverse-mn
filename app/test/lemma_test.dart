import 'package:flutter_test/flutter_test.dart';
import 'package:mn_app/services/word_lookup.dart';

void main() {
  test('lemma candidates reach dictionary forms', () {
    expect(lemmaCandidates('ирсэн'), contains('ирэх'));
    expect(lemmaCandidates('Солонгосоос'), contains('солонгос'));
    expect(lemmaCandidates('явна'), contains('явах'));
  });
}
