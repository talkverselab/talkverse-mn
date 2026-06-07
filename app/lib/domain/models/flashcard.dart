import 'sentence.dart';

/// 플래시카드 한 장 — 문장(색칠 토큰) 또는 단어 한 개를 앞면에.
class FlashItem {
  final List<Tok>? tokens; // 문장 카드 (색칠 렌더)
  final String? word; // 단어 카드 (키릴 한 단어)
  final String tts; // 발음용 텍스트
  final String back; // 뒷면 한국어 뜻
  final String? note; // 뒷면 보조 (포인트/품사)

  const FlashItem({this.tokens, this.word, required this.tts, required this.back, this.note});

  factory FlashItem.fromSentence(Sentence s) =>
      FlashItem(tokens: s.tokens, tts: s.plain, back: s.ko, note: s.note);

  factory FlashItem.word(String word, {required String ko, String? note}) =>
      FlashItem(word: word, tts: word, back: ko, note: note);
}
