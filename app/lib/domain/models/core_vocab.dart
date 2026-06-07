/// spec §6 코어 40 (트랙 A 로직 반복 전용). 닳도록 반복.
/// 나머지 110은 부품 교체로 흘려보냄.
class CoreVocab {
  // 명사 5~6 (성별 다 포함)
  static const nouns = <CoreNoun>[
    CoreNoun(lemma: 'друг',   gender: Gender.masc,  meaning: '친구'),
    CoreNoun(lemma: 'ма́ма',   gender: Gender.fem,   meaning: '엄마'),
    CoreNoun(lemma: 'дом',    gender: Gender.masc,  meaning: '집'),
    CoreNoun(lemma: 'вре́мя',  gender: Gender.neut,  meaning: '시간', irregularNote: '-мя 특수변화'),
    CoreNoun(lemma: 'рабо́та', gender: Gender.fem,   meaning: '일·직장'),
  ];

  // 동사 5~6 (규칙+불규칙)
  static const verbs = <CoreVerb>[
    CoreVerb(lemma: 'знать',   conjugation: VerbClass.r1, meaning: '알다',     irregular: false),
    CoreVerb(lemma: 'де́лать',  conjugation: VerbClass.r1, meaning: '하다(불완)', irregular: false, aspectPair: 'сде́лать'),
    CoreVerb(lemma: 'дать',    conjugation: VerbClass.irregular, meaning: '주다(완)', irregular: true,  aspectPair: 'дава́ть'),
    CoreVerb(lemma: 'идти́',    conjugation: VerbClass.irregular, meaning: '가다(걸어서)', irregular: true),
    CoreVerb(lemma: 'хоте́ть',  conjugation: VerbClass.irregular, meaning: '원하다',  irregular: true),
  ];

  // 형용사 3
  static const adjectives = <String>['но́вый', 'мой', 'хоро́ший'];

  // 전치사 5~6
  static const prepositions = <String>['в', 'на', 'с', 'к', 'у', 'о'];

  // 대명사 (단수 3인칭 정책)
  static const pronouns = <String>['я', 'ты', 'он', 'она́'];

  // 양태 2~3
  static const modalities = <String>['на́до', 'мо́жно', 'хоте́ть'];

  /// 합 = 5 + 5 + 3 + 6 + 4 + 3 = 26. spec "코어 30~40" 하한.
  /// (실제 닳도록 반복하는 표본; 110개 확장은 별도 파일.)
}

enum Gender { masc, fem, neut }
enum VerbClass { r1, r2, irregular }   // 제1식·제2식·불규칙

class CoreNoun {
  final String lemma;
  final Gender gender;
  final String meaning;
  final String? irregularNote;
  const CoreNoun({
    required this.lemma,
    required this.gender,
    required this.meaning,
    this.irregularNote,
  });
}

class CoreVerb {
  final String lemma;
  final VerbClass conjugation;
  final String meaning;
  final bool irregular;
  final String? aspectPair;   // 상 짝 (있으면)
  const CoreVerb({
    required this.lemma,
    required this.conjugation,
    required this.meaning,
    required this.irregular,
    this.aspectPair,
  });
}

/// spec §3 양태 — 주어 격 기준 2분류.
class Modality {
  // A. 여격 주어 (Мне ~), 무변화 — 제일 쉬움, 먼저
  static const yDat = <ModalityItem>[
    ModalityItem(lemma: 'на́до',    meaning: '해야 한다(구어)', subject: '여격', changes: false),
    ModalityItem(lemma: 'ну́жно',   meaning: '해야 한다·필요', subject: '여격', changes: false),
    ModalityItem(lemma: 'мо́жно',   meaning: '해도 된다(허락)', subject: '여격', changes: false),
    ModalityItem(lemma: 'нельзя́',  meaning: '하면 안 된다(금지)', subject: '여격', changes: false),
    ModalityItem(lemma: 'хо́чется', meaning: '(저절로) 하고 싶다', subject: '여격', changes: false),
  ];

  // B. 주격 주어 (Я ~), 변함
  static const yNom = <ModalityItem>[
    ModalityItem(lemma: 'мочь',    meaning: '할 수 있다', subject: '주격', changes: true, kind: '동사(불규칙)'),
    ModalityItem(lemma: 'хоте́ть', meaning: '하고 싶다', subject: '주격', changes: true, kind: '동사(불규칙)'),
    ModalityItem(lemma: 'уме́ть',  meaning: '할 줄 안다', subject: '주격', changes: true, kind: '동사(규칙)'),
    ModalityItem(lemma: 'жела́ть', meaning: '바라다',     subject: '주격', changes: true, kind: '동사(규칙)'),
    ModalityItem(lemma: 'до́лжен', meaning: '해야 한다', subject: '주격', changes: true, kind: '형용사형(성·수 일치)'),
  ];
}

class ModalityItem {
  final String lemma;
  final String meaning;
  final String subject;    // '여격' or '주격'
  final bool changes;
  final String? kind;
  const ModalityItem({
    required this.lemma,
    required this.meaning,
    required this.subject,
    required this.changes,
    this.kind,
  });
}
