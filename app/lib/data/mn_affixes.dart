import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../services/dialogue_service.dart';

/// 몽골어 접사(격어미·복수·재귀 소유·동사 어미) 표 + 자동 분석 — 2026-11-03 사용자 지시
/// ("접사 블록·모음조화 연출·조사 테두리·접사 카드·접사 사전 만들어봐").
///
/// 분석은 규칙 기반이라 틀릴 수 있다(화면에 「자동 분석」 표시). 보수적으로:
/// 2글자 이상 형태만, 어간 3글자 이상만, 자주 쓰는 기능어(아래 [_noSplit])는 나누지 않는다.
/// 예문은 앱에 이미 있는 문장(회화 + 여행 표현)에서만 찾는다 — 새 문장은 만들지 않는다.
enum AffixKind { kase, plural, poss, verb }

extension AffixKindX on AffixKind {
  String get label => switch (this) {
        AffixKind.kase => '격어미',
        AffixKind.plural => '복수',
        AffixKind.poss => '소유',
        AffixKind.verb => '동사 어미',
      };
  Color get color => switch (this) {
        AffixKind.kase => AppColors.ai,
        AffixKind.plural => const Color(0xFFE8913A),
        AffixKind.poss => AppColors.matcha,
        AffixKind.verb => AppColors.beniDeep,
      };
}

/// 모음조화 열쇠: a = 남성(а у), o = 남성 원순(о), e = 여성(э ү и), ö = 여성 원순(ө).
String harmonyOf(String stem) {
  final s = stem.toLowerCase();
  for (var i = s.length - 1; i >= 0; i--) {
    final c = s[i];
    if ('ао'.contains(c) || c == 'у') {
      // 남성: 어간에 о 만 있고 а·у 가 없으면 원순
      final hasA = s.contains('а') || s.contains('у');
      return (s.contains('о') && !hasA) ? 'o' : 'a';
    }
    if ('эүө'.contains(c)) {
      final hasE = s.contains('э') || s.contains('ү');
      return (s.contains('ө') && !hasE) ? 'ö' : 'e';
    }
  }
  return 'e'; // и 만 있으면 여성 쪽
}

class Affix {
  final String id;
  final AffixKind kind;
  final String name; // 한국어 이름
  final String ko; // 대응 한국어(조사·어미)
  final List<String> koMarkers; // 한국어 낱말 속에서 찾을 조사(테두리 묶기)
  final Map<String, String> forms; // 모음조화 열쇠(a·o·e·ö) → 형태
  final List<String> extra; // 모음조화와 무관한 다른 형태
  final String rule;
  const Affix(this.id, this.kind, this.name, this.ko, this.koMarkers, this.forms, this.rule, {this.extra = const []});

  /// 화면에 늘어놓을 형태(중복 없이, a·o·e·ö 순).
  List<String> get variants => {for (final k in const ['a', 'o', 'e', 'ö']) if (forms[k] != null) forms[k]!, ...extra}.toList();
  List<String> get allForms => variants;
}

const List<Affix> kMnAffixes = [
  Affix('abl', AffixKind.kase, '탈격', '-에서 / -로부터', ['에서', '부터'], {'a': 'аас', 'o': 'оос', 'e': 'ээс', 'ö': 'өөс'},
      '어디에서 왔는지·무엇보다. 어간 모음에 맞춰 аас/оос/ээс/өөс.'),
  Affix('dat', AffixKind.kase, '여처격', '-에 / -에서(있는 곳)', ['에서', '에'], {'a': 'ад', 'o': 'од', 'e': 'эд', 'ö': 'өд'},
      '있는 곳·때. 받침 뒤 연결 모음 + д(모음·н·л 뒤에는 д, г·р·с 뒤에는 т 만 붙기도 함).'),
  Affix('acc', AffixKind.kase, '대격', '-을 / -를', ['을', '를'], {'a': 'ыг', 'e': 'ийг'}, '목적어 표시. 남성 ыг, 여성 ийг(모음 뒤 г).'),
  Affix('gen', AffixKind.kase, '속격', '-의', ['의'], {'a': 'ын', 'e': 'ийн'}, '소유·소속. 남성 ын, 여성 ийн(н 뒤 ы/ий, 모음 뒤 н·ний).',
      extra: ['ний']),
  Affix('ins', AffixKind.kase, '조격', '-으로', ['으로', '로'], {'a': 'аар', 'o': 'оор', 'e': 'ээр', 'ö': 'өөр'}, '수단·길. 어간 모음에 맞춰 аар/оор/ээр/өөр.'),
  Affix('com', AffixKind.kase, '공동격', '-와 함께 / -가 있는', ['와', '과', '랑', '함께'], {'a': 'тай', 'o': 'той', 'e': 'тэй'},
      '함께·가지고 있는. 남성 тай, 원순 той, 여성 тэй.'),
  Affix('dir', AffixKind.kase, '방향격', '-로 / -쪽으로', ['로', '쪽'], {'a': 'руу', 'e': 'рүү'}, '가는 방향. 남성 руу, 여성 рүү(р 뒤에는 луу/лүү).',
      extra: ['луу', 'лүү']),
  Affix('pl', AffixKind.plural, '복수', '-들', ['들'], {'a': 'ууд', 'e': 'үүд'}, '여럿. 남성 ууд, 여성 үүд(모음 뒤 нууд/нүүд, 사람 뒤 нар).',
      extra: ['нууд', 'нүүд', 'нар']),
  Affix('refl', AffixKind.poss, '재귀 소유', '자기의 ~', ['자기'], {'a': 'аа', 'o': 'оо', 'e': 'ээ', 'ö': 'өө'},
      '주어 자신의 것. 격어미 뒤에도 붙는다(гэртээ = 자기 집에).'),
  Affix('pres', AffixKind.verb, '현재·미래', '-ㄴ다 / -요', ['요', '다'], {'a': 'на', 'o': 'но', 'e': 'нэ', 'ö': 'нө'}, '지금·곧 하는 일. на/но/нэ/нө.'),
  Affix('pastp', AffixKind.verb, '과거(완료)', '-한 / -했어요', ['했', '왔', '갔', '한'], {'a': 'сан', 'o': 'сон', 'e': 'сэн', 'ö': 'сөн'},
      '이미 한 일·한 적 있는. сан/сон/сэн/сөн.'),
  Affix('past', AffixKind.verb, '과거(방금)', '-했다', ['했', '왔', '갔'], {'a': 'лаа', 'o': 'лоо', 'e': 'лээ', 'ö': 'лөө'}, '방금·확실한 과거. лаа/лоо/лээ/лөө.'),
  Affix('hab', AffixKind.verb, '습관', '-하곤 해요', ['곤', '살아', '해요'], {'a': 'даг', 'o': 'дог', 'e': 'дэг', 'ö': 'дөг'}, '늘 하는 일. даг/дог/дэг/дөг.'),
  Affix('cond', AffixKind.verb, '조건', '-하면', ['면'], {'a': 'вал', 'o': 'вол', 'e': 'вэл', 'ö': 'вөл'}, '~하면. 모음 뒤 в, 자음 뒤 б(бал/бол/бэл/бөл).',
      extra: ['бал', 'бол', 'бэл', 'бөл']),
  Affix('imp', AffixKind.verb, '정중한 명령', '-하세요', ['세요', '요'], {'a': 'аарай', 'o': 'оорой', 'e': 'ээрэй', 'ö': 'өөрэй'},
      '부탁·권유. аарай/оорой/ээрэй/өөрэй.'),
  Affix('desid', AffixKind.verb, '바람', '-고 싶은', ['싶'], {'a': 'маар', 'o': 'моор', 'e': 'мээр', 'ö': 'мөөр'},
      '하고 싶다. 동사 어간 + маар/моор/мээр/мөөр(조격 -аар 와 모양이 비슷하니 주의).'),
  Affix('conv', AffixKind.verb, '연결(~하고서)', '-하고(서)', ['고', '서'], {'a': 'аад', 'o': 'оод', 'e': 'ээд', 'ö': 'өөд'},
      '한 동작 뒤 다음 동작. аад/оод/ээд/өөд.'),
  Affix('inf', AffixKind.verb, '부정사·미래 분사', '-하기 / -할', ['기', '할', '을'], {'a': 'ах', 'o': 'ох', 'e': 'эх', 'ö': 'өх'},
      '사전 형태·할 일. 연결 모음 + х.'),
  Affix('neg', AffixKind.verb, '부정', '-지 않는 / -없는', ['않', '없', '안'], {'e': 'гүй'}, '~하지 않는·~이 없는. 늘 гүй.'),
];

Affix? affixById(String id) => kMnAffixes.where((a) => a.id == id).firstOrNull;

/// 나누지 않는 낱말 — 기능어·인사말처럼 끝이 접사와 같아 보이지만 한 덩어리인 것.
const Set<String> _noSplit = {
  'хаана', 'тэгээд', 'яагаад', 'хэзээ', 'хаашаа', 'ингээд', 'тэгэхээр', 'гэхдээ', 'болохоор', 'учраас', 'бөгөөд',
  'одоо', 'маргааш', 'өчигдөр', 'өнөөдөр', 'энд', 'тэнд', 'хамт', 'үнэхээр', 'заавал', 'үргэлж', 'дахин', 'сайхан',
  'сайн', 'мэнд', 'баяртай', 'тавтай', 'хүсье', 'хоёулаа', 'бүгдээрээ', 'тийм', 'үгүй', 'бас', 'мөн', 'зүгээр',
  'дараа', 'сараа', 'холбоо', 'хажууд', 'дахиад', 'хэдийгээр', 'гадаа', 'дотоо',
};

class AffixHit {
  final String word; // 원래 낱말(대소문자 그대로)
  final String stem;
  final String suffix;
  final Affix affix;
  const AffixHit(this.word, this.stem, this.suffix, this.affix);
  String get harmony => harmonyOf(stem);
}

/// 낱말 하나를 어간 + 접사 하나로 나눈다(가장 긴 형태 우선). 못 나누면 null.
AffixHit? analyzeWord(String word) {
  final w = word.toLowerCase();
  if (w.length < 5 || _noSplit.contains(w)) return null;
  AffixHit? best;
  for (final a in kMnAffixes) {
    for (final f in a.allForms) {
      if (f.length < 2 || !w.endsWith(f)) continue;
      final stemLen = w.length - f.length;
      if (stemLen < 3) continue;
      if (best == null || f.length > best.suffix.length) {
        best = AffixHit(word, word.substring(0, stemLen), word.substring(stemLen), a);
      }
    }
  }
  return best;
}

List<String> splitWords(String s) =>
    s.split(RegExp(r'[^\p{L}\p{M}-]+', unicode: true)).where((w) => w.isNotEmpty).toList();

/// 예문 한 줄(앱에 이미 있는 문장).
class AffixExample {
  final String tl, ko, source;
  final AffixHit hit;
  const AffixExample(this.tl, this.ko, this.source, this.hit);
}

/// 회화(dialogue_service) + 여행 표현(assets/data/vocab/travel_expressions.json)에서 접사가 든 문장을 모은다.
class AffixCorpus {
  AffixCorpus._();
  static final AffixCorpus instance = AffixCorpus._();
  Future<void>? _loading;
  final List<AffixExample> _all = [];

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final lines = <(String, String, String)>[];
    await DialogueService.instance.ensureLoaded();
    for (final d in DialogueService.instance.all) {
      for (final t in d.turns) {
        lines.add((t.tl, t.ko, d.title));
      }
    }
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/vocab/travel_expressions.json')) as Map<String, dynamic>;
      for (final th in (j['themes'] as List? ?? const [])) {
        for (final sec in ((th as Map)['sections'] as List? ?? const [])) {
          for (final w in ((sec as Map)['words'] as List? ?? const [])) {
            final m = w as Map;
            lines.add(('${m['tx'] ?? ''}', '${m['ko'] ?? ''}', '${th['title'] ?? ''}'));
          }
        }
      }
    } catch (_) {}
    final seen = <String>{};
    for (final (tl, ko, src) in lines) {
      for (final w in splitWords(tl)) {
        final h = analyzeWord(w);
        if (h == null) continue;
        if (!seen.add('${h.affix.id}|${w.toLowerCase()}|$tl')) continue;
        _all.add(AffixExample(tl, ko, src, h));
      }
    }
  }

  List<AffixExample> examplesOf(String affixId) => _all.where((e) => e.hit.affix.id == affixId).toList();
  List<AffixExample> get all => List.unmodifiable(_all);
  int count(String affixId) => _all.where((e) => e.hit.affix.id == affixId).length;
}
