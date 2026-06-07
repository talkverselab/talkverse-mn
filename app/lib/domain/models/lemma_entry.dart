/// 한 lemma 빈도 항목. cliff TSV 한 행.
class LemmaEntry {
  final int rank;
  final String lemma;
  final String pos;
  final int count;
  final double pct;
  final double cumPct;

  const LemmaEntry({
    required this.rank,
    required this.lemma,
    required this.pos,
    required this.count,
    required this.pct,
    required this.cumPct,
  });

  factory LemmaEntry.fromTsv(List<String> cols) => LemmaEntry(
        rank: int.parse(cols[0]),
        lemma: cols[1],
        pos: cols[2],
        count: int.parse(cols[3]),
        pct: double.parse(cols[4]),
        cumPct: double.parse(cols[5]),
      );
}

/// POS 한글 라벨. (pymorphy3 OpenCorpora 태그)
const posKo = <String, String>{
  'NPRO': '대명사',
  'PRCL': '불변화사·필러',
  'CONJ': '접속사·종속사',
  'PREP': '전치사',
  'VERB': '동사',
  'INFN': '동사(부정사)',
  'ADJF': '형용사',
  'ADJS': '형용사(단형)',
  'ADVB': '부사',
  'NOUN': '명사',
  'PRED': '술어부사',
  'NUMR': '수사',
  'COMP': '비교급',
  'INTJ': '감탄사',
};
