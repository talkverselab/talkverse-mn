import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../data/mn_affixes.dart';
import '../main.dart';
import 'dialogue_service.dart';

/// 문장 레마 ↔ 단어장(빈도 단어 1,500) 연결 — 사용자 지시 2026-11-04(일본어앱 `byLemmas` 와 같은 역할).
/// 턴에 `lemmas: [[표면형, 기본형, 읽기]]` 데이터가 있으면 그것을, 없으면 앱의 접사 분석기로 기본형 후보를 만든다
/// (낱말 그대로 → 어간 → 어간+х / 어간+모음조화 ах·ох·эх·өх = 동사 사전형).
class LemmaHit {
  final String surface; // 문장 속 형태
  final String base; // 기본형(단어장에 있으면 그 표제어)
  final WordRow? word; // 단어장 항목(없으면 null = 회색 칩)
  const LemmaHit(this.surface, this.base, this.word);
}

/// 내용어가 아닌 품사 — 칩에서 뺀다.
const _skipPos = {'pron', 'conj', 'part', 'postp', 'interj', 'question particle', 'num'};

List<String> lemmaCandidates(String w) {
  final s = w.toLowerCase();
  final out = <String>[s];
  // 단어장 조회용이라 분석기보다 넓게: 끝이 접사 형태와 같으면 긴 것부터 떼어 본다(어간 2자 이상 — ир-сэн 같은 짧은 동사).
  final forms = <String>{for (final a in kMnAffixes) ...a.allForms}.where((f) => f.length >= 2).toList()
    ..sort((x, y) => y.length.compareTo(x.length));
  const inf = {'a': 'ах', 'o': 'ох', 'e': 'эх', 'ö': 'өх'};
  for (final f in forms) {
    if (!s.endsWith(f) || s.length - f.length < 2) continue;
    final st = s.substring(0, s.length - f.length);
    out.addAll([st, '$stх', '$st${inf[harmonyOf(st)]}']);
  }
  return out;
}

Future<List<LemmaHit>> lemmasForTurn(DialogueTurn t) async {
  final given = t.lemmas;
  final surfaces = given.isNotEmpty ? [for (final l in given) l.$1] : splitWords(t.tl.replaceAll(RegExp(r'\{[a-z_]+\}'), ''));
  final cands = <String, List<String>>{};
  for (var i = 0; i < surfaces.length; i++) {
    final s = surfaces[i];
    if (s.length < 2) continue;
    cands[s] = given.isNotEmpty ? [given[i].$2.toLowerCase(), s.toLowerCase()] : lemmaCandidates(s);
  }
  if (cands.isEmpty) return const [];
  final all = {for (final l in cands.values) ...l}.toList();
  final rows = await (appDb.select(appDb.words)..where((w) => w.word.lower().isIn(all))).get();
  final byWord = <String, WordRow>{};
  for (final r in rows) {
    final k = r.word.toLowerCase();
    final prev = byWord[k];
    if (prev == null || r.rank < prev.rank) byWord[k] = r;
  }
  final seen = <String>{};
  final out = <LemmaHit>[];
  for (final e in cands.entries) {
    WordRow? hit;
    for (final c in e.value) {
      hit = byWord[c];
      if (hit != null) break;
    }
    if (hit != null && _skipPos.contains(hit.pos)) continue;
    final base = hit?.word ?? (given.isNotEmpty ? e.value.first : e.key.toLowerCase());
    if (!seen.add(base)) continue;
    out.add(LemmaHit(e.key, base, hit));
  }
  return out;
}
