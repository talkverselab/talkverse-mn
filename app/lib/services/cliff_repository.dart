import 'package:flutter/services.dart';

import '../domain/models/lemma_entry.dart';

/// assets/data/cliff/l{N}_lemma.tsv 로더 + 메모이즈.
class CliffRepository {
  CliffRepository._();
  static final instance = CliffRepository._();

  final Map<String, List<LemmaEntry>> _cache = {};

  /// stageId: 'l1' | 'l2' | 'l3' | 'l4'
  Future<List<LemmaEntry>> loadStage(String stageId) async {
    final cached = _cache[stageId];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/cliff/${stageId}_lemma.tsv');
    final lines = raw.split('\n');
    final out = <LemmaEntry>[];
    for (var i = 1; i < lines.length; i++) {     // skip header
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split('\t');
      if (cols.length < 6) continue;
      out.add(LemmaEntry.fromTsv(cols));
    }
    _cache[stageId] = out;
    return out;
  }
}
