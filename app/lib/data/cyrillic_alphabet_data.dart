import '../domain/models/cyrillic_letter.dart';

/// 몽골 키릴 35자 — 학습 4단계 순서로 재배열.
///
///   1단계 모음: 모음조화(남성 а о у ↔ 여성 э ө ү, 중성 и) + 연모음 + 몽골 전용 Ө Ү.
///   2단계 가짜친구: 영어처럼 보이나 소리 다름 (В Н Р С Х).
///   3단계 몽골 키릴 자음: 라틴에 없는 새 자음.
///   4단계 나머지: 영어와 같은 친구 자음(К М Т) + 반모음(Й) + 부호(Ъ Ь).
/// 발음 규칙은 숨기고 [소리]만 노출. (러시아 키릴 + Ө Ү 두 글자.)
const List<CyrillicLetter> cyrillicAlphabet = [
  // ── 1단계 · 모음 (모음조화 짝 + 연모음) ────────────────────
  CyrillicLetter(upper: 'А', lower: 'а', name: '아', roman: 'a', sound: '아', stage: AlphaStage.vowel, tip: '남성(후설) 모음 [아]. 모음조화의 남성 그룹 대표. 짝은 여성 Э.'),
  CyrillicLetter(upper: 'Э', lower: 'э', name: '에', roman: 'e', sound: '에', stage: AlphaStage.vowel, tip: '여성(전설) 모음 [에]. А의 여성 짝. 어미가 а/э로 갈리는 게 모음조화.'),
  CyrillicLetter(upper: 'О', lower: 'о', name: '오', roman: 'o', sound: '오', stage: AlphaStage.vowel, tip: '남성(후설) [오]. 짝은 여성 Ө.'),
  CyrillicLetter(upper: 'Ө', lower: 'ө', name: '으(ö)', roman: 'ö', sound: '어(ö)', stage: AlphaStage.vowel, tip: '⚠ 몽골 전용 모음. 입술 둥글게 [어]에 가까운 ö. О의 여성 짝.'),
  CyrillicLetter(upper: 'У', lower: 'у', name: '우', roman: 'u', sound: '우(오)', stage: AlphaStage.vowel, tip: '남성(후설) [우~오]. 영어 y 아님! 짝은 여성 Ү.'),
  CyrillicLetter(upper: 'Ү', lower: 'ү', name: '위(ü)', roman: 'ü', sound: '위(ü)', stage: AlphaStage.vowel, tip: '⚠ 몽골 전용 모음. 입술 둥글게 [위]에 가까운 ü. У의 여성 짝.'),
  CyrillicLetter(upper: 'И', lower: 'и', name: '이', roman: 'i', sound: '이', stage: AlphaStage.vowel, tip: '중성 모음 [이]. 남성·여성 어디에나 붙는다.'),
  CyrillicLetter(upper: 'Е', lower: 'е', name: '예', roman: 'ye', sound: '예(여)', stage: AlphaStage.vowel, tip: '연모음 [예]. 단어 첫머리·뒤에선 [여]로도. 영어 E 모양에 속지 말 것.'),
  CyrillicLetter(upper: 'Ё', lower: 'ё', name: '요', roman: 'yo', sound: '요', stage: AlphaStage.vowel, tip: 'О의 연모음 [요]. 거의 항상 강세.'),
  CyrillicLetter(upper: 'Ю', lower: 'ю', name: '유', roman: 'yu', sound: '유', stage: AlphaStage.vowel, tip: 'У/Ү의 연모음 [유].'),
  CyrillicLetter(upper: 'Я', lower: 'я', name: '야', roman: 'ya', sound: '야', stage: AlphaStage.vowel, tip: 'А의 연모음 [야]. 거꾸로 된 R 모양.'),
  CyrillicLetter(upper: 'Ы', lower: 'ы', name: '의', roman: 'y', sound: '으이', stage: AlphaStage.vowel, tip: '깊은 [으이]. 복수 어미(-ууд) 등에서 주로 보인다.'),

  // ── 2단계 · 영어 가짜친구 자음 ───────────────────────────
  CyrillicLetter(upper: 'В', lower: 'в', name: '웨', roman: 'v/w', sound: 'ㅂ(w)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 B 아님! 몽골어선 흔히 [w] 소리.'),
  CyrillicLetter(upper: 'Н', lower: 'н', name: '엔', roman: 'n', sound: 'ㄴ(ㅇ)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 H 아님! [ㄴ]. 어말에선 [ㅇ](받침)으로.'),
  CyrillicLetter(upper: 'Р', lower: 'р', name: '에르', roman: 'r', sound: 'ㄹ(굴림)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 P 아님! 굴리는 [r].'),
  CyrillicLetter(upper: 'С', lower: 'с', name: '에스', roman: 's', sound: 'ㅅ(s)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 C 아님! [s] 소리.'),
  CyrillicLetter(upper: 'Х', lower: 'х', name: '헤', roman: 'kh', sound: 'ㅎ(ㅋ)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 X 아님! 목 긁는 [ㅎ/ㅋ]. 아주 흔한 자음.'),

  // ── 3단계 · 몽골 키릴 자음 ───────────────────────────────
  CyrillicLetter(upper: 'Б', lower: 'б', name: '베', roman: 'b', sound: 'ㅂ', stage: AlphaStage.mongolOnly, tip: '[ㅂ]. 소문자 б는 숫자 6처럼.'),
  CyrillicLetter(upper: 'Г', lower: 'г', name: '게', roman: 'g', sound: 'ㄱ', stage: AlphaStage.mongolOnly, tip: '[ㄱ]. 거꾸로 된 ㄴ 모양.'),
  CyrillicLetter(upper: 'Д', lower: 'д', name: '데', roman: 'd', sound: 'ㄷ', stage: AlphaStage.mongolOnly, tip: '[ㄷ].'),
  CyrillicLetter(upper: 'Ж', lower: 'ж', name: '제', roman: 'j', sound: 'ㅈ(j)', stage: AlphaStage.mongolOnly, tip: '[ㅈ]. 딱정벌레 모양.'),
  CyrillicLetter(upper: 'З', lower: 'з', name: '제', roman: 'z', sound: 'ㅈ(dz)', stage: AlphaStage.mongolOnly, tip: '[dz~ㅈ]. 숫자 3처럼.'),
  CyrillicLetter(upper: 'Л', lower: 'л', name: '엘', roman: 'l', sound: 'ㄹ(l)', stage: AlphaStage.mongolOnly, tip: '혀 옆으로 바람 새는 [l]. 몽골어 특유의 굵은 ㄹ.'),
  CyrillicLetter(upper: 'П', lower: 'п', name: '뻬', roman: 'p', sound: 'ㅍ', stage: AlphaStage.mongolOnly, tip: '[ㅍ]. 주로 외래어. 그리스 π 모양.'),
  CyrillicLetter(upper: 'Ф', lower: 'ф', name: '에프', roman: 'f', sound: 'ㅍ(f)', stage: AlphaStage.mongolOnly, tip: '[f]. 외래어에 주로.'),
  CyrillicLetter(upper: 'Ц', lower: 'ц', name: '쩨', roman: 'ts', sound: 'ㅊ(ts)', stage: AlphaStage.mongolOnly, tip: '[ts] 한 소리.'),
  CyrillicLetter(upper: 'Ч', lower: 'ч', name: '체', roman: 'ch', sound: 'ㅊ', stage: AlphaStage.mongolOnly, tip: '[ㅊ]. 숫자 4처럼.'),
  CyrillicLetter(upper: 'Ш', lower: 'ш', name: '샤', roman: 'sh', sound: '시(sh)', stage: AlphaStage.mongolOnly, tip: '[sh] 굵게.'),
  CyrillicLetter(upper: 'Щ', lower: 'щ', name: '샤', roman: 'shch', sound: '시(sh)', stage: AlphaStage.mongolOnly, tip: '러시아 외래어에만. Ш와 거의 같게 [sh].'),

  // ── 4단계 · 나머지 (친구 자음 · 반모음 · 부호) ───────────
  CyrillicLetter(upper: 'К', lower: 'к', name: '까', roman: 'k', sound: 'ㅋ/ㄲ', stage: AlphaStage.rest, tip: '영어 K와 같음. 주로 외래어 (친구).'),
  CyrillicLetter(upper: 'М', lower: 'м', name: '엠', roman: 'm', sound: 'ㅁ', stage: AlphaStage.rest, tip: '영어 M과 같음 (친구).'),
  CyrillicLetter(upper: 'Т', lower: 'т', name: '떼', roman: 't', sound: 'ㅌ/ㄸ', stage: AlphaStage.rest, tip: '영어 T와 같음. (단, 이탤릭 т는 m처럼 보임!)'),
  CyrillicLetter(upper: 'Й', lower: 'й', name: '하가스 이', roman: 'i/y', sound: '이(짧게)', stage: AlphaStage.rest, tip: '짧은 이. 반모음 [y]. И에 갈고리.'),
  CyrillicLetter(upper: 'Ъ', lower: 'ъ', name: '하투깅 템덱', roman: '—', sound: '(경음부호)', stage: AlphaStage.rest, tip: '소리 없음. 아주 드묾. 앞뒤 음을 분리.'),
  CyrillicLetter(upper: 'Ь', lower: 'ь', name: '죌닝 템덱', roman: '—', sound: '(연음부호)', stage: AlphaStage.rest, tip: '소리 없음. 앞 자음을 부드럽게(구개음화). 흔함.'),
];
